# Enabling this class will set the passwords on the owner and
# endorse hierarchies and the lock password.
#
# With the current version of tpm2-tools (1.7) there is no way to
# dump the capabilities of the tpm to check if the passwords
# are set.  There for it is handled manually  creating a file, owned,
# in Puppet vardir under simp/<tpm device name>.
#
# NOTE: The password should be generated with passgen in order for most of the facts
# to be functional post-ownership, as the tpm commands from tpm-tools
# require the owner password.  You can store the passwords
# locally bit this is not recommended.
#
#
# @param tpm_name     The name of the tpm in the /sys/class/tpm directory.
#
# @param owned        If true set the passwords, if false
#                     It does nothing.
#
# One or more of the following must be set:
# @param ownerauth   The TPM owner auth password, if '' then it will not be set.
# @param lockauth    The TPM lock auth password, if '' then it will not be set.
# @param endorseauth The TPM endorse auth password, if '' then it will not be set.
#
# @param inhex       True if the passowrds above are given in Hex.
#
# @param local       Weather or not to write the passwords to a file
#                    on the local system.  It is recommended to use
#                    passgen instead.
#
# @author SIMP Team https://simp-project.com
#
class tpm::tpm2::ownership (
  String                  $tpm_name         = $tpm::tpm_name,
  Boolean                 $owned        = true,
  String                  $ownerauth    = passgen( "${facts['fqdn']}_tpm_ownerauth"),
  String                  $lockauth     = passgen( "${facts['fqdn']}_tpm_lockauth "),
  String                  $endorseauth  = passgen( "${facts['fqdn']}_tpm_endorseauth"),
  Boolean                 $inhex        = false,
  Boolean                 $local        = false,
) {

  tpm2_ownership { $tpm_name:
    owned       => $owned,
    ownerauth   => $ownerauth,
    lockauth    => $lockauth,
    endorseauth => $endorseauth,
    inhex       => $inhex,
    local       => $local
  }

}
