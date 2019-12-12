# @summary Create a launch policy, modify grub, and enable tboot.
#
# This version of tpm::tboot will work only with tboot versions 1.9.6 or
# later.  To use an earlier version on tboot use pupmod-simp-tpm version 1.1.0.
#
# @param purge_boot_entries
#   Remove other, nontrusted boot entries from Grub
#
# @param lock_kernel_packages
#   Lock kernel related packages in YUM, to avoid accidentally invalidating the
#   launch policy
#
# @param create_policy
#   The verified launch policy and launch control policies will be updated using
#   the scripts identified by parameter policy_script.
#
# @param sinit_name
#   Name of the SINIT policy file, usually ending in `*.BIN`
#
# @param sinit_source
#   Puppet `file` resouce source arrtibute for the SINIT binary
#
# @param tboot_version
#   The verson of tboot installed on the remote system
#
# @param kernel_packages_to_lock
#   List of kernel related packages to lock
#
#   @example
#     The binary was manually copied over to `/root/BIN`, so this entry was set
#     to `file:///root/BIN`
#
# @param rsync_source
#   Rsync location for the SINIT binary
#
# @param rsync_server
#   Rsync server to use for pulling the sinit images
#
# @param rsync_timeout
#   Rsync timeout
#
# @param owner_password
#   The TPM owner password
#
# @param tboot_boot_options
#   Kernel parameters for the tboot kernel `min_ram=0x2000000` is required on
#   systems with more than 4GB of memory
#
#   @see the tboot documentation in `/usr/share/simp/tboot-*/README`
#
# @param additional_boot_options
#   Regular Linux kernel parameters, specific to tboot sessions `intel_iommu=on`
#   is the default here to force the kernel to load VT-d
#
# @param policy_script
#   The script to generate the tboot policy. This should not be changed
#
# @param policy_script_source
#   Where to find the script. This should also not be changed
#
# @param update_script
#   The script to use for updating the tboot policy. This should not be changed.
#
# @param update_script_source
#   Where to find the update script. This should not be changed.
#
# @param package_ensure
#   How to ensure the `tboot` package will be managed
#
class tpm::tboot (
  Boolean              $purge_boot_entries      = false,
  Boolean              $lock_kernel_packages    = true,
  Boolean              $create_policy           = false,
  Optional[String]     $sinit_name              = undef,
  Optional[String]     $sinit_source            = simplib::lookup('simp_options::rsync', { 'default_value' => undef }),
  Optional[String]     $tboot_version           = $facts['tboot_version'],
  Array[String]        $kernel_packages_to_lock = [ 'kernel','kernel-bigmem','kernel-enterprise',
                                                    'kernel-smp','kernel-debug','kernel-unsupported',
                                                    'kernel-source','kernel-devel','kernel-PAE',
                                                    'kernel-PAE-debug','kernel-modules', 'kernel-headers' ],
  String               $rsync_source            = "tboot_${::environment}/",
  Optional[String]     $rsync_server            = simplib::lookup('simp_options::rsync::server', { 'default_value' => '127.0.0.1' }),
  Integer              $rsync_timeout           = simplib::lookup('simp_options::rsync::timeout', { 'default_value' => 1 }),
  String               $owner_password          = simplib::passgen( "${facts['fqdn']}_tpm0_owner_pass", { 'length' => 20 } ),
  Array[String]        $tboot_boot_options      = ['logging=serial,memory,vga','min_ram=0x2000000'],
  Array[String]        $additional_boot_options = ['intel_iommu=on'],
  Stdlib::AbsolutePath $policy_script           = '/root/txt/create_lcp_boot_policy.sh',
  String               $policy_script_source    = 'puppet:///modules/tpm/create_lcp_tboot_policy.sh',
  Stdlib::AbsolutePath $update_script           = '/root/txt/update_tboot_policy.sh',
  String               $update_script_source    = 'puppet:///modules/tpm/update_tboot_policy.sh',
  String               $package_ensure          = simplib::lookup('simp_options::package_ensure', { 'default_value' => 'installed' }),
) {
  include 'tpm'

  file { '/root/txt/':
    ensure => directory
  }

  package { 'tboot':
    ensure => $package_ensure
  }

  if $tboot_version {
    # There is an error in the tboot 1.9.6 code.  It will cause memory errors
    # when trying to build a policy.  The version is checked here to make sure tboot
    # is installed and the version is known.  Because of this puppet has to be
    # run twice to complete the tboot setup.  To avoid this the version can
    # be hardcoded in hiera with tpm::tboot::tboot_version instead of relying
    # on facter to determine the version.

    if versioncmp($tboot_version,'1.9.6') <= 0  and  $create_policy {
      fail("The version of tboot installed must be 1.9.7 or greater to create a policy.\nThe version installed appears to be ${tboot_version}.\n The value for tpm::tboot::local policy should be set to false.\n If you think the version is incorrect make sure tpm::tboot::tboot_version is not set or set correctly in hiera.")
    }

    include 'tpm::tboot::sinit'
    include 'tpm::tboot::policy'
    include 'tpm::tboot::grub'
    include 'tpm::tboot::lock_kernel'


    Class['tpm']
    -> Package['tboot']
    -> Class['tpm::tboot::sinit']
    ~> Class['tpm::tboot::policy']
    ~> Class['tpm::tboot::grub']
    ~> Reboot_notify['Launch tboot']

    reboot_notify{ 'Launch tboot':
      reason => 'Changes have been made to the configuration for Trusted Boot that require a reboot'
    }

  }
}
