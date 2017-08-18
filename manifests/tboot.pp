# Create a launch policy, modify grub, and enable tboot
#
# @param intermediate_grub_entry Provide a tboot Grub entry with no policy, for bootstrapping
# @param purge_boot_entries Remove other, nontrusted boot entries from Grub
# @param sinit_name Name of the SINIT policy file, usually ending in `*.BIN`
# @param sinit_source Puppet `file` resouce source arrtibute for the SINIT binary
#   @example The binary was manually copied over to `/root/BIN`, so this entry was set to `file:///root/BIN`
# @param rsync_source Rsync location for the SINIT binary
# @param rsync_server Rsync server. This param has a smart default of `simp_options::rsync::server`
# @param rsync_timeout Rsync timeout. This param has a smart default of `simp_options::rsync::timeout`
# @param owner_password The TPM owner password
# @param tboot_boot_options Kernel parameters for the tboot kernel
#   `min_ram=0x2000000` is required on systems with more than 4GB of memory
#   @see the tboot documentation in `/usr/share/simp/tboot-*/README`
# @param additional_boot_options Regular Linux kernel parameters, specific to tboot sessions
#   `intel_iommu=on` is the default here to force the kernel to load VT-d
# @param policy_script The script to generate the tboot policy. This should not be changed
# @param policy_script_source Where to find the script. This should also not be changed
# @param package_ensure How to ensure the `tboot` package will be managed
#
class tpm::tboot (
  Boolean              $intermediate_grub_entry = true,
  Boolean              $purge_boot_entries      = false,
  Boolean              $lock_kernel_packages    = true,
  Array[String]        $kernel_packages_to_lock = ['kernel','kernel-bigmem','kernel-enterprise', 'kernel-smp','kernel-debug','kernel-unsupported','kernel-source','kernel-devel','kernel-PAE','kernel-PAE-debug','kernel-modules'],
  Optional[String]     $sinit_name              = undef,
  Optional[String]     $sinit_source            = simplib::lookup('simp_options::rsync', { 'default_value' => undef }),
  String               $rsync_source            = "tboot_${::environment}/",
  Optional[String]     $rsync_server            = simplib::lookup('simp_options::rsync::server', { 'default_value' => '127.0.0.1' }),
  Integer              $rsync_timeout           = simplib::lookup('simp_options::rsync::timeout', { 'default_value' => 1 }),
  String               $owner_password          = passgen( "${facts['fqdn']}_tpm0_owner_pass", { 'length' => 20 } ),
  Array[String]        $tboot_boot_options      = ['logging=serial,memory,vga','min_ram=0x2000000'],
  Array[String]        $additional_boot_options = ['intel_iommu=on'],
  Stdlib::AbsolutePath $policy_script           = '/root/txt/create_lcp_boot_policy.sh',
  String               $policy_script_source    = 'puppet:///modules/tpm/create_lcp_tboot_policy.sh',
  String               $package_ensure          = simplib::lookup('simp_options::package_ensure', { 'default_value' => 'installed' })
) {
  include 'tpm'

  reboot_notify { 'Launch tboot': reason => 'tboot policy has been written, please reboot to complete a verified launch' }

  file { '/root/txt/': ensure => directory }

  package { 'tboot': ensure => $package_ensure }

  include 'tpm::tboot::sinit'
  include 'tpm::tboot::policy'
  include 'tpm::tboot::grub'
  include 'tpm::tboot::lock_kernel'

  Class['tpm']
  -> Class['tpm::tboot::sinit']
  ~> Class['tpm::tboot::policy']
  ~> Class['tpm::tboot::grub']
  ~> Reboot_notify['Launch tboot']

}
