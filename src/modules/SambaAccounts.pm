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
use Crypt::SmbHash;
use Data::Dumper;

use YaST::YCP qw(:DATA :LOGGING);
use YaPI;

textdomain "samba-server";
our %TYPEINFO;

BEGIN {
YaST::YCP::Import("SCR");
YaST::YCP::Import("FileUtils");
YaST::YCP::Import("Directory");
}

my %Pdb = ();
my %PdbCache = ();

BEGIN{$TYPEINFO{GetModified}=["function","boolean"]}
sub GetModified {
    return keys %Pdb;
}

BEGIN{$TYPEINFO{Read}=["function","boolean"]}
sub Read {
    return 1;
}

BEGIN{$TYPEINFO{Write}=["function","boolean"]}
sub Write {
    my $error = 0;
    my $tmpfile = Directory->tmpdir()."/samba-server-pdbedit-tmpfile";

    foreach my $user (keys %Pdb) {
	my $nthash = $Pdb{$user}{nthash};
	$nthash = "X"x32 unless $nthash;
	my $lmhash = $Pdb{$user}{lmhash};
	$lmhash = "X"x32 unless $lmhash;

	my $uid = getpwnam($user);
	if (!defined $uid) {
	    y2error("Unknown user '$user'.");
	    $error = 1;
	    next;
	}
	
	y2debug("delete user '$user' (if exist)");
	SCR->Execute(".target.bash", "pdbedit --delete --user='$user'");
	
	y2debug("add user '$user'");
	my $smbpasswd=sprintf "%s:%d:%s:%s:[%-11s]:LCT-%08X\n", $user, $uid, $lmhash, $nthash, "U", time;

	y2milestone ("Writing user (".$user.") settings to: ".$tmpfile);
	SCR->Write (".target.string", $tmpfile, $smbpasswd);

	my $cmd = "pdbedit -i smbpasswd:$tmpfile";
	if (SCR->Execute(".target.bash", $cmd)) {
	    y2error("Failed to execute '$cmd'");
	    $error = 1;
	    next;
	}
    }

    if (FileUtils->Exists ($tmpfile)) {
	y2milestone ("Removing temporary file: ".$tmpfile);
	SCR->Execute (".target.remove", $tmpfile);
    }

    return $error == 0;
}

BEGIN{$TYPEINFO{Import}=["function","void","any"]}
sub Import {
    my ($self, $config) = @_;
    %Pdb = ();
    return unless $config;
    foreach my $item (@$config) {
	next unless $item->{user};
	$Pdb{$item->{user}} = {map {$_, $item->{$_}} grep {$_ ne "user"} keys %$item};
	$PdbCache{$item->{user}} = 1;
    }
}

BEGIN{$TYPEINFO{Export}=["function","any"]}
sub Export {
    my $list = [];
    foreach my $user (sort keys %Pdb) {
	push @$list, {user=>$user, map {$_, $Pdb{$user}{$_}} keys %{$Pdb{$user}}};
    }
    return $list;
}

BEGIN{$TYPEINFO{UserAdd}=["function","boolean","string","string"]}
sub UserAdd {
    my ($self, $user, $passwd) = @_;
    $Pdb{$user}{lmhash} = Crypt::SmbHash::lmhash($passwd);
    $Pdb{$user}{nthash} = Crypt::SmbHash::nthash($passwd);
    $PdbCache{$user} = 1;
    return 0;
}

BEGIN{$TYPEINFO{UserExists}=["function","boolean","string"]}
sub UserExists {
    my ($self, $user) = @_;
    return $PdbCache{$user} if defined $PdbCache{$user};
    return 0 if Mode->autoinst();
    
    my $cmd = "pdbedit -L -u '$user'";
    my $output = SCR->Execute(".target.bash_output", $cmd);
    y2debug("$cmd => ".Dumper($output));
    $PdbCache{$user} = $output->{exit} == 0;
    return $PdbCache{$user};
}

8;
