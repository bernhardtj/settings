# rpmbuild -ba -D 'forgeurl <URL>' -D 'branch <branch>' -D 'release 1.0' -D 'build make' -D 'install %make_install'

Version: %{release}
%forgemeta
License: (none)
Name: %(basename %{forgeurl})
Release: 1%{?dist}
Source: %{forgesource}
Summary: %{forgeurl}
%description
forge template
%prep
curl -Lo %{SOURCE0} %{forgesource}
%forgesetup
%build
%{build}
%install
%{install}
%check
find %{buildroot} -type d -empty > /tmp/f.txt
find %{buildroot} -type f >> /tmp/f.txt
sed -i 's,%{buildroot},,g;/debug/d' /tmp/f.txt
%files -f /tmp/f.txt
%changelog
%autochangelog

