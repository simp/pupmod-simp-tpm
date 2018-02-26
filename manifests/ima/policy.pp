# Manage IMA Policy
#
#   * The term ``watch``, as used here, means both IMA policy fields
#     ``dont_measure`` and ``dont_appraise``. Both lines will be dropped for
#     each entry here.
#
# @see https://wiki.gentoo.org/wiki/Integrity_Measurement_Architecture
# @see Kernel documentation Documentation/ABI/testing/ima_policy
# @see https://git.kernel.org/cgit/linux/kernel/git/stable/linux-stable.git/tree/Documentation/ABI/testing/ima_policy?id=refs/tags/v3.10.103
#
# @param dont_watch_proc
#   Disable IMA hashing of ``procfs`` filesystems
#
# @param dont_watch_sysfs
#   Disable IMA hashing of ``sysfs`` filesystems
#
# @param dont_watch_debugfs
#   Disable IMA hashing of ``debugfs`` filesystems
#
# @param dont_watch_tmpfs
#   Disable IMA hashing of ``tmpfs`` filesystems
#
# @param dont_watch_ramfs
#   Disable IMA hashing of ``ramfs`` filesystems
#
# @param dont_watch_securityfs
#   Disable IMA hashing of ``securityfs`` filesystems
#
# @param dont_watch_devpts
#   Disable IMA hashing of ``/dev/pts`` filesystems
#
# @param dont_watch_binfmtfs
#   Disable IMA hashing of ``binfmtfs`` filesystems
#
# @param dont_watch_selinux
#   Disable IMA hashing of ``selinux_fs`` filesystems
#
# @param dont_watch_nfs
#   Disable IMA hashing of ``nfs`` filesystems
#
# @param dont_watch_cgroup
#   Disable IMA hashing of ``cgroup`` filesystems
#
# @param dont_watch_initrc_var_log_t
# @param dont_watch_rpm_var_cache_t
# @param dont_watch_puppet_log_t
# @param dont_watch_auditd_log_t
# @param dont_watch_auth_cache_t
# @param dont_watch_fsadm_log_t
# @param dont_watch_rsync_log_t
# @param dont_watch_getty_log_t
# @param dont_watch_nscd_log_t
# @param dont_watch_cron_log_t
# @param dont_watch_lastlog_t
# @param dont_watch_var_log_t
# @param dont_watch_wtmp_t
#
# @param dont_watch_list
#   A list of selinux contexts that shouldn't be watched, merged with all of
#   the parameters above
#
# @param measure_root_read_files
#   Monitor all files opened by root
#
# @param measure_file_mmap
#   Monitor all files mmapped executable in ``file_mmap``
#
# @param measure_bprm_check
#   Monitor all executables in ``bprm_check``
#
# @param measure_module_check
# @param appraise_fowner
#   Appraises all files **owned by root**
#
class tpm::ima::policy (
  Boolean       $manage                      = false,
  Boolean       $dont_watch_proc             = true,
  Boolean       $dont_watch_sysfs            = true,
  Boolean       $dont_watch_debugfs          = true,
  Boolean       $dont_watch_tmpfs            = true,
  Boolean       $dont_watch_ramfs            = true,
  Boolean       $dont_watch_securityfs       = true,
  Boolean       $dont_watch_devpts           = true,
  Boolean       $dont_watch_binfmtfs         = true,
  Boolean       $dont_watch_selinux          = true,
  Boolean       $dont_watch_nfs              = true,
  Boolean       $dont_watch_cgroup           = true,
  Boolean       $dont_watch_initrc_var_log_t = true,
  Boolean       $dont_watch_rpm_var_cache_t  = true,
  Boolean       $dont_watch_puppet_log_t     = true,
  Boolean       $dont_watch_auditd_log_t     = true,
  Boolean       $dont_watch_auth_cache_t     = true,
  Boolean       $dont_watch_fsadm_log_t      = true,
  Boolean       $dont_watch_rsync_log_t      = true,
  Boolean       $dont_watch_getty_log_t      = true,
  Boolean       $dont_watch_nscd_log_t       = true,
  Boolean       $dont_watch_cron_log_t       = true,
  Boolean       $dont_watch_lastlog_t        = true,
  Boolean       $dont_watch_var_log_t        = true,
  Boolean       $dont_watch_wtmp_t           = true,
  Array[String] $dont_watch_list             = [],
  Boolean       $measure_root_read_files     = false,
  Boolean       $measure_file_mmap           = false,
  Boolean       $measure_bprm_check          = false,
  Boolean       $measure_module_check        = false,
  Boolean       $appraise_fowner             = false,
) {

  # magic reference is in Kernel documentation Documentation/ABI/testing/ima_policy
  $magic_hash = {
    '0x9fa0'     => $dont_watch_proc,
    '0x62656572' => $dont_watch_sysfs,
    '0x64626720' => $dont_watch_debugfs,
    '0x01021994' => $dont_watch_tmpfs,
    '0x858458f6' => $dont_watch_ramfs,
    '0x73636673' => $dont_watch_securityfs,
    '0x1cd1'     => $dont_watch_devpts,
    '0x42494e4d' => $dont_watch_binfmtfs,
    '0xf97cff8c' => $dont_watch_selinux,
    '0x6969'     => $dont_watch_nfs,
    '0x27e0eb'   => $dont_watch_cgroup,
  }

  $sel_hash = {
    initrc_var_log_t => $dont_watch_initrc_var_log_t,
    rpm_var_cache_t  => $dont_watch_rpm_var_cache_t,
    puppet_log_t     => $dont_watch_puppet_log_t,
    auditd_log_t     => $dont_watch_auditd_log_t,
    auth_cache_t     => $dont_watch_auth_cache_t,
    fsadm_log_t      => $dont_watch_fsadm_log_t,
    rsync_log_t      => $dont_watch_rsync_log_t,
    getty_log_t      => $dont_watch_getty_log_t,
    nscd_log_t       => $dont_watch_nscd_log_t,
    cron_log_t       => $dont_watch_cron_log_t,
    lastlog_t        => $dont_watch_lastlog_t,
    var_log_t        => $dont_watch_var_log_t,
    wtmp_t           => $dont_watch_wtmp_t,
  }

  if $manage {

    file { '/etc/ima':
      ensure => directory,
      mode   => '0750',
    }

    file { '/etc/ima/policy.conf':
      ensure  => file,
      owner   => 'root',
      mode    => '0640',
      content => template('tpm/ima_policy.conf.erb'),
      require => File['/etc/ima'],
      notify  => Exec['load_ima_policy']
    }

    if member($facts['init_systems'], 'systemd') {
    # Create a hardlink to the custom policy so it is loaded by
    # systemd at startup.
      file { '/usr/lib/systemd/system/import_ima_rules.service':
        ensure => file,
        mode   => '0644',
        source => 'puppet:///modules/tpm/import_ima_rules.service'
      }
      service { 'import_ima_rules.service':
        ensure  => stopped,
        enable  => true,
        require => File['/usr/lib/systemd/system/import_ima_rules.service']
      }
      exec { 'systemd_load_policy':
        command => 'ln /etc/ima/policy.conf /etc/ima/ima-policy.systemd',
        creates => '/etc/ima/ima-policy.systemd',
        path    => '/sbin:/bin:/usr/sbin:/usr/bin',
        require => File['/etc/ima/policy.conf'],
      }
    } else {
      file { '/etc/init.d/import_ima_rules':
        ensure => file,
        mode   => '0755',
        source => 'puppet:///modules/tpm/import_ima_rules'
      }
      service { 'import_ima_rules':
        ensure  => stopped,
        enable  => true,
        require => File['/etc/init.d/import_ima_rules']
      }
    }
    exec { 'load_ima_policy':
      command     => 'cat /etc/ima/policy.conf > /sys/kernel/security/ima/policy',
      refreshonly => true,
      path        => '/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin',
      require     => File['/etc/ima/policy.conf'],
    }
  } else {

    if member($facts['init_systems'], 'systemd') {

      file { '/usr/lib/systemd/system/import_ima_rules.service':
        ensure => absent,
      }
      service { 'import_ima_rules.service':
        ensure => stopped,
        enable => false,
      }
    } else {
      file { '/etc/init.d/import_ima_rules':
        ensure => absent,
      }
      service { 'import_ima_rules':
        ensure => stopped,
        enable => false,
      }
    }
  }
}
