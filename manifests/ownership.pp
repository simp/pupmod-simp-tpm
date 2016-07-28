# Enabling this class will take ownership of the TPM in the system,
# using an auto-generated password created with simplib's passgen.
#
# The password must be generated with passgen in order for most of the facts
# to be functional post-ownership, as the tpm commands from tpm-tools
# require the owner password.
#
# @param owner_pass [String] The TPM owner password
#
# @param srk_pass [String] The TPM SRK password
#
# @param advanced_facts [Boolean] This option will enable facts that require
#   the owner password to function. The password will be on the client
#   filesystem (in `$vardir/simp`) if enabled.
#
# @author Nick Miller <nick.miller@onyxpoint.com>
#
class tpm::ownership (
  $owner_pass     = passgen( "${::fqdn}_tpm0_owner_pass", { 'length' => 20 } ),
  $srk_pass       = passgen( "${::fqdn}_tpm0_srk_pass", { 'length' => 20 } ),
  $advanced_facts = false
){
  validate_bool($advanced_facts)

  compliance_map()

  # 20 is the max keylength in trousers
  $passgen_opts = {
    'length'     => 20
  }

  tpm_ownership { 'tpm0':
    ensure         => present,
    owner_pass     => $owner_pass,
    srk_pass       => $srk_pass,
    advanced_facts => $advanced_facts
  }

}
