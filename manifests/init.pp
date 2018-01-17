# Provides utilities for interacting with a TPM
#
# @param ima Toggles IMA on or off.
#
# @param take_ownership Enable to allow Puppet to take ownership
#   of the TPM.
#
# @param tpm_name  The name of the device (usually tpm0).
#
# @param tpm_version  Override for the tpm_version fact.
#
# @param ensure  The ensure status of packages to be installed
#
# @author Nick Markowski <nmarkowski@keywcorp.com>
# @author Nick Miller <nick.miller@onyxpoint.com>
#
class tpm (
  Boolean          $ima            = false,
  Boolean          $take_ownership = false,
  String           $tpm_name       = 'tpm0',
  Optional[Enum[
    'tpm1',
    'tpm2',
    'unknown']]    $tpm_version    = $facts['tpm_version'],
  String           $ensure         = simplib::lookup('simp_options::package_ensure', { 'default_value' => 'installed' })

){
  # Check if the system has a TPM (which also checks that it
  # is a physical machine, and if so install tools and setup
  # tcsd service - uses str2bool because facts return as strings :(
  if str2bool($facts['has_tpm']) and $tpm_version  {

    case $tpm_version {
      'tpm1':   { include 'tpm::tpm1::install' }
      'tpm2':   { include 'tpm::tpm2::install' }
      default:  { warning("${module_name}:  TPM version - ${tpm_version} - is unknown or not supported.") }
    }
  }

  if $ima{
    include 'tpm::ima'
  }
}
