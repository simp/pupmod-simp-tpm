# Manage grub2 configuration
class tpm::tboot::grub::grub2 {
  assert_private()

  $tboot_boot_options      = $tpm::tboot::tboot_boot_options
  $additional_boot_options = $tpm::tboot::additional_boot_options

  file { '/root/txt/20_linux_tboot.diff':
    ensure  => file,
    content => file('tpm/20_linux_tboot.diff')
  }

  exec { 'Patch 20_linux_tboot':
    command => '/bin/patch -Bf /etc/grub.d/20_linux_tboot /root/txt/20_linux_tboot.diff',
    unless  => "/usr/bin/grep 'Modified by SIMP' /etc/grub.d/20_linux_tboot",
    require => File['/root/txt/20_linux_tboot.diff'],
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
      Grub_config['GRUB_TBOOT_POLICY_DATA']
    ]
  }

}
