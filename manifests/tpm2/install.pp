#
# @summary Installs the TCG Software stack for the TPM and
#          and configures service.
#
class tpm::tpm2::install(
  String        $ensure        = $tpm::ensure
){

  $pkg_list = ['tpm2-tools', 'tpm2-tss']

  # Install the needed packages
  ensure_resource('package', $pkg_list, { 'ensure' => $ensure, before => Service['resourcemgr'] })

  # Start the resource daemon
  service { 'resourcemgr':
    ensure => 'running',
    enable => true,
  }

  if $tpm::take_ownership {
    include 'tpm::tpm2::ownership'
  }

}
