# Copyright 2004, Novell, Inc.  All rights reserved.

=head1 NAME

YaPI::Samba - Samba server configuration API

=head1 PREFACE

This package is the public Yast2 API to configure the Samba server.

=head1 SYNOPSIS

use YaPI::Samba

$serverRole = DetermineRole()

  returns a string representing the currently configure role or
  undef on failure.

$enabled = GetServiceStatus()

  returns true if the services smbd and nmbd are enabled, false if either of
  them is disabled or undef on failure.

$enabled = EditService($enable)

  enabled/disables the smbd and nmbd services. returns the status of the
  service, undef on failure.

$result = EditServerAsBDC($pdc_name)

  configures the samba server as a Backup Domain Controller with the given
  PDC. return undef on failure.

$result = EditServerAsPDC()

  configures the samba server as a Backup Domain Controller with the given
  PDC. return undef on failure.

$result = EditServerAsStandalone()

  configures the samba server as a Backup Domain Controller with the given
  PDC. return undef on failure.

$description = GetServerDescription()

  returns the server comment string, or undef it is not configured or on
  failure.

$result = EditServerDescription($description)

  sets a new server comment string. returns undef on failure

@passdb = GetSAMBackends()

  returns a list of all configured passdb backends or undef on failure.

$result = EditSAMConfiguration($samString,$passdbHash)

  sets the options for a passdb backend. returns undef on failure.

$result = EditDefaultSAM($samString)

  sets the given passdb backend as default (used for creating new users).
  returns undef on error.

$result = AddSAM($samString,$isDefault)

  creates a new passdb backend. returns undef
  on error.

$result = DeleteSAM($samString)

  Deletes the given passdb backend. returns undef on failure.

$result = EnableShare($shareName,$enable)

  enables/disabled the given share. returns undef on failure.

$result = AddShare($shareName,$options)

  creates a new share using the given options. returns undef on failure.

$result = DeleteShare($shareName)

  Deletes a share completely. returns undef on failure.

$result = EditShare($shareName,$options)

  modifies an existing share using the given options. returns undef on failure.

$options = GetShare($shareName)

  returns a hash describing the given share or undef on failure.

$shares = GetAllDirectories()

  returns a list of share names, which are configured as disk shares. returns
  undef on failure.

$result = EnableHomes($enable)

  enables/disables special share [homes]. returns undef on failure.

$result = EnableNetlogon($enable)

  enables/disables special share [netlogon]. returns undef on failure.

$shares = GetAllPrinters()

  returns a list of share names, which are configured as printers. returns
  undef on failure.

$result = EnablePrinters($printerList,$enable)

  enables/disables a list of printers. returns undef on failure.

=head1 DESCRIPTION

=over 2

=cut

package YaPI::Samba;
use YaST::YCP;
BEGIN { push( @INC, '/usr/share/YaST2/modules/' ); }

YaST::YCP::Import ("SambaServer");
YaST::YCP::Import ("SambaServerPassdb");

our %TYPEINFO;

if(not defined do("YaPI.inc")) {
    die "'$!' Can not include YaPI.inc";
}

#######################################################

use strict;

#######################################################
# API start
#######################################################

=item *
C<$hostList = GetServiceStatus ();>

Returns the current status of smb and nmb services. True means 
the services are both started in at least on runlevel.
On error, undef is returned and the Error() function can be used
to get the error hash.

=cut

BEGIN { $TYPEINFO{GetServiceStatus} = ["function", "string" ]; }
sub GetServiceStatus {
    my $self = shift;    
    return YaST::Service::Enabled ("smbd") && YaST::Service::Enabled ("nmbd");
}

=item *
C<$serverRole = DetermineRole();>

This function determines role of a server in the SMB network. 
The return values can be unknown, standalone, bdc and pdc.
On error, undef is returned and the Error() function can be used
to get the error hash.

=cut

BEGIN { $TYPEINFO{DetermineRole} = ["function", "string" ]; }
sub DetermineRole {
    my $self = shift;
    SambaServer::Read ();
    return SambaServer::DetermineRole ();
}

=item *
C<$enabled = EditService($enable);>

Modifies the status of the service. If the parameter is true, 
smb and nmb services are enabled in the default runlevels, 
if there were not enabled already in at least single runlevel. 
False will turn off the service in all runlevels.
On error, undef is returned and the Error() function can be used
to get the error hash.

=cut

BEGIN { $TYPEINFO{EditService} = ["function", "boolean", "boolean" ]; }
sub EditService {
    my $self = shift;    
    my $enable = shift;

    unless (YaST::Service::Enable ("smbd", $enable))
    {
	return undef;
    }

    unless (YaST::Service::Enable ("nmbd", $enable))
    {
	return undef;
    }

    return 1;
}

=item *
C<$result = EditServerAsBDC($pdc_name)>

Configures the global settings of a server to behave like a 
backup domain controller. The primary domain controller is setup by the argument.
On error, undef is returned and the Error() function can be used
to get the error hash.

=cut

BEGIN { $TYPEINFO{EditServerAsBDC} = ["function", "void", "string" ]; }
sub EditServerAsBDC {
    my $self = shift;   
    my $pdc = shift; 
    
    unless (SambaServer::Read ())
    {
	return undef;
    }

    SambaServer::SetAsBDC ($pdc);

    unless ( SambaServer::Write () )
    {
	return undef;
    }

    return 1;
}

=item *
C<$result = EditServerAsPDC()>

Configures the global settings of a server to behave like a primary domain controller.
On error, undef is returned and the Error() function can be used
to get the error hash.

=cut

BEGIN { $TYPEINFO{EditServerAsPDC} = ["function", "void" ]; }
sub EditServerAsPDC {
    my $self = shift;

    unless (SambaServer::Read ())
    {
	return undef;
    }

    SambaServer::SetAsPDC ();

    unless ( SambaServer::Write () )
    {
	return undef;
    }

    return 1;
}

=item *
C<$result = EditServerAsStandalone();>

Configures the global settings of a server to behave like a standalone 
server not taking part in any domain.
On error, undef is returned and the Error() function can be used
to get the error hash.

=cut

BEGIN { $TYPEINFO{EditServerAsStandalone} = ["function", "void" ]; }
sub EditServerAsStandalone {
    my $self = shift;    

    unless (SambaServer::Read ())
    {
	return undef;
    }

    SambaServer::SetAsPDC ();

    unless ( SambaServer::Write () )
    {
	return undef;
    }

    return 1;
}

=item *
C<$description = GetServerDescription();>

Returns the configured description of the server. 
On error, undef is returned and the Error() function can be used
to get the error hash.

=cut

BEGIN { $TYPEINFO{GetServerDescription} = ["function", "string" ]; }
sub GetServerDescription {
    my $self = shift;    

    unless (SambaServer::Read ())
    {
	return undef;
    }

    return SambaServer::server_string ();
}

=item *
C<$result = EditServerDescription($description);>

Configures the description of the server shown in clients. 
On error, undef is returned and the Error() function can be used
to get the error hash.

=cut

BEGIN { $TYPEINFO{EditServerDescription} = ["function", "void", "string" ]; }
sub EditServerDescription {
    my $self = shift;    
    my $description = shift;

    SambaServer::Read ();
    SambaServer::setDescription ($description);
    SambaServer::Write ();

    return 1;
}

=item *
C<@passdb = GetSAMBackends();>

Returns a list of options specified for the given SAM. The structure of the options is sam-type specific.
On error, undef is returned and the Error() function can be used
to get the error hash.

=cut

BEGIN { $TYPEINFO{GetSAMBackends} = ["function", [ "list", "string" ] ]; }
sub GetSAMConfiguration {
    my $self = shift;
    
    unless (SambaServerPassdb::Read ())
    {
	return undef;
    }
    
    return SambaServerPassdb::GetBackends ();
}

=item *
C<$result = EditSAMConfiguration($samString, $passdbHash);>

Modifies the configuration of the given sam. The structure of the hash 
must follow the structure as specified for GetSAMConfiguration. 
On error, undef is returned and the Error() function can be used
to get the error hash.

=cut

BEGIN { $TYPEINFO{EditSAMConfiguration} = ["function", "boolean", "string", ["map", "string", "any" ] ]; }
sub EditSAMConfiguration {
    my $self = shift;
    my $sam = shift;
    my %options = shift;
    
    unless (SambaServerPassdb::Read ())
    {
	return undef;
    }
    
    unless (SambaServerPassdb::EditSAMConfiguration ($sam, %options))
    {
	return undef;
    }

    unless (SambaServerPassdb::Write ())
    {
	return undef;
    }
    
    return 1;
}

=item *
C<$result = EditDefaultSAM($samString);>

Sets the SAM as default one, meaning that adding a new user will be done using this SAM. 
On error, undef is returned and the Error() function can be used
to get the error hash.

=cut

BEGIN { $TYPEINFO{EditDefaultSAM} = ["function", "boolean", "string" ]; }
sub EditDefaultSAM {
    my $self = shift;
    my $sam = shift;
    

    unless (SambaServerPassdb::Read ())
    {
	return undef;
    }
    
    unless (SambaServerPassdb::SetDefaultSAM ($sam))
    {
	return undef;
    }

    unless (SambaServerPassdb::Write ())
    {
	return undef;
    }
    
    return 1;
}

=item *
C<$result = AddSAM($samString,$isDefault);>

Creates a new SAM using the given name and configuration. 
The structure of the hash must follow the structure as specified for GetSAMConfiguration.
On error, undef is returned and the Error() function can be used
to get the error hash.

=cut

BEGIN { $TYPEINFO{AddSAM} = ["function", "boolean", "string", "boolean" ]; }
sub AddSAM {
    my $self = shift;
    my $sam = shift;
    my $default = shift;
    
    my @current = $self->GetSAMBackends ();
    
    if( grep( /^$sam$/, @current ) ) {
        # already there, error
	return undef;
    }
    
    if( $default )
    {
	unshift @current, $sam;
    }
    else
    {
	push @current, $sam;
    }
    
    SambaServerPassdb::SetBackends (@current);
    
    unless (SambaServerPassdb::Write ())
    {
	return undef;
    }
    
    return 1;
}

=item *
C<$result = DeleteSAM($samString);>

Deletes the specified sam. It is not possible to Delete the default one.
On error, undef is returned and the Error() function can be used
to get the error hash.

=cut

BEGIN { $TYPEINFO{DeleteSAM} = ["function", "boolean", "string" ]; }
sub DeleteSAM {
    my $self = shift;
    my $sam = shift;
    
    my @current = $self->GetSAMBackends ();
    
    unless( grep( /^$sam$/, @current ) ) {
        # not there, error
	return undef;
    }

    # filter out the sam
    my $item = undef;
    my @new = ();
    while (@current)
    {
	$item = shift @current;
	if( $item != $sam )
	{
	    push @new, $item;
	}
    }
    
    SambaServerPassdb::SetBackends (@new);
    
    unless (SambaServerPassdb::Write ())
    {
	return undef;
    }
    
    return 1;
}

=item *
C<$result = EnableShare($shareName,$enable);>

Enables/disables the given share. 
On error, undef is returned and the Error() function can be used
to get the error hash.

=cut

BEGIN { $TYPEINFO{EnableShare} = ["function", "boolean", "string", "boolean"] ; }
sub EnableShare {
    my $self = shift;
    my $name = shift;
    my $on = shift;

    unless (SambaServer::Read ())
    {
	return undef;
    }

    unless (SambaServer::EnableShare ($name, Boolean($on) ))
    {
	return undef;
    }

    unless ( SambaServer::Write () )
    {
	return undef;
    }

    return 1;
}

=item *
C<$result = AddShare($shareName,$options);>

Creates a new share with the given name and initial options. 
On error, undef is returned and the Error() function can be used
to get the error hash.

=cut

BEGIN { $TYPEINFO{AddShare} = ["function", "boolean", "string", [ "map", "string", "any" ] ] ; }
sub AddShare {
    my $self = shift;
    my $name = shift;
    my $options = shift;
    
    unless (SambaServer::Read ())
    {
	return undef;
    }

    unless (SambaServer::AddShare ($name, $options ))
    {
	return undef;
    }

    unless ( SambaServer::Write () )
    {
	return undef;
    }

    return 1;
}

=item *
C<$result = DeleteShare($shareName);>

Deletes the given share. 
On error, undef is returned and the Error() function can be used
to get the error hash.

=cut

BEGIN { $TYPEINFO{DeleteShare} = ["function", "boolean", "string"] ; }
sub DeleteShare {
    my $self = shift;
    my $name = shift;
    
    unless (SambaServer::Read ())
    {
	return undef;
    }

    unless (SambaServer::DeleteShare ($name))
    {
	return undef;
    }

    unless ( SambaServer::Write () )
    {
	return undef;
    }

    return 1;
}

=item *
C<$result = EditShare($shareName,$options);>

Modifies the given share to use the given options. 
On error, undef is returned and the Error() function can be used
to get the error hash.

=cut

BEGIN { $TYPEINFO{EditShare} = ["function", "boolean", "string", [ "map", "string", "any" ] ] ; }
sub EditShare {

    my $self = shift;
    my $name = shift;
    my $options = shift;
    
    unless (SambaServer::Read ())
    {
	return undef;
    }

    unless (SambaServer::EditShare ($name, $options ))
    {
	return undef;
    }

    unless ( SambaServer::Write () )
    {
	return undef;
    }

    return 1;
}

=item *
C<$options = GetShare($shareName);>

Returns a hash describing the given share.
On error, undef is returned and the Error() function can be used
to get the error hash.

=cut

BEGIN { $TYPEINFO{GetShare} = ["function", [ "map", "string", "any" ], "string" ] ; }
sub GetShare {
    my $self = shift;
    my $name = shift;

    unless (SambaServer::Read ())
    {
	return undef;
    }

    return SambaServer::GetShare ($name);
}

=item *
C<$shares = GetAllDirectories();>

Returns a list of all shares configured to provide a directory, 
including special-purpose shares like homes and netlogon.
On error, undef is returned and the Error() function can be used
to get the error hash.

=cut

BEGIN { $TYPEINFO{GetAllDirectories} = ["function", [ "list", "string" ] ]; } 
sub GetAllDirectories {

    my $self = shift;

    unless (SambaServer::Read ())
    {
	return undef;
    }

    my @res = ();
    my %shares = SambaServer::shares ();
    
    # filter out the printers
    while (my ($key, %vals) = each (%shares) )
    {
	unless (defined $vals {"printable"})
	{
	    push @res, $key;
	}
    }
    
    return \@res;
}

=item *
C<$result = EnableHomes($enable);>

Enables a special-purpose share for sharing homes of a user. 
If the share does not exist, a default template is used.
On error, undef is returned and the Error() function can be used
to get the error hash.

=cut

BEGIN { $TYPEINFO{EnableHomes} = ["function", "void",  "boolean"] ; }
sub EnableHomes {
    my $self = shift;
    my $on = shift;
    
    return $self->EnableShare ("homes", $on);
}

=item *
C<$result = EnableNetlogon($enable);>

Enables a special-purpose share for login scripts. 
If the share does not exist, a default template is used.
On error, undef is returned and the Error() function can be used
to get the error hash.

=cut

BEGIN { $TYPEINFO{EnableNetlogon} = ["function", "void",  "boolean"] ; }
sub EnableNetlogon {
    my $self = shift;
    my $on = shift;
    
    return $self->EnableShare ("netlogon", $on);
}

=item *
C<$shares = GetAllPrinters();>

Returns a list of all printers configured to be shared.
On error, undef is returned and the Error() function can be used
to get the error hash.

=cut

BEGIN { $TYPEINFO{GetAllPrinters} = ["function", [ "list", "string" ] ]; }
sub GetAllPrinters {
    my $self = shift;
    
    unless (SambaServer::Read ())
    {
	return undef;
    }

    my @res = ();
    my %shares = SambaServer::shares ();
    
    # filter out the printers
    while (my ($key, %vals) = each (%shares) )
    {
	if (defined $vals {"printable"})
	{
	    push @res, $key;
	}
    }
    
    return \@res;
}

=item *
C<$result = EnablePrinters($printerList,$enable);>

Enables/disables sharing of the given printers. 
On error, undef is returned and the Error() function can be used
to get the error hash.

=cut

BEGIN { $TYPEINFO{EnablePrinters} = ["function", "boolean", [ "list", "string" ], "boolean"] ; }
sub EnablePrinters {
    my $self = shift;
    my @printer_names = shift;
    my $enable = shift;
    
    unless (SambaServer::Read ())
    {
	return undef;
    }

    my %shares = SambaServer::shares ();
    
    while (my $share = pop @printer_names)
    {
	my %conf = $shares{ $share };
	
	unless (defined $conf {"printable"})
	{
	    return undef;
	}
	
	$conf {"enabled"} = $enable;

	$self->EditShare ($share, %conf);
    }
    
    return 1;
        
}

#######################################################
# API end
#######################################################

=back

=cut

42;
