# Manage grub2 configuration
class tpm::tboot::grub::grub2 {
  assert_private()

  $tboot_boot_options      = $tpm::tboot::tboot_boot_options
  $additional_boot_options = $tpm::tboot::additional_boot_options

  file { '/etc/grub.d/20_linux_tboot':
    ensure  => file,
    content => file('tpm/20_linux_tboot'),
    notify  => Exec['Update grub config']
  }

  grub_config {
    'GRUB_CMDLINE_TBOOT':       value => $tboot_boot_options;
    'GRUB_CMDLINE_LINUX_TBOOT': value => $additional_boot_options;
    'GRUB_TBOOT_POLICY_DATA':   value => 'list.data';
  }

  exec { 'Update grub config':
    command     => '/sbin/grub2-mkconfig -o /etc/grub2.cfg',
    refreshonly => true,
    require     => [
      Grub_config['GRUB_CMDLINE_TBOOT'],
      Grub_config['GRUB_CMDLINE_LINUX_TBOOT'],
      Grub_config['GRUB_TBOOT_POLICY_DATA'],
      File['/etc/grub.d/20_linux_tboot']
    ]
  }

}
