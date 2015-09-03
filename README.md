[![License](http://img.shields.io/:license-apache-blue.svg)](http://www.apache.org/licenses/LICENSE-2.0.html) [![Build Status](https://travis-ci.org/simp/pupmod-simp-tpm.svg)](https://travis-ci.org/simp/pupmod-simp-tpm) [![SIMP compatibility](https://img.shields.io/badge/SIMP%20compatibility-4.2.*%2F5.1.*-orange.svg)](https://img.shields.io/badge/SIMP%20compatibility-4.2.*%2F5.1.*-orange.svg)

## This is a SIMP module
This module is a component of the [System Integrity Management Platform](https://github.com/NationalSecurityAgency/SIMP), a compliance-management framework built on Puppet.

If you find any issues, they can be submitted to our [JIRA](https://simp-project.atlassian.net/).

Please read our [Contribution Guide](https://simp-project.atlassian.net/wiki/display/SD/Contributing+to+SIMP) and visit our [developer wiki](https://simp-project.atlassian.net/wiki/display/SD/SIMP+Development+Home).

## Work in Progress

Please excuse us as we transition this code into the public domain.

Downloads, discussion, and patches are still welcome!

### tboot.pp
#
# The tpm::tboot class is disabled by default. You will need to add the class and set enable to true. When enabled it will look for the "has_tpm" fact and the version of Enterprise Linux. If it is version 6 or version 7 it will install the tboot RPM and setup grub for trusted boot. A reboot is required to enter tboot mode. If tboot was successful PCR 17-19 will be populated with real hash values. Developement information of Intel(R) TXT can be found here: http://www.intel.com/content/dam/www/public/us/en/documents/guides/intel-txt-software-development-guide.pdf. 
#
###
