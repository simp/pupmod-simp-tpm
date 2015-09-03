# == Class: tpm::tboot
#
# Sets up Intel TXT Trusted Boot (tboot) if TPM chip is installed on system.
# Configures legacy grub and grub2 depending on the OS Version.
# This has been tested on Systems that use Intel TXT compatible TPM chips.
#
# This module will break the functionality of the augeasproviders_grub
# because it moves the kernel perameters to modules. If you are using this
# provider it will need to be done a different way by using the general "augeas"
# as is done in this module.
#
# An example to remove kernel rhgb optioni using augeas instead of 'kernel_perameter'.
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
#   Default: false
#     If true, enable Trustedboot on the system.
#
# == Authors
#
# * Jacob Gingrich <gingrich@sgi.com>
#
class tpm::tboot (
  $enable = false,
){

  if $enable {
    if  ( $::operatingsystem in ['RedHat','CentOS'] ) and str2bool($::has_tpm) {

      package { ['tboot','trousers']:
        ensure => 'present',
      }

      if ( $::lsbmajdistrelease == '6' ) {
        
        augeas { 'grub.conf/mvkernel':
          incl    => '/boot/grub/grub.conf',
          lens    => 'grub.lns',
          changes => 'mv title[*]/kernel title[*]/module[1]',
          onlyif  => "match title[*]/kernel[.='/tboot.gz'] size == 0",
          require => Package['tboot'],
        }

        augeas { 'grub.conf/mvinitrd':
          incl    => '/boot/grub/grub.conf',
          lens    => 'grub.lns',
          changes => 'mv title[*]/initrd title[*]/module[2]',
          onlyif  => 'get title[*][count(initrd)] > 0',
          require => [ Package['tboot'], Augeas['grub.conf/mvkernel']],
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
          require => [ Package['tboot'], Augeas['grub.conf/mvkernel'], Augeas['grub.conf/mvinitrd']],
        }
      }

      if ( $::lsbmajdistrelease == '7' ) {

        exec { 'add-tboot-menu':
          command => '/usr/sbin/grub2-mkconfig -o /boot/grub2/grub.cfg',
          unless  => '/usr/bin/grep tboot /boot/grub2/grub.cfg',
          require => Package['tboot'],
        }

        exec { 'normalize-tboot-menu':
          command => "/usr/bin/sed -i 's/tboot.*{/tboot {/' /boot/grub2/grub.cfg",
          onlyif  => "/usr/bin/grep 'submenu.*tboot [0-9.0-9.0-9]' /boot/grub2/grub.cfg",
          require => [ Package['tboot'], Exec['add-tboot-menu']],
        }

        exec { 'set-default-boot':
          command => '/usr/sbin/grub2-set-default tboot',
          unless  => '/usr/bin/grep tboot /boot/grub2/grubenv',
          require => [ Package['tboot'], Exec['add-tboot-menu'], Exec['normalize-tboot-menu']],
        }
      }
    }
  }

  validate_bool($enable)
}
