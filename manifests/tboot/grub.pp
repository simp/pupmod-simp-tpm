# Configure grub
# This class is controlled by `tpm::tboot`
#
class tpm::tboot::grub {

  $sinit_name    = $tpm::tboot::sinit_name

  case $facts['augeasprovider_grub_version'] {
    1:       { include 'tpm::tboot::grub::grub1' }
    2:       { include 'tpm::tboot::grub::grub2' }
    default: { fail('Unknown grub version, tboot cannot continue') }
  }

  file { "/boot/${sinit_name}":
    ensure  => file,
    source  => "/root/txt/sinit/${sinit_name}",
    require => Class['tpm::tboot::sinit']
  }

}