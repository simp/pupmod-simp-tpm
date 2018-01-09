#
# @summary Installs the TCG Software stack for the TPM and
#          and configures service.
#
class tpm::tpm1::install(
  String        $ensure        = $tpm::ensure
){

  $pkg_list = [ 'tpm-tools', 'trousers']

  # Install the needed packages
  ensure_resource('package', $pkg_list, { 'ensure' => $ensure, before => Service['tcsd'] })

  # Start the resource daemon
  service {  'tcsd':
    ensure => 'running',
    enable => true,
  }

  if $tpm::take_ownership {
    include 'tpm::tpm1::ownership'
  }

}
