# File:		modules/SambaAccounts.pm
# Package:	Configuration of samba-server
# Authors:	Stanislav Visnovsky <visnov@suse.cz>
#		Martin Lazar <mlazar@suse.cz>
#
# $Id$
#
# Representation of the configuration of samba-server.
# Input and output routines.


package SambaAccounts;

use strict;
use Data::Dumper;

use YaST::YCP qw(:DATA :LOGGING);
use YaPI;

textdomain "samba-server";
our %TYPEINFO;

BEGIN {
YaST::YCP::Import("SCR");
}

my %Passwords = ();
my %PdbCache = ();

BEGIN{$TYPEINFO{GetModified}=["function","boolean"]}
sub GetModified {
    return keys %Passwords;
}

BEGIN{$TYPEINFO{Read}=["function","boolean"]}
sub Read {
    return 1;
}

BEGIN{$TYPEINFO{Write}=["function","boolean"]}
sub Write {
    my $tmp = SCR->Read(".target.tmpdir") . "/inp";
    foreach my $user (keys %Passwords) {
	my $passwd = $Passwords{$user}{passwd};
	y2debug("UserAdd($user, ".($passwd?("*"x length($passwd)):"<undef>").")");
	if (!SCR->Write(".target.string", $tmp, $passwd . "\n" . $passwd . "\n")) {
	    y2error("Failed to prepare pdbedit input for user '$user'");
	    next;
	}
    
	my $cmd = "cat " . $tmp . " | pdbedit -a -t -u '$user'";
	if (SCR->Execute(".target.bash", $cmd)) {
	    y2error("Failed to execute '$cmd'");
	    next;
	}
    }
    SCR->Execute(".target.remove", $tmp);
    return 1;
}

BEGIN{$TYPEINFO{Import}=["function","void","any"]}
sub Import {
    my ($self, $config) = @_;
    %Passwords = ();
    return unless $config;
    foreach(@$config) {
	$Passwords{$_->{user}}{passwd} = $_->{passwd};
    }
}

BEGIN{$TYPEINFO{Export}=["function","any"]}
sub Export {
    my $list;
    foreach(keys %Passwords) {
	push @$list, {user=>$_, passwd=>$Passwords{$_}{passwd}};
    }
    return $list;
}

BEGIN{$TYPEINFO{UserAdd}=["function","boolean","string","string"]}
sub UserAdd {
    my ($self, $user, $passwd) = @_;
    $Passwords{$user}{passwd} = $passwd;
    $PdbCache{$user} = 1;
    return 0;
}

BEGIN{$TYPEINFO{UserExists}=["function","boolean","string"]}
sub UserExists {
    my ($self, $user) = @_;
    return $PdbCache{$user} if defined $PdbCache{$user};
    return 0 if Mode->test() || Mode->autoinst();
    
    my $cmd = "pdbedit -L -u '$user'";
    my $output = SCR->Execute(".target.bash_output", $cmd);
    y2debug("$cmd => ".Dumper($output));
    $PdbCache{$user} = $output->{exit} == 0;
    return $PdbCache{$user};
}

8;
