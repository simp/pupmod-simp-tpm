Puppet::Type.type(:tpm_ownership).provide(:trousers) do
  desc 'The trousers provider for the tpm_ownership type used `tcsd`-provided
    commands to take ownership of tpm0. Trousers does not allow the user
    to provide a TPM on another path.

    @author Nick Miller <nick.miller@onyxpoint.com>'

  has_feature :take_ownership

  confine :has_tpm => true
  # confine do
  #   File.read(File.join(tpm_path,'device','enabled')).to_i == 1
  # end

  defaultfor :kernel => :Linux

  commands :tpm_takeownership => 'tpm_takeownership'

  # mk_resource_methods

  def initialize(value={})
    super(value)
    @property_flush = {}
  end

  # Dump the owner password to a flat file in Puppet's `$vardir`
  #
  # @param [String] path where fact will be dumped
  def dump_owner_pass(vardir)
    pass_file = File.expand_path("#{vardir}/simp/tpm_ownership_owner_pass")

    # Check to make sure the SIMP directory in vardir exists, or create it
    if !File.directory?( File.dirname(pass_file) )
      FileUtils.mkdir_p( File.dirname(pass_file), :mode => 0700 )
      FileUtils.chown( 'root','root', File.dirname(pass_file) )
    end

    # Dump the password to pass_file
    file = File.new( pass_file, 'w', 0660 )
    file.write( resource[:owner_pass] )
    file.close

    File.read(pass_file)
  end

  # Interact with a tpm_takeownership using stdin
  #
  # @param command [String] The command to interact with
  # @param stdin [Array<Regex, String>] List of pairs [regex, string] to print as stdin
  # @return [Boolean] <= 0 is true, anything else is false
  def tpm_takeownership(expect_array, cmd = 'tpm_takeownership' )
    require 'expect'
    require 'pty'

    pty_timeout = 15

    PTY.spawn( cmd ) do |r,w,pid|
      w.sync = true

      expect_array.each do |reg,stdin|
        begin
          r.expect( reg, pty_timeout) do |s|
            w.puts stdin
            debug( [reg, stdin, s] )
          end
        rescue Errno::EIO
        end
      end

      Process.wait(pid) # set $? to the correct exit code
    end
    exit_code = $?
    debug( ['exit code', exit_code] )

    exit_code.exitstatus == 0 ? true : false
  end

  # Generate the arguments required to interact with tpm_takeownership.
  #
  # @return [Array,String] The first item returned will be an array of arrays,
  #   representing an Expect interaction. Each subarray first contains a regex
  #   of what to expect, and next contains the text to be typed in. The second
  #   item being returned is the command that will be interacted with, with
  #   proper arguments as decided by this function.
  def generate_args
    stdin      = []
    cmd        = ['tpm_takeownership']
    owner_pass = resource[:owner_pass]
    srk_pass   = resource[:srk_pass]

    if owner_pass != 'well-known'
      stdin << [ /owner password/i,   owner_pass ]
      stdin << [ /Confirm password/i, owner_pass ]
    else
      cmd << '-y'
    end

    if srk_pass != 'well-known'
      stdin << [ /SRK password/i,     srk_pass   ]
      stdin << [ /Confirm password/i, srk_pass   ]
    else
      cmd << '-z'
    end
    return stdin, cmd.join(' ')
  end

  def self.read_sys(sys_glob = '/sys/class/tpm/*')
    t = { 1 => true, 0 => false }
    Dir.glob(sys_glob).collect do |tpm_path|
      debug(tpm_path)
      {
        :name        => File.basename(tpm_path),
        :active      => t[File.read(File.join(tpm_path,'device','active')).to_i],
        :owned       => t[File.read(File.join(tpm_path,'device','owned')).to_i],
        :enabled     => t[File.read(File.join(tpm_path,'device','enabled')).to_i],
        :tpm_version => File.readlines(File.join(tpm_path,'device','caps'))[1].split(':')[1].to_f,
      }
    end
  end


  def self.instances
    read_sys.collect do |tpm|
      debug("Adding tpm #{tpm[:name]}")
      new(tpm)
    end
  end

  def self.prefetch(resources)
    instances.each do |prov|
      if resource = resources[prov.name]
        resource.provider = prov
      end
    end
  end

  def owned=(should)
    debug 'got to owned='
    @property_flush[:owned] = true
  end

  def owned
    debug 'tpm existing?'
    if resource[:advanced_facts]
      debug "Dumping tpm owner password"
      dump_owner_pass(Puppet[:vardir])
    end
    @property_hash[:owned]
  end

  def active
    debug 'found active'
    @property_hash[:active]
  end

  def enabled
    debug 'found enabled'
    @property_hash[:enabled]
  end

  def tpm_version
    debug 'found tpm_version'
    @property_hash[:tpm_version]
  end

  def flush
    debug 'flushing tpm'
    if @property_flush[:owned] == true and @property_hash[:owned] == false
      expect, cmd = generate_args
      debug 'expect input' + expect.inspect
      debug 'tpm_takeownership command' + cmd.inspect

      tpm_takeownership(expect, cmd)

      @property_hash[:owned] = true
    end
  end

end
