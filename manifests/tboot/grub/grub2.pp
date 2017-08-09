# Manage grub2 configuration
# This class is controlled by `tpm::tboot`
#
class tpm::tboot::grub::grub2 {
  assert_private()

  $intermediate_grub_entry = $tpm::tboot::intermediate_grub_entry
  $purge_boot_entries      = $tpm::tboot::purge_boot_entries
  $tboot_boot_options      = $tpm::tboot::tboot_boot_options
  $additional_boot_options = $tpm::tboot::additional_boot_options

  # Mark the grub script to be executable or not - depending on whether
  #   we want the untrusted kernel available
  $_stock_boot_entries_mode = $purge_boot_entries ? {
    true    => '0644',
    default => '0755'
  }
  file { '/etc/grub.d/10_linux':
    mode   => $_stock_boot_entries_mode,
    notify => Exec['Update grub config']
  }

  if $intermediate_grub_entry {
    exec { 'Install second grub script':
      command => '/usr/bin/install --preserve-context --mode 755 /etc/grub.d/20_linux_tboot /etc/grub.d/19_linux_tboot_pretxt',
      unless  => '/usr/bin/test -e /etc/grub.d/19_linux_tboot_pretxt',
      notify  => Exec['Patch 19_linux_tboot_pretxt, removing list.data and SINIT']
    }
    file { '/root/txt/19_linux_tboot_pretxt.diff':
      ensure  => file,
      content => file('tpm/19_linux_tboot_pretxt.diff'),
      notify  => Exec['Patch 19_linux_tboot_pretxt, removing list.data and SINIT']
    }
    exec { 'Patch 19_linux_tboot_pretxt, removing list.data and SINIT':
      command     => '/bin/patch -Bfu /etc/grub.d/19_linux_tboot_pretxt /root/txt/19_linux_tboot_pretxt.diff',
      refreshonly => true,
      notify      => Exec['Update grub config']
    }
  }
  else {
    file {
      default: ensure => absent;
      '/root/txt/19_linux_tboot_pretxt.diff':;
      '/etc/grub.d/19_linux_tboot_pretxt': notify => Exec['Update grub config'];
    }
  }

  file { '/root/txt/20_linux_tboot.diff':
    ensure  => file,
    content => file('tpm/20_linux_tboot.diff'),
    notify  => Exec['Patch 20_linux_tboot with list.data and SINIT']
  }

  exec { 'Patch 20_linux_tboot with list.data and SINIT':
    command     => '/bin/patch -Bfu /etc/grub.d/20_linux_tboot /root/txt/20_linux_tboot.diff',
    refreshonly => true,
    notify      => Exec['Update grub config']
  }

  $grub_tboot = {
    'GRUB_CMDLINE_TBOOT'       => "\"${tboot_boot_options.join(' ')}\"",
    'GRUB_CMDLINE_LINUX_TBOOT' => "\"${additional_boot_options.join(' ')}\"",
    'GRUB_TBOOT_POLICY_DATA'   => '"list.data"'
  }
  $_content = $grub_tboot.reduce([]) |$memo,$value| {
    $memo + [ "${value[0]}=${value[1]}" ]
  }
  file { '/etc/default/grub-tboot':
    ensure  => file,
    content => $_content.join("\n"),
    notify  => Exec['Update grub config']
  }

  # this isn't getting updated the first run
  exec { 'Update grub config':
    command     => '/sbin/grub2-mkconfig -o /etc/grub2.cfg',
    refreshonly => true,
    logoutput   => true,
    require     => File['/etc/default/grub-tboot']
  }

}
