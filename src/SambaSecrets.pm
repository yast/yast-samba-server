#! /usr/bin/perl
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

my $Secrets;

# return true if effective user id is 0 (root user)
sub isRoot {
    return 1; #TODO
}

# Read the current contents of the secrets file
BEGIN{$TYPEINFO{Read}=["function", "boolean"]}
sub Read {
    my ($self) = shift;
    
    return 1 if $Secrets;
    $Secrets = {};
    
    if (not isRoot()) {
	y2error("You have to have root permisions to acces to secret.tdb");
	return 0;
    }
    
    # if the secrets file does not exist at all, return empty map
    my $res = SCR->Read(".target.stat", secret_tdb);
    unless (defined $res and keys %$res) {
	y2warning(secret_tdb." not found");
	return 0;
    }
    
    $res = SCR->Execute(".target.bash_output", tdbdump . " " . secret_tdb);
    if ($res->{exit}) {
	y2error("Cannot read TDB dump: " . ($res->{stdout}||"<undef>"));
	return 0;
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
		return 0;
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
    Read(0) or return undef unless $Secrets;

    return $Secrets->{$key};
}

# get LDAP bind passford for given admin dn
BEGIN{$TYPEINFO{GetLDAPBindPw}=["function","string","string"]}
sub GetLDAPBindPw {
    my ($self, $admin_dn) = @_;
    
    Read(0) or return undef unless $Secrets;
    my $passwd = $Secrets->{"SECRETS/LDAP_BIND_PW/$admin_dn"};
    $passwd =~ s/\00// if defined $passwd;
    unless (defined $passwd) {
	y2warning("Cannot find LDAP bind password");
    }
    return $passwd;
}

# set LDAP bind dn
# NOTE: you have to write "ldap admin dn" to smb.conf first!
BEGIN{$TYPEINFO{WriteLDAPBindPw}=["function","boolean","string"]}
sub WriteLDAPBindPw {
    my ($self, $passwd) = @_;
    
    # change password
    my $cmd = "smbpasswd -w '$passwd'";
    my $result = SCR->Execute(".target.bash_output", $cmd);
    if ($result->{exit}) {
	y2error($result->{stderr} || "Cannot set the LDAP password.");
	return 0;
    }
    $Secrets = undef;
    return 1;
}

# return trused domains / passwords pairs
BEGIN{$TYPEINFO{GetTrustedDomains}=["function",["list","string"]]}
sub GetTrustedDomains {
    my ($self) = @_;
    
    # initialize if needed
    Read(0) or return undef unless $Secrets;

    my $res = [];
    while(my ($key, $data) = each %$Secrets) {
	push @$res, $1 if $key =~ m|SECRETS/\$DOMTRUST.ACC/(.+)|;
    };
    return $res;
}

8;

# EOF
