%define perl_vendorlib %(eval "`%{__perl} -V:installvendorlib`"; echo $installvendorlib)
%define perl_vendorarch %(eval "`%{__perl} -V:installvendorarch`"; echo $installvendorarch)
%define real_name Crypt-OpenSSL-RSA

Summary:        RSA encoding and decoding
Name:           perl-Crypt-OpenSSL-RSA
Version:        0.28
Release:        1.efa%{?dist}
License:        perl_5
Group:          Applications/CPAN
URL:            http://search.cpan.org/dist/Crypt-OpenSSL-RSA/
Source:         https://cpan.metacpan.org/authors/id/P/PE/PERLER/%{real_name}-%{version}.tar.gz
BuildRoot:      %{_tmppath}/%{name}-%{version}-%{release}-root
BuildRequires:  openssl-devel >= 1.0.1e
BuildRequires:  krb5-devel >= 1.10.3
BuildRequires:  perl(ExtUtils::MakeMaker)
BuildRequires:  perl(Crypt::OpenSSL::Random) >= 0.04
Requires:       perl(:MODULE_COMPAT_%(eval "`%{__perl} -V:version`"; echo $version))
Requires:       perl(Crypt::OpenSSL::Random) >= 0.04
Requires:       openssl >= 1.0.1e

%filter_from_requires /^perl*/d
%filter_setup

%description
Crypt::OpenSSL::RSA is an XS perl module designed to provide basic RSA
functionality.  It does this by providing a glue to the RSA functions
in the OpenSSL library.

%prep
%setup -n %{real_name}-%{version}

%build
CFLAGS="%{optflags}" %{__perl} Makefile.PL INSTALLDIRS="vendor" PREFIX="%{buildroot}%{_prefix}"
%{__make} %{?_smp_mflags} OPTIMIZE="%{optflags}" INC="-I/usr/kerberos/include"

%install
%{__rm} -rf %{buildroot}
%{__make} pure_install
%{__rm} -f %{buildroot}%{perl_vendorarch}/auto/Crypt/OpenSSL/RSA/.packlist
%{__rm} -f %{buildroot}%{perl_archlib}/perllocal.pod

%clean
%{__rm} -rf %{buildroot}

%files
%defattr(-, root, root, 0755)
%doc Changes README LICENSE
%{_mandir}/man3/*.3pm*
%dir %{perl_vendorarch}/Crypt/
%dir %{perl_vendorarch}/Crypt/OpenSSL/
%{perl_vendorarch}/Crypt/OpenSSL/RSA.pm
%dir %{perl_vendorarch}/auto/Crypt/
%dir %{perl_vendorarch}/auto/Crypt/OpenSSL/
%{perl_vendorarch}/auto/Crypt/OpenSSL/RSA/

%changelog
* Fri Feb 14 2016 Shawn Iverson <shawniverson@gmail.com> - 0.28-1
- Rebuilt for EFA https://efa-project.org

* Thu Feb 16 2012 David Hrbáč <david@hrbac.cz> - 0.28-1
- new upstream release

* Thu Dec 31 2009 Christoph Maser <cmr@financial.com> - 0.26-1
- Updated to version 0.26.

* Mon Jun 18 2007 Dries Verachtert <dries@ulyssis.org> - 0.25-1
- Updated to release 0.25.

* Tue Nov 14 2006 Dries Verachtert <dries@ulyssis.org> - 0.24-1
- Updated to release 0.24.

* Fri Jun  2 2006 Dries Verachtert <dries@ulyssis.org> - 0.23-1
- Updated to release 0.23.

* Wed Mar 22 2006 Dries Verachtert <dries@ulyssis.org> - 0.22-1.2
- Rebuild for Fedora Core 5.

* Wed Jun  8 2005 Dries Verachtert <dries@ulyssis.org> - 0.22-1
- Updated to release 0.22.

* Wed Jun 16 2004 Dries Verachtert <dries@ulyssis.org> - 0.21-1
- Initial package.
