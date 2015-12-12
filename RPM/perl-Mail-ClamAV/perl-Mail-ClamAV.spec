# Authority: efa-project.org

%define perl_vendorlib %(eval "`%{__perl} -V:installvendorlib`"; echo $installvendorlib)
%define perl_vendorarch %(eval "`%{__perl} -V:installvendorarch`"; echo $installvendorarch)

%define real_name Mail-ClamAV

BuildArch:     x86_64
Name:          perl-Mail-ClamAV
Version:       0.29
Release:       2.efa%{?dist}
License:       Artistic 
Group:         Applications/CPAN
Summary:       Perl module with bindings for the clamav virus scanner
Distribution:  EFA repository for Red Hat Enterprise Linux 6
URL:           http://search.cpan.org/dist/Mail-ClamAV/
Vendor:        https://efa-project.org
Packager:      Shawn Iverson <shawniverson@gmail.com>
Source: http://www.cpan.org/modules/by-module/Mail/Mail-ClamAV-%{version}.tar.gz

BuildRequires: bzip2-devel
BuildRequires: clamav-devel >= 0.99-3
BuildRequires: gmp-devel
BuildRequires: perl
BuildRequires: perl-Inline
BuildRequires: perl(Parse::RecDescent)
BuildRequires: zlib-devel
Provides:      ClamAV.so()(64bit)  
Provides:      perl(Mail::ClamAV) = 0.29
Provides:      perl(Mail::ClamAV::Status)  
Provides:      perl-Mail-ClamAV = 0.29-2.efa.el6
Provides:      perl-Mail-ClamAV(x86-64) = 0.29-2.efa.el6
Requires:      libbz2.so.1()(64bit)  
Requires:      libc.so.6()(64bit)  
Requires:      libc.so.6(GLIBC_2.2.5)(64bit)  
Requires:      libclamav.so.7()(64bit)  
Requires:      libclamav.so.7(CLAMAV_PUBLIC)(64bit)  
Requires:      libz.so.1()(64bit)  
Requires:      perl  
Requires:      perl >= 0:5.006001
Requires:      perl(Carp)  
Requires:      perl(Class::Struct)  
Requires:      perl(Exporter)  
Requires:      perl(IO::Handle)  
Requires:      perl(Inline)  
Requires:      perl(strict)  
Requires:      perl(warnings)  
Requires:      rtld(GNU_HASH)  

%description
Mail-ClamAV is a Perl module with bindings for the clamav virus scanner.

%prep
%setup -n %{real_name}-%{version}

%build
CFLAGS="%{optflags}" %{__perl} Makefile.PL INSTALLDIRS="vendor" PREFIX="%{buildroot}%{_prefix}"
%{__make} OPTIMIZE="%{optflags}"

%install
%{__rm} -rf %{buildroot}
%{__make} pure_install

### Clean up buildroot
find %{buildroot} -name .packlist -exec %{__rm} {} \;

%clean
%{__rm} -rf %{buildroot}

%files
%defattr(-, root, root, 0755)
%dir %{perl_vendorarch}/Mail/
%{perl_vendorarch}/Mail/ClamAV.pm
%dir %{perl_vendorarch}/auto/Mail/
%{perl_vendorarch}/auto/Mail/ClamAV/
%doc Changes INSTALL MANIFEST META.yml README
%doc %{_mandir}/man3/Mail::ClamAV.3pm*

%changelog
* Sat Dec 12 2015 Shawn Iverson <shawniverson@gmail.com> - 0.29-2.efa
- Fix libclamav.so.6 failed dependency for clamav-0.99-3

* Thu Jul 23 2009 Christoph Maser <cmr@financial.com> - 0.29-1 - 7981/dag
- Updated to version 0.29.

* Wed May 28 2008 Dag Wieers <dag@wieers.com> - 0.22-1
- Updated to release 0.22.

* Tue Jan 15 2008 Dries Verachtert <dries@ulyssis.org> - 0.21-1
- Updated to release 0.21.

* Thu Dec 20 2007 Dag Wieers <dag@wieers.com> - 0.20-2
- Rebuild against clamav 0.92.

* Wed May 02 2007 Dag Wieers <dag@wieers.com> - 0.20-1
- Initial package. (using DAR)

