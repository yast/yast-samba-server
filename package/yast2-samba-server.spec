#
# spec file for package yast2-samba-server
#
# Copyright (c) 2013 SUSE LINUX Products GmbH, Nuernberg, Germany.
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


Name:           yast2-samba-server
Version:        4.1.0
Release:        0

BuildRoot:      %{_tmppath}/%{name}-%{version}-build
Source0:        %{name}-%{version}.tar.bz2
Url:            https://github.com/yast/yast-samba-server

Group:          System/YaST
License:        GPL-2.0
# Service.Active
BuildRequires:  libsmbclient-devel
BuildRequires:  perl-Crypt-SmbHash
BuildRequires:  perl-X500-DN
BuildRequires:  perl-XML-Writer
BuildRequires:  samba-client
BuildRequires:  update-desktop-files
# Yast2::ServiceWidget
BuildRequires:  yast2 >= 4.1.0
BuildRequires:  yast2-devtools >= 3.1.10
BuildRequires:  yast2-ldap
BuildRequires:  yast2-perl-bindings
BuildRequires:  yast2-samba-client
BuildRequires:  yast2-testsuite
BuildRequires:  yast2-users

Requires:	perl-Crypt-SmbHash
# Yast2::ServiceWidget
Requires:	yast2 >= 4.1.0
Requires:	yast2-ldap >= 3.1.2
Requires:	yast2-perl-bindings
Requires:	yast2-network
# samba-client/routines.rb
Requires:	yast2-samba-client >= 3.1.15
Requires:	yast2-users

# bnc #386473, recommend yast2-samba-server when installaing these packages
Supplements:	samba

BuildArchitectures:	noarch

Requires:       yast2-ruby-bindings >= 1.0.0

Summary:	YaST2 - Samba Server Configuration

%description
This package contains the YaST2 component for Samba server
configuration.

%prep
%setup -n %{name}-%{version}

%build
%yast_build

%install
%yast_install


%files
%defattr(-,root,root)
%dir %{yast_yncludedir}/samba-server
%{yast_yncludedir}/samba-server/*
%{yast_ydatadir}/*.rb
%{yast_clientdir}/*.rb
%{yast_moduledir}/*
%{yast_desktopdir}/samba-server.desktop
%{yast_schemadir}/autoyast/rnc/samba-server.rnc
%doc %{yast_docdir}
