# File:		modules/SambaLDAP.pm
# Package:	Configuration of samba-server
# Authors:	Stanislav Visnovsky <visnov@suse.cz>
#		Martin Lazar <mlazar@suse.cz>
#
# $Id$
#
# Representation of the configuration of samba-server.
# Input and output routines.

package SambaBackendLDAP;

use strict;
use Switch 'perl6';

use YaST::YCP qw(:DATA :LOGGING);
use YaPI;

textdomain "samba-server";
our %TYPEINFO;

BEGIN {
YaST::YCP::Import("URL");
YaST::YCP::Import("DNS");
YaST::YCP::Import("Ldap");
YaST::YCP::Import("Mode");
YaST::YCP::Import("Service");
YaST::YCP::Import("LdapServerAccess");

YaST::YCP::Import("SambaConfig");
YaST::YCP::Import("SambaSecrets");
}

use constant {
    TRUE => 1,
    FALSE => 0,
};


# Samba LDAP Password
my $Passwd;

# Orginaly readed password and admin dn
# if one of this change, new password have to be writed to secret.tdb
my $OrgPasswd;
my $OrgAdminDN;

# Samba Default values
my $SambaDefaultValues = {
    "ldap admin dn" => "",
    "ldap suffix" => "",
    "ldap user suffix" => "",
    "ldap group suffix" => "",
    "ldap idmap suffix" => "",
    "ldap machine suffix" => "",

    "ldap delete dn" => "No",
    "ldap filter" => "(uid=%u)",
    "ldap passwd sync" => "No",
    "ldap replication sleep" => "1000",
    "ldap ssl" => "Start_tls",
    "ldap timeout" => "5",
};

# Suse Default (Recomendet) Values
# filled in readSuseDefaultValues
my $SuseDefaultValues = {
    "ldap passwd sync" => "Yes",
};

# get SAMBA default config value
BEGIN{$TYPEINFO{GetSambaDefaultValue}=["function","string","string"]}
sub GetSambaDefaultValue {
    my ($self,$opt) = @_;
    return $SambaDefaultValues->{$opt} if exists $SambaDefaultValues->{$opt};
    y2error("Require for non-exists samba default value '$opt'");
    return undef;
}

# get SUSE default (recomendet) config value
BEGIN{$TYPEINFO{GetSuseDefaultValue}=["function","string","string"]}
sub GetSuseDefaultValue {
    my ($self,$opt) = @_;
    return $SuseDefaultValues->{$opt} if exists $SuseDefaultValues->{$opt};
    y2error("Require for non-exists suse default value '$opt'");
    return undef;
}

# get SUSE default (recomendet) config value
BEGIN{$TYPEINFO{GetSuseDefaultValues}=["function",["map", "string", "string"]]}
sub GetSuseDefaultValues {
    my ($self,$opt) = @_;
    return $SuseDefaultValues;
}

# get modified flag
BEGIN{$TYPEINFO{GetModified}=["function","boolean","string"]}
sub GetModified {
    my ($self,$name) = @_;
    my $admin_dn = SambaConfig->GlobalGetStr("ldap admin dn", "");
    # also modified if any "ldap suffix ..." modified => modified if any samba config entry modified
    return $admin_dn ne $OrgAdminDN or $Passwd ne $OrgPasswd or SambaConfig::GetModified();
}

# return true if ldapsam is first passdb backend
sub isLDAPDefault {
    my @backends = split " ", SambaConfig->GlobalGetStr("passdb backend", "sambapasswd");
    return $backends[0] =~ /^ldapsam(?::.*)?$/ ? 1 : 0;
}

# return LDAP server URL form first ldapsam backend
BEGIN{$TYPEINFO{GetPassdbServerUrl}=["function",["map","string","string"]]}
sub GetPassdbServerUrl {
    # find our host - first LDAP backend
    my @backends = split " ", SambaConfig->GlobalGetStr("passdb backend", "smbpasswd");
    foreach (@backends) {
	next unless (/^ldapsam(?::(.*))?/);
	my $url = $1 ? URL->Parse(String($1)) : { host => "localhost"};
	my $ssl = SambaConfig->GlobalGetStr("ldap ssl", "Start_tls") =~ /^(Yes|On)$/i;
#	$url->{port} = $ssl  ? 639 : 389 unless $url->{port};
	$url->{scheme} = $ssl  ? "ldaps" : "ldap" unless $url->{scheme};
	return $url;
    };
    return undef;
}

# return LDAP server URL form idmap backend
BEGIN{$TYPEINFO{GetIdmapServerUrl}=["function",["map", "string", "string"]]}
sub GetIdmapServerUrl {
    # find our host - first LDAP backend
    my $backend = SambaConfig->GlobalGetStr("idmap backend", "");
    return undef unless $backend =~ /^ldap(?::(.*))?/;
    my $url = $1 ? URL->Parse(String($1)) : { host => "localhost"};
    my $ssl = SambaConfig->GlobalGetStr("ldap ssl", "Start_tls") =~ /^(Yes|On)$/i;
#    $url->{port} = $ssl  ? 639 : 389 unless $url->{port};
    $url->{scheme} = $ssl  ? "ldaps" : "ldap" unless $url->{scheme};
    return $url;
}

# add Samba3 schema, add indicies and setup ACL on local samba server
# TODO: test it
sub installSchema {

    return if Mode::test();

    my $url = GetPassdbServerUrl();
    unless ($url) {
#	y2warning("No ldapsam backend found");
	return;
    }
    return unless DNS->IsHostLocal($url->{host});

    my $restart_server;
    my $suffix = SambaConfig->GlobalGetStr("ldap suffix", "");
    my $admin_dn = SambaConfig->GlobalGetStr("ldap admin dn", "");
	
    # add schema
    my $ret = LdapServerAccess->AddLdapSchemas(["/etc/openldap/schema/samba3.schema"], 0);
    if (not defined $ret) {
	y2error("Add LDAP Samba3 schema failed");
	return;
    } elsif ($ret) {
        $restart_server = 1;
    }

    # add indices
    foreach("sambaSID", "sambaPrimaryGroupSID", "sambaDomainName") {
	$ret = LdapServerAccess->AddIndex({attr=>$_, param=>"eq"}, $suffix, 0);
        if (not defined $ret) {
    	    y2error("Add Index '$_' failed");
	    return;
	} elsif ($ret) {
    	    $restart_server = 1;
	}
    }

    # setup ACLs
    if ($admin_dn) {
	$ret = LdapServerAccess->AddSambaACLHack($admin_dn, 0);
        if (not defined $ret) {
	    y2error("Samba ACL Hack failed");
	    return;
	} elsif ($ret) {
    	    $restart_server = 1;
	}
    }
    
    # restart server if running
    if ($restart_server && not Service->Status("ldap")) {
	unless (Service->Restart("ldap")) {
	    y2error("Error when restarting service 'ldap'");
	}
    }
}

# return true if first ldapsamb backend use the same LDAP server as specified in /etc/ldap.conf
# require LDAP->Read()
sub usingCommonLDAP {
    my $url = GetPassdbServerUrl();
    return 0 unless $url;

    if ($url->{scheme} ne "ldap") {
	y2milestone("Not using common LDAP: not ldap scheme($url->{scheme})");
	return 0;
    }
    
    (my $ldap_server = Ldap->server) =~ s/([^:]*)(?::(.*))?/$1/;
    my $ldap_port = $2 || 389;

    # TODO: betrer check equalito of hosts
    if (($ldap_server||"localhost") ne ($url->{host}||"localhost")) {
	y2milestone("Not using common LDAP: different server ($ldap_server vs $url->{host})");
	return 0;
    }

    # TODO: better check port (use default value if undef)
    if ($ldap_port ne ($url->{port}||389)) {
	y2milestone("Not using common LDAP: different port ($ldap_port vs $url->{port})");
	return 0;
    }
    
    # TODO: check ssl and tls
    
    my $suffix = SambaConfig->GlobalGetStr("ldap suffix", "");
    if ((Ldap->GetDomain()||"") ne $suffix) {
	y2milestone("Not using common LDAP: different base dn (".(Ldap->GetDomain()||"")." vs $suffix)");
	return 0;
    }

    return 1;
}

# return error message from LDAP library/server
sub getLdapError { 
    my $map = shift;
    $map = SCR->Read(".ldap.error") unless defined $map;
    if ($map) {
	my $msg = $map->{msg};
	# translators: in error message
	$msg .= "\n" . __("Additional info:") . " ". $map->{server_msg} if $map->{server_msg};
	return $msg if $msg;
    }
    # translators: unknown error message
    return __("Unknown error. Perhaps 'yast2-ldap' is not available.");
}

# try to setup users plugin, i.e. add UserPluginSamba to UserTemplate/susePlugin
# and UserPluginSambaGroup to GroupTemplate/susePlugin
# TODO: test it
sub setupUsersPlugin {
    my $res;
    return if Mode::test();
    
    # only Common (SUSE) LDAP server contains (SUSE) UsersTemplate and GroupTempalte
    return unless isLDAPDefault() and usingCommonLDAP();
    
    if ($res = Ldap->LDAPInit())	{ y2error($res); return }
    if ($res = Ldap->LDAPBind($Passwd))	{ y2error($res); return }
    if ($res = Ldap->InitSchema())	{ y2error($res); return }
    if ($res = Ldap->ReadTemplates())	{ y2error($res); return }
    
    my $modified;
		    
    my $templates = Ldap->GetTemplates();
    while(my ($dn, $content) = each %$templates) {
	my %objectclass = map {lc $_, 1} @{$content->{objectclass}};
	my %suseplugin = map {$_, 1} @{$content->{suseplugin}};
	if ($objectclass{suseusertemplate} and not $suseplugin{UsersPluginSamba}) {
	    push @{$content->{suseplugin}}, "UsersPluginSamba";
	    $modified = $content->{modified} = "edited";
	}
	if ($objectclass{susegrouptemplate} and not $suseplugin{UsersPluginSambaGroup}) {
	    push @{$content->{suseplugin}}, "UsersPluginSambaGroup";
	    $modified = $content->{modified} = "edited";
	}
    }
		    
    # store the result
    if ($modified) {
	my $map = Ldap->WriteToLDAP($templates);
	if ($map && keys %$map) {
	    y2error(getLdapError($map));
	}
    }
}

# create ldap dn
# also recursively create parent dn if not exists
sub addLdapDn { 
    my $dn = shift;
    
    return if Mode->test();
    
    # check existence
    my $res = SCR->Read(".ldap.search", {base_dn=>$dn, scope=>Integer(0), not_found_ok=>Boolean(1)});
    unless (defined $res) {
	return getLdapError();
    }
    return if @$res;	# dn already exists
    
    # create parent
    my ($attr, $value, $parent) = ($dn =~ /^([^=]*)=([^,]*)(?:,(.*))?$/);
    if ($parent) {
	my $errmsg = addLdapDn($parent);
	return $errmsg if $errmsg;
    }

    # create dn
    y2milestone("Creating dn: $dn");
    my $map;
    given($attr) {
	when ("dc") {$map = {objectclass => ["top", "dcobject"], dc => $value}}
	when ("ou") {$map = {objectclass => ["top", "organizationalunit"], ou => $value}}
	# translators: error message
	default {return __("Unknown class:")." $dn\n".__("YaST supports only dcObject (dc) and organizationalUnit (ou) classes.")}
    };
    
    if ($map && !SCR->Write(".ldap.add", {dn=>$dn}, $map)) {
	return getLdapError();
    }
    
    return undef;
}

# try bind to specified LDAP server with specified admin_dn and password
# return nil on succes, otherwise error message
sub tryBind { 
    my ($url, $admin_dn, $passwd) = @_;

    return undef if Mode->test();
    
    unless ($url->{port}) {
	my $ssl = SambaConfig->GlobalGetStr("ldap ssl", "Start_tls") =~ /^(Yes|On)$/i;
	$url->{port} = ($url->{scheme} eq "ldaps" || $ssl) ? 689 : 389;
    }
    
    $passwd = $Passwd||"" unless defined $passwd;
    
    # initialize LDAP
    my $map = {
	hostname => String($url->{host}),
	port => Integer($url->{port}),
	version => Integer(3),
    };
    my $res = SCR->Execute(".ldap", $map);
    if (not defined $res || $res) {
	return getLdapError();
    }

    # try to bind
    $admin_dn = SambaConfig->GlobalGetStr("ldap admin dn", "") unless $admin_dn;

    if (!SCR->Execute(".ldap.bind", {bind_dn=>$admin_dn, bind_pw=>$passwd})) {
	return getLdapError();
    }
    
    return undef;
}

# Try bind to specified LDAP server with specified admin_dn and password
# return nil on succes, error message on fail
BEGIN{$TYPEINFO{TryBind}=["function", "string", "string", "string", "string"]}
sub TryBind {
    my ($self, $url_s, $admin_dn, $passwd) = @_;
    my $url = URL->Parse($url_s);
    return tryBind($url, $admin_dn, $passwd);
}

# create user, group, machine and idmap suffixes on LDAP server
sub createSuffixes {
    return if Mode::test();
    my $suffix = SambaConfig->GlobalGetStr("ldap suffix", "");
    my ($mysuffix, $dn);
    my $errmsg;
    
    my $admin_dn = SambaConfig->GlobalGetStr("ldap admin dn", $SambaDefaultValues->{"ldap admin dn"}) || "";

    # create "ldap XXX suffix" on ldap server if first "passdb backend" is "ldapsam"
    if (isLDAPDefault()) {
	$errmsg = tryBind(GetPassdbServerUrl(), $admin_dn, $Passwd);
	return $errmsg if $errmsg;
        # create suffix
        foreach my $subSuffix ("machine", "user", "group") {
	    $mysuffix = SambaConfig->GlobalGetStr("ldap $subSuffix suffix", $SambaDefaultValues->{"ldap $subSuffix suffix"});
	    $dn = ($mysuffix||"") . ($suffix && $mysuffix ? "," : "") . ($suffix||"");
	    $errmsg = addLdapDn($dn);
	    return $errmsg if $errmsg;
	}
    } else {
	y2milestone("ldapsam backend isn't default => omit create suffixes");
    }

    # create "ldap idmap suffix" on ldap server if "idmap backend" is "ldap"
    my $idmap_url = GetIdmapServerUrl();
    if ($idmap_url) {
	$errmsg = tryBind(GetPassdbServerUrl(), $admin_dn, $Passwd);
	return $errmsg if $errmsg;
	$mysuffix = SambaConfig->GlobalGetStr("ldap idmap suffix", "");
	$dn = ($mysuffix||"") . ($suffix && $mysuffix ? "," : "") . ($suffix||"");
	$errmsg = addLdapDn($dn);
	return $errmsg if $errmsg;
    }
    
    return undef;
}

# Enable ldapsam
# if there is no ldap settings in config file, use LDAP Samba Default Values
# othervise do nothing
BEGIN{$TYPEINFO{PassdbEnable}=["function","boolean","string", "string"]}
sub PassdbEnable {
    my ($self, $name, $location) = @_;
    my $configured;
    while(!$configured && (my ($k,$v) = each %{$SambaDefaultValues})) {
	$configured = 1 if SambaConfig->GlobalGetStr($k, undef);
    }
    
    unless($configured) {
	SambaConfig->GlobalSetMap($SambaDefaultValues);
	y2milestone("enabling ldap settings (use suse default values)");
    } else {
	y2milestone("ldap settings already enabled (do not use suse default values)");
    }

    return TRUE;
}

# Disable ldapsam: actualy do nothing.
BEGIN{$TYPEINFO{PassdbDisable}=["function","boolean","string"]}
sub PassdbDisable {
    my ($self, $name) = @_;
    return TRUE;
}

# Set "add machine script" to script which add machine to LDAP server
BEGIN{$TYPEINFO{UpdateScripts}=["function","boolean","string","string"]}
sub UpdateScripts {
    my ($self,$name,$location) = @_;
    SambaConfig->GlobalSetMap({
	"add machine script" => "/sbin/yast /usr/share/YaST2/data/add_machine.ycp %m\$",
    });
    return TRUE;
}

# read secret password
sub readPasswd {
    $OrgAdminDN = SambaConfig->GlobalGetStr("ldap admin dn", "");
    $Passwd = $OrgPasswd = Mode::test() ? "secret" : SambaSecrets->GetLDAPBindPw($OrgAdminDN);
}

# read SUSE default values
sub readSuseDefaultValues {

    # try to lookup user/group suffix
    my (@user, @group);
    if (!Mode::test()) {
	my $errmsg = Ldap->LDAPInit();
	if ($errmsg) { y2warning("Can't initialize LDAP: $errmsg"); }
	Ldap->ReadConfigModules();
	my $conf = Ldap->GetConfigModules();
	while(my ($dn, $c) = each %$conf) {
    	    my %classes = map {lc $_, 1} @{$c->{objectclass}};
	    @user = split ",", $c->{susedefaultbase}[0] if $classes{"suseuserconfiguration"};
	    @group = split ",", $c->{susedefaultbase}[0] if $classes{"susegroupconfiguration"};
	}
	y2milestone("SuseDefaultBase: user=".join(",",@user)." group=",join(",",@group));
    }
    
    # remove common suffix
    my @suffix = split ",", Ldap->GetDomain();
    @user = () if @user < @suffix;
    for(my $i=0; @user && $i<@suffix; $i++) {
        @user = () if $user[-$i-1] ne $suffix[-$i-1]
    }
    @user = @user[0..(@user-@suffix-1)] if @user;
    @group = () if @group < @suffix;
    for(my $i=0; @group && $i<@suffix; $i++) {
	@group = () if $group[-$i-1] ne $suffix[-$i-1]
    }
    @group = @group[0..(@group-@suffix-1)] if @group;
    (my $p = $user[0] || $group[0] || "ou") =~ s/=.*//;
    
    # store SUSE default values
    $SuseDefaultValues = { %{$SambaDefaultValues}, %{$SuseDefaultValues},
	"ldap user suffix" => join(",", @user) || "$p=Users",
	"ldap group suffix" => join(",", @group) || "$p=Groups",
	"ldap suffix" => Ldap->GetDomain(),
	"ldap machine suffix" => "$p=Machines",
	"ldap idmap suffix" => "$p=Idmap",
	"ldap admin dn" => Ldap->bind_dn,
	"ldap ssl" => Ldap->ldap_tls ? "Start_tls" : "No",
    };
    
    # log suse defaults (for debuging)
    my $s;
    for(keys %$SuseDefaultValues) {
	(my $k = $_) =~ s/^ldap //;
	$k =~ s/ /_/g;
	$s.= "$k=$SuseDefaultValues->{$_} ";
    }
    y2milestone("LDAPSuseDefaults: $s");
}

# write administration password
sub writePasswd {
    my $admin_dn = SambaConfig->GlobalGetStr("ldap admin dn", "");

    # return if no change
    return if $admin_dn eq ($OrgAdminDN||"") and ($Passwd||"") eq ($OrgPasswd||"");
    
    # write the smb.conf now, otherwise secrets.tdb would contain a wrong entry (#40866)
    return "Cannot write samba configuration." unless SambaConfig->Write();
    
    # change password
    SambaSecrets->WriteLDAPBindPw($Passwd) or return;

    $OrgPasswd = $Passwd;
    $OrgAdminDN = $admin_dn;
}

# Writa all LDAP-related settings.
BEGIN{$TYPEINFO{Write}=["function","boolean","string","boolean"]}
sub Write {
    my ($self, $name, $write_only) = @_;

    # write password only if changed password or admin_dn
    writePasswd();
    
    # install schema only if an backend LDAP server is local
    installSchema();

    # create suffixes only if the default backend is a ldapsam
    # idmap suffix is created always (indeed unless already exists)
    # bind with smb.conf "ldap admin dn" and secret.tdb LDAP_BIND_PW password (via SCR)
    if (!$write_only) {
	my $errmsg = createSuffixes();
	if ($errmsg) {
	    y2error("Create suffixes: $errmsg");
	}
    }
    
    # setup UsersPlugin only if the default backend is the SUSE's common LDAP server
    # bind with common dn (== "ldap admin dn") and secret.tdb LDAP_BIND_PW password (via LDAP module)
    setupUsersPlugin();

    # create buildin groups and group appings
#    createBuildinGroups();

# TODO: updateScript - check if there is default SUSE script
# if needet scripts - if not suse (tdbsam or ldapsam) defualt - warn and ask for overwrite
#                   - if suse default - set ldap suse default
# if not needet - if suse default - remove
#               - if not suse default - leave

    return TRUE;
}



# Read LDAP-related settings.
BEGIN{$TYPEINFO{Read}=["function","boolean","string"]}
sub Read {
    my ($self,$name) = @_;
    
    Ldap->Read() unless Mode::test();
    
    readSuseDefaultValues();
    
    readPasswd();
    return TRUE;
}


# Set LDAP admin password.
# @param password	the new password
BEGIN{$TYPEINFO{SetAdminPassword}=["function","void","string"]}
sub SetAdminPassword {
    my ($self, $password) = @_;
    $Passwd = $password;
}

# Return the LDAP Administration Password
BEGIN{$TYPEINFO{GetAdminPassword}=["function","string"]}
sub GetAdminPassword {
    my ($self) = @_;
    return $Passwd || "";
}

# Test LDAP connection to the server using ldapsearch.
# @param server	the LDAP server
# @param search_base	base to be tested
# @return boolean	true on success
BEGIN{$TYPEINFO{TestLDAP}=["function","boolean","string","string"]}
sub TestLDAP {
    my ($self, $server, $search_base) = @_;

    my $result = SCR->Execute(".target.bash_output", "ldapsearch -x -H '$server' -b '$search_base'");

    if ($result->{exit}) {
	# translators: warning message, %s is LDAP server name/IP
	Report->Warning(sprintf(__("It seems like there is no functional\nLDAP server at %s.\n"), $server));
	return 0;
    }
    
    return 1;
}

# Export all LDAP setting
# TODO: not implemented yet (export password)
BEGIN{$TYPEINFO{Export}=["function","any","string"]}
sub Export {
    my ($self,$name) = @_;
    return undef;
}

# Import all LDAP setting
# TODO: not implemented yet
BEGIN{$TYPEINFO{Import}=["function","void","string","any"]}
sub Import {
    my ($self, $name,$any) = @_;
}

8;
