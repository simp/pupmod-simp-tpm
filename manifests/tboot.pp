# == Class: tpm::tboot
#
# Sets up Intel TXT Trusted Boot (tboot) if TPM chip is installed on system.
# Configures legacy grub and grub2 depending on the OS Version.
# This has been tested on Systems that use Intel TXT compatible TPM chips.
#
# This module will break the functionality of the augeasproviders_grub
# because it moves the kernel parameters to modules. If you are using this
# provider it will need to be done a different way by using the general "augeas"
# as is done in this module.
#
# An example to remove kernel rhgb option using augeas instead of 'kernel_parameter'.
#    augeas { 'grub.conf/no_rhgb':
#        incl    => '/boot/grub/grub.conf',
#        lens    => 'grub.lns',
#        changes => 'rm  title[*]/kernel/rhgb',
#    }
#
#
# == Parameters
#
# [*enable*]
#   Type: Boolean
#   Default: true
#     If true, enable Trustedboot on the system.
#     If false, disable Trustedboot on the system.
#
# == Authors
#
# * Jacob Gingrich <gingrich@sgi.com>
#
class tpm::tboot (
  $enable = true,
){

  validate_bool($enable)

  if $enable {
    if  ( $::operatingsystem in ['RedHat','CentOS'] ) and str2bool($::has_tpm) {

      package { ['tboot','trousers']:
        ensure => 'present',
      }

      if ( $::lsbmajdistrelease == '6' ) {
        
        exec { 'backup-grub-conf':
          command => '/bin/cp --backup=numbered /boot/grub/grub.conf /boot/grub/grub.conf.puppet-bak',
          unless  => '/usr/bin/diff /boot/grub/grub.conf /boot/grub/grub.conf.puppet-bak',
        }

        augeas { 'grub.conf/mvkernel':
          incl    => '/boot/grub/grub.conf',
          lens    => 'grub.lns',
          changes => 'mv title[*]/kernel title[*]/module[1]',
          onlyif  => "match title[*]/kernel[.='/tboot.gz'] size == 0",
          require => [ Package['tboot'], Exec['backup-grub-conf']],
        }

        augeas { 'grub.conf/mvinitrd':
          incl    => '/boot/grub/grub.conf',
          lens    => 'grub.lns',
          changes => 'mv title[*]/initrd title[*]/module[2]',
          onlyif  => 'get title[*][count(initrd)] > 0',
          require => [ Package['tboot'], Augeas['grub.conf/mvkernel'], Exec['backup-grub-conf']],
        }

        augeas { 'grub.conf/kernel':
          incl    => '/boot/grub/grub.conf',
          lens    => 'grub.lns',
          changes => [
            'ins kernel before title[*]/module[1]',
            "set title[*]/kernel '/tboot.gz'",
            "setm title[*]/kernel logging 'serial,vga,memory'",
            ],
          onlyif  => 'match title[*]/kernel size == 0',
          require => [ Package['tboot'], Augeas['grub.conf/mvkernel'], Exec['backup-grub-conf'], Augeas['grub.conf/mvinitrd']],
        }
      }

      if ( $::lsbmajdistrelease == '7' ) {

        exec { 'add-tboot-menu':
          command => '/usr/sbin/grub2-mkconfig -o /boot/grub2/grub.cfg',
          unless  => '/usr/bin/grep tboot /boot/grub2/grub.cfg',
          require => Package['tboot'],
        }

        file_line { 'normalize-tboot-menu':
          path     => '/boot/grub2/grub.cfg',
          line     => 'submenu tboot {',
          match    => '^submenu.*tboot.*[0-9.0-9.0-9].*{',
          multiple => false,
          require  => [ Package['tboot'], Exec['add-tboot-menu']],
        }

        exec { 'set-default-boot':
          command => '/usr/sbin/grub2-set-default tboot',
          unless  => '/usr/bin/grep saved_entry=tboot /boot/grub2/grubenv',
          require => [ Package['tboot'], Exec['add-tboot-menu'], File_line['normalize-tboot-menu']],
        }
      }
    }
  }

  else {

    if ( $::lsbmajdistrelease == '6' ) {

      exec { 'backup-grub-conf':
        command => '/bin/cp --backup=numbered /boot/grub/grub.conf /boot/grub/grub.conf.puppet-bak',
        unless  => '/usr/bin/diff /boot/grub/grub.conf /boot/grub/grub.conf.puppet-bak',
      }

      augeas { 'grub.conf/rmkernel':
        incl    => '/boot/grub/grub.conf',
        lens    => 'grub.lns',
        changes => 'rm title[*]/kernel',
        onlyif  => "match title[*]/kernel[.='/tboot.gz'] size > 0",
        require => Exec['backup-grub-conf'],
      }

      augeas { 'grub.conf/kernel':
        incl    => '/boot/grub/grub.conf',
        lens    => 'grub.lns',
        changes => 'mv title[*]/module[1] title[*]/kernel',
        onlyif  => 'match title[*]/kernel size == 0',
        require => [ Augeas['grub.conf/rmkernel'], Exec['backup-grub-conf']],
      }

      augeas { 'grub.conf/mvinitrd':
        incl    => '/boot/grub/grub.conf',
        lens    => 'grub.lns',
        changes => 'mv title[*]/module[1] title[*]/initrd',
        onlyif  => 'match title[*]/initrd size == 0',
        require => [ Augeas['grub.conf/rmkernel'], Exec['backup-grub-conf'], Augeas['grub.conf/kernel']],
      }

      package { ['tboot']:
        ensure  => 'absent',
        require => [ Augeas['grub.conf/kernel'], Augeas['grub.conf/rmkernel'], Exec['backup-grub-conf'], Augeas['grub.conf/mvinitrd']],
      }
    }

    if ( $::lsbmajdistrelease == '7' ) {

      exec { 'remove-default-tboot':
        command => '/usr/sbin/grub2-set-default 0',
        onlyif  => '/usr/bin/grep saved_entry=tboot /boot/grub2/grubenv',
      }

      package { ['tboot']:
        ensure  => 'absent',
        require => Exec['remove-default-tboot'],
      }

      exec { 'remove-tboot-menu':
        command => '/usr/sbin/grub2-mkconfig -o /boot/grub2/grub.cfg',
        onlyif  => '/usr/bin/grep tboot /boot/grub2/grub.cfg',
        require => [ Package['tboot'], Exec['remove-default-tboot']],
      }
    }
  }

}
