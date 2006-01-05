# File:		modules/SambaRole.pm
# Package:	Configuration of samba-server
# Authors:	Stanislav Visnovsky <visnov@suse.cz>
#		Martin Lazar <mlazar@suse.cz>
#
# $Id$
#
# Representation of the configuration of samba-server.
# Input and output routines.


package SambaRole;

use strict;
use Data::Dumper;

use YaST::YCP qw(:DATA :LOGGING);
use YaPI;

textdomain "samba-server";
our %TYPEINFO;

BEGIN {
YaST::YCP::Import("SambaConfig");
YaST::YCP::Import("SambaBackend");
}

# mapping of name to role (for summary)
my %RoleToName = (
# translators: server role name
    STANDALONE => __("File and Printer Sharing"),
# translators: server role name
    BDC => __("Backup Domain Controller"),
# translators: server role name
    PDC => __("Primary Domain Controller"),
# translators: server role name
    MEMBER => __("Domain Member Server")
);

# default settings for [netlogon]
my $default_netlogon = {
    "comment" =>	"Network Logon Service",
    "path" =>		"/var/lib/samba/netlogon",
    "write list" =>	"root",
#    "guest ok" =>	"Yes",
#    "browseable" =>	"No",
};

# default settings for [profiles]
my $default_profiles = {
    "comment" =>	"Profiles",
    "path" =>		"/var/lib/samba/profiles",
    "read only" =>	"No",
    "create mask" =>	"0600",
    "directory mask" =>	"0700",
};

sub setDomainLogons {
    my ($on) = shift;
    SambaConfig->GlobalSetTruth("domain logons", $on);
    SambaConfig->ShareAdjust("netlogon", $on);
    SambaConfig->ShareUpdateMap("netlogon", $default_netlogon) if $on;
}

#sub setProfiles {
#    my ($on) = shift;
#    SambaConfig->ShareAdjust("profiles", $on);
#    SambaConfig->ShareUpdateMap("profiles", $default_profiles) if $on;
#}

# set Local Master Browser
sub setLMB {
    my ($on) = shift;
    
    # nmbd will participate in elections for local master browser
    SambaConfig->GlobalSetTruth("local master", $on); # default = Yes

    # nmbd will force an election on startup, and it will have a slight advantage in winning the election
    SambaConfig->GlobalSetTruth("preferred master", $on); # default = Auto (Yes if LocalMaster and DomainMaster)

    if ($on) {
	# ensure high os level for LocalMaster
	my $oslevel = SambaConfig->GlobalGetInteger("os level", 20);
	SambaConfig->GlobalSetInteger("os level", 65) if $oslevel < 65;
    } else {
	SambaConfig->GlobalSetInteger("os level", undef); # default 20
    }
}


# (for BDC) Retrieve the domain SID for DOMAIN from PDC and store it in secret.tdb
sub getSID {
    my $domain = SambaConfig->GlobalGetStr("workgroup", "");
    my $name = SambaConfig->GlobalGetStr("netbios name", undef);
    my $cmd = "LANG=C net rpc getsid -w '$domain' -s /dev/null" . ($name?" -n '$name'":"");
    my $result = SCR->Execute(".target.bash_output", $cmd);
    y2debug("$cmd => ".Dumper($result));
    if (!$result || !exists $result->{stdout} || $result->{exit}) {
	y2error("Error retrieving SID for domain '$domain': ".Dumper($cmd,$result));
	return undef;
    }
    unless ($result->{stdout} =~ /^Storing SID (\S*) for Domain$/) {
	y2error("Unexpected output: ".Dumper($cmd, $result)); 
	return undef;
    }
    return $1;
}

# (for PDC) Synchronize domain SID in LDAP and in secret.tdb (generete new one if doesn't exists yet)
sub getLocalSID {
    my $name = SambaConfig->GlobalGetStr("netbios name", undef);
    my $cmd = "LANG=C net getlocalsid -s /dev/null" . ($name?" -n '$name'":"");
    my $result = SCR->Execute(".target.bash_output", $cmd);
    y2debug("$cmd => ".Dumper($result));
    if (!$result || !exists $result->{stdout} || $result->{exit}) {
	y2error("Error retrieving local SID: ".Dumper($cmd, $result));
	return undef;
    }
    unless ($result->{stdout} =~ /^SID for domain .* is: (\S*)/) {
	y2error("Unexpected output: ".Dumper($cmd, $result));
	return undef;
    }

    return $1;
}


# Configure as PDC.
BEGIN{$TYPEINFO{SetAsPDC} = ["function", "void"]}
sub SetAsPDC {
    my ($self) = @_;
    y2milestone("SetAsPDC()");

    SambaConfig->GlobalSetStr("security", "user");
    setDomainLogons(1);
    
    SambaConfig->GlobalSetTruth("domain master", 1);
    setLMB(1);
    
    SambaConfig->GlobalSetTruth("encrypt passwords", undef);	# default = Yes
    SambaConfig->GlobalSetStr("password server", undef);
    
    SambaBackend->UpdateScripts();
    
    getLocalSID();
}

# Configure as BDC.
BEGIN{$TYPEINFO{SetAsBDC} = ["function", "void"]}
sub SetAsBDC() {
    my ($self) = @_;
    y2milestone("SetAsBDC()");

    SambaConfig->GlobalSetStr("security", "user");
    setDomainLogons(1);

    SambaConfig->GlobalSetTruth("domain master", 0);
    setLMB(undef);
    
    SambaConfig->GlobalSetTruth("encrypt passwords", undef);	# default = Yes
    SambaConfig->GlobalSetStr("password server", undef);

    SambaBackend->UpdateScripts();
    
    getSID();
}

# Configure as a standalone server (no domain logons).
# @return boolean	true on success
BEGIN{$TYPEINFO{SetAsStandalone} = ["function", "void"]}
sub SetAsStandalone() {
    my ($self) = @_;
    y2milestone("SetAsStandalone()");

    SambaConfig->GlobalSetStr("security", "user");
    setDomainLogons(0);

    SambaConfig->GlobalSetTruth("domain master", 0);
    setLMB(undef);
    
    SambaConfig->GlobalSetTruth("encrypt passwords", undef);	# default = Yes
    SambaConfig->GlobalSetStr("password server", undef);

    SambaBackend->UpdateScripts();
}

# Configure as a member
# @return boolean	true on success
BEGIN{$TYPEINFO{SetAsMember} = ["function", "void"]}
sub SetAsMember() {
    my ($self) = @_;
    y2milestone("SetAsMember()");
    
    SambaConfig->GlobalSetStr("security", "domain");
    setDomainLogons(0);

    SambaConfig->GlobalSetTruth("domain master", 0);
    setLMB(undef);
    
    SambaConfig->GlobalSetTruth("encrypt passwords", undef);	# default = Yes
    SambaConfig->GlobalSetStr("password server", "*");
    
    SambaBackend->RemoveScripts();
}

# Configure for a given role. Calls @ref SetAsPDC, @ref SetAsBDC and @ref SetAsStandalone
# @param  new_role	the new role
# @return integer	error code (zero on sucess, 22 (EINVAL) on unknown role)
BEGIN{$TYPEINFO{"SetRole"} = ["function", "void", "string"]}
sub SetRole {
    my ($self, $role) = @_;
    if (uc $role eq "PDC") {return SetAsPDC() }
    elsif (uc $role eq "BDC") {return SetAsBDC() }
    elsif (uc $role eq "STANDALONE") {return SetAsStandalone() }
    elsif (uc $role eq "MEMBER") {return SetAsMember() }
    y2error("Unknown role: ".Dumper($role));
}


# Find out the role of a server using the read settings
# @return string	the role it appears to be
BEGIN{ $TYPEINFO{GetRole} = ["function", "string"] }
sub GetRole {
    my ($self) = @_;
    
    my $security = uc SambaConfig->GlobalGetStr("security", "USER");
    my $domain_logons = SambaConfig->GlobalGetTruth("domain logons", 0);
    my $domain_master = SambaConfig->GlobalGetStr("domain master", "Auto");

    if ($security eq "SHARE") { return "STANDALONE" }
    elsif ($security eq "SERVER") { return "MEMBER" }
    elsif ($security eq "DOMAIN") { return $domain_logons ? "BDC" : "MEMBER" }
    elsif ($security eq "ADS") { return $domain_logons ? "PDC" : "MEMBER" }
    elsif ($security eq "USER")	{ 
	return "STANDALONE" unless $domain_logons;
	return "PDC" if $domain_master =~ /^(1|Yes|True|Auto)$/i;
	return "BDC";
    }
    return "STANDALONE";
}

BEGIN{$TYPEINFO{GetRoleName} = ["function", "string"]}
sub GetRoleName {
    my ($self) = @_;
    return $RoleToName{$self->GetRole()};
}

8;
