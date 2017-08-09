# Manage grub configuration for tboot
# This class is controlled by `tpm::tboot`
#
class tpm::tboot::grub::grub1 {
  assert_private()

  fail('This module does not currently support Grub 0.99-1.0')

}
