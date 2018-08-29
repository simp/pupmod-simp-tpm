# Provides utilities for interacting with a TPM
#
# @param ima Toggles IMA on or off. 
#   NOTE: This parameter is deprecated and throws a warning if specified.
#   IMA may remain on if the ima module is enabled elsewhere.
#
# @param take_ownership Enable to allow Puppet to take ownership
#   of the TPM.
#
# @author https://github.com/simp/pupmod-simp-tpm/graphs/contributors
#
class tpm (
  Boolean $ima            = false,
  Boolean $take_ownership = false
){
  # Check if the system has a TPM (which also checks that it
  # is a physical machine, and if so install tools and setup
  # tcsd service - uses str2bool because facts return as strings :(
  if str2bool($facts['has_tpm']) {
    package { 'tpm-tools': ensure => latest }
    package { 'trousers': ensure => latest }

    service { 'tcsd':
      ensure  => 'running',
      enable  => true,
      require => Package['tpm-tools'],
    }

    if $take_ownership {
      include '::tpm::ownership'
    }
  }

  # The following should be removed at a later date, along with the
  # dependency in the metadata.json.
  if $ima {
    warning ('tpm::ima is deprecated and has been moved to its own module.')
    include '::ima'
  }
}
