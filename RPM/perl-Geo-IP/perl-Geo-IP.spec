%define perl_vendorlib %(eval "`%{__perl} -V:installvendorlib`"; echo $installvendorlib)
%define perl_vendorarch %(eval "`%{__perl} -V:installvendorarch`"; echo $installvendorarch)
%define real_name perl-Geo-IP

Summary:        Maxmind geoip legacy perl API
Name:           perl-Geo-IP
Version:        1.45
Release:        1.efa%{?dist}
License:        Artistic/GPL
Group:          Applications
URL:            https://github.com/maxmind/geoip-api-perl
Source:         perl-Geo-IP-%{version}.tar.gz
BuildRoot:      %{_tmppath}/%{name}-%{version}-%{release}-root
BuildRequires:  perl >= 5
BuildRequires:  GeoIP-devel >= 1.4.5
Requires:       perl(:MODULE_COMPAT_%(eval "`%{__perl} -V:version`"; echo $version))

%description
This module a simple file-based database.  This database simply contains
IP blocks as keys, and countries as values.  The data contains all
public IP addresses and should be more complete and accurate than reverse DNS lookups.

%prep
%setup -q -n %{real_name}-%{version}

%build
%{__perl} Makefile.PL INSTALLDIRS="vendor" PREFIX="%{buildroot}%{_prefix}"
%{__make} %{?_smp_mflags}

%install
%{__rm} -rf %{buildroot}
%{__make} install

### Clean up buildroot
find %{buildroot} -name .packlist -exec %{__rm} {} \;
find %{buildroot} -name perllocal.pod -exec %{__rm} {} \;

%check
%{__make} test

%clean
%{__rm} -rf %{buildroot}

%files
%defattr(-, root, root, 0755)
%doc Changes LICENSE README
%{_mandir}/man3/*
%{perl_vendorarch}/Geo/*
%{perl_vendorarch}/auto/Geo/IP/*

%changelog
* Sun Feb 21 2016 Shawn Iverson <shawniverson@gmail.com> - 1.45-1
- Built for EFA https://efa-project.org
