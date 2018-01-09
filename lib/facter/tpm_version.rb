# A strucured fact that determines what version the TPM is.
#
# This is needed before the software install so the software
# cannot determine the version.  Instead the name of the device
# is checked.  TPM 2.0 are named with MSFT in the devicename
# older versions are not.
Facter.add('tpm_version') do
  confine :has_tpm => true

   setcode do
    tpmlist = Facter::Core::Execution.exec('ls -la /sys/class/tpm/tpm* ')

    if tpmlist.include? 'MSFT' then
      version = 'tpm2'
    else
      version = 'tpm1'
    end
    version
  end
end

