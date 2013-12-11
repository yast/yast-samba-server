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
Version:        3.1.1
Release:        0

BuildRoot:      %{_tmppath}/%{name}-%{version}-build
Source0:        %{name}-%{version}.tar.bz2

Group:          System/YaST
License:        GPL-2.0
# Service module switched to systemd
BuildRequires:	yast2 >= 2.23.15
BuildRequires:	libsmbclient libsmbclient-devel perl-Crypt-SmbHash perl-X500-DN samba-client yast2-samba-client perl-XML-Writer update-desktop-files yast2-testsuite yast2-perl-bindings yast2-ldap-client yast2-users
BuildRequires:  yast2-devtools >= 3.1.10

Requires:	perl-Crypt-SmbHash
# Wizard::SetDesktopTitleAndIcon
Requires:	yast2 >= 2.21.22
Requires:	yast2-ldap >= 2.17.3
Requires:	yast2-ldap-client
Requires:	yast2-perl-bindings
Requires:	yast2-network
# samba-client/routines.rb
Requires:	yast2-samba-client >= 3.0.0
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
