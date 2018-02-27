# Sets up IMA kernel boot flags if they are not enabled, and mounts the
# ``securityfs`` when they are.
#
# @param enable
#   Enable IMA on the system
#
# @param manage_policy
#   Include the ``tpm::ima::policy`` Class
#
#   * Please read the documentation for that class **carefully**, as it can
#     cause live filesystems to become read-only until a reboot.
#
# @param mount_dir
#   Where to mount the IMA ``securityfs``
#
# @param ima_audit
#   Audit control
#
#   * ``true``  - Enable additional integrity auditing messages
#   * ``false`` - Enable integrity auditing messages
#
# @param ima_template
#   A predefined IMA measurement template format.
#
#   * NOTE: This is only valid in kernel version >= ``3.13``. It is always
#     ``ima`` in older versions.
#
# @param ima_hash
#   The list of supported hashes can be found in ``crypto/hash_infotru.h``
#
#   * NOTE: This is only valid in kernel version >= ``3.13``. It is always
#     ``sha1`` in older versions.
#
# @param ima_tcb
#   Toggle the TCB policy
#
#   * IMA will measure all programs called via ``exec``, files copied via
#     ``mmap``, and all files opened by ``uid=0``.
#
# @param log_max_size
#   The size of ``/sys/kernel/security/ima/ascii_runtime_measurements``, in
#   bytes, that will cause a reboot notification will be sent to the user.
#
class tpm::ima (
  Boolean              $enable          = true,
  Boolean              $manage_appraise = false,
  Boolean              $manage_policy   = false,
  Stdlib::AbsolutePath $mount_dir       = '/sys/kernel/security',
  Boolean              $ima_tcb         = true,
  Boolean              $ima_audit       = false,
  Tpm::Ima::Template   $ima_template    = 'ima-ng',
  String[1]            $ima_hash        = 'sha256',
  Integer[1]           $log_max_size    = 30000000
) {

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

    $_ima_audit = $ima_audit ? {
      true    => '1',
      default => '0'
    }
    kernel_parameter { 'ima_audit':
      value    => $_ima_audit,
      bootmode => 'normal'
    }

    if (versioncmp($facts[kernelmajversion],'3.13') >= 0) {
      kernel_parameter { 'ima_template':
        value    => $ima_template,
        bootmode => 'normal'
      }
      kernel_parameter { 'ima_hash':
        value    => $ima_hash,
        bootmode => 'normal'
      }
    } else {
      kernel_parameter { [ 'ima_template', 'ima_hash' ]:
        ensure   => 'absent',
        bootmode => 'normal'
      }
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

    if $manage_appraise {
      include '::tpm::ima::appraise'
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
