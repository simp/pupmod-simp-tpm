# Manage IMA Appraisal
#
# @see https://wiki.gentoo.org/wiki/Integrity_Measurement_Architecture
# @see Kernel documentation Documentation/ABI/testing/ima_policy
# @see https://git.kernel.org/cgit/linux/kernel/git/stable/linux-stable.git/tree/Documentation/ABI/testing/ima_policy?id=refs/tags/v3.10.103
#
# To enable IMA appraisal first make sure all your locally mounted file systems
# with root files on them are mounted with ``i_version`` option.
#
# (TODO: check for this and set if possible)
#
# Then include the ``tpm`` module in your classes and set the following in Hiera:
#
# @example enable IMA via Hiera
#   tpm::ima: true
#   tpm::ima::enable: true
#
#   # enable IMA Appraisal
#   tpm::ima::manage_appraise: true
#   tpm::ima::appraise::enable: true
#
#   # It is also recommended although not necessary, to enable the management of
#   # the ima policy because the default policy is over zealous
#   tpm::ima::manage_policy: true
#   tpm::ima::policy::manage: true
#
# When ``puppet`` runs it will configure the system to reboot into ``ima_appraise`` mode ``fix``.
#
# The system will then need to be rebooted and will notify with an
# ``ima_appraise_fix_reboot`` notice.
#
# When the system is rebooted it will be in ``fix`` mode and it will label all
# the files with the required ``security.ima`` filesystem attribute. This takes
# a while.  Puppet will notify not to reboot until this script completes.
# Puppet will notify with an ``ima_appraise_enforce_reboot`` notice when the
# script completes.
#
# When the system is rebooted it will boot into ``ima_appraisal`` in
# ``enforce`` mode.
#
# If you need to update files after the system has been in enforce mode:
#
#   1. Set ``tpm::ima::appraise::force_fixmode`` to ``true``,
#   2. Run ``puppet`` and reboot when prompted.
#
# When you have completed the upgrade, run the script ``/usr/local/bin/ima_security_attr_update.sh``.
#
# When the completes, set ``force_fixmode`` back to ``false``, rerun
# ``puppet``, and reboot when prompted.
#
# Troubleshooting:
#
# * If you reboot and are getting SELinux errors or you do not have permissions
#   to access your files then you probably forgot to set ``i_version`` on your
#   mounts in ``/etc/fstab``.
#
# * If you reboot and it won't load the ``initramfs`` then the ``dracut``
#   update didn't run. You can fix this by rebooting without the ``ima`` kernel
#   settings, running ``dracut -f`` and then rebooting in ``ima`` ``appraise``
#   mode.
#
# @param enable
#   Enable IMA appraise capability
#
# @param package_ensure
#   How to treat installations of packages
#
# @param relabel_file
#   The file to touch when the file system needs relabeling
#
# @param scriptdir
#   The directory to place scripts.
#
# @param force_fixmode
#   This will force the system into ``fix_mode`` so you can update files and
#   then relabel the system - requires a reboot.
#
# @author SIMP Team  <https://simp-project.com/>
#
class tpm::ima::appraise(
  Simplib::PackageEnsure $package_ensure = $::tpm::package_ensure,
  Boolean                $enable         = true,
  Stdlib::AbsolutePath   $relabel_file   = "${facts['puppet_vardir']}/simp/.ima_relabel",
  Stdlib::AbsolutePath   $scriptdir      = '/usr/local/bin',
  Boolean                $force_fixmode  = false,
){

  if $enable {
    # Provides ability to check for special attributes
    package { 'attr':
      ensure => $package_ensure
    }
    # Provides the utility to set the security.ima attributes.
    package { 'ima-evm-utils':
      ensure => $package_ensure
    }

    kernel_parameter { 'ima_appraise_tcb':
      notify   => Reboot_notify['ima_appraise_reboot'],
      bootmode => 'normal'
    }

    kernel_parameter { 'rootflags':
      value    => 'i_version',
      bootmode => 'normal'
    }
    file { "${scriptdir}/ima_security_attr_update.sh":
      ensure => file,
      owner  => 'root',
      mode   => '0700',
      source => 'puppet:///modules/tpm/ima_security_attr_update.sh'
    }
    # check if ima_apprasal is set on the boot cmdline
    if $force_fixmode {
      class { 'tpm::ima::appraise::fixmode':
        relabel_file => $relabel_file,
        relabel      => false
      }
    } else {
      case $facts['cmdline']['ima_appraise'] {
        'fix': {
          class { 'tpm::ima::appraise::relabel':
            relabel_file => $relabel_file
          }
        }
        'off' : {
          class { 'tpm::ima::appraise::fixmode':
            relabel_file => $relabel_file,
            relabel      => true
          }
        }
        'enforce' : {
          file { $relabel_file:
            ensure => absent
          }
        }
        default: {
          if $facts['cmdline']['ima_appraise_tcb'] {
          # if ima_appraise_tcb defaults to enforce mode.
            file { $relabel_file:
              ensure => absent
            }
          } else {
          # It is being turned on and should be set to fix mode
            class { 'tpm::ima::appraise::fixmode':
              relabel_file        => $relabel_file,
              relabel => true
            }
          }
        }
      }
    }
  } else {
  # If ima_appraise disabled
    kernel_parameter { ['ima_appraise', 'ima_appraise_tcb']:
      ensure   => absent,
      bootmode => 'normal'
    }
    file { "${scriptdir}/ima_security_attr_update.sh":
      ensure => absent
    }
  }

  reboot_notify { 'ima_appraise_reboot':
    subscribe => [
      Kernel_parameter['ima_appraise_tcb'],
    ]
  }
}
