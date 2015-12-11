Summary: TPM Puppet Module
Name: pupmod-tpm
Version: 0.0.1
Release: 9
License: Apache License, Version 2.0
Group: Applications/System
Source: %{name}-%{version}-%{release}.tar.gz
Buildroot: %{_tmppath}/%{name}-%{version}-%{release}-buildroot
Requires: pupmod-augeasproviders >= 1.0.2-1
Requires: pupmod-simplib >= 1.0.0-0
Requires: puppet >= 3.3.0
Requires: puppetlabs-stdlib >= 4.1.0-0
Buildarch: noarch
Requires: simp-bootstrap >= 4.2.0
Obsoletes: pupmod-tpm-test

Prefix: /etc/puppet/environments/simp/modules

%description
This module provides the ability to configure the IMA on your system if it supports it.

At this time, there is no good way of detecting if your system has IMA support without attempting to install it.

Full TPM support will be added in later versions.

%prep
%setup -q

%build

%install

[ "%{buildroot}" != "/" ] && rm -rf %{buildroot}

mkdir -p %{buildroot}/%{prefix}/tpm

dirs='lib manifests templates'
for dir in $dirs; do
  test -d $dir && cp -r $dir %{buildroot}/%{prefix}/tpm
done

mkdir -p %{buildroot}/usr/share/simp/tests/modules/tpm

%clean
[ "%{buildroot}" != "/" ] && rm -rf %{buildroot}

mkdir -p %{buildroot}/%{prefix}/tpm

%files
%defattr(0640,root,puppet,0750)
%{prefix}/tpm

%post
#!/bin/sh

if [ -d %{prefix}/tpm/plugins ]; then
  /bin/mv %{prefix}/tpm/plugins %{prefix}/tpm/plugins.bak
fi

%postun
# Post uninstall stuff

%changelog
* Mon Nov 09 2015 Chris Tessmer <chris.tessmer@onypoint.com> - 0.0.1-9
- migration to simplib and simpcat (lib/ only)

* Mon Jul 27 2015 Trevor Vaughan <tvaughan@onyxpoint.com> - 0.0.1-8
- Disable IMA by default.

* Thu Jul 09 2015 Nick Markowski <nmarkowski@kewcorp.com> - 0.0.1-7
- Cast ima_audit to string when passed to kernel_parameter.

* Thu Feb 19 2015 Trevor Vaughan <tvaughan@onyxpoint.com> - 0.0.1-6
- Migrated to the new 'simp' environment.

* Fri Jan 16 2015 Trevor Vaughan <tvaughan@onyxpoint.com> - 0.0.1-5
- Changed puppet-server requirement to puppet

* Sat Aug 23 2014 Trevor Vaughan <tvaughan@onyxpoint.com> - 0.0.1-4
- Replaced the reboot calls with the new reboot_notify type.

* Sat Aug 02 2014 Trevor Vaughan <tvaughan@onyxpoint.com> - 0.0.1-3
- Upadted the has_tpm fact to use /sys
- Fixed the ima_enabled fact to use /proc/cmdline

* Thu Jul 31 2014 Adam Yohrling <adam.yohrling@onyxpoint.com> - 0.0.1-2
- Added has_tpm fact
- Added installation of tpm-tools and trousers (by dependency)
- Added tcsd service
- Updated spec_helper to include rubygems (didn't run without)
- Updated spec tests
- Changed existing logic to use str2bool in tpm::ima class for fact check

* Thu Jul 10 2014 Trevor Vaughan <tvaughan@onyxpoint.com> - 0.0.1-2
- Updated the 'tpm::ima' class to use the new 'common::reboot'
  functionality as well as the kernel_parameter augeasproviders mods

* Mon Apr 28 2014 Nick Markowski <nmarkowski@keywcorp.com> - 0.0.1-1
- Updated ima_enabled fact to properly return IMA status
- Typo fix in the template

* Thu Mar 27 2014 Nick Markowski <nmarkowski@keywcorp.com> - 0.0.1-0
- Initial Commit.
- Provided basic IMA functionality to set kernel boot flags, and mount
  securityfs at /sys/kernel/security if present.
