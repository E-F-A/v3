Name:           perl-Socket
Version:        2.021
Release:        1.efa%{?dist}
Summary:        Perl socket networking constants and support functions
License:        GPL+ or Artistic
Group:          Development/Libraries
URL:            https://metacpan.org/pod/Socket
Source0:        https://cpan.metacpan.org/authors/id/P/PE/PEVANS/Socket-%{version}.tar.gz
BuildRoot:      %{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)
Requires:       perl(:MODULE_COMPAT_%(eval "`%{__perl} -V:version`"; echo $version))

%description
This module provides a variety of constants, structure manipulators and other functions related to socket-based networking. The values and functions provided are useful when used in conjunction with Perl core functions such as socket(), setsockopt() and bind(). It also provides several other support functions, mostly for dealing with conversions of network addresses between human-readable and native binary forms, and for hostname resolver operations.

%prep
%setup -q -n Socket-%{version}

%build
%{__perl} Makefile.PL INSTALLDIRS="vendor" PREFIX="%{buildroot}%{_prefix}"
%{__make} %{?_smp_mflags}

%install
%{__rm} -rf %{buildroot}
%{__make} install

### Clean up buildroot
find %{buildroot} -name .packlist -exec %{__rm} {} \;
find %{buildroot} -name perllocal.pod -exec %{__rm} {} \;
find %{buildroot} -depth -type d -exec rmdir {} 2>/dev/null \;

# Remove man conflict with perl package
%{__rm} -rf %{buildroot}/%{_mandir}/man3

%{_fixperms} %{buildroot}/*

%check
%{__make} test

%clean
%{__rm} -rf %{buildroot}

%files
%defattr(-,root,root,-)
%doc Artistic Copying Changes LICENSE
%{perl_vendorarch}/*
%{perl_vendorarch}/auto/Socket/*

%changelog
* Sun Feb 21 2016 Shawn Iverson <shawniverson@gmail.com> - 2.021-1
- Built for EFA https://efa-project.org
