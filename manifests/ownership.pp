# @summary Take ownership of the TPM in the system, using an auto-generated password created with simplib's passgen.
#
# The password must be generated with passgen in order for most of the facts
# to be functional post-ownership, as the tpm commands from tpm-tools
# require the owner password.
#
# @param owned
#   Whether or not the module should take ownership
#
# @param owner_pass
#   The TPM owner password
#
# @param srk_pass
#   The TPM SRK password
#
#   * Defaults to an empty String because according to the [trousers
#     documentation](http://trousers.sourceforge.net/pkcs11.html) it needs to be
#     null to be useful.
#
# @param advanced_facts
#   Enable facts that require the owner password to function. The password will
#   be on the client filesystem (in `$vardir/simp`) if enabled.
#
# @author Nick Miller <nick.miller@onyxpoint.com>
#
class tpm::ownership (
  Boolean                                $owned          = true,
  Variant[Enum['well-known'],String[20]] $owner_pass     = simplib::passgen( "${facts['networking']['fqdn']}_tpm0_owner_pass", { 'length' => 20 } ),
  Optional[String]                       $srk_pass       = undef,
  Boolean                                $advanced_facts = false
) {

  tpm_ownership { 'tpm0':
    owned          => $owned,
    owner_pass     => $owner_pass,
    srk_pass       => $srk_pass,
    advanced_facts => $advanced_facts,
  }
}
