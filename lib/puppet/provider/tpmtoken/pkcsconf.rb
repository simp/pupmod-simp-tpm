#
# @author Nick Miller <nick.miller@onyxpoint.com>
#
Puppet::Type.type(:tpmtoken).provide :pkcsconf do

  confine :has_tpm => true

  defaultfor :kernel => :Linux

  commands :pkcsconf        => 'pkcsconf'
  commands :tpmtoken_init   => 'tpmtoken_init'
  commands :tpm_restrictsrk => 'tpm_restrictsrk'

  mk_resource_methods

  def initialize(value={})
    super(value)
    @property_flush = {}
  end

  def tpmtoken_init(expect_array, cmd = 'tpmtoken_init')
    require 'expect'
    require 'pty'

    pty_timeout = 15

    PTY.spawn( cmd ) do |r,w,pid|
      w.sync = true

      expect_array.each do |reg,stdin|
        debug("Starting the expect session with #{cmd}")
        begin
          r.expect( reg, pty_timeout) do |s|
            w.puts stdin
            debug( "Matched: #{s} | Matcher regex: #{reg} | String typed in: #{stdin}" )
          end
        rescue Errno::EIO
        end
      end

      Process.wait(pid) # set $? to the correct exit code
    end
    exit_code = $?
    debug( "exit code #{exit_code}" )

    if exit_code.exitstatus == 0
      return true
    else
      return false
    end

  end

  def initialize_token(so_pin, user_pin)
    stdin = [
      [ /Enter new password:/i, so_pin   ],
      [ /Confirm password/i,    so_pin   ],
      [ /Enter new password:/i, user_pin ],
      [ /Confirm password/i,    user_pin ],
    ]
    success = tpmtoken_init(stdin)
    debug("Ran tpmtoken_init, which returned exit code: #{success}")
    err('Ininitalizing the TPM PKCS#11 token failed') unless success
  end

  # @return [Array<Hash>] returns an array of hashes, with each hash
  #   representing a different PKCS#11 token
  def self.read_tokens
    require 'yaml'

    begin
      cmd = pkcsconf(['-t']).split("\n")
      debug("Ran pkcsconf -t, with output: #{cmd}")
    rescue Puppet::ExecutionFailure => e
      Puppet.debug "#read_slots had an error -> #{e.inspect}"
      return []
    end

    # clean the output so the YAML parser will read it
    cmd.each do |line|
      line.gsub!(/\t/,' '*4)        # tabs make YAML unhappy
      line.gsub!(/[^[:print:]]/,'') # removes non-printable characters, like \b
      line.gsub!(/#/,'')            # the hash symbol also makes YAML misbehave
    end
    debug('Cleaned the text, now loading YAML')
    y = YAML.load(cmd.join("\n"))

    # lowercase all the keys and replace all spaces with _
    lower = []
    y.values.each do |val|
      debug('Lowercasing all the keys')
      lower << Hash[val.map{ |k,v| [k.downcase.gsub(/ /, '_').to_sym, v] }]
    end

    properties = []
    lower.each do |prop|
      # isolate the flags
      prop[:flags_raw] = prop[:flags]
      prop[:flags]     = prop[:flags_raw].scan(/([A-Z_]{3,})/ ).flatten

      # these need to be in the type
      prop[:name]   = prop[:label]
      prop[:ensure] = prop[:flags].include?('TOKEN_INITIALIZED') ? :present : :absent

      debug("Found token: #{prop.to_json}")
      properties << prop
    end

    properties
  end

  def self.instances
    list = []
    read_tokens.each do |token|
      debug("Adding instance of '#{token[:label]}'")
      list << new(token)
    end
    list
  end

  def self.prefetch(resources)
    debug('Prefetching')
    instances.each do |prov|
      if resource = resources[prov.name]
        resource.provider = prov
      end
    end
  end

  def flush
    if @property_flush[:ensure] == :absent
      f = File.expand_path('/var/lib/opencryptoki/tpm/root')
      FileUtils.rm_rf(f) if File.exists?(f)
      debug("Deleted interface #{resource[:name]} folder at #{f}")
      @property_hash[:ensure] = :absent
    end

    if @property_flush[:ensure] == :present
      if resource[:so_pin].nil? or resource[:user_pin].nil?
        raise(Puppet::Error, 'Both PINs are required to use pkcs_slot')
      end
      debug('Initializing token using initialize_token')
      initialize_token( resource[:so_pin], resource[:user_pin] )
      @property_hash[:ensure] = :present
    end
  end

  def exists?
    debug('Checking if resource exists')
    @property_hash[:ensure] == :present
  end

  def create
    debug('Creating resource')
    @property_flush[:ensure] = :present
  end

  def destroy
    debug('Destroying resource')
    @property_flush[:ensure] = :absent
  end

end
