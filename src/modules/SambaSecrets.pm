#! /usr/bin/perl
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

# File:		modules/SambaSecrets.pm
# Package:	Samba server
# Summary:	Reading of /etc/samba/secrets.tdb
# Authors:	Stanislav Visnovsky <visnov@suse.cz>
#
# $Id$
#

package SambaSecrets;

use strict;
use Data::Dumper;

use YaST::YCP qw(:DATA :LOGGING);
use YaPI;

textdomain "samba-server";
our %TYPEINFO;

## Global imports
BEGIN{
YaST::YCP::Import("SCR");
}

use constant {
    secret_tdb => "/etc/samba/secrets.tdb",
    tdbdump => "/usr/bin/tdbdump",
};

our $Secrets;

# return true if effective user id is 0 (root user)
##sub isRoot {
##    return 1; #TODO
##}

# Read the current contents of the secrets file
BEGIN{$TYPEINFO{Read}=["function", "boolean"]}
sub Read {
    my ($self) = shift;
    
    return 1 if $Secrets;
    $Secrets = undef;
    
##    if (not isRoot()) {
##	y2error("You have to have root permisions to acces to secret.tdb");
##	return undef;
##
##    }
    # if the secrets file does not exist at all, return empty map
    my $res = SCR->Read(".target.stat", secret_tdb);
    unless (defined $res and keys %$res) {
	y2warning(secret_tdb." not found");
	return undef;
    }
    
    $res = SCR->Execute(".target.bash_output", tdbdump . " " . secret_tdb);
    if (!defined $res or $res->{exit}) {
	y2error("Cannot read TDB dump: " . Data::Dumper->Dump([$res], ["result"]));
	return undef;
    }
    
    my $current_key = undef;
    my @lines = split(/\n/, $res->{"stdout"});
    while (my $line = shift @lines) {
	if ($line =~ /^key = \"([^\"]*)\"$/) {
	    $current_key = $1;
	} elsif ($line =~ /^data = \"([^\"]*)\"$/) {
	    my $current_data = $1;
	    if (not defined $current_key) {
		y2error("Broken TDB dump - data without key");
		$Secrets = undef;
		return undef;
	    }
	    $Secrets->{$current_key} = $current_data;
	    $current_key = undef;
	}
    }
    y2debug("Readed " . scalar(keys %$Secrets) . " secret keys");
    return 1;
}

# get value from samba secret db
BEGIN{$TYPEINFO{GetKey}=["function","string","string"]}
sub GetKey {
    my ($self, $key) = @_;
    
    # initialize if needed
    return undef unless $Secrets or Read(0);

    return $Secrets->{$key};
}

# get LDAP bind passford for given admin dn
BEGIN{$TYPEINFO{GetLDAPBindPw}=["function","string","string"]}
sub GetLDAPBindPw {
    my ($self, $admin_dn) = @_;
    
    return undef unless $Secrets or Read(0);
    my $passwd = $Secrets->{"SECRETS/LDAP_BIND_PW/$admin_dn"};
    $passwd =~ s/\\00$// if defined $passwd;
    unless (defined $passwd) {
	y2warning("Cannot get LDAP bind password");
    }
    return $passwd;
}

# set LDAP bind dn
# NOTE: you have to write "ldap admin dn" to smb.conf first!
BEGIN{$TYPEINFO{WriteLDAPBindPw}=["function","boolean","string"]}
sub WriteLDAPBindPw {
    my ($self, $passwd) = @_;
    
    # change password
    my $cmd = "smbpasswd -w '".($passwd||"")."'";
    my $result = SCR->Execute(".target.bash_output", $cmd);
    if (!defined $result || $result->{exit}) {
	y2error("Cannot set the LDAP password: ". Data::Dumper->Dump([$result],["result"]));
	return undef;
    }
    $Secrets = undef;
    return 1;
}

# return trused domains / passwords pairs
BEGIN{$TYPEINFO{GetTrustedDomains}=["function",["list","string"]]}
sub GetTrustedDomains {
    my ($self) = @_;
    
    # initialize if needed
    return undef unless $Secrets or Read(0);

    my $res = [];
    while(my ($key, $data) = each %$Secrets) {
	push @$res, $1 if $key =~ m|SECRETS/\$DOMTRUST.ACC/(.+)|;
    };
    return $res;
}

8;

# EOF
