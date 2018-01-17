# A strucured fact that determines what version the TPM is.
#
# This is needed before the software install so the software
# cannot determine the version.  Instead the name of the device
# is checked.  TPM 2.0 are named with MSFT in the devicename
# older versions are not.
Facter.add('tpm_version') do
  confine :has_tpm => true

   setcode do
    tpmlist = Dir.glob('/sys/class/tpm/tpm*').map {|x|
        if File.symlink?(x)
          File.readlink(x)
        end
      }
    # if there are no files or no links to devices then return
    # unknown
    if tpmlist.empty? or tpmlist.join.empty? then
      version = 'unknown'
    elsif tpmlist.to_s.include? 'MSFT' then
      version = 'tpm2'
    else
      version = 'tpm1'
    end
    version
  end

end
