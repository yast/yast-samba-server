#! /usr/bin/perl -w
# File:		modules/SambaServerPassdb.pm
# Package:	Configuration of smb.conf passdb backend option
# Summary:	Configuration of passdb backend option, input and output functions
# Authors:	Stanislav Visnovsky <visnov@suse.cz>
#
# $Id$
#
# Representation of the configuration of passdb backend option from smb.conf.


package SambaServerPassdb;

use strict;

use ycp;
use YaST::YCP qw(Boolean);

use Locale::gettext;
use POSIX;     # Needed for setlocale()

setlocale(LC_MESSAGES, "");
textdomain("samba-server");

sub _ {
    return gettext($_[0]);
}

our %TYPEINFO;

## Global imports
YaST::YCP::Import ("SCR");

##
 # Data was modified?
 #
my $modified = 0;

##
 # Data was modified?
 # @return true if modified
 #
BEGIN { $TYPEINFO {Modified} = ["function", "boolean"]; }
sub Modified {
    y2debug ("modified=$modified");
    return Boolean($modified);
}

# Settings: Define all variables needed for configuration of XXpkgXX
# TODO FIXME: Define all the variables necessary to hold
# TODO FIXME: the configuration here (with the appropriate
# TODO FIXME: description)
# TODO FIXME: For example:
#   ##
#    # List of the configured cards.
#    #
#   my @cards = ();
#
#   ##
#    # Some additional parameter needed for the configuration.
#    #
#   my $additional_parameter = 1;

my @backends = ("smbpasswd");

##
 # Read all XXpkgXX settings
 # @return true on success
 #
BEGIN { $TYPEINFO{Read} = ["function", "boolean"]; }
sub Read {

    my $ret = SCR::Read (".etc.smb.value.global.passdb backend");
    
    if ( defined $ret )
    {
	@backends = split (/[\s,]+/, $ret);
    }

    $modified = 0;
    return Boolean(1);
}

##
 # Write all XXpkgXX settings
 # @return true on success
 #
BEGIN { $TYPEINFO{Write} = ["function", "boolean"]; }
sub Write {

    my $pom = join(" ", @backends);
    
    if ( $modified == 0 )
    {
	return Boolean(1);
    }
    
    # write down the settings
    my $ret = SCR::Write (".etc.smb.value.global.\"passdb backend\"", join(" ", @backends) );
    if( $ret == 0 )
    {
	y2error ("Cannot write passdb backend");
    }
    
    $modified = ! $ret;

    return Boolean($ret);
}

##
 # TODO
 #
BEGIN { $TYPEINFO{GetBackends} = ["function", ["list", "string"] ]; }
sub GetBackends {
    return \@backends;
}

##
 # TODO
 #
BEGIN { $TYPEINFO{SetBackends} = ["function", "void", ["list", "string"] ]; }
sub SetBackends {
    @backends = @{$_[0]};
    
    $modified = 1;
    return;
}

BEGIN { $TYPEINFO{BackendSAM} = ["function", "string", "string" ]; }
sub BackendSAM 
{
    my $url = shift;
    my @parts = split (/:/, $url);
    
    if( @parts )
    {
	return $parts[0];
    }
    
    return undef;
}
    
BEGIN { $TYPEINFO{BackendDetails} = ["function", "string", "string" ]; }
sub BackendDetails {
    my @parts = split (/:/, shift);
    
    if ( defined $parts[1] )
    {
	# skip the first part, join the rest together
	shift @parts;
	return join (":",@parts);
    }
    else
    {
	return "";
    }
}

BEGIN { $TYPEINFO{BackendString} = ["function", "string", "string", "string" ]; }
sub BackendString
{
    my $type = shift;
    my $url = shift;
    
    if ( $url != "" )
    {
	return $type . ":" . $url;
    }
    else
    {
	return $type;
    }
}
    

42

# EOF
