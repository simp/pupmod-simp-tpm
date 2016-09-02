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

  # Get the pubek from tpm_getpubek when the TPM is owned
  # @param [String] the owner password of the TPM
  # @return [String] the output of the command, or nil if it times out
  #
  def get_pubek_owned(owner_pass)
    require 'expect'
    require 'pty'
    require 'timeout'

    out = []

    begin
      Timeout::timeout(15) do
        Puppet.debug('running tpm_getpubek')
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
      end
    rescue Timeout::Error
      return nil
    end

    # get rid of title line and return if the exit code is 0
    out.drop(1).join if $? == 0
  end

  # Get the pubek from tpm_getpubek when the TPM isn't owned
  # @return [String] the output of the command, or nil if it times out
  #
  def get_pubek_unowned
    require 'timeout'

    begin
      status = Timeout::timeout(15) do
        Puppet.debug('running tpm_getpubek')
        Facter::Core::Execution.execute('tpm_getpubek')
      end
    rescue Timeout::Error
      status = 'error: tpm_getpubek timed out'
    end

    status
  end

  # Get the output of tpm_version
  # @return [String] the output of the command, or nil if it times out
  #
  def tpm_version
    require 'timeout'

    begin
      status = Timeout::timeout(15) do
        Puppet.debug('running tpm_version')
        Facter::Core::Execution.execute('tpm_version')
      end
    rescue Timeout::Error
      return nil
    end

    status
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
    cmd_out = tpm_version

    if cmd_out == "" or cmd_out.nil?
      output['_status'] = 'Trousers is not running'
      return output
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
      next if File.directory?(file)
      next if File.basename(file) == 'pubek' # pubek is found in another section

      raw = YAML.load(Facter::Core::Execution.execute("cat #{file}"))
      if raw.is_a? Hash
        out[File.basename(file)] = Hash[raw.map{ |k,v| [k.downcase.gsub(/ /, '_'), v] }]
      else
        out[File.basename(file)] = raw
      end
    end

    out
  end

  # If the TPM is unowned, it can be retreived simply with the command. However,
  #   when the TPM is owned, the command asks for a password. We use an
  #   an interactive PTY to get around this restriction.
  #
  # @param [Boolean] whether or not the TPM is owned
  # @return [Hash] the TPM public key, including the raw key in `['raw']`
  #
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
        owner_pass = Facter::Core::Execution.execute("cat #{pass_file} 2>/dev/null")
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

    if raw.nil? or raw == ""
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
