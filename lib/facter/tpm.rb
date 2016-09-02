# A strucured fact that return some facts about the TPM:
#
# * output of `tpm_version`
# * pubek
# * owned, enabled, and active status
# * PCRS status
# * caps
#
# @author Nick Miller <nick.miller@onyxpoint.com>
#
Facter.add('tpm') do
  confine :has_tpm => true
  # confine :true => ! (`puppet resource service tcsd | grep running`.eql? "")

  # There is sometimes an unprinted unicode character captured from the command lines
  #   in older versions of ruby, we need to do this encoding nonsense. In ruby 2.1+,
  #   the String#scrub method can be used.
  #
  # @param [String] the string to be cleaned
  #
  # @return [String] string with non-acii characters removed
  #
  def clean_text(text)
    encoding_options = {
      :invalid           => :replace,  # Replace invalid byte sequences
      :undef             => :replace,  # Replace anything not defined in ASCII
      :replace           => '',        # Use a blank for those replacements
      :universal_newline => true       # Always break lines with \n
    }
    text.encode(Encoding.find('ASCII'), encoding_options).gsub(/\u0000/, '')
  end

  # @param [String] the owner password of the TPM
  #
  # @return [String] the output of the command
  #
  def get_pubek_owned(owner_pass)
    require 'expect'
    require 'pty'
    require 'timeout'

    out = []
    PTY.spawn('/sbin/tpm_getpubek') do |r,w,pid|
      w.sync = true
      begin
        r.expect( /owner password/i, 15 ) { |s| w.puts owner_pass }
        r.each { |line| out << line }
      rescue Errno::EIO
        # just until the end of the IO stream
      end
      Process.wait(pid)
    end
    # get rid of title line and return if the exit code is 0
    out.drop(1).join if $? == 0
  end

  def get_pubek_unowned
    require 'timeout'

    out = ''

    status = Timeout::timeout(15) do
      # require 'pry';binding.pry
      out = Facter::Core::Execution.execute('tpm_getpubek')
    end

    out
  end

  # @return [Hash] the yaml output from `tpm_version`
  #
  # The output of tpm_version just so happens to be valid yaml, and
  # it is parsed as such.
  #
  # Example output:
  #  ```
  #    TPM 1.2 Version Info:
  #    Chip Version:        1.2.18.60
  #    Spec Level:          2
  #    Errata Revision:     3
  #    TPM Vendor ID:       IBM
  #    TPM Version:         01010000
  #    Manufacturer Info:   49424d00
  #  ```
  #
  def version
    require 'yaml'

    output = Hash.new
    cmd_out = Facter::Core::Execution.execute('tpm_version')

    if cmd_out == "" or cmd_out.nil?
      output['_status'] = 'Trousers is not running'
    else
      version = YAML.load(clean_text(cmd_out))

      # Format keys in a way that Facter will like
      begin
        output = Hash[version.flatten[1].map{ |k,v| [k.downcase.gsub(/ /, '_'), v] }]
      rescue NoMethodError
        version.delete_if { |k,y| k =~ /Version Info/ }
        output = Hash[version.map{ |k,v| [k.downcase.gsub(/ /, '_'), v] }]
      end

      output['_status'] = 'tpm_version loaded correctly'
    end

    output
  end

  # @return [Hash] information about the TPM from /sys/class/tpm/tpm0/
  #
  def status
    require 'yaml'

    files = Dir.glob('/sys/class/tpm/tpm0/device/*')

    out = Hash.new

    files.each do |file|
      next if File.directory? file
      raw = YAML.load(Facter::Core::Execution.execute("cat #{file}"))
      if raw.is_a? Hash
        out[File.basename(file)] = Hash[raw.map{ |k,v| [k.downcase.gsub(/ /, '_'), v] }]
      else
        out[File.basename(file)] = raw
      end
    end

    out
  end

  # @param [Boolean] whether or not the TPM is owned
  #
  # @return [Hash] the TPM public key, including the raw key in `['raw']`
  #
  # If the TPM is unowned, it can be retreived simply with the command. However,
  #  when the TPM is owned, the command asks for a password. We use an
  #  an interactive PTY to get around this restriction.
  def pubek(status)

    pass_file = "#{Puppet[:vardir]}/simp/tpm_ownership_owner_pass"
    enabled   = status['enabled'] == 1
    owned     = status['owned'] == 1

    out = Hash.new
    raw = ''

    if !enabled
      out['_status'] = 'error: tpm not enabled'
      return out
    elsif !owned
      raw = get_pubek_unowned
      out['_status'] = 'success: tpm unowned'
    else
      if File.exists?(pass_file)
        owner_pass = Facter::Core::Execution.execute("cat #{pass_file}")
        if owner_pass.eql? ""
          out['_status'] = 'error: the password file is empty'
          return out
        else
          raw = get_pubek_owned(owner_pass)
          out['_status'] = 'success: raw pubek grabbed' unless raw.nil?
        end
      else
        out['_status'] = 'error: password file not found'
        return out
      end
    end

    if raw.nil?
      out['_status'] = 'error: trousers is not running, the tpm is not enabled, or the password in the password file is incorrect'
    else
      pubek = YAML.load(raw.gsub(/\t/,' '*4).split("\n").drop(1).join("\n"))
      pubek['Public Key'].gsub!(/ /, '')
      pubek['raw'] = raw
      out.merge!( Hash[pubek.map{ |k,v| [k.downcase.gsub(/ /, '_'), v] }] )
      out['_status'] = 'success: raw parsed'
    end

    out
  end

  setcode do
    out = Hash.new

    # Assemble!
    out['version'] = version
    out['status']  = status
    out['pubek']   = pubek(out['status'])

    out
  end
end
