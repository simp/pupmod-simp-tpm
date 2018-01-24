# Enabling this class will set the passwords on the owner and
# endorse hierarchies and the lock password.
#
# With the current version of tpm2-tools (1.7) there is no way to
# dump the capabilities of the tpm to check if the passwords
# are set. There for it is handled manually creating a file, owned,
# in Puppet vardir under simp/<tpm device name>.
#
# NOTE: The password should be generated with passgen in order for most of the facts
# to be functional post-ownership, as the tpm commands from tpm-tools
# require the owner password. You can store the passwords
# locally bit this is not recommended.
#
#
# @param tpm_name     The name of the tpm in the /sys/class/tpm directory.
#
# @param owned        If true set the passwords, if false
#                     It does nothing.
#
# One or more of the following must be set:
# @param owner_auth   The TPM owner auth password, if '' then it will not be set.
# @param lock_auth    The TPM lock auth password, if '' then it will not be set.
# @param endorse_auth The TPM endorse auth password, if '' then it will not be set.
#
# @param in_hex       True if the passwords above are given in Hex.
#
# @param local        Weather or not to write the passwords to a file
#                     on the local system. It is recommended to use
#                     passgen instead.
#
# @author SIMP Team https://simp-project.com
#
class tpm::tpm2::ownership (
  String  $tpm_name     = $tpm::tpm_name,
  Boolean $owned        = true,
  String  $owner_auth   = passgen("${facts['fqdn']}_tpm_owner_auth"),
  String  $lock_auth    = passgen("${facts['fqdn']}_tpm_lock_auth"),
  String  $endorse_auth = passgen("${facts['fqdn']}_tpm_endorse_auth"),
  Boolean $in_hex       = false,
  Boolean $local        = false,
) {

  tpm2_ownership { $tpm_name:
    owned        => $owned,
    owner_auth   => $owner_auth,
    lock_auth    => $lock_auth,
    endorse_auth => $endorse_auth,
    in_hex       => $in_hex,
    local        => $local
  }

}
