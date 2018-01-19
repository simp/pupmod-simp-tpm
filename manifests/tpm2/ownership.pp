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
# @param owned        If true set the passwords, if false
#                     It does nothing.
#
# @param ownerauth   The TPM owner auth password
# @param lockauth    The TPM lock auth password
# @param endorseauth The TPM endorse auth password
#
# @author SIMP Team https://simp-project.com
#
#
class tpm::tpm2::ownership (
  Boolean          $owned        = true,
  Optional[String] $ownerauth    = passgen( "${facts['fqdn']}_tpm_ownerauth"),
  Optional[String] $lockauth     = passgen( "${facts['fqdn']}_tpm_lockauth "),
  Optional[String] $endorseauth  = passgen( "${facts['fqdn']}_tpm_endorseauth"),
) {

  tpm2_ownership { "#{tpm::tpm_name}":
    owned        => $owned,
    owner_pass   => $ownerauth,
    lock_pass    => $lockauth ,
    endorse_pass => $endorseauth,
  }

}
