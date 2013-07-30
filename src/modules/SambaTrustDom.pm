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

# File:		modules/SambaTrustDom.pm
# Package:	Configuration of samba-server
# Authors:	Stanislav Visnovsky <visnov@suse.cz>
#		Martin Lazar <mlazar@suse.cz>
#
# $Id$
#
# Representation of the configuration of samba-server.
# Input and output routines.


package SambaTrustDom;

use strict;
use Data::Dumper;

use YaST::YCP qw(:DATA :LOGGING);
use YaPI;

textdomain "samba-server";
our %TYPEINFO;


BEGIN {
YaST::YCP::Import("SCR");
YaST::YCP::Import("SambaConfig");
YaST::YCP::Import("SambaSecrets");
}

our $ToEstablish;
our $ToRevoke;

BEGIN{$TYPEINFO{GetModified}=["function","boolean"]}
sub GetModified {
    my $self = $_;
    return $ToEstablish || $ToRevoke ? 1 : undef;
}

BEGIN{$TYPEINFO{Write}=["function","boolean"]}
sub Write {
    my $self = shift;
    my $ret = 1;
    if ($ToRevoke) {
	foreach(keys %$ToRevoke) {
	    $ret = 0 if $self->Revoke($_);
	}
	$ToRevoke = undef;
    }
    if ($ToEstablish) {
	while (my ($dom, $passwd) = each %$ToEstablish) {
	    $ret = 0 if $self->Establish($dom, $passwd);
	}
	$ToEstablish = undef;
    }
    return $ret;
}

BEGIN{$TYPEINFO{Export}=["function","any"]}
sub Export {
    return { revoke => $ToRevoke, establish => $ToEstablish };
}

BEGIN{$TYPEINFO{Import}=["function","void","any"]}
sub Import {
    my ($self, $map) = @_;
    $ToEstablish = $map->{establish};
    $ToRevoke = $map->{revoke};
}

BEGIN{$TYPEINFO{Revoke}=["function","boolean","string"]}
sub Revoke {
    my ($self, $domain) = @_;
    return undef unless defined $domain;

    my $cmd = "net rpc trustdom revoke '$domain'";
    y2debug("$cmd");
    if (SCR->Execute(".target.bash", $cmd)) {
	y2error("Cannot revoke trusted domain relationship for '$domain'");
	return undef;
    }
    return 1;
}

# Establish a trust relationship to a trusting domain.
BEGIN{$TYPEINFO{Establish}=["function","boolean","string","string"]}
sub Establish {
    my ($self, $domain, $passwd) = @_;
    return undef unless defined $domain;

    # escape all quote-strings
    $passwd =~ s/\"/\\\"/g;
    
    my $cmd = 'net rpc trustdom establish "'.$domain.'" -U "root%'.$passwd.'"';
    y2milestone('Running command >net rpc trustdom establish "'.$domain.'" -U "root%$password"<');
    if (SCR->Execute(".target.bash", $cmd)) {
	y2error("Cannot establish trusted domain relationship for '$domain'");
	return undef;
    }
    
    return 1;
}

BEGIN{$TYPEINFO{List}=["function",["list","string"]]}
sub List {
    my ($self) = @_;
    return SambaSecrets->GetTrustedDomains();
}

8;
