#! /usr/bin/perl -w
# File:		modules/SambaSecrets.pm
# Package:	Samba server
# Summary:	Reading of /etc/samba/secrets.tdb
# Authors:	Stanislav Visnovsky <visnov@suse.cz>
#
# $Id$
#


package SambaSecrets;

use strict;

use YaST::YCP qw(:LOGGING);

our %TYPEINFO;

## Global imports
YaST::YCP::Import ("SCR");

use Data::Dumper;

##
 # Read the current contents of the secrets file
 # @return map of data or undef on error
 #
BEGIN { $TYPEINFO{Read} = ["function", ["map", "string", "string"] ]; }
sub Read {
    my $self = shift;
    my %result = ();
    
    # if the secrets file does not exist at all, return empty map
    my $res = SCR->Read (".target.stat", "/etc/samba/secrets.tdb" );
    unless ( defined $res )
    {
	return undef;
    }
    
    if ( ! keys %{ $res } )
    {
	y2milestone ("File does not exist");
	return \%result;
    }

    $res = SCR->Execute (".target.bash_output", "/usr/bin/tdbdump /etc/samba/secrets.tdb" );
    if ( ! defined $res || $res->{"exit"} )
    {
	y2error ("Cannot read TDB dump");
	return undef;
    }
    
    $res = $res->{"stdout"};
    
    my $current_key = undef;
    my @lines = split ( /\n/, $res);
    while ( @lines )
    {
	my $line = shift @lines;
	
	if ( $line =~ /^key = \"([^\"]*)\"$/ )
	{
	    $current_key = $1;
	    y2debug ("Parsed key: " . $current_key );
	}
	elsif ( $line =~ /^data = \"([^\"]*)\"$/ )
	{
	    my $current_data = $1;

	    y2debug ("Parsed data: " . $current_key );

	    unless ( defined $current_key )
	    {
		y2error ("Broken TDB dump - data without key");
		return undef;
	    }
	    
	    $result { $current_key } = $current_data;
	    
	    $current_key = undef;
	}
    }

    y2debug ("Result: ". Dumper ( \%result ) );
    
    return \%result;
}

42

# EOF
