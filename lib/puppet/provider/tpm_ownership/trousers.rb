# The trousers provider for the tpm_ownership type used `tcsd`-provided
# commands to take ownership of tpm0. Trousers does not allow the user
# to provide a TPM on another path.
#
# @author Nick Miller <nick.miller@onyxpoint.com>
#
Puppet::Type.type(:tpm_ownership).provide :trousers do
  has_feature :take_ownership

  confine :has_tpm => true
  # confine :tpm do |value|
  #   value['status']['enabled'] == 1
  # end

  defaultfor :kernel => :Linux

  commands :tpm_takeownership => 'tpm_takeownership'

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

    if exit_code.exitstatus == 0
      return true
    else
      return false
    end
  end

  def exists?
    if resource[:advanced_facts]
      dump_owner_pass(Puppet[:vardir])
    end

    if Facter.value(:tpm)['status']['owned'] == 1
      return true
    else
      return false
    end
  end

  def create
    stdin = [
      [ /owner password/i,   resource[:owner_pass] ],
      [ /Confirm password/i, resource[:owner_pass] ],
      [ /SRK password/i,     resource[:srk_pass]   ],
      [ /Confirm password/i, resource[:srk_pass]   ],
    ]
    success = tpm_takeownership(stdin)

    err('Taking ownership of the TPM failed.') unless success
  end

  def destroy
    alert('Clearing the TPM is not supported in Puppet due to the risk of data loss')
  end

end
