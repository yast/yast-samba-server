# File:		modules/SambaLDAP.pm
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
use Switch 'Perl6';

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

BEGIN{$TYPEINFO{Enable}=["function","boolean","string", "string"]}
sub Enable {
    my ($self, $name, $location) = @_;
    return TRUE;
}

BEGIN{$TYPEINFO{Disable}=["function","boolean","string"]}
sub Disable {
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
