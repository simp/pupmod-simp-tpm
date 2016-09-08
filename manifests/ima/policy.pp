# https://wiki.gentoo.org/wiki/Integrity_Measurement_Architecture
# Kernel documentation Documentation/ABI/testing/ima_policy or
# https://git.kernel.org/cgit/linux/kernel/git/stable/linux-stable.git/tree/Documentation/ABI/testing/ima_policy?id=refs/tags/v3.10.103
#
# The term 'watch', as used here, means both IMA policy fields dont_measure
#   and dont_appraise. Both lines will be dropped for each entry here.
#
# @param manage [Boolean] Enable policy management
#
# @param dont_watch_proc [Boolean] If true, disable IMA hashing of procfs
#   filesystems, as noted by the kernel magic documentation above.
# @param dont_watch_sysfs [Boolean] If true, disable IMA hashing of sysfs
#   filesystems, as noted by the kernel magic documentation above.
# @param dont_watch_debugfs [Boolean] If true, disable IMA hashing of debugfs
#   filesystems, as noted by the kernel magic documentation above.
# @param dont_watch_tmpfs [Boolean] If true, disable IMA hashing of tmpfs
#   filesystems, as noted by the kernel magic documentation above.
# @param dont_watch_ramfs [Boolean] If true, disable IMA hashing of ramfs
#   filesystems, as noted by the kernel magic documentation above.
# @param dont_watch_securityfs [Boolean] If true, disable IMA hashing of securityfs
#   filesystems, as noted by the kernel magic documentation above.
# @param dont_watch_devpts [Boolean] If true, disable IMA hashing of /dev/pts
#   filesystems, as noted by the kernel magic documentation above.
# @param dont_watch_binfmtfs [Boolean] If true, disable IMA hashing of binfmtfs
#   filesystems, as noted by the kernel magic documentation above.
# @param dont_watch_selinux [Boolean] If true, disable IMA hashing of selinux fs
#   filesystems, as noted by the kernel magic documentation above.
# @param dont_watch_nfs [Boolean] If true, disable IMA hashing of nfs
#   filesystems, as noted by the kernel magic documentation above.
# @param dont_watch_cgroup [Boolean] If true, disable IMA hashing of cgroup
#   filesystems, as noted by the kernel magic documentation above.
#
# @param dont_watch_initrc_var_log_t [Boolean] If true, don't watch selinux
#   context initrc_var_log_t
# @param dont_watch_rpm_var_cache_t [Boolean] If true, don't watch selinux
#   context rpm_var_cache_t
# @param dont_watch_puppet_log_t [Boolean] If true, don't watch selinux
#   context puppet_log_t
# @param dont_watch_auditd_log_t [Boolean] If true, don't watch selinux
#   context auditd_log_t
# @param dont_watch_auth_cache_t [Boolean] If true, don't watch selinux
#   context auth_cache_t
# @param dont_watch_fsadm_log_t [Boolean] If true, don't watch selinux
#   context fsadm_log_t
# @param dont_watch_rsync_log_t [Boolean] If true, don't watch selinux
#   context rsync_log_t
# @param dont_watch_getty_log_t [Boolean] If true, don't watch selinux
#   context getty_log_t
# @param dont_watch_nscd_log_t [Boolean] If true, don't watch selinux
#   context nscd_log_t
# @param dont_watch_cron_log_t [Boolean] If true, don't watch selinux
#   context cron_log_t
# @param dont_watch_lastlog_t [Boolean] If true, don't watch selinux
#   context lastlog_t
# @param dont_watch_var_log_t [Boolean] If true, don't watch selinux
#   context var_log_t
# @param dont_watch_wtmp_t [Boolean] If true, don't watch selinux
#   context wtmp_t
#
# @param dont_watch_list [Array] A list of selinux contexts that shouldn't be
#   watched, merged with all of the parameters above
#
# @param measure_root_read_files [Boolean] Monitor all files opened by root
# @param measure_file_mmap [Boolean] Monitor all files mmapped executable in file_mmap
# @param measure_bprm_check [Boolean] Monitor all executables in bprm_check
# @param measure_module_check [Boolean]
# @param appraise_fowner [Boolean] Appraises all files owned by root
#
# @author Nick Miller <nick.miller@onyxpoint.com>
#
class tpm::ima::policy (
  $manage = false,

  # magic filesystems, default settings
  $dont_watch_proc       = true,
  $dont_watch_sysfs      = true,
  $dont_watch_debugfs    = true,
  $dont_watch_tmpfs      = true,
  $dont_watch_ramfs      = true,
  $dont_watch_securityfs = true,
  # magic, additional settings
  $dont_watch_devpts     = true,
  $dont_watch_binfmtfs   = true,
  $dont_watch_selinux    = true,
  $dont_watch_nfs        = true,
  $dont_watch_cgroup     = true,

  # selinux contexts
  $dont_watch_initrc_var_log_t = true,
  $dont_watch_rpm_var_cache_t  = true,
  $dont_watch_puppet_log_t     = true,
  $dont_watch_auditd_log_t     = true,
  $dont_watch_auth_cache_t     = true,
  $dont_watch_fsadm_log_t      = true,
  $dont_watch_rsync_log_t      = true,
  $dont_watch_getty_log_t      = true,
  $dont_watch_nscd_log_t       = true,
  $dont_watch_cron_log_t       = true,
  $dont_watch_lastlog_t        = true,
  $dont_watch_var_log_t        = true,
  $dont_watch_wtmp_t           = true,
  $dont_watch_list = [],

  # other defaults
  $measure_root_read_files = true,
  $measure_file_mmap       = true,
  $measure_bprm_check      = true,
  $measure_module_check    = true,
  $appraise_fowner         = true,
){
  validate_bool($dont_watch_proc)
  validate_bool($dont_watch_sysfs)
  validate_bool($dont_watch_debugfs)
  validate_bool($dont_watch_tmpfs)
  validate_bool($dont_watch_ramfs)
  validate_bool($dont_watch_securityfs)
  validate_bool($dont_watch_devpts)
  validate_bool($dont_watch_binfmtfs)
  validate_bool($dont_watch_selinux)
  validate_bool($dont_watch_nfs)
  validate_bool($dont_watch_cgroup)
  validate_bool($dont_watch_initrc_var_log_t)
  validate_bool($dont_watch_rpm_var_cache_t)
  validate_bool($dont_watch_puppet_log_t)
  validate_bool($dont_watch_auditd_log_t)
  validate_bool($dont_watch_auth_cache_t)
  validate_bool($dont_watch_fsadm_log_t)
  validate_bool($dont_watch_rsync_log_t)
  validate_bool($dont_watch_getty_log_t)
  validate_bool($dont_watch_nscd_log_t)
  validate_bool($dont_watch_cron_log_t)
  validate_bool($dont_watch_lastlog_t)
  validate_bool($dont_watch_var_log_t)
  validate_bool($dont_watch_wtmp_t)
  validate_array($dont_watch_list)
  validate_bool($measure_root_read_files)
  validate_bool($measure_file_mmap)
  validate_bool($measure_bprm_check)
  validate_bool($measure_module_check)
  validate_bool($appraise_fowner)

  # magic reference is in Kernel documentation Documentation/ABI/testing/ima_policy
  $magic_hash = {
    0x9fa0     => $dont_watch_proc,
    0x62656572 => $dont_watch_sysfs,
    0x64626720 => $dont_watch_debugfs,
    0x01021994 => $dont_watch_tmpfs,
    0x858458f6 => $dont_watch_ramfs,
    0x73636673 => $dont_watch_securityfs,
    0x1cd1     => $dont_watch_devpts,
    0x42494e4d => $dont_watch_binfmtfs,
    0xf97cff8c => $dont_watch_selinux,
    0x6969     => $dont_watch_nfs,
    0x27e0eb   => $dont_watch_cgroup,
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

    if member($::init_systems, 'systemd') {
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
    if member($::init_systems, 'systemd') {
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
