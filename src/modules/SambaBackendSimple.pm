# ------------------------------------------------------------------------------
# Copyright (c) 2006-2012 Novell, Inc. All Rights Reserved.
#
#
# This program is free software; you can redistribute it and/or modify it under
# the terms of version 2 of the GNU General Public License as published by the
# Free Software Foundation.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along with
# this program; if not, contact Novell, Inc.
#
# To contact Novell about this file by physical or electronic mail, you may find
# current contact information at www.novell.com.
# ------------------------------------------------------------------------------

# File:		modules/SambaBackendSimple.pm
# Package:	Configuration of samba-server
# Authors:	Stanislav Visnovsky <visnov@suse.cz>
#		Martin Lazar <mlazar@suse.cz>
#
# $Id$
#
# Representation of the configuration of samba-server.
# Input and output routines.

package SambaBackendSimple;

use strict;

use Data::Dumper;

use YaST::YCP qw(:DATA :LOGGING);
use YaPI;

textdomain "samba-server";
our %TYPEINFO;

BEGIN {
YaST::YCP::Import("SambaConfig");
}

use constant {
    TRUE => 1,
    FALSE => 0,
};

# enable passdb backend
BEGIN{$TYPEINFO{PassdbEnable}=["function","boolean","string", "string"]}
sub PassdbEnable {
    my ($self, $name, $location) = @_;
    return TRUE;
}

# diable passdb backend
BEGIN{$TYPEINFO{PassdbDisable}=["function","boolean","string"]}
sub PassdbDisable {
    my ($self,$name) = @_;
    return TRUE;
}

BEGIN{$TYPEINFO{UpdateScripts}=["function","boolean","string","string"]}
sub UpdateScripts {
    my ($self,$name,$location) = @_;
    SambaConfig->GlobalSetMap({
	"add machine script" => "/usr/sbin/useradd  -c Machine -d /var/lib/nobody -s /bin/false %m\$",
    });
    return TRUE;
}

BEGIN{$TYPEINFO{GetModified}=["function","boolean","string"]}
sub GetModified {
    my ($self,$name) = @_;
    return FALSE;
}

BEGIN{$TYPEINFO{Read}=["function","boolean","string"]}
sub Read {
    my ($self,$name) = @_;
    return TRUE;
}

BEGIN{$TYPEINFO{Write}=["function","boolean","string","boolean"]}
sub Write {
    my ($self, $name,$write_only) = @_;
    return TRUE;
}

BEGIN{$TYPEINFO{Export}=["function","any","string"]}
sub Export {
    my ($self,$name) = @_;
    return undef;
}

BEGIN{$TYPEINFO{Import}=["function","void","string","any"]}
sub Import {
    my ($self, $name,$any) = @_;
}

8;
