[![License](http://img.shields.io/:license-apache-blue.svg)](http://www.apache.org/licenses/LICENSE-2.0.html) [![Build Status](https://travis-ci.org/simp/pupmod-simp-tpm.svg)](https://travis-ci.org/simp/pupmod-simp-tpm) [![SIMP compatibility](https://img.shields.io/badge/SIMP%20compatibility-4.2.*%2F5.1.*-orange.svg)](https://img.shields.io/badge/SIMP%20compatibility-4.2.*%2F5.1.*-orange.svg)

#### Table of Contents

1. [Description](#description)
2. [Setup - The basics of getting started with tpm](#setup)
    * [What tpm affects](#what-tpm-affects)
    * [Setup requirements](#setup-requirements)
    * [Beginning with the tpm](#beginning-with-the-tpm)
3. [Usage - Configuration options and additional functionality](#usage)
4. [Reference - An under-the-hood peek at what the module is doing and how](#reference)
5. [Limitations - OS compatibility, etc.](#limitations)
6. [Development - Guide for contributing to the module](#development)
    * [Acceptance Tests - Beaker env variables](#acceptance-tests)


## Description

This module manages a TPM, including taking ownership and enabling IMA. You must
take ownership of a TPM to load and unload certs, use it as a PKCS #11
interface, or to use SecureBoot or IMA.

The [Integrity Management Architecture (IMA)](https://sourceforge.net/p/linux-ima/wiki/Home/) subsystem is a tool that
uses the TPM to verify integrity of the system, based on filesystem and file
hashes. The IMA class sets up IMA kernel boot flags if they are not enabled and
when they are, mounts the `securityfs`.

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

This module will:
* install `tpm-tools` and `trousers`
* enable the `tcsd` service
* (*OPTIONAL*) Take ownership of the TPM
  * The password will be in a flat file in `$vardir/simp`
* (*OPTIONAL*) Enable IMA on the host


### Setup Requirements

In order to use the TPM module or a TPM in general, you must do the following:

1. Enable the TPM in BIOS
2. Set a user/admin BIOS password
3. Be able to type in the user/admin password at boot time, every boot


### Beginning with the TPM module

Include the TPM class and set the passwords in hieradata:

```yaml
classes:
  - tpm

tpm::take_ownership: true
tpm::ownership::advanced_facts: true
```

To enable IMA, add this line to hiera:

```yaml
tpm::use_ima: true
```

## Usage

The type and provider provided in this module can be used as follows:

```puppet
tpm_ownership { 'tpm0':
  ensure         => present,
  owner_pass     => 'badpass',
  srk_pass       => 'badpass2',
  advanced_facts => true
}
```

## Reference

Please refer to the inline documentation within each source file, or to the module's generated YARD documentation for reference material.


## Limitations

SIMP Puppet modules are generally intended for use on Red Hat Enterprise Linux and compatible distributions, such as CentOS. Please see the [`metadata.json` file](./metadata.json) for the most up-to-date list of supported operating systems, Puppet versions, and module dependencies.

This module does not support clearing a previously owned TPM.


## Development

Please read our [Contribution Guide](https://simp-project.atlassian.net/wiki/display/SD/Contributing+to+SIMP) and visit our [developer wiki](https://simp-project.atlassian.net/wiki/display/SD/SIMP+Development+Home).


### Acceptance tests

**TODO:** There are currently no acceptance tests. We would need to use a
[virtual TPM](https://github.com/stefanberger/swtpm/) to ensure test system
stability, and it requires quite a few patches to libvirt, associated
emulation software, Beaker, and Vagrant before acceptance tests for this module become feasible. Read
our [progress so far on the issue](https://simp-project.atlassian.net/wiki/x/CgAVAg).

This module will include [Beaker](https://github.com/puppetlabs/beaker) acceptance tests using the SIMP [Beaker Helpers](https://github.com/simp/rubygem-simp-beaker-helpers).  By default the tests will use [Vagrant](https://www.vagrantup.com/) with [VirtualBox](https://www.virtualbox.org) as a back-end; Vagrant and VirtualBox must both be installed to run these tests without modification. To execute the tests, when written, run the following:

```shell
bundle install
bundle exec rake beaker:suites
```

Please refer to the [SIMP Beaker Helpers documentation](https://github.com/simp/rubygem-simp-beaker-helpers/blob/master/README.md) for more information.
