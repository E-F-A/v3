%define perl_vendorlib %(eval "`%{__perl} -V:installvendorlib`"; echo $installvendorlib)
%define perl_vendorarch %(eval "`%{__perl} -V:installvendorarch`"; echo $installvendorarch)
%define real_name Net-DNS

Summary:        Perl DNS resolver module
Name:           perl-Net-DNS
Version:        1.04
Release:        1.efa%{?dist}
License:        mit
Group:          Applications/CPAN
URL:            http://search.cpan.org/dist/Net-DNS/
Source:         https://cpan.metacpan.org/authors/id/N/NL/NLNETLABS/Net-DNS-%{version}.tar.gz
BuildRoot:      %{_tmppath}/%{name}-%{version}-%{release}-root
BuildRequires:  perl(ExtUtils::MakeMaker) >= 6.55, perl(Test::More)
BuildRequires:  perl(Digest::HMAC) >= 1.03
Requires:       perl(:MODULE_COMPAT_%(eval "`%{__perl} -V:version`"; echo $version))

%description
Net::DNS is a DNS resolver implemented in Perl.  It allows the
programmer to perform nearly any type of DNS query from a Perl
script.

%prep
%setup -n %{real_name}-%{version}

%build
CFLAGS="%{optflags}" %{__perl} Makefile.PL INSTALLDIRS="vendor" PREFIX="%{buildroot}%{_prefix}" \
    --no-online-tests
%{__make} %{?_smp_mflags} OPTIMIZE="%{optflags}"

%install
%{__rm} -rf %{buildroot}
%{__make} pure_install

### Clean up buildroot
find %{buildroot} -name .packlist -exec %{__rm} {} \;

### Clean up docs
find contrib/ -type f -exec %{__chmod} a-x {} \;

%clean
%{__rm} -rf %{buildroot}

%files
%defattr(-, root, root, 0755)
%doc Changes README contrib/
%doc %{_mandir}/man3/*.3pm*
%dir %{perl_vendorarch}/auto/Net/
%{perl_vendorarch}/auto/Net/DNS/
%dir /usr/share/perl5/vendor_perl/Net/
/usr/share/perl5/vendor_perl/Net/DNS/
/usr/share/perl5/vendor_perl/Net/DNS.pm

%changelog
* Sun Feb 14 2016 Shawn Iverson <shawniverson@gmail.com> - 1.04-1
- Updated for EFA https://efa-project.org

* Mon Dec 17 2012 David Hrbáč <david@hrbac.cz> - 0.71-1
- new upstream release

* Thu Feb 16 2012 David Hrbáč <david@hrbac.cz> - 0.68-1
- new upstream release

* Mon Jan 16 2012 David Hrbáč <david@hrbac.cz> - 0.67-1
- new upstream release

* Thu Dec 31 2009 Christoph Maser <cmr@financial.com> - 0.66-1
- Updated to version 0.66.

* Sat Jul  4 2009 Christoph Maser <cmr@financial.com> - 0.65-1
- Updated to version 0.65.

* Wed Feb 20 2008 Dag Wieers <dag@wieers.com> - 0.63-1
- Updated to release 0.63.

* Fri Jan 04 2008 Dag Wieers <dag@wieers.com> - 0.62-1
- Updated to release 0.62.

* Mon Aug 27 2007 Dag Wieers <dag@wieers.com> - 0.61-1
- Updated to release 0.61.

* Tue Sep 19 2006 Dries Verachtert <dries@ulyssis.org> - 0.59-1
- Updated to release 0.59.

* Mon Sep 18 2006 Dries Verachtert <dries@ulyssis.org> - 0.58-1
- Updated to release 0.58.

* Sat Apr 08 2006 Dries Verachtert <dries@ulyssis.org> - 0.57-1
- Updated to release 0.57.

* Sat Nov 05 2005 Dries Verachtert <dries@ulyssis.org> - 0.53-1
- Updated to release 0.53.

* Wed Oct 20 2004 Dries Verachtert <dries@ulyssis.org> - 0.48-1
- Updated to release 0.48.

* Sat Jun 19 2004 Dag Wieers <dag@wieers.com> - 0.47-1
- Updated to release 0.47.

* Mon Jul 14 2003 Dag Wieers <dag@wieers.com> - 0.38-0
- Updated to release 0.38.

* Sun Jan 26 2003 Dag Wieers <dag@wieers.com> - 0.33-0
- Initial package. (using DAR)
