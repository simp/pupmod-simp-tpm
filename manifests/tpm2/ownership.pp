# Enabling this class will set the passwords on the owner and
# endorse hierarchies and the lock password.
#
# With the current version of tpm-tools (1.7) there is no way to
# dump the capabilities of the tpm to check if the passwords
# are set.  There for it is handled manually by storing the password once
# set in a file in ${vardir}/simp. If these files, one for each password,
# exist it will not attempt to set the password.  Also because of this you must
# either set all three or clear all three.
#
# There is a check to make sure the passwords are atleast 16 characters.
#
# To clear the passwords, you only need the lockauth password.
#
# If there is an error then the file will be created with an error
# message and must be removed before this module will attempt to set the
# password again.
#
# The password must be generated with passgen in order for most of the facts
# to be functional post-ownership, as the tpm commands from tpm-tools
# require the owner password.
#
# @param owned        If true set the passwords, if false clear the
#                     passwords (requires the lockauth password.)
#
# @param owner_pass   The TPM owner auth password
# @param lock_pass    The TPM lock auth password
# @param endorse_pass The TPM endorse auth password
#
# @author SIMP Team https://simp-project.com
#
#
class tpm::tpm2::ownership (
  Boolean          $owned        = true,
  Optional[String] $ownerauth    = passgen( "${facts['fqdn']}_tpm0_ownerauth"),
  Optional[String] $lockauth     = passgen( "${facts['fqdn']}_tpm0_lockauth "),
  Optional[String] $endorseauth  = passgen( "${facts['fqdn']}_tpm0_endorseauth"),
) {

  tpm2_ownership { "#{tpm::tpm_name}":
    owned        => $owned,
    owner_pass   => $ownerauth,
    lock_pass    => $lockauth ,
    endorse_pass => $endorseauth,
  }

}
