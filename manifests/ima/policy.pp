# Manage IMA Policy
#
#   * The term 'watch', as used here, means both IMA policy fields dont_measure
#     and dont_appraise. Both lines will be dropped for each entry here.
#
# @see https://wiki.gentoo.org/wiki/Integrity_Measurement_Architecture
# @see Kernel documentation Documentation/ABI/testing/ima_policy
# @see https://git.kernel.org/cgit/linux/kernel/git/stable/linux-stable.git/tree/Documentation/ABI/testing/ima_policy?id=refs/tags/v3.10.103
#
# @param manage Enable policy management
#
# @param dont_watch_proc If true, disable IMA hashing of procfs
#   filesystems, as noted by the kernel magic documentation above.
# @param dont_watch_sysfs If true, disable IMA hashing of sysfs
#   filesystems, as noted by the kernel magic documentation above.
# @param dont_watch_debugfs If true, disable IMA hashing of debugfs
#   filesystems, as noted by the kernel magic documentation above.
# @param dont_watch_tmpfs If true, disable IMA hashing of tmpfs
#   filesystems, as noted by the kernel magic documentation above.
# @param dont_watch_ramfs If true, disable IMA hashing of ramfs
#   filesystems, as noted by the kernel magic documentation above.
# @param dont_watch_securityfs If true, disable IMA hashing of securityfs
#   filesystems, as noted by the kernel magic documentation above.
# @param dont_watch_devpts If true, disable IMA hashing of /dev/pts
#   filesystems, as noted by the kernel magic documentation above.
# @param dont_watch_binfmtfs If true, disable IMA hashing of binfmtfs
#   filesystems, as noted by the kernel magic documentation above.
# @param dont_watch_selinux If true, disable IMA hashing of selinux fs
#   filesystems, as noted by the kernel magic documentation above.
# @param dont_watch_nfs If true, disable IMA hashing of nfs
#   filesystems, as noted by the kernel magic documentation above.
# @param dont_watch_cgroup If true, disable IMA hashing of cgroup
#   filesystems, as noted by the kernel magic documentation above.
#
# @param dont_watch_initrc_var_log_t If true, don't watch selinux
#   context initrc_var_log_t
# @param dont_watch_rpm_var_cache_t If true, don't watch selinux
#   context rpm_var_cache_t
# @param dont_watch_puppet_log_t If true, don't watch selinux
#   context puppet_log_t
# @param dont_watch_auditd_log_t If true, don't watch selinux
#   context auditd_log_t
# @param dont_watch_auth_cache_t If true, don't watch selinux
#   context auth_cache_t
# @param dont_watch_fsadm_log_t If true, don't watch selinux
#   context fsadm_log_t
# @param dont_watch_rsync_log_t If true, don't watch selinux
#   context rsync_log_t
# @param dont_watch_getty_log_t If true, don't watch selinux
#   context getty_log_t
# @param dont_watch_nscd_log_t If true, don't watch selinux
#   context nscd_log_t
# @param dont_watch_cron_log_t If true, don't watch selinux
#   context cron_log_t
# @param dont_watch_lastlog_t If true, don't watch selinux
#   context lastlog_t
# @param dont_watch_var_log_t If true, don't watch selinux
#   context var_log_t
# @param dont_watch_wtmp_t If true, don't watch selinux
#   context wtmp_t
#
# @param dont_watch_list A list of selinux contexts that shouldn't be
#   watched, merged with all of the parameters above
#
# @param measure_root_read_files Monitor all files opened by root
# @param measure_file_mmap Monitor all files mmapped executable in file_mmap
# @param measure_bprm_check Monitor all executables in bprm_check
# @param measure_module_check
# @param appraise_fowner Appraises all files owned by root
#
# @author Nick Miller <nick.miller@onyxpoint.com>
#
class tpm::ima::policy (
  Boolean $manage = false,

  # magic filesystems, default settings
  Boolean $dont_watch_proc       = true,
  Boolean $dont_watch_sysfs      = true,
  Boolean $dont_watch_debugfs    = true,
  Boolean $dont_watch_tmpfs      = true,
  Boolean $dont_watch_ramfs      = true,
  Boolean $dont_watch_securityfs = true,
  # magic, additional settings
  Boolean $dont_watch_devpts     = true,
  Boolean $dont_watch_binfmtfs   = true,
  Boolean $dont_watch_selinux    = true,
  Boolean $dont_watch_nfs        = true,
  Boolean $dont_watch_cgroup     = true,

  # selinux contexts
  Boolean $dont_watch_initrc_var_log_t = true,
  Boolean $dont_watch_rpm_var_cache_t  = true,
  Boolean $dont_watch_puppet_log_t     = true,
  Boolean $dont_watch_auditd_log_t     = true,
  Boolean $dont_watch_auth_cache_t     = true,
  Boolean $dont_watch_fsadm_log_t      = true,
  Boolean $dont_watch_rsync_log_t      = true,
  Boolean $dont_watch_getty_log_t      = true,
  Boolean $dont_watch_nscd_log_t       = true,
  Boolean $dont_watch_cron_log_t       = true,
  Boolean $dont_watch_lastlog_t        = true,
  Boolean $dont_watch_var_log_t        = true,
  Boolean $dont_watch_wtmp_t           = true,
  Array[String] $dont_watch_list = [],

  # other defaults
  Boolean $measure_root_read_files = true,
  Boolean $measure_file_mmap       = true,
  Boolean $measure_bprm_check      = true,
  Boolean $measure_module_check    = true,
  Boolean $appraise_fowner         = true,
){

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
      mode    => '0640',
      content => template('tpm/ima_policy.conf.erb'),
      require => File['/etc/ima'],
      notify  => Exec['load_ima_policy']
    }

    exec { 'load_ima_policy':
      command => 'cat /etc/ima/policy.conf > /sys/kernel/security/ima/policy',
      unless  => 'grep ima_reboot `puppet config print vardir`/reboot_notifications.json',
      path    => '/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin',
      require => File['/etc/ima/policy.conf'],
    }

    if member($facts['init_systems'], 'systemd') {
      file { '/usr/lib/systemd/system/import_ima_rules.service':
        ensure => file,
        mode   => '0644',
        source => 'puppet:///modules/tpm/import_ima_rules.service'
      }
      service { 'import_ima_rules.service':
        ensure  => running,
        enable  => true,
        require => File['/usr/lib/systemd/system/import_ima_rules.service']
      }
    }
    else {
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
  }
  else {
    if member($facts['init_systems'], 'systemd') {
      file { '/usr/lib/systemd/system/import_ima_rules.service':
        ensure => absent,
      }
      service { 'import_ima_rules.service':
        ensure => stopped,
        enable => false,
      }
    }
    else {
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
