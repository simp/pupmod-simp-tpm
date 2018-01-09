Puppet::Type.type(:tpm2_ownership).provide(:tpm2tools) do
  desc 'The tpm2tools providers uses the TCG software stack (tpm2-tss) and commands provided 
    by tpm2-tools rpm to set the passwords for a TPM 2.0. The current tools
    can not check if the password is set so it will set it and set a flag.  In later versions
    of the tools you can check the status and it the password is unset, you can set it.

    @author SIMP Team https://simp-project.com'

  has_feature :take_ownership

  confine :has_tpm => true
  confine :tpm_version => 'tpm2'

  defaultfor :kernel => :Linux

  commands :tpm2_takeownership => 'tpm2_takeownership'

  def initialize(value={})
    super(value)
    @property_flush = {}
  end

  # Dump the owner password to a flat file in Puppet's `$vardir`
  #
  # @param [String] path where fact will be dumped
  def dump_pass(name, vardir)
    require 'json'
    pass_file = File.expand_path("#{vardir}/simp/#{name}_data")

    passwords = { "owner_pass" => resource[:owner_pass],
                  "lock_pass" => resource[:lock_pass],
                  "endorse_pass" => resource[:endorse_pass]
                }
    # Check to make sure the SIMP directory in vardir exists, or create it
    if !File.directory?( File.dirname(pass_file) )
      FileUtils.mkdir_p( File.dirname(pass_file), :mode => 0700 )
      FileUtils.chown( 'root','root', File.dirname(pass_file) )
    end

    debug('tpm2: creating data file')
    # Dump the password to pass_file
    file = File.new( pass_file, 'w', 0600 )
    file.write( passwords.to_json )
    file.close

  end

  # Call  tpm2_takeownership and write out the data file
  #
  def takeownership( )
    require 'json'

    output = ''

    debug('tpm2_takeownership: calling subroutines to get options')
#    options = gen_tcti_args() + gen_passwd_args()
    options = gen_passwd_args()

    begin
      debug('tpm2: printing options')
      debug(options.to_s)
      output = tpm2_takeownership(options)
    rescue Puppet::ExecutionFailure => e
      debug("tpm2_takeownership failed with error -> #{e.inspect}")
      return e
    end

    dump_pass(resource[:name], Puppet[:vardir])
# may need to check the output    
    output
  end

  # Generate standard args for connecting to the TPM.  These arguements
  # are common for most TPM2 commands.
  #
  # @return [String] Return a string of the tcti arguements.
  def gen_tcti_args()
    options    = []

    debug('tpm2_takeownership setting tcti args.')
    case resource[:tcti]
    when :devicefile
      options << "--tcti device"
      options << "-d #{resource[:devicefile]}"
    else
      options << "--tcti socket"
      options << "-R #{resource[:socket_address]}"
      options << "-p #{resource[:socket_port]}"
    end

    options
  end

  # Generate the passwords argumentsto set on the TPM.
  #
  # @return [String] Return a string arguements.
  def gen_passwd_args()
    options = []

    debug('tpm2_takeownership setting passwd args.')
#   where to check that at least one of these is set?  Here or in type.
    if !resource[:owner_pass].nil?
      options << "-o #{resource[:owner_pass]}"
    end
    if !resource[:lock_pass].nil?
      options << "-l #{resource[:lock_pass]}"
    end
    if !resource[:endorse_pass].nil?
      options << "-e #{resource[:endorse_pass]}"
    end

    unless options.any?
      raise Puppet::Error, "At least one of owner_pass, lock_pass or endorse_pass must be provided"
    end

    if resource[:inhex]
      options << "-X"
    end

    options
  end


  def self.read_sys( sys_glob = '/sys/class/tpm/*', vardir = Puppet[:vardir])
    # Check and see if the data file exists for the tpm.  In version 2 you can
    # use tpm2_dump_capability to check what passwords are set.
    Dir.glob(sys_glob).collect do |tpm_path|
      debug(tpm_path)
      tpmname = File.basename(tpm_path)
      datafile = "#{vardir}/simp/#{tpmname}_data"
      debug('tpm2: data file name:')
      debug(datafile)
      if File.exists?(datafile)
        currently_owned = :true
      else
        currently_owned = :false
      end
      {
        name:  tpmname,
        owned: currently_owned
      }
    end
  end

  def self.instances
    read_sys.collect do |tpm|
      debug("tpm2: Adding tpm: #{tpm[:name]}")
      debug("tpm2: with owned: #{tpm[:owned].to_s}")
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
    debug 'tpm2: Setting property_flush to should'
    if should == :false 
      warning 'tpm2_ownership does not support disowning the tpm'
      @property_flush[:owned] = true
    else
      @property_flush[:owned] = should
    end
  end

  def owned
    @property_hash[:owned]
  end

  def flush
    debug 'tpm2: Flushing tpm2_ownership'
    debug 'tpm2: property flush owned'
    debug @property_flush[:owned]
    debug 'tpm2: property hash owned'
    debug @property_hash[:owned]
    if @property_flush[:owned] == :true  and @property_hash[:owned] == :false
      debug('tpm2: calling tpm2_takeownership routine.')
      output =  takeownership()
      unless output.nil?
        fail Puppet::Error,"Could not take ownership of the tpm. Error from tpm2_takeownership is #{output.inspect}"
      end
      @property_hash[:owned] = :true
    else
      debug 'tpm2: resource is in correct state'
    end
  end

end

