[![License](http://img.shields.io/:license-apache-blue.svg)](http://www.apache.org/licenses/LICENSE-2.0.html)
[![CII Best Practices](https://bestpractices.coreinfrastructure.org/projects/73/badge)](https://bestpractices.coreinfrastructure.org/projects/73)
[![Puppet Forge](https://img.shields.io/puppetforge/v/simp/tpm.svg)](https://forge.puppetlabs.com/simp/tpm)
[![Puppet Forge Downloads](https://img.shields.io/puppetforge/dt/simp/tpm.svg)](https://forge.puppetlabs.com/simp/tpm)
[![Build Status](https://travis-ci.org/simp/pupmod-simp-tpm.svg)](https://travis-ci.org/simp/pupmod-simp-tpm)

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

This module manages TPM, including taking ownership. You must take ownership of
a TPM to load and unload certs, use it as a PKCS #11 interface, or to use
SecureBoot.

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


### This is a SIMP module

This module is a component of the [System Integrity Management Platform](https://simp-project.com),
a compliance-management framework built on Puppet.

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

This module will:
* Install `tpm-tools` and `trousers`
* Enable the `tcsd` service
* (*OPTIONAL*) Take ownership of the TPM
  * The password will be in a flat file in `$vardir/simp`
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

This module supports versions of tboot 1.9.6 and later.
This module only supports grub2.

#### Known Errors
There are known errors in tboot v1.9.6 and the creation of the LCP and VLP
fail with memory errors.  This was fixed in  tboot v1.9.7.

By default policy creation is disabled because as of Sept 06, 2018 tboot
v1.9.6 is the version delivered with RedHat 7.5.
If you want to compile tboot yourself the source can be obtained from the sourceforge:
 https://sourceforge.net/projects/tboot/

In order to check if tboot version is > 1.9.6 and policy is not true
it needs to do two passes because the fact for the version is executed
before the module installs tboot.

To avoid this the tboot version can be set in hiera:

```yaml
---
tpm::tboot::tboot_version: "1.9.6"
```

#### Setting up trusted boot

To set up trusted boot on a system do the following:

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
tpm::ownership::owner_pass: "whatever your password is"
# If you are using version 1.9.7 or later and want the LCP and VLP updated:
tpm::tboot::create_policy: true
# To avoid puppet having to do 2 passes to determine what version of tboot is installed
# you can set the version of tboot.
tpm::tboot::tboot_version: "1.9.6"
```

5. Include the `tpm::tboot` class:

```yaml
---
classes:
  - tpm
  - tpm::tboot
```

6. Run puppet (run it twice if you have not set the tboot version).
   Reboot and select the tboot option from the menu.
7. Check the `tboot` fact for a measured launch: `puppet facts | grep measured_launch` or just run `txt-stat`

#### Removing other options from the boot menu

If only the tboot menu option should be available to users then set the following in hiera:

```yaml
---
tpm::tboot::purge_boot_entries: true
```

This removes the execute permissions from the /etc/grub.d/10_linux file.
If you decide to remove tboot later, these permissions will need to
be set back to executable and the grub2-mkconfig run again.

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

## Development

Please read our [Contribution Guide](https://simp.readthedocs.io/en/stable/contributors_guide/Contribution_Procedure.html)


### Acceptance tests

**TODO:** There are currently no acceptance tests. We would need to use a
[virtual TPM](https://github.com/stefanberger/swtpm/) to ensure test system
stability, and it requires quite a few patches to libvirt, associated
emulation software, Beaker, and Vagrant before acceptance tests for this module become feasible. Read
our [progress so far on the issue](https://simp-project.atlassian.net/wiki/x/CgAVAg).
