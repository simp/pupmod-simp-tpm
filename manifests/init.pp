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
  Boolean                $ima            = false,
  Boolean                $take_ownership = false,
  Array[String]          $package_list   = [],
  String                 $service_name   = '',
  String                 $ensure         = simplib::lookup('simp_options::package_ensure', { 'default_value' => 'installed' }),
  Optional[
    Enum['tpm1','tpm2']] $tpm_version    = $facts['tpm_version']
){
  # Check if the system has a TPM (which also checks that it
  # is a physical machine, and if so install tools and setup
  # tcsd service - uses str2bool because facts return as strings :(
  if str2bool($facts['has_tpm']) and $tpm_version  {

    case $tpm_version {
      'tpm1': { include 'tpm::tpm1::install' }
      'tpm2': { include 'tpm::tpm2::install' }
      default:  { warning("${module_name}:  TPM version - ${tpm_version} - is unknown or not supported.") }
    }
  }

  if $ima{
    include 'tpm::ima'
  }
}
