# Sets up rngd service to provide entropy to the system via the
# tpm.
#
# @param ensure  How to manage the package.
#
# @param random_dev Kernel device used for random number output
#
# @param kernel_dev Kernel device used for random number input
#
# @param random_step Number of bytes written to random-device at a time
#
# @param entropy_cnt Number of bits to consider random when adding entropy
#
# @watermark feed entropy to random-device until at least fill-watermark
#            bits  of  entropy  are  available  in  its  entropy  pool
#
# @see man pages for rngd
#
# @author SIMP Team https://simpproject.com
#
class tpm::tpm2::entropy(
  String               $ensure        = $tpm::package_ensure,
  String               $random_dev    = '/dev/random',
  String               $kernel_dev    = '/dev/hwrng',
  Integer              $random_step   = 64,
  Integer[1,8]         $entropy_cnt   = 8,
  Integer[1024,4096]   $watermark     = 2048,
  StdLib::AbsolutePath $defaultsfile  = '/etc/sysconfig/rngd',
  StdLib::AbsolutePath $servicefile   = '/usr/lib/systemd/system/rngd.service',
  String               $servicetemp   = 'rngd/systemd',
  String               $defaultstemp  = 'rngd/defaults'
){

  include 'tpm'

  if facts('has_tpm') {

    package { 'rng-tools':
      ensure => $ensure,
    }

    kmod { 'tpm_rng':
      require => Package['rng-tools']
    }

    service {  'rngd':
      ensure  => 'running',
      enable  => true,
      require => Kmod['tpm_rng']
    }
  }

}
