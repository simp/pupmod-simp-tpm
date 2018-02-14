#  set the ima appraise mode to enforce
#
class tpm::ima::appraise::enforcemode(
){

    kernel_parameter { 'ima_appraise':
      value    => 'enforce',
      bootmode => 'normal',
      notify   => [ Reboot_notify['ima_appraise_enforce_reboot'], Exec['dracut ima appraise rebuild']]
    }
    reboot_notify { 'ima_appraise_enforce_reboot':
      subscribe => Kernel_parameter['ima_appraise']
    }
    exec { 'dracut ima appraise rebuild':
      command     => '/sbin/dracut -f',
      subscribe   => Kernel_parameter['ima_appraise'],
      refreshonly => true
    }
}
