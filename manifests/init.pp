# == Class: tpm
#
# Provides utilities for interacting with a TPM
#
# == Parameters
#
# [*use_ima*]
#   Boolean.  Toggles IMA on or off.
#
# [*use_tboot*]
#   Boolean.  Toggles tboot on or off.  
#
# == Authors
#
# * Nick Markowski <nmarkowski@keywcorp.com>
#
class tpm (
  $use_ima = false,
  $use_tboot = false
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

  if $use_tboot {
    include '::tpm::tboot'
  }
}
