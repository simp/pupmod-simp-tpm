# Manage the tpm-enabled PKCS #11 interface
#
# If the SO_PIN_LOCKED flag gets thrown, you will have to reset your interface
#   by deleting the /var/lib/opencryptoki/tpm/root/NVTOK.DAT file.
#
# @param so_pin 4-8 character password used for the Security Officer pin.
#
# @param user_pin 4-8 character password used for the user pin.
#
# @param package_ensure The ensure status of packages to be installed.
#
class tpm::pkcs11 (
  String $so_pin         = passgen("${facts['fqdn']}_pkcs_so_pin", { 'length' => 8 } ),
  String $user_pin       = passgen("${facts['fqdn']}_pkcs_user_pin", { 'length' => 8 } ),
  String $package_ensure = simplib::lookup('simp_options::package_ensure', { 'default_value' => 'installed' })
) {
  ##################################################################################################################
  # Here's a nice doc on how to set up the PKCS #11 interface
  # https://access.redhat.com/documentation/en-US/Red_Hat_Enterprise_Linux/7/html/Security_Guide/sec-Encryption.html
  # http://trousers.sourceforge.net/pkcs11.html
  ##################################################################################################################
  package { 'opencryptoki':        ensure => $package_ensure }
  package { 'opencryptoki-tpmtok': ensure => $package_ensure }
  package { 'tpm-tools-pkcs11':    ensure => $package_ensure }

  service { 'pkcsslotd':
    ensure => running,
    enable => true,
  }

  tpmtoken { 'TPM PKCS#11 Token':
    ensure   => present,
    so_pin   => $so_pin,
    user_pin => $user_pin
  }

}
