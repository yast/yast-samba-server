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
use Switch 'Perl6';

use Data::Dumper;

use YaST::YCP qw(:DATA :LOGGING);
use YaPI;

textdomain "samba-server";
our %TYPEINFO;

BEGIN {
YaST::YCP::Import("SambaConfig");
YaST::YCP::Import("SambaSecrets");

YaST::YCP::Import("URL");
YaST::YCP::Import("DNS");
YaST::YCP::Import("Ldap");
YaST::YCP::Import("Service");
YaST::YCP::Import("LdapServerAccess");
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



BEGIN{$TYPEINFO{GetModified}=["function","boolean","string"]}
sub GetModified {
    my ($self,$name) = @_;
    my $admin_dn = SambaConfig->GlobalGetStr("ldap admin dn", "");
    return $admin_dn ne $OrgAdminDN or $Passwd ne $OrgPasswd;
}


sub isLDAPDefault {
    my @backends = split " ", SambaConfig->GlobalGetStr("passdb backend", "sambapasswd");
    return $backends[0] =~ /^ldapsam(?::.*)?$/ ? 1 : 0;
}

sub getServerUrl {
    # find our host - first LDAP backend
    my @backends = split " ", SambaConfig->GlobalGetStr("passdb backend", "smbpasswd");
    my $url;
    foreach (@backends) {
	next unless (/^ldapsam(?::(.*))?/);
	return URL->Parse(String($1)) if $1;
	my $ssl = SambaConfig->GlobalGetStr("ldap ssl", "Start_tls") =~ /^(Yes|On)$/i;
        return {
	    host	=> SambaConfig->GlobalGetStr("ldap server", "localhost"), 
	    port	=> SambaConfig->GlobalGetInteger("ldap port", $ssl  ? 639 : 389),
	    scheme	=> $ssl ? "ldaps" : "ldap",
	}
    };
    return undef;
}

# add Samba3 schema, add indicies and setup ACL on local samba server
# TODO: test it
sub installSchema {

    my $url = getServerUrl();
    unless ($url) {
	y2error("No ldapsam backend found");
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


# require LDAP->Read()
sub usingCommonLDAP {
    my $url = getServerUrl();
    return 0 unless $url;
    
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

sub getLdapError { 
    my $map = shift;
    $map = SCR->Read(".ldap.error") unless $map;
    return "Unknown error ('yast2-ldap' is not available?)" unless $map;
    return $map->{msg} . ($map->{server_msg} ? "\n$map->{server_msg}" : "");
}

# try to setup users plugin
sub setupUsersPlugin {
    my $res;
    
    # only Common (SUSE) LDAP server contains (SUSE) UsersPlugin
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

sub getLdapEntry { 
    return SCR->Read(".ldap.search", {base_dn=>$_[0], scope=>Integer(0), not_found_ok=>Boolean(1)});
}

sub addLdapDn { 
    my $dn = shift;
    
    # check existence
    my $res = getLdapEntry($dn);
    unless (defined $res) {
	y2error(getLdapError());
	return 1;
    }
    return 0 if @$res;
    
    # create parent
    my ($attr, $value, $parent) = ($dn =~ /^([^=]*)=([^,]*)(?:,(.*))?$/);
    if ($parent) {
	return if addLdapDn($parent);
    }

    # create dn
    y2milestone("Creating dn: $dn");
    my $map;
    given($attr) {
	when ("dc") {$map = {objectclass => ["top", "dcobject"], dc => $value}}
	when ("ou") {$map = {objectclass => ["top", "organizationalunit"], ou => $value}}
	default {y2warning("Unknown dn: $dn")}
    };
    
    if ($map && SCR->Write(".ldap.add", {dn=>$dn}, $map)) {
	y2error(getLdapError());
    }
}

sub tryBind { 
    my ($url, $passwd) = @_;
    
    # initialize LDAP
    my $map = {
	hostname => String($url->{host}),
	port => Integer($url->{port}),
	version => Integer(3),
    };
    my $res = SCR->Execute(".ldap", $map);
    if (not defined $res || $res) {
	y2error($res?getLdapError():"bind: unknown error (is yast2-ldap intalled?)");
	return 0;
    }

    # try to bind
    my $admin_dn = SambaConfig->GlobalGetStr("ldap admin dn", "");
    if (SCR->Execute(".ldap.bind", {bind_dn=>$admin_dn, bind_pw=>$passwd})) {
	y2error(getLdapError());
	return 0;
    }
    return 1;
}

sub createSuffixes {
    my $suffix = SambaConfig->GlobalGetStr("ldap suffix", "");

    # create "ldap XXX suffix" on ldap server if first "passdb backend" is "ldapsam"
    if (isLDAPDefault()) {
	tryBind(getServerUrl(), $Passwd) or return;

	# create suffix
	foreach my $subSuffix ("machine", "user", "group") {
	    my $mysuffix = SambaConfig->GlobalGetStr("ldap $subSuffix suffix", "");
	    my $dn = ($mysuffix||"") . ($suffix && $mysuffix ? "," : "") . ($suffix||"");
	    addLdapDn($dn) or return;
	}
    }

    # create "ldap idmap suffix" on ldap server if "idmap backend" is "ldap"
    my $idmap_backend = SambaConfig->GlobalGetStr("idmap backend", "");
    if ($idmap_backend =~ /^ldap(?::(.*))?$/) {
	tryBind(URL->Parse($1), $Passwd) or return;
	my $mysuffix = SambaConfig->GlobalGetStr("ldap idmap suffix", "");
	my $dn = ($mysuffix||"") . ($suffix && $mysuffix ? "," : "") . ($suffix||"");
	addLdapDn($dn) or return;
    }
}

BEGIN{$TYPEINFO{Enable}=["function","boolean","string", "string"]}
sub Enable {
    my ($self, $name, $location) = @_;
    
    my $user_suffix = "ou=People";
    my $group_suffix = "ou=Groups";
    
    # try to lookup user/group suffix
    if (Ldap->LDAPInit()) {
	Ldap->ReadConfigModules();
	my $conf = Ldap->GetConfigModules();
	while(my ($dn, $c) = each %$conf) {
    	    my %classes = map {lc $_, 1} @{$c->{objectclass}};
	    $user_suffix  = $c->{susedefaultbase}[0] if $classes{suseuserconfiguration};
	    $group_suffix = $c->{susedefaultbase}[0] if $classes{susegroupconfiguration};
	}
    }
    
    my $global = {
#	"ldap server" => $server,
#	"ldap port" => ($port && $port == 368) ? undef : $port,
#	"ldap ssl" => $start_ssl,
	"ldap admin dn" => Ldap->bind_dn,
	"ldap suffix" => Ldap->GetDomain(),
	"ldap user suffix" => $user_suffix,
	"ldap group suffix" => $group_suffix,
	"ldap machine suffix" => "ou=Computers",
	"ldap idmap suffix" => "ou=Idmap",
	"lasp passwd sync" => "Yes",
	"idmap backend" => "ldap" . ($location ? ":$location" : ""),
    };
    SambaConfig->GlobalSetMap($global);
    
    return TRUE;
}

BEGIN{$TYPEINFO{Disable}=["function","boolean","string"]}
sub Disable {
    my ($self, $name) = @_;
    my $global = {
	"ldap server" => undef,
	"ldap port" => undef,
	"ldap admin dn" => undef,
	"ldap suffix" => undef,
	"ldap ssl" => undef,
	"ldap user suffix" => undef,
	"ldap group suffix" => undef,
	"ldap machine suffix" => undef,
	"ldap idmap suffix" => undef,
	"lasp passwd sync" => undef,
	"idmap backend" => undef,
    };
    SambaConfig->GlobalSetMap($global);
    return TRUE;
}

BEGIN{$TYPEINFO{UpdateScripts}=["function","boolean","string","string"]}
sub UpdateScripts {
    my ($self,$name,$location) = @_;
    SambaConfig->GlobalSetMap({
	"add machine script" => "/sbin/yast /usr/share/YaST2/data/add_machine.ycp %m\$",
    });
    return TRUE;
}

# get secret password
sub readPasswd {
    $OrgAdminDN = SambaConfig->GlobalGetStr("ldap admin dn", "");
    $Passwd = $OrgPasswd = SambaSecrets->GetLDAPBindPw($OrgAdminDN);
}


sub writePasswd {
    my $admin_dn = SambaConfig->GlobalGetStr("ldap admin dn", "");

    # return if no change
    return if $admin_dn eq $OrgAdminDN and $Passwd eq $OrgPasswd;
    
    # write the smb.conf now, otherwise secrets.tdb would contain a wrong entry (#40866)
    return "Cannot write samba configuration." unless SambaConfig->Write();
    
    # change password
    SambaSecret->WriteLDAPBindPw($Passwd) or return;

    $OrgPasswd = $Passwd;
    $OrgAdminDN = $admin_dn;
}


BEGIN{$TYPEINFO{Write}=["function","boolean","string","boolean"]}
sub Write {
    my ($self, $name,$write_only) = @_;

    # write password only if changed password or admin_dn
    writePasswd();
    
    # install schema only if an backend LDAP server is local
    installSchema();

    # create suffixes only if the default backend is a LDAP server
    # idmap suffix is created always (indeed unless already exists)
    # bind with smb.conf "ldap admin dn" and secret.tdb LDAP_BIND_PW password (via SCR)
    createSuffixes();
    
    # setup UsersPlugin only if the default backend is the common LDAP server
    # bind with common dn (eq "ldap admin dn") and secret.tdb LDAP_BIND_PW password (via LDAP module)
    setupUsersPlugin();

    # create buildin groups and group appings
#    createBuildinGroups();

    return TRUE;
}



# Read LDAP-related settings.
BEGIN{$TYPEINFO{Read}=["function","boolean","string"]}
sub Read {
    my ($self,$name) = @_;
    
    Ldap->Read();
    
    readPasswd();
    return TRUE;
}




# Setup LDAP admin password using smbpasswd -w. Switches backend to LDAP first.
# @param password	the new password
# @return string 	nil for success, error message otherwise
BEGIN{$TYPEINFO{SetAdminPassword}=["function","string","string"]}
sub SetAdminPassword {
    my ($self, $password) = @_;

    my $url = getServerUrl();
    return unless $url; # no Server found
    
    my $res = tryBind($url, $password);
    return unless $res; # bind error
    
    $Passwd = $password;
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

BEGIN{$TYPEINFO{Export}=["function","any","string"]}
sub Export {
    my ($self,$name) = @_;
    return undef;
}

BEGIN{$TYPEINFO{Import}=["function","void","string","any"]}
sub Import {
    my ($self, $name,$any) = @_;
}



8;
