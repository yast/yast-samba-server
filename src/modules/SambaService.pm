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

# File:		modules/SambaService.ycp
# Package:	Configuration of samba-server
# Summary:	Data for configuration of samba-server, input and output functions.
# Authors:	Stanislav Visnovsky <visnov@suse.cz>
#		Martin Lazar <mlazar@suse.cz>
#		Lukas Ocilka <locilka@suse.cz>
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

our @service_names = ("nmb", "smb");

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
    if ($Service) {
        foreach my $service_name (@service_names) {
            Service->Enable($service_name) or $error = 1;
        }
    } else {
        foreach my $service_name (@service_names) {
            Service->Disable($service_name) or $error = 1;
        }
    }

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

# Get Whether SAMBA is running now or not
BEGIN{$TYPEINFO{GetServiceRunning} = ["function", "boolean"]}
sub GetServiceRunning {
    my $running = 1;
    foreach(@service_names) {
	if (! Service->Active($_)) {
	    $running = 0;
	}
    }
    return $running;
}

# Start/Stop SAMBA server daemons (smb and nmb) NOW.
# return @integer	0 on succes, -1 if cannot start, -2 if cannot reload, -3 if cannot stop
BEGIN{$TYPEINFO{StartStopNow}=["function", "boolean", "boolean"]};
sub StartStopNow {
    my ($self, $on) = @_;
    my $error = 0;

    # Zero connected users -> restart, either -> reload
    my $connected_users = $self->ConnectedUsers();
    my $nr_connected_users = scalar(@$connected_users);

    foreach my $service_name (@service_names) {
	if ($on) {
    	    # check, if the services run
	    if (Service->Active($service_name)) {
		# the service does not run => start it
		unless (Service->Start($service_name)) {
		    y2error("Service::Start($service_name) failed");
		    $error = 1;
		}
	    } else {
		# the service runs => relaod it
		# RunInitScript return exit code, 0 = OK
		# Bugzilla #120080 - 'reload' instead of 'restart'
		my $run_command = (($nr_connected_users > 0) ? "Reload":"Restart");
		y2milestone("Number of connected users: ".$nr_connected_users.", running ".$service_name." -> ".$run_command);
		if (! Service->$run_command($service_name)) {
		    y2error("Service::RunInitScript(".$service_name.", '".$run_command."') failed");
		    $error = 1;
		}
	    }
	} else {
	    # turn services off
	    unless (Service->Active($service_name)) {
		unless (Service->Stop($service_name)) {
		    y2error("Service::Stop($service_name) failed");
		    $error = 1;
		}
	    }
	}
    }
    
    return $error == 0;
}

BEGIN{$TYPEINFO{StartStopReload}=["function", "boolean"]};
sub StartStopReload {
    my $class = shift;

    # samba server should be enabled
    if ($class->GetServiceAutoStart()) {
	y2milestone("(re)starting samba-server...");
	$class->StartStopNow(1);
    # samba server should be disabled
    } else {
	y2milestone("stopping samba-server...");
	$class->StartStopNow(0);
    }
}

# Returns list of connected users
BEGIN{$TYPEINFO{ConnectedUsers}=["function",["list","string"]]};
sub ConnectedUsers {
    my $connected_users = [];
    my $command = 'LANG=C /usr/bin/smbstatus --brief';
    my $run_command = SCR->Execute('.target.bash_output', $command);
    if ($run_command->{'exit'} ne '0') {
	y2error("Command '".$command."' failed");
    } else {
	my $hr_found = 0;
	foreach (split(/\n/, $run_command->{'stdout'})) {
	    # listing of users starts with a horizontal line "----"
	    if (/^-+$/) { $hr_found = 1; }
	    # table contains: "[ ]*PID     Username      Group         Machine$"
	    if (($hr_found == 1) && /^[\t ]*\d+[\t ]+([^\t ]+)[\t ]+/) {
		push (@$connected_users, $1);
	    }
	}
    }
    return $connected_users;
}

8;
