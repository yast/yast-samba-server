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

$enabled = ModifyService($enable)

  enabled/disables the smbd and nmbd services. returns the status of the
  service, undef on failure.

$result = ModifyServerAsBDC($pdc_name)

  configures the samba server as a Backup Domain Controller with the given
  PDC. return undef on failure.

$result = ModifyServerAsPDC()

  configures the samba server as a Backup Domain Controller with the given
  PDC. return undef on failure.

$result = ModifyServerAsStandalone()

  configures the samba server as a Backup Domain Controller with the given
  PDC. return undef on failure.

$description = GetServerDescription()

  returns the server comment string, or undef it is not configured or on
  failure.

$result = ModifyServerDescription($description)

  sets a new server comment string. returns undef on failure

$passdbHash = GetSAMConfiguration($samString)

  returns a hash containing the configuration options related to a passdb
  backend. return undef on failure.

$result = ModifySAMConfiguration($samString,$passdbHash)

  sets the options for a passdb backend. returns undef on failure.

$result = SetDefaultSAM($samString)

  sets the given passdb backend as default (used for creating new users).
  returns undef on error.

$result = CreateSAMConfiguration($samString,$passdbHash)

  creates a new passdb backend using the given options. returns undef
  on error.

$result = RemoveSAM($samString)

  removes the given passdb backend. returns undef on failure.

$result = EnableShare($shareName,$enable)

  enables/disabled the given share. returns undef on failure.

$result = CreateShare($shareName,$options)

  creates a new share using the given options. returns undef on failure.

$result = RemoveShare($shareName)

  removes a share completely. returns undef on failure.

$result = ModifyShare($shareName,$options)

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
    # TODO:
    $self = shift;    
    return undef;
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
    # TODO:
    $self = shift;    
    return undef;
}

=item *
C<$enabled = ModifyService($enable);>

Modifies the status of the service. If the parameter is true, 
smb and nmb services are enabled in the default runlevels, 
if there were not enabled already in at least single runlevel. 
False will turn off the service in all runlevels.
On error, undef is returned and the Error() function can be used
to get the error hash.

=cut

BEGIN { $TYPEINFO{ModifyService} = ["function", "boolean", "boolean" ]; }
sub ModifyService {
    # TODO:
    $self = shift;    
    $enable = shift;
    return undef;
}

=item *
C<$result = ModifyServerAsBDC($pdc_name)>

Configures the global settings of a server to behave like a 
backup domain controller. The primary domain controller is setup by the argument.
On error, undef is returned and the Error() function can be used
to get the error hash.

=cut

BEGIN { $TYPEINFO{ModifyServerAsBDC} = ["function", "void", "string" ]; }
sub ModifyServerAsBDC {
    # TODO:
    $self = shift;   
    $pdc = shift; 
    return undef;
}

=item *
C<$result = ModifyServerAsPDC()>

Configures the global settings of a server to behave like a primary domain controller.
On error, undef is returned and the Error() function can be used
to get the error hash.

=cut

BEGIN { $TYPEINFO{ModifyServerAsPDC} = ["function", "void" ]; }
sub ModifyServerAsPDC {
    # TODO:
    $self = shift;
    return undef;
}

=item *
C<$result = ModifyServerAsStandalone();>

Configures the global settings of a server to behave like a standalone 
server not taking part in any domain.
On error, undef is returned and the Error() function can be used
to get the error hash.

=cut

BEGIN { $TYPEINFO{ModifyServerAsStandalone} = ["function", "void" ]; }
sub ModifyServerAsStandalone {
    # TODO:
    $self = shift;    
    return undef;
}

=item *
C<$description = GetServerDescription();>

Returns the configured description of the server. 
On error, undef is returned and the Error() function can be used
to get the error hash.

=cut

BEGIN { $TYPEINFO{GetServerDescription} = ["function", "string" ]; }
sub GetServerDescription {
    # TODO:
    $self = shift;    
    return undef;
}

=item *
C<$result = ModifyServerDescription($description);>

Configures the description of the server shown in clients. 
On error, undef is returned and the Error() function can be used
to get the error hash.

=cut

BEGIN { $TYPEINFO{ModifyServerDescription} = ["function", "void", "string" ]; }
sub ModifyServerDescription {
    # TODO:
    $self = shift;    
    $description = shift;
    return undef;
}

=item *
C<$passdbHash = GetSAMConfiguration($samString);>

Returns a list of options specified for the given SAM. The structure of the options is sam-type specific.
On error, undef is returned and the Error() function can be used
to get the error hash.

=cut

BEGIN { $TYPEINFO{GetSAMConfiguration} = ["function", [ "map", "string", "any" ], "string" ]; }
sub GetSAMConfiguration {
    # TODO
    $self = shift;
    $sam = shift;
    
    return undef;
}

=item *
C<$result = ModifySAMConfiguration($samString, $passdbHash);>

Modifies the configuration of the given sam. The structure of the hash 
must follow the structure as specified for GetSAMConfiguration. 
On error, undef is returned and the Error() function can be used
to get the error hash.

=cut

BEGIN { $TYPEINFO{ModifySAMConfiguration} = ["function", "boolean", "string", ["map", "string", "any" ] ]; }
sub ModifySAMConfiguration {
    # TODO
    $self = shift;
    $sam = shift;
    %options = shift;
    
    return undef;
}

=item *
C<$result = SetDefaultSAM($samString);>

Sets the SAM as default one, meaning that adding a new user will be done using this SAM. 
On error, undef is returned and the Error() function can be used
to get the error hash.

=cut

BEGIN { $TYPEINFO{SetDefaultSAM} = ["function", "boolean", "string" ]; }
sub SetDefaultSAM {
    # TODO
    $self = shift;
    $sam = shift;
    
    return undef;
}

=item *
C<$result = CreateSAMConfiguration($samString, $passdbHash);>

Creates a new SAM using the given name and configuration. 
The structure of the hash must follow the structure as specified for GetSAMConfiguration.
On error, undef is returned and the Error() function can be used
to get the error hash.

=cut

BEGIN { $TYPEINFO{CreateSAMConfiguration} = ["function", "boolean", "string", [ "map", "string", "any" ] , "boolean" ]; }
sub CreateSAMConfiguration {
    # TODO
    $self = shift;
    $sam = shift;
    %options = shift;
    $default = shift;
    
    return undef;
}

=item *
C<$result = RemoveSAM($samString);>

Removes the specified sam. It is not possible to remove the default one.
On error, undef is returned and the Error() function can be used
to get the error hash.

=cut

BEGIN { $TYPEINFO{RemoveSAM} = ["function", "boolean", "string" ]; }
sub RemoveSAM {
    # TODO
    $self = shift;
    $sam = shift;
    
    return undef;
}

=item *
C<$result = EnableShare($shareName,$enable);>

Enables/disables the given share. 
On error, undef is returned and the Error() function can be used
to get the error hash.

=cut

BEGIN { $TYPEINFO{EnableShare} = ["function", "boolean", "string", "boolean"] ; }
sub EnableShare {
    # TODO
    $self = shift;
    $name = shift;
    $on = shift;
    
    return undef;
}

=item *
C<$result = CreateShare($shareName,$options);>

Creates a new share with the given name and initial options. 
On error, undef is returned and the Error() function can be used
to get the error hash.

=cut

BEGIN { $TYPEINFO{CreateShare} = ["function", "boolean", "string", [ "map", "string", "any" ] ] ; }
sub CreateShare {
    # TODO
    $self = shift;
    $name = shift;
    %options = shift;
    
    return undef;
}

=item *
C<$result = RemoveShare($shareName);>

Removes the given share. 
On error, undef is returned and the Error() function can be used
to get the error hash.

=cut

BEGIN { $TYPEINFO{RemoveShare} = ["function", "boolean", "string"] ; }
sub RemoveShare {
    # TODO
    $self = shift;
    $name = shift;
    
    return undef;
}

=item *
C<$result = ModifyShare($shareName,$options);>

Modifies the given share to use the given options. 
On error, undef is returned and the Error() function can be used
to get the error hash.

=cut

BEGIN { $TYPEINFO{ModifyShare} = ["function", "boolean", "string", [ "map", "string", "any" ] ] ; }
sub ModifyShare {
    # TODO
    $self = shift;
    $name = shift;
    %options = shift;
    
    return undef;
}

=item *
C<$options = GetShare($shareName);>

Returns a hash describing the given share.
On error, undef is returned and the Error() function can be used
to get the error hash.

=cut

BEGIN { $TYPEINFO{ModifyShare} = ["function", "boolean", "string", [ "map", "string", "any" ] ] ; }
sub ModifyShare {
    # TODO
    $self = shift;
    $name = shift;
    %options = shift;
    
    return undef;
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
    # TODO
    $self = shift;
    
    return undef;
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
    # TODO
    $self = shift;
    $on = shift;
    
    return undef;
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
    # TODO
    $self = shift;
    $on = shift;
    
    return undef;
}

=item *
C<$shares = GetAllPrinters();>

Returns a list of all printers configured to be shared.
On error, undef is returned and the Error() function can be used
to get the error hash.

=cut

BEGIN { $TYPEINFO{GetAllPrinters} = ["function", [ "list", "string" ] ]; }
sub GetAllPrinters {
    # TODO
    $self = shift;
    
    return undef;
}

=item *
C<$result = EnablePrinters($printerList,$enable);>

Enables/disables sharing of the given printers. 
On error, undef is returned and the Error() function can be used
to get the error hash.

=cut

BEGIN { $TYPEINFO{EnablePrinters} = ["function", "boolean", [ "list", "string" ], "boolean"] ; }
sub EnablePrinters {
    # TODO
    $self = shift;
    @printer_names = shift;
    $enable = shift;
    
    return undef;
}

#######################################################
# API end
#######################################################

=back

=cut

42;
