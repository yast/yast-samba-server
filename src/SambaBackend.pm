# File:		modules/SambaBackend.pm
# Package:	Configuration of samba-server
# Authors:	Stanislav Visnovsky <visnov@suse.cz>
#		Martin Lazar <mlazar@suse.cz>
#
# $Id$
#
# Representation of the configuration of samba-server.
# Input and output routines.

package SambaBackend;

use strict;
use Switch 'Perl6';

use Data::Dumper;

use YaST::YCP qw(:DATA :LOGGING);
use YaPI;

textdomain "samba-server";
our %TYPEINFO;

YaST::YCP::Import("SambaConfig");

my %AvailableBackends = (
    ldapsam => "SambaBackendLDAP",
    tdbsam => "SambaBackendSimple",
    smbpasswd => "SambaBackendSimple",
#    mysql => "SambaBackendMySQL",
#    nisplussam => "SambaBackendNIS",
);

foreach(values %AvailableBackends) {
    YaST::YCP::Import($_);
}


use constant {
    TRUE => 1,
    FALSE => 0,
};

BEGIN{$TYPEINFO{GetPassdbBackends}=["function",["list","string"]]}
sub GetPassdbBackends {
    my ($self) = @_;
    return [ split " ", SambaConfig->GlobalGetStr("passdb backend", "smbpasswd") ];
}

BEGIN{$TYPEINFO{GetLocation}=["function","string","string"]}
sub GetLocation {
    my ($self, $backend) = @_;
    return $backend=~/:/?$':"";
}

BEGIN{$TYPEINFO{GetName}=["function","string","string"]}
sub GetName {
    my ($self, $backend) = @_;
    return $backend=~/:/?$`:$backend;
}

BEGIN{$TYPEINFO{SetPassdbBackends}=["function","boolean",["list","string"]]}
sub SetPassdbBackends {
    my ($self, $backends) = @_;
    my @toEnable;
    my %toDisable = map {$_, 1} keys %AvailableBackends;
    my $failed = 0;
    foreach (@$backends) {
	my $name = /:/?$`:$_;
	my $location = $';
	if (my $backend=$AvailableBackends{$name}) {
	    unshift @toEnable, {name=>$name, backend=>$backend, location=>$location};
	    delete $toDisable{$name};
	} else {
	    y2warning("Unknown backend '$name'");
	}
    }
    foreach (keys %toDisable) {
	$AvailableBackends{$_}->PassdbDisable($_) or $failed++;
    }
    foreach (@toEnable) {
	$_->{backend}->PassdbEnable($_->{name}, $_->{location}) or $failed++;
    }
    SambaConfig->GlobalSetStr("passdb backend", join(" ", @$backends));
    return $failed==0;
}

# add default (first in list) passdb backend
BEGIN{$TYPEINFO{AddPassdbBackend}=["function","boolean","string","string"]}
sub AddPassdbBackend {
    my ($self, $name, $url) = @_;
    # get backend and delete $name from list
    my @backends = grep {$_ !~ /^$name(:.*)$/} split " ", SambaConfig->GlobalGetStr("passdb backend", "smbpasswd");
    # prepend with new backend
    unshift @backends, $url ? "$name:$url" : $name;
    # set abckends
    return SetPassdbBackends($self, \@backends);
}

# delete passdb backend
BEGIN{$TYPEINFO{RemovePassdbBackend}=["function","boolean","string"]}
sub RemovePassdbBackend {
    my ($self, $name) = @_;
    # get backend and delete $name from list
    my @backends = grep {$_ !~ /^$name(:.*)$/} split " ", SambaConfig->GlobalGetStr("passdb backend", "smbpasswd");
    # set default backend
    @backends = ("tdbsam") unless @backends;
    # set abckends
    return SetPassdbBackends($self, \@backends);
}

BEGIN{$TYPEINFO{UpdateScripts}=["function","boolean"]}
sub UpdateScripts {
    my ($self) = @_;
    $self->RemoveScripts();
    my @backends = split " ", SambaConfig->GlobalGetStr("passdb backend","smbpasswd");
    (my $name = $backends[0]) =~ s/:(.*)//;
    my $location = $1;
    my $backend = $AvailableBackends{$name};
    if ($backend) {
	return $backend->UpdateScripts($name, $location);
    }
    y2warning("Unknown backend '$name'");
    return 1;
}

BEGIN{$TYPEINFO{RemoveScripts}=["function","void"]}
sub RemoveScripts {
    my ($self) = @_;
    my @opts = map {"$_ script"} map {("add $_", "delete $_")} 
	("user", "group", "machine", "user to group", "user from group");
    my %map = map {$_, undef} @opts;
    SambaConfig->GlobalSetMap(\%map);
}

BEGIN{$TYPEINFO{GetModified}=["function","boolean"]}
sub GetModified {
    my ($self) = @_;
    while(my ($a, $b) = each %AvailableBackends) {
	return TRUE if $b->GetModified($a);
    }
    return FALSE;
}

BEGIN{$TYPEINFO{Read}=["function", "boolean"]}
sub Read {
    my ($self) = @_;
    my $failed=0;
    while(my ($a,$b)=each %AvailableBackends) {
	$b->Read($a) or $failed++;
    }
    return $failed==0;
}

BEGIN{$TYPEINFO{Write}=["function","boolean","boolean"]}
sub Write {
    my ($self, $write_only) = @_;
    my $failed=0;
    while(my ($a,$b)=each %AvailableBackends) {
	$b->Write($a,$write_only) or $failed++;
    }
    return $failed==0;
}


BEGIN{$TYPEINFO{Export}=["function","any"]}
sub Export {
    my ($self) = @_;
    my $export = {};
    while(my ($a,$b) = each %AvailableBackends) {
	$export->{$a} = $b->Export($a);
    }
    return $export;
}

BEGIN{$TYPEINFO{Import}=["function","void","any"]}
sub Import {
    my ($self, $any) = @_;
    while(my ($a,$b) = each %AvailableBackends) {
	$b->Import($a,$any->{$a});
    }
}

8;
