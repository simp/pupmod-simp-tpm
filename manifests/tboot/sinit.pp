# Install the sinit for your platform
# This class is controlled by `tpm::tboot`
#
class tpm::tboot::sinit {
  assert_private()

  $sinit_name    = $tpm::tboot::sinit_name
  $sinit_source  = $tpm::tboot::sinit_source
  $rsync_source  = $tpm::tboot::rsync_source
  $rsync_server  = $tpm::tboot::rsync_server
  $rsync_timeout = $tpm::tboot::rsync_timeout

  # if the sinit is not built into the bios...
  if $sinit_name {
    file { '/root/txt/sinit':
      ensure => directory
    }

    if $sinit_source == 'rsync' {
      rsync { 'tboot':
        source  => $rsync_source,
        target  => '/root/txt/sinit',
        server  => $rsync_server,
        timeout => $rsync_timeout,
        require => File['/root/txt/sinit']
      }
    }
    else {
      file { "/root/txt/sinit/${sinit_name}":
        ensure  => file,
        source  => $sinit_source,
        require => File['/root/txt/sinit']
      }
    }

  }
}
