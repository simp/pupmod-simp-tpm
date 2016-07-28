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
  def get_pubek(owner_pass)
    require 'expect'
    require 'pty'

    out = []
    PTY.spawn('/sbin/tpm_getpubek') do |r,w|
      w.sync = true
      begin
        r.expect( /owner password/i, 15 ) { |s| w.puts owner_pass }
        r.each { |line| out << line }
      rescue Errno::EIO
        # just until the end of the IO stream
      end
    end
    out.drop(1).join
  end

  # @return [Hash] the yaml output from `tpm_version`
  #
  # The output of tpm_version just so happens to be valid yaml, and
  # it is parsed as such.
  #
  # Example output:
  #  ```
  #  TPM 1.2 Version Info:
  #  Chip Version:        1.2.18.60
  #  Spec Level:          2
  #  Errata Revision:     3
  #  TPM Vendor ID:       IBM
  #  TPM Version:         01010000
  #  Manufacturer Info:   49424d00
  #  ```
  #
  def version
    require 'yaml'

    output = Facter::Core::Execution.execute('tpm_version')

    if output == "" or output.nil?
      'Trousers is not running'
    else
      version = YAML.load(clean_text(output))

      # Format keys in a way that Facter will like
      begin
        Hash[version.flatten[1].map{ |k,v| [k.downcase.gsub(/ /, '_'), v] }]
      rescue NoMethodError
        version.delete_if { |k,y| k =~ /Version Info/ }
        Hash[version.map{ |k,v| [k.downcase.gsub(/ /, '_'), v] }]
      end
    end
  end

  # @return [Hash] information about the TPM from /sys/class/tpm/tpm0/
  #
  def status
    require 'yaml'

    out = Hash.new

    pcrs = YAML.load(Facter::Core::Execution.execute('cat /sys/class/tpm/tpm0/device/pcrs'))
    caps = YAML.load(Facter::Core::Execution.execute('cat /sys/class/tpm/tpm0/device/caps'))

    # keys can be symbols when we use ruby 2.1+
    out['pcrs'] = Hash[pcrs.map{ |k,v| [k.downcase.gsub(/ /, '_'), v] }]
    out['caps'] = Hash[caps.map{ |k,v| [k.downcase.gsub(/ /, '_'), v] }]

    out['owned']   = Facter::Core::Execution.execute('cat /sys/class/tpm/tpm0/device/owned')
    out['enabled'] = Facter::Core::Execution.execute('cat /sys/class/tpm/tpm0/device/enabled')
    out['active']  = Facter::Core::Execution.execute('cat /sys/class/tpm/tpm0/device/active')

    out
  end

  # @param [Boolean] whether or not the TPM is owned
  #
  # @return [Hash] the TPM public key, including the raw key in `['raw']`
  #
  # If the TPM is unowned, it can be retreived simply with the command. However,
  #  when the TPM is owned, the command asks for a password. We use an
  #  an interactive PTY to get around this restriction.
  def pubek(owned)
    require 'timeout'

    pass_file = "#{Puppet[:vardir]}/simp/tpm_ownership_owner_pass"

    if !owned
      if File.exists?(pass_file)
        raw = 'Cannot access pubek. Check that $vardir/simp/tpm_ownership_owner_pass exists and contains the correct password. Then, check your tpm_ownership resource to make sure the it uses the correct password.'
      else
        raw = Facter::Core::Execution.execute('tpm_getpubek')
      end
    else
      if File.exists?(pass_file)
        owner_pass = Facter::Core::Execution.execute("cat #{pass_file}")
        raw = get_pubek(owner_pass) unless owner_pass.eql? ""
      else
        raw = 'Password file not found or Trousers is not running'
      end
    end

    raw = 'Trousers is not running' if raw.nil? or raw.eql? ""

    pubek = YAML.load(raw.gsub(/\t/,' '*4).split("\n").drop(1).join("\n"))
    if pubek.is_a? Hash
      pubek['Public Key'].gsub!(/ /, '')
      pubek['raw'] = raw
      Hash[pubek.map{ |k,v| [k.downcase.gsub(/ /, '_'), v] }]
    else
      raw.strip
    end
  end

  setcode do
    out = Hash.new

    # Assemble!
    out['version'] = version
    out['status']  = status
    out['pubek']   = pubek(out['status']['owned'] == '1')

    out
  end
end
