[![License](http://img.shields.io/:license-apache-blue.svg)](http://www.apache.org/licenses/LICENSE-2.0.html) [![Build Status](https://travis-ci.org/simp/pupmod-simp-tpm.svg)](https://travis-ci.org/simp/pupmod-simp-tpm)

#### Table of Contents

1. [Description](#description)
2. [Setup - The basics of getting started with tpm](#setup)
    * [What tpm affects](#what-tpm-affects)
    * [Setup requirements](#setup-requirements)
    * [Beginning with the tpm](#beginning-with-the-tpm-module)
3. [Usage - Configuration options and additional functionality](#usage)
4. [Reference - An under-the-hood peek at what the module is doing and how](#reference)
5. [Limitations - OS compatibility, etc.](#limitations)
6. [Development - Guide for contributing to the module](#development)
    * [Acceptance Tests - Beaker env variables](#acceptance-tests)


## Description

### For TPM 1.2:
This module manages a TPM, including taking ownership and enabling IMA. You must
take ownership of a TPM to load and unload certs, use it as a PKCS #11
interface, or to use SecureBoot or IMA.

The [Integrity Management Architecture (IMA)](https://sourceforge.net/p/linux-ima/wiki/Home/)
subsystem is a tool that uses the TPM to verify integrity of the system, based
on filesystem and file hashes. The IMA class sets up IMA kernel boot flags if
they are not enabled and when they are, mounts the `securityfs`. This module can
manage the IMA policy, although modifying the policy incorrectly could cause
your system to become read-only.

The TPM ecosystem has been designed to be difficult to automate. The difficulty
has shown many downsides of using a tool like this module to manage your
TPM device. For example, simply reading the TPM's public key after taking
ownership of the device requires the owner password to be typed in at the
command line. This is an intentional feature to encourage admins to be
physically present at the machine with the device. To get around this, the
provider included in this module and the advanced facts use Ruby's `expect`
library to interact with the command line. This module also drops the owner
password in the Puppet `$vardir` to make interacting with trousers in facts
possible.

### TPM 2.0

This module can be used to set the owner, endorement hierarchy and lock out passowrds
on TPM 2.0.

Limitations:  It currently only works for a system with one TPM and can not be used to
  unset the password.

It will create a file called owned in the /sys/class/tpm/<tpm name> directory to indicate that
the TPM is owned.  To reset the passwords the Password must be cleared and this file removed.
### This is a SIMP module

This module is a component of the [System Integrity Management Platform](https://github.com/NationalSecurityAgency/SIMP), a compliance-management framework built on Puppet.

If you find any issues, they may be submitted to our [bug tracker](https://simp-project.atlassian.net/).

This module is optimally designed for use within a larger SIMP ecosystem, but it can be used independently:

 * When included within the SIMP ecosystem, security compliance settings will be managed from the Puppet server.
 * If used independently, all SIMP-managed security subsystems are disabled by default and must be explicitly opted into by administrators.  Please review the `$client_nets`, `$enable_*` and `$use_*` parameters in `manifests/init.pp` for details.


## Setup


### What tpm affects

--------------------------------------------------------------------------------
> **WARNING**
>
> This module can take ownership of your TPM. This could be a destructive
> process and is not easily reversed. For that reason, the provider does not
> support clearing a TPM.

--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
> **WARNING**
>
> Inserting poorly-formed or incorrect policy into the IMA policy file could
> cause your system to become read-only. This can be temporarily remedied by a
> reboot. This is the current case with the way the module manages the policy
> and it is not recommended to use this section of the module at this time.

--------------------------------------------------------------------------------

This module will:
* Install `tpm-tools` and `trousers`
* Enable the `tcsd` service
* (*OPTIONAL*) Take ownership of the TPM
  * The password will be in a flat file in `$vardir/simp`
* (*OPTIONAL*) Enable IMA on the host
  * (*OPTIONAL*) Manage the IMA policy (BROKEN - See Limitations)
* (*OPTIONAL*) Install `tboot`, create policy, and add grub entry


### Setup Requirements

In order to use this module or a TPM in general, you must do the following:

1. Enable the TPM in BIOS
2. Set a user/admin BIOS password
3. Be able to type in the user/admin password at boot time, every boot


### Beginning with the TPM module

--------------------------------------------------------------------------------
> **NOTE**
>
> Using the 'well-known' SRK password is not recommended for actual use,
> but it is required for both Intel TXT (Trusted Boot) and the [PKCS#11
> interface](http://trousers.sourceforge.net/pkcs11.html). If you aren't using
> either of those technologies, please use a real password.

--------------------------------------------------------------------------------

Include the TPM class and set the passwords in hiera. If either of the passwords
are the string 'well-known', then the well known option will be added to the
`tpm_takeownership` command used to take ownership of the TPM:

```yaml
classes:
  - tpm

tpm::take_ownership: true
tpm::ownership::advanced_facts: true

tpm::ownership::owner_pass: 'twentycharacters0000'
tpm::ownership::srk_pass: 'well-known'
```

To enable IMA and the PKCS #11 interface, add this to hiera:

```yaml
tpm::use_ima: true
tpm::enable_pkcs_interface: true
```

To enable the PKCS#11 interface, add the `tpm::pkcs11` class to your node and set the PINs in hiera:

```yaml
classes:
  - tpm::pkcs11

tpm::pkcs11::so_pin: '12345678'
tpm::pkcs11::user_pin: '87654321'
```

To start with Trusted Boot follow the directions below carefully.

## Usage

### Ownership

The type and provider for tpm ownership provided in this module can be used as follows:

```puppet
tpm_ownership { 'tpm0':
  ensure         => present,
  owner_pass     => 'well-known',
  srk_pass       => 'well-known',
  advanced_facts => true
}
```

### PKCS#11

The PKCS#11 slot type and provider can be enabled as follows:

```puppet
tpmtoken { 'TPM PKCS#11 token':
  ensure   => present,
  so_pin   => '12345678',
  user_pin => '87654321'
}
```

### Trusted Boot

This module should be able to create the policy required to allow the machine to
complete a measured launch.

1. Make sure the TPM owner password is 20 characters long and the SRK password
   is 'well-known', equivalent to `tpm_takeownership -z`
2. Download the appropriate SINIT for your platform from the [Intel website](https://software.intel.com/en-us/articles/intel-trusted-execution-technology)
3. Extract the zip and put it on a webserver somewhere or in a profile module.
4. Set the following data in hiera:

```yaml
---
tpm::tboot::sinit_name: 2nd_gen_i5_i7_SINIT_51.BIN # the appropriate BIN
tpm::tboot::sinit_source: 'puppet:///profiles/2nd_gen_i5_i7_SINIT_51.BIN' # where ever you choose to stash this
tpm::tboot::owner_password: "%{alias('tpm::ownership::owner_pass')}"
```

5. Include the `tpm::tboot` class:

```yaml
---
classes:
  - tpm
  - tpm::tboot
```

6. Reboot into the Grub option that specifies 'no policy', booting into a tboot session
7. Let puppet run again at boot
8. Reboot into the normal tboot boot option
9. Check the `tboot` fact for a measured launch: `puppet facts | grep measured_launch` or just run `txt-stat`

#### Locking the kernel

The `tpm::tboot` class will use the `yum::versionlock` define from the
`voxpupuli/yum` module to make sure the version of the kernel that the tboot
policy was created with doesn't get upgraded without the user knowing. To
disable this, set the `tpm::tboot::lock_kernel_packages` parameter to `false`.

This module does provide a script to upgrade the policy, though it shouldn't be
run from Puppet. To update your verified launch policy, do the following steps:

1. `yum update kernel`
2. `grub2-mkconfig -o /etc/grub2.cfg`
3. `sh /root/txt/txt/update_tboot_policy.sh <owner password>`

And reboot!

## Reference

Please refer to the inline documentation within each source file, or to the
module's generated YARD documentation for reference material.


## Limitations

SIMP Puppet modules are generally intended for use on Red Hat Enterprise Linux
and compatible distributions, such as CentOS. Please see the
[`metadata.json` file](./metadata.json) for the most up-to-date list of
supported operating systems, Puppet versions, and module dependencies.

This module does not support clearing a previously owned TPM.

### IMA

The current RedHat implementation of IMA does not seem to work after inserting
our default policy (generated example in `spec/files/default_ima_policy.conf`).
It causes the system to become read-only, even though it is only using supported
configuration elements. The module will be updated soon with more sane defaults
to allow for at least the minimal amount of a system to be measured.

To get started, include the `tpm::ima::policy` class and set these parameters.
From there, they can be changed to `true` on one by one:

```yaml
tpm::ima::policy::measure_root_read_files: false
tpm::ima::policy::measure_file_mmap: false
tpm::ima::policy::measure_bprm_check: false
tpm::ima::policy::measure_module_check: false
tpm::ima::policy::appraise_fowner: false
```

## Development

Please read our [Contribution Guide](https://simp.readthedocs.io/en/master/contributors_guide/Contribution_Procedure.html)


### Acceptance tests

**TODO:** There are currently no acceptance tests. We would need to use a
[virtual TPM](https://github.com/stefanberger/swtpm/) to ensure test system
stability, and it requires quite a few patches to libvirt, associated
emulation software, Beaker, and Vagrant before acceptance tests for this module become feasible. Read
our [progress so far on the issue](https://simp-project.atlassian.net/wiki/x/CgAVAg).
