%define perl_vendorlib %(eval "`%{__perl} -V:installvendorlib`"; echo $installvendorlib)
%define perl_vendorarch %(eval "`%{__perl} -V:installvendorarch`"; echo $installvendorarch)

Name:           perl-IP-Country
Version:        2.28
Release:        1.efa%{?dist}
Summary:        fast lookup of country codes from IP addresses
License:        GPL+ or Artistic
Group:          Development/Libraries
URL:            https://metacpan.org/pod/IP::Country
Source0:        https://cpan.metacpan.org/authors/id/N/NW/NWETTERS/IP-Country-%{version}.tar.gz
BuildRoot:      %{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)
Requires:       perl(:MODULE_COMPAT_%(eval "`%{__perl} -V:version`"; echo $version))

%description
Finding the home country of a client using only the IP address can be difficult. 
Looking up the domain name associated with that address can provide some help, 
but many IP address are not reverse mapped to any useful domain, 
and the most common domain (.com) offers no help when looking for country.

This module comes bundled with a database of countries where various IP addresses have been assigned. 
Although the country of assignment will probably be the country associated with a large ISP rather than the client herself, 
this is probably good enough for most log analysis applications,
and under test has proved to be as accurate as reverse-DNS and WHOIS lookup.

%prep
%setup -q -n IP-Country-%{version}

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
#%{__rm} -rf %{buildroot}/%{_mandir}/man3

%{_fixperms} %{buildroot}/*

%check
%{__make} test

%clean
%{__rm} -rf %{buildroot}

%files
%defattr(-,root,root,-)
%doc CHANGES MANIFEST INSTALL README
%{perl_vendorlib}/*
%dir %{perl_vendorlib}/IP
%{perl_vendorlib}/IP/*
%dir %{perl_vendorlib}/IP/Country
%dir %{perl_vendorlib}/IP/Authority
%{perl_vendorlib}/IP/Country/*
%{perl_vendorlib}/IP/Authority/*
%dir %{perl_vendorlib}/IP/Country/Fast
%{perl_vendorlib}/IP/Country/Fast/*
%{_mandir}/man1/ip2cc.1.gz
%{_mandir}/man3/*.3pm*
/usr/bin/ip2cc


%changelog
* Sun Aug 28 2016 Shawn Iverson <shawniverson@gmail.com> - 2.28-1
- Built for EFA https://efa-project.org
