# == Class: tpm
#
# Sets up tpm
#
# == Parameters
#
# [*use_ima*]
#   Boolean.  Toggles IMA on or off.
#
# == Authors
#
# * Nick Markowski <nmarkowski@keywcorp.com>
#
class tpm (
  $use_ima = true
){
  # Check if the system has a TPM (which also checks that it
  # is a physical machine, and if so install tools and setup
  # tcsd service - uses str2bool because facts return as strings :(
  if str2bool($::has_tpm) {
    package { 'tpm-tools':
      ensure => 'present',
    }

    service { 'tcsd':
      ensure  => 'running',
      enable  => true,
      require => Package['tpm-tools'],
    }
  }

  if $use_ima {
    include '::tpm::ima'
  }
}
