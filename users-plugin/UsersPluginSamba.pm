#! /usr/bin/perl -w
#
# Samba plugin module
# This is the API part of UsersPluginSamba plugin 
#
# The following user parameters are handled inside this module
#

package UsersPluginSamba;

use strict;

use ycp;
use YaST::YCP;
our %TYPEINFO;

use Locale::gettext;
use POSIX ();

## FIXME
use Data::Dumper;
use Crypt::SmbHash;

YaST::YCP::Import ("SCR");

POSIX::setlocale(LC_MESSAGES, "");
textdomain("users");	# TODO own textdomain for new plugins

##--------------------------------------
##--------------------- global imports

YaST::YCP::Import ("SCR");

##--------------------------------------

# All functions have 2 "any" parameters: this will probably mean
# 1st: configuration map (hash) - e.g. saying if we work with user or group
# 2nd: data map (hash) of user (group) to work with

# in 'config' map there is a info of this type:
# "what"		=> "user" / "group"
# "modified"		=> "added"/"edited"/"deleted"
# "enabled"		=> 1/ key not present
# "disabled"		=> 1/ key not present

# 'data' map contains the atrtributes of the user. It could also contain
# some keys, which Users module uses internaly (like 'groupname' for name of
# user's default group). Just ignore these values
# default object classes of LDAP users

    
##------------------------------------

# TODO check for Mode::config???
 

# return names of provided functions
BEGIN { $TYPEINFO{Interface} = ["function", ["list", "string"], "any", "any"];}
sub Interface {

    my $self		= shift;
    my @interface 	= (
	    "GUIClient",
	    "Check",
	    "Name",
	    "Summary",
	    "Restriction",
	    "Add",
            "AddBefore",
	    "Edit",
	    "EditBefore",
	    "Interface",
            "PluginPresent",
	    "Disable",
            "InternalAttributes"
    );
    return \@interface;
}

# return plugin name, used for GUI (translated)
BEGIN { $TYPEINFO{Name} = ["function", "string", "any", "any"];}
sub Name {

    my $self		= shift;
    # plugin name
    return _("Samba Attributes");
}

# return plugin summary
BEGIN { $TYPEINFO{Summary} = ["function", "string", "any", "any"];}
sub Summary {

    my $self	= shift;
    my $what	= "user";
    # summary
    my $ret 	= _("Manage Samba Account of LDAP user");

    if (defined $_[0]->{"what"} && $_[0]->{"what"} eq "group") {
	$ret 	= _("Edit remaining attributes of LDAP group");
    }
    return $ret;
}


# return name of YCP client defining YCP GUI
BEGIN { $TYPEINFO{GUIClient} = ["function", "string", "any", "any"];}
sub GUIClient {

    my $self	= shift;
    return "users_plugin_samba";
}

##------------------------------------
# Type of users and groups this plugin is restricted to.
# If this function doesn't exist, plugin is applied for all user (group) types.
BEGIN { $TYPEINFO{Restriction} = ["function",
    ["map", "string", "any"], "any", "any"];}
sub Restriction {

    my $self	= shift;
    # this plugin applies only for LDAP users and groups
    return { "ldap"	=> 1 };
}

# checks the current data map of user/group (2nd parameter) and returns
# true if given user (group) has our plugin
BEGIN { $TYPEINFO{PluginPresent} = ["function", "boolean", "any", "any"];}
sub PluginPresent {
    my $self	= shift;
    my $config    = shift;
    my $data    = shift;

    if ( grep /^sambasamaccount$/i, @{$data->{'objectclass'}} ) {
        y2milestone( "SambaPlugin: Plugin Present");
        return 1;
    } else {
        y2milestone( "SambaPlugin: Plugin not Present");
        return 0;
    }
}



##------------------------------------
# check if all required atributes of LDAP entry are present
# parameter is (whole) map of entry (user/group)
# return error message
BEGIN { $TYPEINFO{Check} = ["function",
    "string",
    "any",
    "any"];
}
sub Check {

    my $self	= shift;
    my $config	= $_[0];
    my $data	= $_[1];
    
    return "";
}

# this will be called at the beggining of Users::Edit
BEGIN { $TYPEINFO{Disable} = ["function",
    ["map", "string", "any"],
    "any", "any"];
}
sub Disable {

    my $self	= shift;
    my $config	= $_[0];
    my $data	= $_[1];

    y2internal ("Disable Samba called");
    return $data;
}


# Could be called multiple times for one user/group!
BEGIN { $TYPEINFO{AddBefore} = ["function", ["map", "string", "any"], "any", "any"];}
sub AddBefore {
    my $self	= shift;
    my $config	= $_[0];
    my $data	= $_[1];
   
    if( ! $data->{'sambainternal'} ) {
        $data->{'sambainternal'} = {};
    }
    my $ret = $self->init_samba_sid( $config, $data );
    if( $ret ) {
        return $ret;
    } else {
    }
    $ret = $self->update_object_classes( $config, $data );
    if( $ret ) {
        return $ret;
    }
    
    return $data;
}

# This will be called just after Users::Add - the data map probably contains
# the values which we could use to create new ones
# Could be called multiple times for one user/group!
BEGIN { $TYPEINFO{Add} = ["function", ["map", "string", "any"], "any", "any"];}
sub Add {
    my $self	= shift;
    my $config	= $_[0];
    my $data	= $_[1];
    y2internal ("Add Samba called");
    
    $self->update_attributes ($config, $data);

    y2internal ( Data::Dumper->Dump( [ $data ] ) );
    return $data;
}

BEGIN { $TYPEINFO{EditBefore} = ["function",
    ["map", "string", "any"],
    "any", "any"];
}
sub EditBefore {
    my $self	= shift;
    my $config	= $_[0];
    my $data	= $_[1];
    # First time call to Edit() 
    if( ! $data->{'sambainternal'} ) {
        $data->{'sambainternal'} = {};
        $self->init_samba_sid( $config, $data );
    }
    return $data;
}

# this will be called at the beggining of Users::Edit
BEGIN { $TYPEINFO{Edit} = ["function",
    ["map", "string", "any"],
    "any", "any"];
}
sub Edit {
    my $self	= shift;
    my $config	= $_[0];
    my $data	= $_[1];

    y2internal ("Edit Samba called");
    y2internal ( Data::Dumper->Dump( [ $data ] ) );
    
    if( ! $data->{'sambainternal'}->{'initialized'} ) {
        $self->init_internal_keys( $config,  $data );
        $data->{'sambainternal'}->{'initialized'} = 1;
    }

    # If user doesn't have a Samba Account yet some initialization
    # has to take place now.
    if ( ! $self->PluginPresent( $config, $data ) ) {
        $self->update_object_classes( $config, $data );
    }

    $self->update_attributes ($config, $data);
    if ( (! $data->{'sambalmpassword'})  ) {
        y2internal ("no samba password hashes present yet");
    }

    y2internal ( Data::Dumper->Dump( [ $data ] ) );
    return $data;
}

# this will be called at the beggining of Users::Edit
BEGIN { $TYPEINFO{InternalAttributes} = ["function",
    ["map", "string", "any"],
    "any", "any"];
}
sub InternalAttributes {
    return [ "sambainternal", "sambanoexpire", "sambadisabled"];
}

sub update_object_classes {
    my ($self, $config, $data) = @_;

    my $oc = "sambaSamAccount";

    # define the object class for new user/groupa
    if (defined $data->{"objectclass"} && ref $data->{"objectclass"} eq "ARRAY")
    {
        if ( ! grep /^$oc$/i, @{$data->{'objectclass'}} ) {
	    push @{$data->{'objectclass'}}, $oc;
            y2milestone("added ObjectClass $oc");
        }
    }
    return undef;
}

sub init_internal_keys {
    my ($self, $config, $data) = @_;
    y2internal("UsersPluginSamba::init_internal_keys");
    if ( $data->{'sambaacctflags'} ) {
        if ( ! defined( $data->{'sambadisabled'} ) ) {
            y2internal("    UsersPluginSamba::init_internal_keys sambadisabled undefined ");
            if ( $data->{'sambaacctflags'} =~ /^\[.*D.*\]/ ) {
                $data->{'sambadisabled'} = "1";
            } else {
                $data->{'sambadisabled'} = "0";
            }
        }
        if ( ! defined( $data->{'sambanoexpire'} ) ) {
            y2internal("    UsersPluginSamba::init_internal_keys sambanoexpire undefined ");
            if ( $data->{'sambaacctflags'} =~ /^\[.*X.*\]/ ) {
                $data->{'sambanoexpire'} = "1";
            } else {
                $data->{'sambanoexpire'} = "0";
            }
        }
    }
    return undef;
}

sub update_attributes {
    my ( $self, $config, $data ) = @_;

    my $SID     = $data->{'sambainternal'}->{'sambalocalsid'};
    my $uidNumber = $data->{'uidnumber'};
    if ( $uidNumber ) {
        $data->{'sambasid'} = $SID."-". ( 2 * $uidNumber + 1000 );
    }
    my $gidNumber = $data->{'gidnumber'};
    if ( $gidNumber ) {
        $data->{'sambaprimarygroupsid'} = $SID."-". (2 * $gidNumber + 1001);
    }
    $data->{'sambainternal'}->{'sambacleartextpw'} = $data->{'text_userpassword'};

    my $ret = $self->update_samba_pwhash( $config, $data );
    if( $ret ) {
        return $ret;
    }
    $ret = $self->update_samba_acctflags( $config, $data );
    if( $ret ) {
        return $ret;
    }

}

sub update_samba_acctflags {
    my ($self, $config, $data) = @_;
    y2milestone("update_samba_acctflags");
    my $acctflags = $data->{'sambaacctflags'} || "[U         ]";
    y2milestone("    acctflags: $acctflags");

    $acctflags =~ s/^\[(\w+)\s*\]$/$1/g;
    y2milestone("    acctflags: $acctflags");
    if( defined( $data->{'sambadisabled'} ) && 
            $data->{'sambadisabled'} eq "1" ) {
        if ( $acctflags !~ /D/ ) {
            $acctflags .= "D";
        }
    } elsif ( (! defined( $data->{'sambadisabled'})) 
                || $data->{'sambadisabled'} eq "0" ) {
        $acctflags =~ s/^(.*)D(.*)$/$1$2/g;
    }
    if( defined( $data->{'sambanoexpire'} ) 
                && $data->{'sambanoexpire'} eq "1" ) {
        if ( $acctflags !~ /X/ ) {
            $acctflags .= "X";
        }
    } elsif ( (! defined( $data->{'sambanoexipre'})) 
                || $data->{'sambanoexpire'} eq "0" ) {
        $acctflags =~ s/^(.*)X(.*)$/$1$2/g;
    }
    y2milestone("    length:" .length($acctflags) );
    my $len = length($acctflags);
    for( my $i=0; $i < ( 11 - $len ); $i++ ) {
        $acctflags .= " ";
    }
    y2milestone("    updated acctflags: $acctflags");
    $data->{'sambaacctflags'} = "[". $acctflags ."]";
    return undef;
}

sub update_samba_pwhash {
    my ( $self, $config, $data ) = @_;
    
    if ( $data->{'sambainternal'}->{'sambacleartextpw'} ) {
        y2milestone("update_samba_pwhash");
        my $update_timestamp = 0;
        my ($lmHash, $ntHash) = ntlmgen($data->{'sambainternal'}->{'sambacleartextpw'});
        y2internal ("   LMHASH: ". $lmHash );
        y2internal ("   NTHASH: ". $ntHash );
        if ( $lmHash ne $data->{'sambalmpassword'} ) {
            $data->{'sambalmpassword'} = $lmHash;
            $update_timestamp = 1;
        }
        if ( $ntHash ne $data->{'sambantpassword'} ) {
            $data->{'sambantpassword'} = $ntHash;
            $update_timestamp = 1;
        }
        if ( $update_timestamp ) {
            $data->{'sambapwdlastset'} = time ();
            $data->{'sambapwdcanchange'} = $data->{'sambapwdlastset'};
        }
        $data->{'sambapwdmustchange'} = ( 1 << 31 ) - 1;
    }
    return undef;
}

sub init_samba_sid {
    my ( $self, $config, $data ) = @_;
    y2milestone("init samba sid ");
    if ( (! $data->{'sambainternal'}->{'sambalocalsid'}) || ($data->{'sambainternal'}->{'sambalocalsid'} eq "") ) {
        my $base_dn = Ldap->GetDomain();
        my $res = SCR->Read(".ldap.search", { base_dn => $base_dn,
                                              scope => YaST::YCP::Integer(2),
                                              filter => "(objectClass=sambaDomain)",
                                              attrs => ['sambasid']
                                            } 
                            ); 
        if ( ! $res ){
            y2milestone( "LDAP Error" );
            my $ldaperr = SCR::Read(".ldap.error" );
            y2internal("$ldaperr->{'code'}");
            y2internal("$ldaperr->{'msg'}");
        } else {
            y2milestone( Data::Dumper->Dump( [$res] ));
            y2milestone( "SAMBASID: ".$res->[0]->{'sambasid'}->[0] );
            if ( $res->[0]->{'sambasid'}->[0] ) {
                $data->{'sambainternal'}->{'sambalocalsid'} = $res->[0]->{'sambasid'}->[0];
                return undef;
            } else {
                return "error reading samba sid";
            }
        }
    }
}


1;
# EOF
