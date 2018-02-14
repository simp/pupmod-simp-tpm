#  set the ima appraise mode to fix
#
class tpm::ima::appraise::fixmode(
  StdLib::AbsolutePath $relabel_file,
  Boolean              $relabel
){

  kernel_parameter { 'ima_appraise':
    value    => 'fix',
    bootmode => 'normal',
    notify   => Reboot_notify['ima_appraise_fix_reboot']
  }

  if $relabel {
    file { $relabel_file:
      ensure  => 'file',
      owner   => 'root',
      mode    => '0600',
      content => 'relabel'
    }
  } else {
    file { $relabel_file:
      ensure => 'absent'
    }
  }

  reboot_notify { 'ima_appraise_fix_reboot':
    subscribe => [
      Kernel_parameter['ima_appraise'],
    ]
  }

}
