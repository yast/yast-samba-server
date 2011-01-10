# File:		modules/SambaPrinters.pm
# Package:	Configuration of samba-server
# Authors:	Stanislav Visnovsky <visnov@suse.cz>
#		Martin Lazar <mlazar@suse.cz>
#
# $Id$
#
# Representation of the configuration of samba-server.
# Input and output routines.

package SambaPrinters;

use strict;
use Switch 'Perl6';
use Data::Dumper;

use YaST::YCP qw(:DATA :LOGGING);
use YaPI;

textdomain "samba-server";
our %TYPEINFO;

BEGIN {
YaST::YCP::Import("SambaConfig");
}

8;

=x

module "SambaPrinters";
textdomain "samba-server";

import "SambaConfig";

import "Spooler";

/**
 * list of all system printers
 */
list<string> system_printers = [];


/**
 * default settings for [printers]
 */
map<string, any> default_printers = $[
   "comment": "All Printers",
   "path": "/var/tmp",
   "printable": true,
   "browseable": false,
   "available": "yes",
   "guest ok": "no",
   "yast": true
];

/**
 * default settings for a single printer share
 */
map<string, any> default_printer_share = $[
   "path": "/var/tmp",
   "browseable": true,
   "printable": true,
   "yast": true
];


global Read() {

    printer_status = $[];
    
//    Progress::off();
    string spooler = Spooler::checkSpoolSystemNoDialog();
    y2milestone ("Spooler: %1", spooler );
    Spooler::Set(spooler);
    system_printers = Spooler::GetAvailableQueues();
//    Progress::on();

    SambaConfig::Read();

    // setup correctly the printer status
    if (SambaConfig::ExistsShare("printers")) {
	// load the system printers
	
	// setup system printer status
	boolean on = SambaServer::IsEnabledShare("printers") && toboolean(SambaConfig::GetGlobal("load printers", "Yes"));

	share_printers = on;
	if (system_printers != nil) {
	    foreach(string printer, system_printers , ``{
		printer_status[printer] = on;
	    });
	}
    }
    
    // update printer_status for printable shares
    foreach(string share, map options, SambaConfig::GetShares(), ``{
	if (share != "printers") {
	    if (toboolean(SambaConfig::GetShare(share, "printable", "No"))) {
		// if the printer was enabled because of printers and it is commented, skip
		// TODO - handle "available" correctly
		boolean on = SambaConfig::ShareEnabled(share);
		if (!(printer_status[share]:false && !on)) {
		    printer_status[share] = on;
		    if (on) share_printers = true;
		}
	    }
	}
    });
    
    return true;
}

/** 
 * Turn on/off [printers]
 *
 * @param on 		should be enabled?
 */
global  define void enablePrinters( boolean on ) ``{
    if( share_printers != on ) {
	share_printers = on;

	// if they should be turned off and there is no such share, done
	if (!on) {
	    disableAllPrinters();
	} else {
	    SambaConfig::EnableShare("printers");
	    enableAllSystemPrinters();
	}

	modified = true;
    }
}

/** 
 * Turn on all system printers. Will enable [printers] as well.
 */
global define void enableAllSystemPrinters() ``{
    if (system_printers != nil) {	
	foreach(  string printer, system_printers, ``{
	    printer_status[ printer ] = true;
	    share_printers = true;
	});
    }
}


/**
 * Disable all printers.
 */
global define void disableAllPrinters() ``{
    // disable each share with printable = true
    foreach(string share, SambaConfig::GetShares(), {
	if (toboolean(SambaConfig::GetShare(share, "printable", nil))) 
	    SambaConfig::DisableShare(share);
    });
}

/**
 * Enable printers in a list. If possible, use [printers] section
 *
 * @param enable_names	list of printer names to be enabled
 */
global define void enablePrinterNames( list<string> enable_names ) ``{
    
    y2debug( "System printers are: %1", system_printers );
    y2debug( "Enable: %1", enable_names );
    
    // first, check, if we can use [printers]
    boolean printers = true;
    if (system_printers != nil) {	
	foreach( string name, system_printers, ``{
	    // each system printer must be enabled and not disabled
	    if( (printer_status[name]:false) && !contains( enable_names, name ) ) {
		printers = false;
		y2debug( "[printers] can't be used, because of %1", name );
	    }
	});
    }
    
    enableShare( "printers", printers );
    // if we can use [printers]
    if( printers ) {
	// filter out printers enabled by [printers]
	enable_names = filter( string name, enable_names, ``( !contains( system_printers, name ) ) );
	// remove yast-defined shares
	shares = filter( string name, map<string,any> options, shares, ``( ! (options["yast"]:false) ) );
    }
    
    // update the status of these printers
    if (system_printers != nil) {
	foreach( string name, system_printers, ``{
	    printer_status[ name ] = printers;
	    // if printers are used, do not use the shares themselves
	    if( printers ) {
		enableShare( name, false );
	    }
	});
    }
    
    // work on enable_names
    y2debug( "Now need to work on %1", enable_names );
    foreach( string name, enable_names, ``{
	if( haskey( shares, name ) ) {
	    if( shares[name, "printable"]:false == true ) {
		printer_status[ name ] = true;
		enableShare( name, true );
		y2debug( "Enabling printer %1", name );
	    }
	    else 
	    {
		// a share with the same name, but without printable!!!
		y2error( "Share '%1' is not printable: %2", name, shares[name]:$[] );
		// translators: error message. There is a given share, but configured differently
		Report::Error( sformat( _("There is already a share '%1',
but it is not configured
as a printer.\n
YaST2 will not modify this share."), name ) );
	    }
	}
	else 
	{
	    y2debug( "Adding a share for printer %1", name );
	    // no share, create one
	    shares[ name ] = eval(default_printer_share);
	    printer_status[ name ] = true;
	    enableShare( name, true );
	}
    });
    
    modified = true;
}

/**
 * Are some of the system printers enabled?
 *
 * @return boolean	true if yes
 */
global define boolean SystemPrintersEnabled() ``{
    boolean result = false;
    if (system_printers != nil) {
	foreach( string printer, system_printers, ``{
	    if( printer_status[ printer ]:false ) result = true;
        });
    }
    
    return result;
}

removeShare() {
    ...
// update the printer lists
//    if( haskey( printer_status, name ) ) printer_status = remove( printer_status, name );

    ...
}

enableShare() {
    ...
    // [printers] is coupled with "load printers"
    if( name == "printers" ) 
	global_config["load printers"] = on;

    ...
}
