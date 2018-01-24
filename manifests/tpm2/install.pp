#
# Installs the TCG Software stack for the TPM and
# and configures service.
#
# @param package_ensure The ensure status of packages to be installed
#
class tpm::tpm2::install(
  String $package_ensure = $::tpm::package_ensure
){

  if $facts['os']['name'] in ['RedHat','CentOS'] {
    if versioncmp($facts['os']['release']['major'],'7') >= 0 {
      $pkg_list = ['tpm2-tools', 'tpm2-tss']

      # Install the needed packages
      ensure_resource('package',
        $pkg_list,
        {
          'ensure' => $package_ensure,
          'before' => Service['resourcemgr']
        }
      )

      # Start the resource daemon
      service { 'resourcemgr':
        ensure => 'running',
        enable => true,
      }

      if $::tpm::take_ownership {
        include '::tpm::tpm2::ownership'
      }

    }
    else {
      fail("Operating System ${facts['os']['name']} version ${facts['os']['release']['major']} is not supported for TPM 2.0")
    }
  }
  else {
    fail("Operating System ${facts['os']['name']} is not supported for TPM 2.0")
  }
}
