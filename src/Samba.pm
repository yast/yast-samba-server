=head1 NAME

YaPI::Samba

=head1 PREFACE

This package is the public Yast2 API to configure the Samba server.

=head1 SYNOPSIS

use YaPI::Samba

$serverRole = string DetermineRole ()

  returns a string representing the currently configure role or
  undef on failure.

boolean GetServiceStatus ()

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
# default and vhost API start
#######################################################

=item *
C<$hostList = GetServiceStatus ();>

This function returns FIXME
On error, undef is returned and the Error() function can be used
to get the error hash.

=cut

BEGIN { $TYPEINFO{GetServiceStatus} = ["function", "status" ]; }
sub GetServiceStatus {
    # TODO:
    $self = shift;    
    return undef;
}

BEGIN { $TYPEINFO{DetermineRole} = ["function", "string" ]; }
sub DetermineRole {
    # TODO:
    $self = shift;    
    return undef;
}

BEGIN { $TYPEINFO{ModifyService} = ["function", "boolean", "boolean" ]; }
sub ModifyService {
    # TODO:
    $self = shift;    
    $enable = shift;
    return undef;
}

BEGIN { $TYPEINFO{ModifyServerAsBDC} = ["function", "void", "string" ]; }
sub ModifyServerAsBDC {
    # TODO:
    $self = shift;   
    $pdc = shift; 
    return undef;
}

BEGIN { $TYPEINFO{ModifyServerAsPDC} = ["function", "void" ]; }
sub ModifyServerAsPDC {
    # TODO:
    $self = shift;
    return undef;
}

BEGIN { $TYPEINFO{ModifyServerAsStandalone} = ["function", "void" ]; }
sub ModifyServerAsStandalone {
    # TODO:
    $self = shift;    
    return undef;
}

BEGIN { $TYPEINFO{GetServerDescription} = ["function", "string" ]; }
sub GetServerDescription {
    # TODO:
    $self = shift;    
    return undef;
}

BEGIN { $TYPEINFO{ModifyServerDescription} = ["function", "void", "string" ]; }
sub ModifyServerDescription {
    # TODO:
    $self = shift;    
    $description = shift;
    return undef;
}

map GetSAMConfiguration (string sam)
boolean ModifySAMConfiguration (string sam, map options)
boolean SetDefaultSAM (string sam)
boolean CreateSAMConfiguration (string sam, map options, boolean default)
boolean RemoveSAM (string sam)

boolean EnableShare (string name, boolean on)
boolean CreateShare (string name, map options)
boolean RemoveShare (string name)
boolean ModifyShare (string name, map options)

list&lt;string&gt; GetAllDirectories ()
void EnableHomes (boolean on)
void EnableNetlogon (boolean on)
list&lt;string&gt; GetAllPrinters ()
EnablePrinters (list &lt;string&gt; printer_names, boolean on)

#######################################################
# default and vhost API end
#######################################################

42;
