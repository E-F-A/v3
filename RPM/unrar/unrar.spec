Summary:    Utility for extracting RAR archives
Name:       unrar
Version:    5.7.4
Release:    1%{?dist}

License:    Proprietary
Group:      Applications/Archiving
URL:        http://www.rarlab.com/download.htm
Source0:    http://www.rarlab.com/rar/unrarsrc-%{version}.tar.gz

ExclusiveArch:    x86_64

%description
Utility for extracting, and viewing RAR archives

%prep
%setup -q -c -T
tar --strip-components=1 -xzf %{SOURCE0} --wildcards "unrar/*"

%build
make

%install
rm -rf %{buildroot}
mkdir -p %{buildroot}

mkdir -p %{buildroot}%{_bindir}
mkdir -p %{buildroot}%{_libdir}
mkdir -p %{buildroot}%{_sysconfdir}
mkdir -p %{buildroot}%{_defaultdocdir}/%{name}-%{version}
mkdir -p %{buildroot}%{_mandir}/man1

# Install RAR files
install -pm 755 unrar %{buildroot}%{_bindir}/unrar
install -pm 644 acknow.txt %{buildroot}%{_defaultdocdir}/%{name}-%{version}/acknow.txt
install -pm 644 license.txt %{buildroot}%{_defaultdocdir}/%{name}-%{version}/license.txt
install -pm 644 readme.txt %{buildroot}%{_defaultdocdir}/%{name}-%{version}/readme.txt

%files
%{_bindir}/%{name}
%{_defaultdocdir}/%{name}-%{version}/acknow.txt
%{_defaultdocdir}/%{name}-%{version}/license.txt
%{_defaultdocdir}/%{name}-%{version}/readme.txt

%changelog
* Sun Apr  7 2019 E.F.A. Project - 5.7.4-1
- updated to 5.7.4 version

* Wed Jun 17 2015 E.F.A. Project - 5.2.7-1
- initial build for CentOS & E.F.A. Project
