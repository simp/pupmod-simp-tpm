#  This module executes the script to label the files
#  systems with the security.ima attributes and if it
#  is complete, adds resources to set ima_appraise to
#  enforce mode.
#
#  When a the file system needs to be labeled a file,
#  relabel file is created in the appraise class.  If this
#  file exists then the script to relabel the files is called
#  and passed the file name. The script will remove the file
#  when it is complete.
#
#  The fact ima_security checks the status of the file and
#  also checks if the script is running.  If the script is active,
#  no resources are created, if the relabel file exists and
#  and the script is not active, it launches the script
#  if the file does not exist, it calls the class to create the
#  resources for setting the system into enforce mode.
#
#  @param relabel_file   The location of the file that
#     that indicates a labeling of the file system is needed.
#
class tpm::ima::appraise::relabel(
  Stdlib::AbsolutePath  $relabel_file,
  Stdlib::AbsolutePath  $scriptdir = $tpm::ima::appraise::scriptdir,
){

  case  $facts['ima_security_attr'] {
    'inactive': {
      include 'tpm::ima::appraise::enforcemode'
    }
    'active': {
      notify {'IMA updates running':
        message  => 'The script to update the security.ima attributes is running. Do not reboot until the ima_security_attr_update.sh script completes running',
        loglevel => 'warning'
      }
    }
    default: {
      exec { 'ima_security_attr_update':
        command => "${scriptdir}/ima_security_attr_update.sh ${relabel_file} &",
        path    => "${scriptdir}:/sbin:/bin:/usr/sbin:/usr/bin",
        require => File["${scriptdir}/ima_security_attr_update.sh"],
      }
      notify {'IMA updates started':
        message  => 'The script to has been started.  Do not reboot until the ima_security_attr_update.sh script completes running.',
        before   => Exec['ima_security_attr_update'],
        loglevel => 'warning'
      }
    }
  }
}
