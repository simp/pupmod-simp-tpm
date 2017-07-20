# Create a launch policy, modify grub, and enable tboot
class tpm::tboot (
  Optional[String]     $sinit_name              = undef,
  Optional[String]     $sinit_source            = simplib::lookup('simp_options::rsync', { 'default_value' => undef }),
  String               $rsync_source            = "tboot_${::environment}/",
  Optional[String]     $rsync_server            = simplib::lookup('simp_options::rsync::server', { 'default_value' => '127.0.0.1' }),
  Integer              $rsync_timeout           = simplib::lookup('simp_options::rsync::timeout', { 'default_value' => 1 }),
  String               $owner_password          = passgen( "${facts['fqdn']}_tpm0_owner_pass", { 'length' => 20 } ),
  Array[String]        $tboot_boot_options      = ['logging=serial,memory,vga'],
  Array[String]        $additional_boot_options = ['intel_iommu=on'],
  Stdlib::AbsolutePath $policy_script           = '/root/txt/create_lcp_boot_policy.sh',
  String               $policy_script_source    = 'puppet:///modules/tpm/create_lcp_boot_policy.sh'
) {
  include 'tpm'

  reboot_notify { 'Launch tboot': reason => 'tboot has been enabled, please reboot and complete a measured launch.' }

  file { '/root/txt/': ensure => directory }

  include 'tpm::tboot::sinit'
  include 'tpm::tboot::policy'
  include 'tpm::tboot::grub'

  Class['tpm']
  -> Class['tpm::tboot::sinit']
  -> Class['tpm::tboot::policy']
  ~> Class['tpm::tboot::grub']
  ~> Reboot_notify['Launch tboot']

}
