#
# spec file for package yast2-configuration-management
#
# Copyright (c) 2017 SUSE LINUX GmbH, Nuernberg, Germany.
#
# All modifications and additions to the file contributed by third parties
# remain the property of their copyright owners, unless otherwise agreed
# upon. The license for this file, and modifications and additions to the
# file, is the same license as for the pristine package itself (unless the
# license for the pristine package is not an Open Source License, in which
# case the license is the MIT License). An "Open Source License" is a
# license that conforms to the Open Source Definition (Version 1.9)
# published by the Open Source Initiative.

# Please submit bugfixes or comments via http://bugs.opensuse.org/
#


Name:           yast2-configuration-management
Version:        4.0.2
Release:        0

BuildRoot:      %{_tmppath}/%{name}-%{version}-build
Source0:        %{name}-%{version}.tar.bz2

Url:            http://github.com/yast/yast-migration

BuildRequires:  yast2
BuildRequires:  yast2-devtools
BuildRequires:  yast2-installation
BuildRequires:  rubygem(rspec)
BuildRequires:  rubygem(yast-rake)

Requires:       yast2
Requires:       yast2-installation

BuildArch:      noarch

Summary:        YaST2 - YaST Configuration Management
License:        GPL-2.0-only
Group:          System/YaST

%description
This package contains the YaST2 component for Configuration Management Provisioning.

%prep
%setup -n %{name}-%{version}

%check
rake test:unit

%build

%install
rake install DESTDIR="%{buildroot}"

%files
%defattr(-,root,root)
%{yast_clientdir}/*.rb
%{yast_libdir}/configuration_management
%{yast_desktopdir}/*.desktop

%dir %{yast_docdir}
%license %{yast_docdir}/COPYING
%doc %{yast_docdir}/README.md
%doc %{yast_docdir}/CONTRIBUTING.md

%changelog
