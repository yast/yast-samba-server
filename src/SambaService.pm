# File:		modules/SambaService.ycp
# Package:	Configuration of samba-server
# Summary:	Data for configuration of samba-server, input and output functions.
# Authors:	Stanislav Visnovsky <visnov@suse.cz>
#		Martin Lazar <mlazar@suse.cz>
#
# $Id$
#
# Representation of the configuration of samba-server.
# Input and output routines.


package SambaService;

use strict;
use Data::Dumper;

use YaST::YCP qw(:DATA :LOGGING);
use YaPI;

textdomain "samba-server";
our %TYPEINFO;

BEGIN {
YaST::YCP::Import("Service");
}

# Data was modified?
our $Modified = 0;

# Is smb and nmb service enabled? 
our $Service = 0;

# Data was modified?
BEGIN{ $TYPEINFO{GetModified} = ["function", "boolean"] }
sub GetModified {
    my ($self) = @_;
    return $Modified;
};

# Export
BEGIN{$TYPEINFO{Export}=["function", "any"]}
sub Export {
    my ($self) = @_;
    return $Service ? "Enabled" : "Disabled";
}

# Import
BEGIN{$TYPEINFO{Import}=["function", "void", "any"]}
sub Import {
    my ($self, $any) = @_;
    $any = "No" unless $any;
    $Service = ($any =~ /^(1|Enabled?|True|Yes)$/i) ? 1 : 0;
    $Modified = 0;
}

# Read
BEGIN{$TYPEINFO{Read}=["function", "boolean"]}
sub Read {
    my ($self) = @_;
    $Service = Service->Enabled("smb");
    $Modified = 0;
    return 1;
}

# Write
# return true on succes
BEGIN{$TYPEINFO{Write}=["function", "boolean"]}
sub Write {
    my ($self) = @_;
    my $error = 0;
    return 1 unless $Modified;
    y2debug("Samba service if ". ($Service ? "enabled" : "disabled"));
    Service->Adjust("nmb", $Service ? "enable" : "disable") or $error = 1;
    Service->Adjust("smb", $Service ? "enable" : "disable") or $error = 1;
    $Modified = 0;
    return $error == 0;
}

# Adjust SAMBA server services (smb and nmb).
BEGIN{$TYPEINFO{SetServiceAutoStart} = ["function", "void", "boolean"]}
sub SetServiceAutoStart {
    my ($self, $on) = @_;
    $on = 1 unless defined $on;
    unless (($on && $Service) || (!$on && !$Service)) {
	$Service = $on ? 1 : 0;
	$Modified = 1;
    }
}

# Get SAMBA server services (smb and nmb) status.
BEGIN{$TYPEINFO{GetServiceAutoStart} = ["function", "boolean"]}
sub GetServiceAutoStart {
    return $Service ? 1 : 0;
}

# Start/Stop SAMBA server daemons (smb and nmb) NOW.
# return @integer	0 on succes, -1 if cannot start, -2 if cannot reload, -3 if cannot stop
BEGIN{$TYPEINFO{StartStopNow}=["function", "boolean", "boolean"]};
sub StartStopNow {
    my ($self, $on) = @_;
    my $error = 0;
    
    foreach("nmb", "smb") {
	if ($on) {
    	    # check, if the services run
	    if (Service->Status($_)) {
		# the service does not run => start it
		unless (Service->Start($_)) {
		    y2error("Service::Start($_) failed");
		    $error = 1;
		}
	    } else {
		# the service runs => relaod it
		unless (Service->RunInitScript($_, "restart")) {
		    y2error("Service::RunInitScript($_, 'restart') failed");
		    $error = 1;
		}
	    }
	} else {
	    # turn services off
	    unless (Service->Status($_)) {
		unless (Service->Stop($_)) {
		    y2error("Service::Stop($_) failed");
		    $error = 1;
		}
	    }
	}
    }
    
    return $error == 0;
}

8;
