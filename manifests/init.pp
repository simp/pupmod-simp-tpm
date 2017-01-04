# Provides utilities for interacting with a TPM
#
# @param ima Toggles IMA on or off.
#
# @param take_ownership Enable to allow Puppet to take ownership
#   of the TPM.
#
# @author Nick Markowski <nmarkowski@keywcorp.com>
# @author Nick Miller <nick.miller@onyxpoint.com>
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

  if $ima {
    include '::tpm::ima'
  }

}
