name:          perl-ExtUtils-Install
summary:       ExtUtils-Install - Perl module
version:       2.04
release:       1.efa%{?dist}
license:       Artistic
group:         Applications/CPAN
url:           https://metacpan.org/pod/ExtUtils::Install
buildroot:     %{_tmppath}/%{name}-%{version}-%(id -u -n)
buildarch:     noarch
prefix:        %(echo %{_prefix})
source:        https://cpan.metacpan.org/authors/id/B/BI/BINGOS/ExtUtils-Install-%{version}.tar.gz
buildrequires: perl(Module::Build)
buildrequires: perl(Test::Harness)
buildrequires: perl(Test::More)
Requires:      perl(:MODULE_COMPAT_%(eval "`%{__perl} -V:version`"; echo $version))

%description
Install perl modules into the source tree. Used by ExtUtils::MakeMaker and
Module::Build.

%prep
%setup -q -n ExtUtils-Install-%{version} 

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

%check
%{__make} test

%clean
%{__rm} -rf %{buildroot}

%files 
%defattr(-,root,root,-)
%doc Changes README
%{perl_vendorlib}/*
%{_mandir}/man3/*

%changelog
* Tue Feb 23 2016 Shawn Iverson <shawniverson@gmail.com> - 2.04-1
- Built for EFA https://efa-project.org

* Mon Mar 11 2013 nicokad@nkadel-sl6.localdomain
- Initial build.
- Exclude manpages that conflict with perl-version and perl-JSON.
- Add dependencies on Module::Build, Test::Harness, and Test::More.
