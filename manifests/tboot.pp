# Create a launch policy, modify grub, and enable tboot
class tpm::tboot (
  String $sinit_path,
  Array[String] $tboot_boot_options = ['logging=serial,memory,vga'],
  Array[String] $additional_boot_options = ['intel_iommu=on'],
) {

  include 'tpm::tboot::policy'
  include 'tpm::tboot::grub'

  Class['tpm::tboot::policy']
  -> Class['tpm::tboot::grub']

}
