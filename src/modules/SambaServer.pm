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

# File:		modules/SambaServer.ycp
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


package SambaServer;

use strict;
use Data::Dumper;

use YaST::YCP qw(:DATA :LOGGING);
use YaPI;

textdomain "samba-server";
our %TYPEINFO;

BEGIN {
YaST::YCP::Import("SCR");
YaST::YCP::Import("Mode");
YaST::YCP::Import("Report");
YaST::YCP::Import("Summary");
YaST::YCP::Import("Progress");
#HELPME: YaST::YCP::Import("Directory");
YaST::YCP::Import("FirewalldWrapper");
YaST::YCP::Import("PackageSystem");

YaST::YCP::Import("SambaRole");
YaST::YCP::Import("SambaConfig");
YaST::YCP::Import("SambaService");
YaST::YCP::Import("SambaBackend");
YaST::YCP::Import("SambaSecrets");
YaST::YCP::Import("SambaNmbLookup");
YaST::YCP::Import("SambaTrustDom");
YaST::YCP::Import("SambaAccounts");
YaST::YCP::Import("Samba");
YaST::YCP::Import ("Popup");

}

use constant {
#HELPME:    DONE_ONCE_FILE => Directory->vardir . "/samba_server_done_once"
    DONE_ONCE_FILE => "/var/lib/YaST2" . "/samba_server_done_once"
};


my $Modified;

# list of required packages
my $RequiredPackages = ["samba", "samba-client"];
# ... or another packages (BNC #657414)
my $RequiredPackages_gplv3 = ["samba-gplv3", "samba-gplv3-client"];
# cups packages needed for printer sharing
my $CupsPackages = ["cups"];

my $GlobalsConfigured = 0;


# Set modify flag
BEGIN{ $TYPEINFO{SetModified} = ["function", "void"] }
sub SetModified {
    my ($self) = @_;
    $Modified = 1;
}

# Data was modified?
BEGIN{ $TYPEINFO{GetModified} = ["function", "boolean"] }
sub GetModified {
    my ($self) = @_;
    return $Modified 
	|| SambaConfig->GetModified() 
	|| SambaService->GetModified() 
	|| SambaBackend->GetModified()
	|| SambaTrustDom->GetModified()
	|| SambaAccounts->GetModified();
};

# Check that base packages are installed or offer their installation
BEGIN{ $TYPEINFO{GetModified} = ["function", "boolean"] }
sub CheckAndInstallBasePackages {
  # installed_required_packages? or installed_packages_gplv3? or install_packages!
  PackageSystem->InstalledAll($RequiredPackages) ||
    PackageSystem->InstalledAll($RequiredPackages_gplv3) ||
      PackageSystem->CheckAndInstallPackagesInteractive($RequiredPackages) ||
        return 0;
  return 1;
}

BEGIN{ $TYPEINFO{GetModified} = ["function", "boolean"] }
sub CheckNeedToInstallCupsPackages {
    my $printing = SambaConfig->GlobalGetStr("printing", "cups");

    unless ((lc $printing eq "cups") and SambaConfig->ShareExists("printers") and SambaConfig->ShareEnabled("printers")) {
        return 0;
    }
    if (PackageSystem->InstalledAll($CupsPackages)) {
        return 0;
    }

    return 1;
}

# Read all samba-server settings
# @param force_reread force reread configuration
# @param no_progreass_bar disable progress bar
# @return true on success
BEGIN{ $TYPEINFO{Read} = ["function", "boolean"] }
sub Read {
    my ($self) = @_;

    # Samba-server read dialog caption
    my $caption = __("Initializing Samba Server Configuration");

    # We do not set help text here, because it was set outside
    Progress->New($caption, " ", 7, [
	    # translators: progress stage
	    __("Read global Samba settings"),
	    # translators: progress stage
	    __("Read Samba secrets"),
	    # translators: progress stage
	    __("Read Samba service settings"),
	    # translators: progress stage
	    __("Read Samba accounts"),
	    # translators: progress stage
	    __("Read the back-end settings"),
	    # translators: progress stage
	    __("Read the firewall settings"),
	    # translators: progress stage
	    __("Read Samba service role settings"),
	], [
	    # translators: progress step
	    __("Reading global Samba settings..."),
	    # translators: progress step
	    __("Reading Samba secrets..."),
	    # translators: progress step
	    __("Reading Samba service settings..."),
	    # translators: progress step
	    __("Reading Samba accounts..."),
	    # translators: progress step
	    __("Reading the back-end settings..."),
	    # translators: progress step
	    __("Reading the firewall settings..."),
	    # translators: progress stage
	    __("Reading Samba service role settings..."),
	    # translators: progress finished
	    __("Finished"),
	],
	""
    );

    # 1: read global settings
    Progress->NextStage();
    # check installed packages
    unless (Mode->test()) {
	CheckAndInstallBasePackages() or return 0;
    }
    SambaConfig->Read();
    unless (Mode->test()) {
        if (CheckNeedToInstallCupsPackages()) {
            my $answer = Popup->YesNo(__("Cups is required by samba for printing to \nwork correctly. Do you wish to disable printing?\nNote: To reenable printing you will need to \nmanually enable the \"printers\" share and install cups."));
            if ($answer) {
                SambaConfig->ShareDisable("printers");
                SambaConfig->ShareSetModified("printers");
            } else {
                PackageSystem->CheckAndInstallPackagesInteractive($CupsPackages) or return 0
            }
        }
    }
    Samba->ReadSharesSetting();
    
    # 2: read samba secrets
    Progress->NextStage();
    SambaSecrets->Read();
    
    # 3: read services settings
    Progress->NextStage();
    SambaService->Read();
    # start nmbstatus in background
    SambaNmbLookup->Start() unless Mode->test();
    
    # 4: read accounts
    Progress->NextStage();
    SambaAccounts->Read();

    # 5: read backends settings
    Progress->NextStage();
    SambaBackend->Read();

    # 6: read firewall setting
    Progress->NextStage();
    my $po = Progress->set(0);
    FirewalldWrapper->read();
    Progress->set($po);

    # 7: Read other settings
    Progress->NextStage();
    $Modified = 0;
    
    $GlobalsConfigured = $self->Configured();

    # ensure nmbd is restarted if stopped for lookup
    SambaNmbLookup->checkNmbstatus() unless Mode->test();

    y2milestone("Service:". (SambaService->GetServiceAutoStart() ? "Enabled" : "Disabled"));
    y2milestone("Role:". SambaRole->GetRoleName());

    # Reading finished
    Progress->Finish();
    
    return 1;
}

BEGIN{ $TYPEINFO{Configured} = ["function", "boolean"] }
sub Configured {
    my ($self) = @_;

    # check /etc/samba/smb.conf
    return 0 unless SambaConfig->Configured();
    
    # check file /$VARDIR/samba_server_done_once
    my $stat = SCR->Read(".target.stat", DONE_ONCE_FILE);
    return 1 if defined $stat->{size};

    # check if the main config file is modified already
    my $res = SCR->Execute(".target.bash_output", "rpm -V samba-client | grep '/etc/samba/smb\.conf'");
    return 1 if $res && !$res->{"exit"} and $res->{"stdout"};

    return 0;
}


# Write all samba-server settings
# @param write_only if true write only
# @return true on success
BEGIN{ $TYPEINFO{Write} = ["function", "boolean", "boolean"] }
sub Write {
    my ($self, $write_only) = @_;

    # Samba-server read dialog caption
    my $caption = __("Saving Samba Server Configuration");

    # We do not set help text here, because it was set outside
    Progress->New($caption, " ", 4, [
	    # translators: write progress stage
	    _("Write global settings"),
	    # translators: write progress stage
	    # translators: write progress stage
	    _("Write back-end settings"),
	    # translators: write progress stage
	    _("Write Samba accounts"),
	    # translators: write progress stage
	    _("Save firewall settings")
	], [
	    # translators: write progress step
	    _("Writing global settings..."),
	    # translators: write progress step
	    _("Writing back-end settings..."),
	    # translators: write progress step
	    _("Writing Samba accounts..."),
	    # translators: write progress step
	    _("Saving firewall settings..."),
	    # translators: write progress step
	    _("Finished")
	],
	""
    );

    # 1: write settings
    # if nothing to write, quit (but show at least the progress bar :-)
    Progress->NextStage();
    return 1 unless $self->GetModified();

# bnc #387085
# package not available anymore
#
#    # check, if we need samba-pdb package
#    my %backends = map {/:/;$`||$_,1} split " ", SambaConfig->GlobalGetStr("passdb backend", "");
#    if($backends{mysql}) {
#	PackageSystem->CheckAndInstallPackagesInteractive(["samba-pdb"]) or return 0;
#    }

    y2milestone ("Writing WINS Host Resolution=", Samba->GetHostsResolution());
    Samba->WriteHostsResolution();

    if (!SambaConfig->Write($write_only)) {
	# /etc/samba/smb.conf is filename
    	Report->Error(__("Cannot write settings to /etc/samba/smb.conf."));
	return 0;
    }
    SCR->Execute(".target.bash", "touch " . DONE_ONCE_FILE);
    # write samba shares feature, only write => 1
    Samba->WriteShares();

    # 2: write backends settings && write trusted domains
    Progress->NextStage();
    SambaBackend->Write();
    SambaTrustDom->Write();

    # 3: write accounts
    Progress->NextStage();
    SambaAccounts->Write();

    # 4: save firewall settings
    Progress->NextStage();
    my $po = Progress->set(0);
    FirewalldWrapper->write();
    Progress->set($po);
    
    # progress finished
    Progress->NextStage();

    $GlobalsConfigured = 1;
    $Modified = 0;

    return 1;
}

# Get all samba-server settings from the first parameter
# (For use by autoinstallation.)
# @param settings The YCP structure to be imported.
BEGIN{ $TYPEINFO{Import} = ["function", "void", ["map", "any", "any"]] }
sub Import {
    my ($self, $settings) = @_;

    if ($settings and defined $settings->{"config"} and scalar(@{$settings->{"config"}})) {
	$GlobalsConfigured = 1;
    } else {
	$GlobalsConfigured = 0;
    }
    $Modified = 1;
	
    y2debug("Importing: ", Dumper($settings));

    SambaConfig->Import($settings->{"config"});
    SambaService->Import($settings->{"service"});
    SambaTrustDom->Import($settings->{"trustdom"});
    SambaBackend->Import($settings->{"backend"});
    SambaAccounts->Import($settings->{"accounts"});
}

# Dump the samba-server settings to a single map
# (For use by autoinstallation.)
# @return map Dumped settings (later acceptable by Import ())
BEGIN{ $TYPEINFO{Export} = ["function", "any"]}
sub Export {
    my ($self) = @_;

    $GlobalsConfigured = 1 if $self->GetModified();
    # Export does not change the status, only Import and Write
    # $Modified = 0;
    
    return {
	version =>	"2.11",
	config =>	SambaConfig->Export(),
	backend =>	SambaBackend->Export(),
	service =>	SambaService->Export(),
	trustdom =>	SambaTrustDom->Export(),
	accounts =>	SambaAccounts->Export(),
    };
}

# Create a textual summary and a list of unconfigured options
# @return summary of the current configuration
BEGIN { $TYPEINFO{Summary} = ["function", "string"] }
sub Summary {
    my ($self) = @_;
    
    # summary header
    my $summary = "";
    
    unless ($GlobalsConfigured) {
	$summary = Summary->AddLine($summary, Summary->NotConfigured());
	return $summary;
    }
    
    # summary item: configured workgroup/domain
    $summary = Summary->AddHeader($summary, __("Global Configuration:"));
    
    $summary = Summary->AddLine($summary, sprintf(__("Workgroup or Domain: %s"), SambaConfig->GlobalGetStr("workgroup", "")));

    if (SambaService->GetServiceAutoStart()) {
        # summary item: selected role for the samba server
        $summary = Summary->AddLine($summary, sprintf(__("Role: %s"), SambaRole->GetRoleName()));
    } else {
        # summary item: status of the samba service
        $summary = Summary->AddLine($summary, __("Samba server is disabled"));
    }

    # summary heading: configured shares
    $summary = Summary->AddHeader($summary, __("Share Configuration:"));

    my $shares = SambaConfig->GetShares();
    
    if (!$shares or $#$shares<0) {
        # summary item: no configured shares
        $summary = Summary->AddLine($summary, __("None"));
    } else {
	$summary = Summary->OpenList($summary);
    	foreach(@$shares) {
	    my $path = SambaConfig->ShareGetStr($_, "path", undef);
	    $summary = Summary->AddListItem($summary, $_ . ($path ? " (<i>$path</i>)" : ""));
	
	    my $comment = SambaConfig->ShareGetComment($_);
    	    $summary = Summary->AddLine($summary, $comment) if $comment;
	};
	$summary = Summary->CloseList($summary);
    }

    return $summary;
}

# Return required packages for auto-installation
# @return map of packages to be installed and to be removed
BEGIN{$TYPEINFO{AutoPackages}=["function",["map","string",["list","string"]]]}
sub AutoPackages {
    my ($self) = @_;
    return { install=> $RequiredPackages, remove => []};
}

8;

