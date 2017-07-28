%define name smeserver-qmail-printpdf
%define version 0.1
%define release 7
Summary: Plugin to enable allow email print to PDF
Name: %{name}
Version: %{version}
Release: %{release}
License: GNU GPL version 2
URL: http://libreswan.org/
Group: SMEserver/addon
Source: %{name}-%{version}.tar.gz

BuildRoot: /var/tmp/%{name}-%{version}
BuildArchitectures: noarch
BuildRequires: e-smith-devtools
Requires:  e-smith-release >= 9.0
Requires:  uudeview >= 0.5.20-2
AutoReqProv: no

%description
Plugin to enable allow email print to PDF

%changelog
* Fri Jul 28 2017 John Crisp <jcrisp@safeandsoundit.co.uk> 0.1-7
- fix mssing parenthesis

* Mon May 15 2017 John Crisp <jcrisp@safeandsoundit.co.uk> 0.1-6
- refine printpdf.conf template

* Mon May 15 2017 John Crisp <jcrisp@safeandsoundit.co.uk> 0.1-5
- fix wrong directory structure in /etc/

* Mon May 15 2017 John Crisp <jcrisp@safeandsoundit.co.uk> 0.1-4
- Add missing DB type

* Mon May 15 2017 John Crisp <jcrisp@safeandsoundit.co.uk> 0.1-3
- fix printpdf perms

* Thu Apr 20 2017 John Crisp <jcrisp@safeandsoundit.co.uk> 0.1-2
- initial release

* Fri Feb 03 2017 John Crisp <jcrisp@safeandsoundit.co.uk> 0.1-1
- initial release

%prep
%setup

%build
perl createlinks

%install
rm -rf $RPM_BUILD_ROOT
(cd root ; find . -depth -print | cpio -dump $RPM_BUILD_ROOT)
rm -f %{name}-%{version}-filelist
/sbin/e-smith/genfilelist $RPM_BUILD_ROOT > %{name}-%{version}-filelist
echo "%doc COPYING" >> %{name}-%{version}-filelist


%clean
cd ..
rm -rf %{name}-%{version}

%files -f %{name}-%{version}-filelist
%defattr(-,root,root)

%pre
%preun
%post


echo "see http://wiki.contribs.org/PrintToPDF"

%postun
