# Provides utilities for interacting with a TPM
#
# @param use_ima [Boolean] Toggles IMA on or off.
#
# @param take_ownership [Boolean] Enable to allow Puppet to take ownership
#   of the TPM.
#
# @author Nick Markowski <nmarkowski@keywcorp.com>
# @author Nick Miller <nick.miller@onyxpoint.com>
#
class tpm (
  $use_ima               = false,
  $take_ownership        = false
){
  validate_bool($use_ima)
  validate_bool($take_ownership)

  # Check if the system has a TPM (which also checks that it
  # is a physical machine, and if so install tools and setup
  # tcsd service - uses str2bool because facts return as strings :(
  if str2bool($::has_tpm) {
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

  if $use_ima {
    include '::tpm::ima'
  }

}
