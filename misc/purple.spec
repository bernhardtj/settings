Name:       EionRobb-purple-teams
Version:    c01fddf
Release:    1
Summary:    Most simple RPM package
License:    FIXME
Source0:    tarball.tar.gz

%description
This is my first RPM package, which does nothing.

%prep
curl -Lo /var/home/jj/rpmbuild/SOURCES/tarball.tar.gz https://github.com/eionrobb/purple-teams/tarball/master
%setup -q

%build
make

%install
%make_install

%files
/usr/lib/debug/usr/lib64/purple-2/libteams.so-c01fddf-1.x86_64.debug
/usr/lib64/purple-2/libteams.so
/usr/share/pixmaps/pidgin/protocols/16/teams.png
/usr/share/pixmaps/pidgin/protocols/22/teams.png
/usr/share/pixmaps/pidgin/protocols/48/teams.png

%changelog
# let's skip this for now

