#
# Installs the TCG Software stack for the TPM and
# and configures service.
#
# @param package_ensure The ensure status of packages to be installed
#
class tpm::tpm1::install(
  String $package_ensure = $::tpm::package_ensure
){

  $pkg_list = [ 'tpm-tools', 'trousers']

  # Install the needed packages
  ensure_resource('package',
    $pkg_list,
    {
      'ensure' => $package_ensure,
      'before' => Service['tcsd']
    }
  )

  # Start the resource daemon
  service { 'tcsd':
    ensure => 'running',
    enable => true,
  }

  if $::tpm::take_ownership {
    include '::tpm::tpm1::ownership'
  }

}
