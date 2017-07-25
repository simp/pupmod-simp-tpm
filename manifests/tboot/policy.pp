# Generate and install policy
# This class is controlled by `tpm::tboot`
#
class tpm::tboot::policy {
  assert_private()

  $owner_password       = $tpm::tboot::owner_password
  $policy_script        = $tpm::tboot::policy_script
  $policy_script_source = $tpm::tboot::policy_script_source

  file { $policy_script:
    ensure => file,
    source => $policy_script_source
  }

  # if the last boot wasn't measured, but we did boot with the tboot kernel
  if $facts['tboot'] {
    if ! $facts['tboot']['measured_launch'] and $facts['tboot']['tboot_session'] {
      exec { 'Generate and install tboot policy':
        command => "/usr/bin/sh ${policy_script} ${owner_password}",
        tries   => 1
      }
    }
  }

}
