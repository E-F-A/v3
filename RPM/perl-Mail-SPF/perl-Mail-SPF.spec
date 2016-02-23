Name:           perl-Mail-SPF
Version:        2.9.0
Release:        1.efa%{?dist}
Summary:        Object-oriented implementation of Sender Policy Framework
License:        BSD
Group:          Development/Libraries
URL:            http://search.cpan.org/dist/Mail-SPF/
Source0:        https://cpan.metacpan.org/authors/id/J/JM/JMEHNLE/mail-spf/Mail-SPF-v%{version}.tar.gz
BuildRoot:      %{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)
BuildArch:      noarch
BuildRequires:  perl(Error) >= 0.17015
BuildRequires:  perl(Module::Build)
BuildRequires:  perl(NetAddr::IP) >= 4.078
BuildRequires:  perl(Net::DNS) >= 1.04
BuildRequires:  perl(Net::DNS::Resolver::Programmable) >= 0.003
BuildRequires:  perl(Test::More)
BuildRequires:  perl(Test::Pod) >= 1.51
BuildRequires:  perl(URI) >= 1.13
BuildRequires:  perl(version) >= 0.77
Requires:       perl(Net::DNS) >= 0.58
Requires:       perl(URI) >= 1.40
Requires:       perl(:MODULE_COMPAT_%(eval "`%{__perl} -V:version`"; echo $version))

%description
Mail::SPF is an object-oriented implementation of Sender Policy Framework
(SPF). See http://www.openspf.org for more information about SPF.

%prep
%setup -q -n Mail-SPF-v%{version}

chmod -x bin/* sbin/*

%build
%{__perl} Build.PL installdirs=vendor
./Build

%install
rm -rf $RPM_BUILD_ROOT

./Build install destdir=$RPM_BUILD_ROOT create_packlist=0
find $RPM_BUILD_ROOT -depth -type d -exec rmdir {} 2>/dev/null \;

%{_fixperms} $RPM_BUILD_ROOT/*

# Don't include the spfd and spfquery scripts in _bindir.
rm -f $RPM_BUILD_ROOT%{_bindir}/spfquery $RPM_BUILD_ROOT%{_sbindir}/spfd
rm -rf $RPM_BUILD_ROOT%{_mandir}/man1

%check
./Build test

%clean
rm -rf $RPM_BUILD_ROOT

%files
%defattr(-,root,root,-)
%doc CHANGES LICENSE README TODO SIGNATURE
%{perl_vendorlib}/*
%{_mandir}/man3/*

%changelog
* Sun Feb 14 2016 Shawn Iverson <shawniverson@gmail.com> - 2.9.0
- Updated for EFA https://efa-project.org

* Sun Jul 26 2009 Fedora Release Engineering <rel-eng@lists.fedoraproject.org> - 2.006-3
- Rebuilt for https://fedoraproject.org/wiki/Fedora_12_Mass_Rebuild

* Thu Feb 26 2009 Fedora Release Engineering <rel-eng@lists.fedoraproject.org> - 2.006-2
- Rebuilt for https://fedoraproject.org/wiki/Fedora_11_Mass_Rebuild

* Fri Dec 12 2008 Steven Pritchard <steve@kspei.com> 2.006-1
- Update to 2.006.

* Thu Mar 06 2008 Tom "spot" Callaway <tcallawa@redhat.com> - 2.005-2
- Rebuild for new perl

* Mon Jul 09 2007 Steven Pritchard <steve@kspei.com> 2.005-1
- Specfile autogenerated by cpanspec 1.71.
- Add the "v" before version numbers to handle broken upstream packaging.
- Remove redundant perl build dependency.
- Drop bogus version number from Net::DNS::Resolver::Programmable dependency.
- Drop redundant explicit dependencies.
- BR Test::More and Test::Pod.
- Include the spfd and spfquery scripts as %%doc