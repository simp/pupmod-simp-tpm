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
  confine do
    Facter::Core::Execution.which('tpm_version')
  end

  setcode do
    require 'facter/tpm/util' unless defined?(Facter::TPM)

    Facter::TPM::Util.new('/sys/class/tpm/tpm0').result
  end
end
