# File:		modules/SambaServer.ycp
# Package:	Configuration of samba-server
# Summary:	Data for configuration of samba-server, input and output functions.
# Authors:	Stanislav Visnovsky <visnov@suse.cz>
#		Martin Lazar <mlazar@suse.cz>
#
# $Id$
#
# Representation of the configuration of samba-server.
# Input and output routines.


package SambaServer;

use strict;
use Switch 'Perl6';
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
#HELPME: YaST::YCP::Import("SuSEFirewall");
YaST::YCP::Import("PackageSystem");

YaST::YCP::Import("SambaRole");
YaST::YCP::Import("SambaLDAP");
YaST::YCP::Import("SambaConfig");
YaST::YCP::Import("SambaService");
YaST::YCP::Import("SambaBackend");
YaST::YCP::Import("SambaSecrets");
YaST::YCP::Import("SambaNmbLookup");
}

use constant {
#HELPME:    DONE_ONCE_FILE => Directory->vardir . "/samba_server_done_once"
    DONE_ONCE_FILE => "/var/lib/YaST2" . "/samba_server_done_once"
};


my $Modified;

# list of required packages
my $RequiredPackages = ["samba", "samba-client"];

# Abort function
# return boolean return true if abort
#my $AbortFunction = undef;

my $GlobalsConfigured = 0;


#sub ServerReallyAbort {
#    my ($self) = @_;
#    return !GetModified() || Popup->ReallyAbort(Boolean(1));
#}

# Abort function
#sub Abort {
#    my ($self) = @_;
#    return defined $AbortFunction ? &$AbortFunction() : 0;
#}

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
	|| SambaTrustDom->GetModified();
};

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
    Progress->New($caption, " ", 5, [
	    # translators: progress stage 1/5
	    __("Read global Samba settings"),
	    # translators: progress stage 4/5
	    __("Read the LDAP settings"),
	    # translators: progress stage 5/5
	    __("Read the firewall settings")
	], [
	    # translators: progress step 1/5
	    __("Reading global Samba settings..."),
	    # translators: progress step 4/5
	    __("Reading the LDAP settings..."),
	    # translators: progress step 5/5
	    __("Reading the firewall settings..."),
	    # translators: progress finished
	    __("Finished")
	],
	""
    );

    # read global settings
    Progress->NextStage();
    
    # check installed packages
    unless (Mode->test()) {
	PackageSystem->CheckAndInstallPackagesInteractive($RequiredPackages) or return 0;
    }

    SambaConfig->Read();
    SambaSecrets->Read();
    SambaService->Read();

    $GlobalsConfigured = $self->Configured();

    y2milestone("Service:". (SambaService->GetServiceAutoStart() ? "Enabled" : "Disabled"));
    y2milestone("Role:". SambaRole->GetRoleName());

    # start nmbstatus in background
    SambaNmbLookup->Start() unless Mode->test();

    # read LDAP settings
    Progress->NextStage();
    SambaBackend->Read();
#    if(Abort()) return false;
    
    # read firewall setting
    Progress->NextStage();
# HELPME:    SuSEFirewall->Read();
#    if(Abort()) return false;

    # Read finished
    Progress->NextStage();
    $Modified = 0;
    
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
	    _("Write the settings"),
	    # translators: write progress stage
	    _("Run SuSEconfig"),
	    # translators: write progress stage
	    ( !SambaService->GetServiceAutoStart() ? _("Disable Samba services") 
	    # translators: write progress stage
		: _("Enable Samba services") ),
	    # translators: write progress stage
	    _("Save firewall settings")
	], [
	    # translators: write progress step
	    _("Writing the settings..."),
	    # translators: write progress step
	    _("Running SuSEconfig..."),
	    # translators: write progress step
	    ! SambaService->GetServiceAutoStart() ? _("Disabling Samba services...") 
	    # translators: write progress step
		: _("Enabling Samba services..."),
	    # translators: write progress step
	    _("Saving firewall settings..."),
	    # translators: write progress step
	    _("Finished")
	],
	""
    );

    # if nothing to write, quit (but show at least the progress bar :-)
    Progress->NextStage();
    return 1 unless $self->GetModified();

    # check, if we need samba-pdb package
    my %backends = map {/:/;$`||$_,1} split " ", SambaConfig->GlobalGetStr("passdb backend", "");
    if($backends{mysql}) {
	PackageSystem->CheckAndInstallPackagesInteractive(["samba-pdb"]) or return 0;
    }

    # write settings
#    if (Abort()) return false;

    if (SambaConfig->Write($write_only)) {
    	Report->Error(__("Cannot write settings to /etc/samba/smb.conf."));
	return 0;
    }
    SCR->Execute(".target.bash", "touch " . DONE_ONCE_FILE);
    
    # run SuSEconfig for samba
#    if(Abort()) return false;
#    Progress->NextStage() unless $noprogress;

    SambaBackend->Write();    
    SambaService->Write();
    SambaTrustDom->Write();

#    if(Abort()) return false;

    # save firewall settings
#HELPME    SuSEFirewall->Write();
#    if(Abort()) return false;
    
    # progress finished
#    Progress->NextStage();

#    if(Abort()) return false;

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

    if ($settings and $settings->{"config"} and keys %{$settings->{"config"}}) {
	$GlobalsConfigured = 1;
    } else {
	$GlobalsConfigured = 0;
    }
    $Modified = 0;
	
    y2debug("Importing: ", Dumper($settings));

    SambaConfig->Import($settings->{"config"});
    SambaService->Import($settings->{"service"});
    SambaTrustDom->Import($settings->{"trustdom"});
    SambaBackend->Import($settings->{"backend"});
}

# Dump the samba-server settings to a single map
# (For use by autoinstallation.)
# @return map Dumped settings (later acceptable by Import ())
BEGIN{ $TYPEINFO{Export} = ["function", "any"]}
sub Export {
    my ($self) = @_;

    $GlobalsConfigured = 1 if $self->GetModified();
    $Modified = 0;
    
    return {
	version =>	"2.10",
	config =>	SambaConfig->Export(),
	backend =>	SambaBackend->Export(),
	service =>	SambaService->Export(),
	trustdom =>	SambaTrustDom->Export(),
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
    $summary = Summary->AddHeader($summary, __("Global Configuration"));
    
    $summary = Summary->AddLine($summary, sprintf(__("Workgroup or Domain: %s"), SambaConfig->GlobalGetStr("workgroup", "")));

    if (SambaService->GetServiceAutoStart()) {
        # summary item: selected role for the samba server
        $summary = Summary->AddLine($summary, sprintf(__("Role: %s"), SambaRole->GetRoleName()));
    } else {
        # summary item: status of the samba service
        $summary = Summary->AddLine($summary, __("Samba server is <i>disabled</i>"));
    }

    # summary heading: configured shares
    $summary = Summary->AddHeader($summary, __("Share Configuration"));

    my $shares = SambaConfig->GetShares();
    
    if (!$shares or $#$shares<0) {
        # summary item: no configured shares
        $summary = Summary->AddLine($summary, __("none"));
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

