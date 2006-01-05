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
use Switch 'Perl6';
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
    
    my $cmd = "net rpc trustdom establish '$domain' -U 'root%$passwd'";
    y2debug("net rpc trustdom establish '$domain' -U root%".("*"x length($passwd)));
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
