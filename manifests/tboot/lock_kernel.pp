#
class tpm::tboot::lock_kernel {

  $lock_kernel_packages    = $tpm::tboot::lock_kernel_packages
  $kernel_packages_to_lock = $tpm::tboot::kernel_packages_to_lock

  $kernel_packages_to_lock.each |$kernel_package| {
    $_ensure = $lock_kernel_packages ? {
      true    => present,
      default => absent
    }
    yum::versionlock { "*:${kernel_package}-*-*.*":
      ensure => $_ensure
    }
  }

}
