#! /usr/bin/perl -w
#
# Samba plugin module
# This is the API part of UsersPluginSamba plugin 
#
# The following user parameters are handled inside this module
#

package UsersPluginSambaGroups;

use strict;

use ycp;
use YaST::YCP;
our %TYPEINFO;

use Locale::gettext;
use POSIX ();

## FIXME
use Data::Dumper;
use Crypt::SmbHash;

YaST::YCP::Import ("ProductFeatures");
YaST::YCP::Import ("SCR");

POSIX::setlocale(LC_MESSAGES, "");
textdomain("samba-users");	# TODO own textdomain for new plugins

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
my $pluginName = "UsersPluginSambaGroups"; 

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
    my $ret 	= _("Manage Samba attribute of LDAP groups");

    return $ret;
}


# return name of YCP client defining YCP GUI
BEGIN { $TYPEINFO{GUIClient} = ["function", "string", "any", "any"];}
sub GUIClient {

    my $self	= shift;
    return "users_plugin_samba_groups";
}

##------------------------------------
# Type of users and groups this plugin is restricted to.
# If this function doesn't exist, plugin is applied for all user (group) types.
BEGIN { $TYPEINFO{Restriction} = ["function",
    ["map", "string", "any"], "any", "any"];}
sub Restriction {

    my $self	= shift;
    # plugin only available in expert mode
    if (ProductFeatures->GetFeature("globals", "ui_mode") ne "expert") {
	return {};
    }
    # this plugin applies only for LDAP users and groups
    return { "ldap"	=> 1,
             "group"     => 1 };
}

# checks the current data map of user/group (2nd parameter) and returns
# true if given user (group) has our plugin
BEGIN { $TYPEINFO{PluginPresent} = ["function", "boolean", "any", "any"];}
sub PluginPresent {
    my $self	= shift;
    my $config    = shift;
    my $data    = shift;

    if ( grep /^sambagroupmapping$/i, @{$data->{'objectclass'}} ) {
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

    #y2internal ( Data::Dumper->Dump( [ $data ] ) );
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
    #y2internal ("EditBefore Samba called");
    
    # First time call to Edit() 
    if( ! $data->{'sambainternal'} ) {
        $data->{'sambainternal'} = {};
        $self->init_samba_sid( $config, $data );
    }
    
    #y2internal ( Data::Dumper->Dump( [ $data ] ) );
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

    #y2internal ( Data::Dumper->Dump( [ $data ] ) );
    # Has the plugin been removed?
    if( grep /^$pluginName$/, @{$data->{'plugins_to_remove'}} ) {
        $self->remove_plugin_data( $config, $data );
        #y2internal ( Data::Dumper->Dump( [ $data ] ) );
        return $data;
    }
    
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

    return $data;
}

# this will be called at the beggining of Users::Edit
BEGIN { $TYPEINFO{InternalAttributes} = ["function",
    ["map", "string", "any"],
    "any", "any"];
}
sub InternalAttributes {
    return [ "sambainternal"];
}

sub update_object_classes {
    my ($self, $config, $data) = @_;

    my $oc = "sambaGroupMapping";

    # define the object class for new user/groupa
    if (defined $data->{"objectclass"} && ref $data->{"objectclass"} eq "ARRAY")
    {
        if ( ! grep /^$oc$/i, @{$data->{'objectclass'}} ) {
	    push @{$data->{'objectclass'}}, $oc;
            #y2milestone("added ObjectClass $oc");
        }
    }
    return undef;
}

sub init_internal_keys {
    my ($self, $config, $data) = @_;
    #y2internal("UsersPluginSamba::init_internal_keys");
    return undef;
}

sub update_attributes {
    my ( $self, $config, $data ) = @_;

    my $SID     = $data->{'sambainternal'}->{'sambalocalsid'};
    my $gidNumber = $data->{'gidnumber'};
    if ( $gidNumber ) {
        $data->{'sambasid'} = $SID."-". (2 * $gidNumber + $data->{'sambainternal'}->{'ridbase'} + 1);
    }
    if( ! $data->{'displayname'} ) {
        $data->{'displayname'} = $data->{'cn'};
    }
    $data->{'sambagrouptype'} = "2";
    return undef;
}

sub init_samba_sid {
    my ( $self, $config, $data ) = @_;
    #y2milestone("init samba sid ");
    if ( (! $data->{'sambainternal'}->{'sambalocalsid'}) || ($data->{'sambainternal'}->{'sambalocalsid'} eq "") ) {
        my $base_dn = Ldap->GetDomain();
        my $res = SCR->Read(".ldap.search", { base_dn => $base_dn,
                                              scope => YaST::YCP::Integer(2),
                                              filter => "(objectClass=sambaDomain)",
                                              attrs => ['sambasid', 'sambaalgorithmicridbase']
                                            } 
                            ); 
        if ( ! $res ){
            y2internal( "LDAP Error" );
            my $ldaperr = SCR::Read(".ldap.error" );
            y2internal("$ldaperr->{'code'}");
            y2internal("$ldaperr->{'msg'}");
        } else {
            #y2milestone( Data::Dumper->Dump( [$res] ));
            if ( $res->[0]->{'sambasid'}->[0] ) {
                $data->{'sambainternal'}->{'sambalocalsid'} = $res->[0]->{'sambasid'}->[0];
                $data->{'sambainternal'}->{'ridbase'} = $res->[0]->{'sambaalgorithmicridbase'}->[0];
                return undef;
            } else {
                return "error reading samba sid";
            }
        }
    }
}

sub remove_plugin_data {
    my ( $self, $config, $data ) = @_;
  
    my @updated_oc;
    foreach my $oc ( @{$data->{'objectclass'}} ) {
        if ( lc($oc) ne "sambagroupmapping" ) {
            push @updated_oc, $oc;
        }
    }
#    delete( $data->{'sambainternal'});
#    delete( $data->{'sambapwdmustchange'});
#    delete( $data->{'sambapwdlastset'});
#    delete( $data->{'sambapwdcanchange'});
#    delete( $data->{'sambantpassword'});
#    delete( $data->{'sambalmpassword'});
#    delete( $data->{'sambaacctflags'});
#    delete( $data->{'sambahomedrive'});
#    delete( $data->{'sambahomepath'});
#    delete( $data->{'sambaprofilepath'});
#    delete( $data->{'sambalogonscript'});
#    delete( $data->{'sambasid'});
#    delete( $data->{'sambaprimarygroupssid'});
#    delete( $data->{'sambanoexprire'});
#    delete( $data->{'sambadisabled'});

    $data->{'objectclass'} = \@updated_oc;
    return undef;
}

1;
# EOF
