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

BEGIN{$TYPEINFO{UserAdd}=["function","boolean","string","string"]}
sub UserAdd {
    my ($self, $user, $passwd) = @_;

    y2debug("UserAdd($user, ".($passwd?("*"x length($passwd)):"<undef>").")");
    my $tmp = SCR->Read(".target.tmpdir") . "/inp";
    
    if (!SCR->Write(".target.string", $tmp, $passwd + "\n" + $passwd + "\n")) {
	y2error("Failed to prepare pdbedit input");
	return 0;
    }
    
    my $cmd = "cat " + $tmp + " | pdbedit -a -t -u '$user'";
    if (SCR->Execute(".target.bash", $cmd)) {
	y2error("Failed to execute '$cmd'");
	return 0;
    }
        
    return 1;
}

BEGIN{$TYPEINFO{UserExists}=["function","boolean","string"]}
sub UserExists {
    my ($self, $user) = @_;
    
    my $cmd = "pdbedit -L -u '$user'";
    my $output = SCR->Execute(".target.bash_output", $cmd);
    y2debug("$cmd => ".Dumper($output));
    return 0 if $output->{exit};
    return 1;
}

8;
