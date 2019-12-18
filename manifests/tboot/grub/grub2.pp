# @summary Manage grub2 configuration
#
# This class is controlled by `tpm::tboot`
#
class tpm::tboot::grub::grub2 {
  assert_private()

  $purge_boot_entries      = $tpm::tboot::purge_boot_entries
  $tboot_boot_options      = $tpm::tboot::tboot_boot_options
  $additional_boot_options = $tpm::tboot::additional_boot_options
  $create_policy           = $tpm::tboot::create_policy

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
  $_policy_file = $create_policy ? {
    true    => 'list.data',
    default => ''
  }

  file_line{ 'Allow Acccess to  option in boot menu':
    ensure => present,
    path   => '/etc/grub.d/20_linux_tboot',
    line   => 'CLASS="--class gnu-linux --class gnu --class os --class tboot --unrestricted"',
    match  => '^CLASS="--class\ gnu-linux\ --class\ gnu\ --class\ os\ --class\ tboot"$',
    notify => Exec['Update grub config']
  }

  $grub_tboot = {
    'GRUB_CMDLINE_TBOOT'       => "\"${tboot_boot_options.join(' ')}\"",
    'GRUB_CMDLINE_LINUX_TBOOT' => "\"${additional_boot_options.join(' ')}\"",
    'GRUB_TBOOT_POLICY_DATA'   => "\"${_policy_file}\""
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
