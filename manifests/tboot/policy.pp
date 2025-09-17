# @summary Generate and install policy
#
# This class is controlled by `tpm::tboot`
#
class tpm::tboot::policy {
  assert_private()

  $owner_password       = $tpm::tboot::owner_password
  $create_policy        = $tpm::tboot::create_policy
  $policy_script        = $tpm::tboot::policy_script
  $policy_script_source = $tpm::tboot::policy_script_source
  $update_script        = $tpm::tboot::update_script
  $update_script_source = $tpm::tboot::update_script_source

  file { $policy_script:
    ensure => file,
    source => $policy_script_source
  }

  file { $update_script:
    ensure => file,
    source => $update_script_source
  }

  if $create_policy {

    exec { 'Generate and install tboot policy':
      command => "/usr/bin/sh ${policy_script} ${owner_password}",
      tries   => 1,
      unless  => 'test -f /boot/list.data',
      require => File[$policy_script],
      notify  => Reboot_notify['Tboot Policy Change']
    }

  } else {

    file { '/boot/list.data':
      ensure => absent,
      notify => Reboot_notify['Tboot Policy Change']
    }

  }

  reboot_notify { 'Tboot Policy Change':
    reason => 'Trusted tboot policy has been changed, please reboot to complete a verified launch'
  }

}
