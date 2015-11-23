Summary:    Utility for extracting RAR archives
Name:       unrar
Version:    5.2.7
Release:    %{dist}
Epoch:      1

License:    Proprietary
Group:      Applications/Archiving
URL:        http://www.rarlab.com/download.htm
Source0:    http://www.rarlab.com/rar/unrarsrc-%{version}.tar.gz

ExclusiveArch:    x86_64

%description
Utility for extracting, and viewing RAR archives

%prep
%setup -q -c -T

%build

%install
rm -rf %{buildroot}
mkdir -p %{buildroot}

tar -xvf %{SOURCE0}

mkdir -p %{buildroot}%{_bindir}
mkdir -p %{buildroot}%{_libdir}
mkdir -p %{buildroot}%{_sysconfdir}
mkdir -p %{buildroot}%{_defaultdocdir}/%{name}-%{version}
mkdir -p %{buildroot}%{_mandir}/man1

# Install RAR files
pushd %{name}
    install -pm 755 unrar %{buildroot}%{_bindir}/unrar
    install -pm 755 default.sfx %{buildroot}%{_libdir}/default.sfx
    install -pm 644 rarfiles.lst %{buildroot}%{_sysconfdir}/rarfiles.lst
    install -pm 644 acknow.txt %{buildroot}%{_defaultdocdir}/%{name}-%{version}/acknow.txt
    install -pm 644 license.txt %{buildroot}%{_defaultdocdir}/%{name}-%{version}/license.txt
    install -pm 644 order.htm %{buildroot}%{_defaultdocdir}/%{name}-%{version}/order.htm
    install -pm 644 rar.txt %{buildroot}%{_defaultdocdir}/%{name}-%{version}/rar.txt
    install -pm 644 readme.txt %{buildroot}%{_defaultdocdir}/%{name}-%{version}/readme.txt
    install -pm 644 whatsnew.txt %{buildroot}%{_defaultdocdir}/%{name}-%{version}/whatsnew.txt
popd

%files
%{_bindir}/%{name}
%{_libdir}/default.sfx
%config %{_sysconfdir}/rarfiles.lst

%files -n unrar
%{_bindir}/unrar

%changelog
* Wed Jun 17 2015 E.F.A. Project - 5.2.7-1
- initial build for CentOS & E.F.A. Project
