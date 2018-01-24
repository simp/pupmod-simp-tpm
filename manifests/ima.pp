# Sets up IMA kernel boot flags if they are not enabled, and mounts the
# securityfs when they are.
#
# @param enable If true, enable IMA on the system.
#
# @param manage_policy If true, the tpm::ima::policy class will be
#   included. Please read the documentation for that class **carefully**, as it can
#   cause live filesystems to become read-only until a reboot.
#
# @param mount_dir Where to mount ima securityfs
#
# @param ima_audit
#   Audit control. Can be set to:
#     true  - Enable additional integrity auditing messages
#     false - Enable integrity auditing messages (default)
#
# @param ima_template
#   A pre-defined IMA measurement template format.
#
# @param ima_hash
#   The list of supported hashes can be found in crypto/hash_info.h
#
# @param ima_tcb Toggle the TCB policy. This means IMA will measure
#   all programs exec'd, files mmap'd for exec, and all file opened
#   for read by uid=0. Defaults to true.
#
# @param log_max_size The size of the
#   /sys/kernel/security/ima/ascii_runtime_measurements, in bytes, that will
#   cause a reboot notification will be sent to the user.
#
# @author Nick Markowski <namarkowski@keywcorp.com>
# @author Trevor Vaughan <tvaughan@onyxpoint.com>
#
class tpm::ima (
  Boolean              $enable        = true,
  Boolean              $manage_policy = false,
  Stdlib::AbsolutePath $mount_dir     = '/sys/kernel/security',
  Boolean              $ima_audit     = true,
  Tpm::Ima::Template   $ima_template  = 'ima-ng',
  String               $ima_hash      = 'sha256',
  Boolean              $ima_tcb       = true,
  Integer              $log_max_size  = 30000000
){

  if $enable {
    if $facts['cmdline']['ima'] == 'on' {
      mount { $mount_dir:
        ensure   => mounted,
        atboot   => true,
        device   => 'securityfs',
        fstype   => 'securityfs',
        target   => '/etc/fstab',
        remounts => true,
        options  => 'defaults',
        dump     => '0',
        pass     => '0'
      }
    }

    kernel_parameter { 'ima':
      value    => 'on',
      bootmode => 'normal'
    }
    kernel_parameter { 'ima_audit':
      value    => bool2str($ima_audit),
      bootmode => 'normal'
    }
    kernel_parameter { 'ima_template':
      value    => $ima_template,
      bootmode => 'normal'
    }
    kernel_parameter { 'ima_hash':
      value    => $ima_hash,
      bootmode => 'normal'
    }

    if $ima_tcb {
      kernel_parameter { 'ima_tcb':
        notify   => Reboot_notify['ima_reboot'],
        bootmode => 'normal'
      }
    }

    # Be very careful with this class it could make the system read-only
    if $manage_policy {
      include '::tpm::ima::policy'
    }

    if $facts['ima_log_size'] {
      if $facts['ima_log_size'] >= $log_max_size {
        reboot_notify { 'ima_log':
          reason => 'The IMA /sys/kernel/security/ima/ascii_runtime_measurements is filling up kernel memory. Please reboot to clear.'
        }
      }
    }
  }
  else {
    kernel_parameter { 'ima_tcb':
      ensure   => 'absent',
      bootmode => 'normal'
    }
    kernel_parameter { [ 'ima', 'ima_audit', 'ima_template', 'ima_hash' ]:
      ensure   => 'absent',
      bootmode => 'normal'
    }
  }

  reboot_notify { 'ima_reboot':
    subscribe => [
      Kernel_parameter['ima'],
      Kernel_parameter['ima_tcb'],
      Kernel_parameter['ima_audit'],
      Kernel_parameter['ima_template'],
      Kernel_parameter['ima_hash']
    ]
  }
}
