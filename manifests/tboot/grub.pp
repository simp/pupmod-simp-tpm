# Configure grub
class tpm::tboot::grub {
  case $facts['augeasprovider_grub_version'] {
    1:       { include 'tpm::tboot::grub::grub1' }
    2:       { include 'tpm::tboot::grub::grub2' }
    default: { fail('Unknown grub version, tboot cannot continue') }
  }
}