#!/usr/bin/perl

use SambaRole;
use Data::Dumper;

use SambaConfig;

## fake modules
sub SambaBackend::UpdateScripts {print "SambaBackend::UpdateScripts()\n"}
sub SambaBackend::RemoveScripts {print "SambaBackend::RemoveScripts()\n"}
sub SCR::Execute {print "Execute($_[1], $_[2])\n"; return $exec}

## SetAsPDC() + getLocalSID()
$exec = undef;
SambaConfig->Import({global=>{"os level"=>100, "workgroup"=>"TUX-NET"}});
SambaRole->SetRole("PDC");
SambaConfig->Dump();

$exec = {exit=>8};
SambaConfig->Import({global=>{"os level"=>10, "netbios name"=>"mr. tux"}});
SambaRole->SetRole("PDC");
SambaConfig->Dump();

SambaConfig->Import({global=>{"os level"=>10, "netbios name"=>"mr. tux"}});
$exec = {stdout=>"fake output text", exit=>1, stderr=>"error"};
print Dumper(!SambaRole::getLocalSID());

SambaConfig->Import({global=>{"os level"=>10, "netbios name"=>"mr. tux"}});
$exec = {stdout=>"fake bad stdout"};
print Dumper(!SambaRole::getLocalSID());

SambaConfig->Import({global=>{"os level"=>10, "netbios name"=>"mr. tux"}});
$exec = {stdout=>"SID for domain HUHU is: XYZ-345"};
print Dumper(SambaRole::getLocalSID() eq "XYZ-345");


## SetAsBDC() + getSID()
$exec = undef;
SambaConfig->Import({global=>{"os level"=>100, "password server"=>"tux", "local master"=>"Yes"}});
SambaRole->SetRole("BDC");
SambaConfig->Dump();

SambaConfig->Import({global=>{"workgroup"=>"TUX-NET", "netbios name"=>"mr. tux"}});
$exec = {stdout=>"Storing SID 1234-ABC for Domain"};
print Dumper(SambaRole::getSID() eq "1234-ABC");

SambaConfig->Import({global=>{"workgroup"=>"TUX-NET", "netbios name"=>"mr. tux"}});
$exec = {stdout=>"Storing SID 1234-ABC for Domain", exit=>1, stderr=>"error"};
print Dumper(!SambaRole::getSID());

SambaConfig->Import({global=>{"workgroup"=>"TUX-NET"}});
$exec = {stdout=>"fake bad output text"};
print Dumper(!SambaRole::getSID());

SambaConfig->Import({global=>{"workgroup"=>"TUX-NET"}});
$exec = {exit=>1};
print Dumper(!SambaRole::getSID());


## SetAsStandalone()
SambaConfig->Import({global=>{"os level"=>100, "password server"=>"tux", "local master"=>"Yes"},netlogon=>{comment=>"a comment"}});
SambaRole->SetRole("Standalone");
SambaConfig->Dump();

## SetAsMember()
SambaConfig->Import({global=>{"os level"=>100, "password server"=>"tux", "local master"=>"Yes"}});
SambaRole->SetRole("Member");
SambaConfig->Dump();

## bad role name
SambaRole->SetRole("bad role");
SambaRole->SetRole();

## GetRole()/GetRoleName()
SambaConfig->Import();
print Dumper(SambaRole->GetRole() eq "STANDALONE");

SambaConfig->Import({global=>{security=>"bad security"}});
print Dumper(SambaRole->GetRole() eq "STANDALONE");

SambaConfig->Import({global=>{security=>"USER", "domain logons"=>1}});
print Dumper(SambaRole->GetRole() eq "PDC");

SambaConfig->Import({global=>{security=>"USER", "domain logons"=>1, "domain master"=>"No"}});
print Dumper(SambaRole->GetRole() eq "BDC");

SambaConfig->Import({global=>{security=>"SHARE"}});
print Dumper(SambaRole->GetRole() eq "STANDALONE");

SambaConfig->Import({global=>{security=>"SERVER"}});
print Dumper(SambaRole->GetRole() eq "MEMBER");

SambaConfig->Import({global=>{security=>"DOMAIN"}});
print Dumper(SambaRole->GetRole() eq "MEMBER");

SambaConfig->Import({global=>{security=>"DOMAIN", "domain logons"=>"Yes"}});
print Dumper(SambaRole->GetRole() eq "BDC");

SambaConfig->Import({global=>{security=>"ADS", "domain logons"=>"Yes"}});
print Dumper(SambaRole->GetRole() eq "PDC");

SambaConfig->Import({global=>{security=>"ADS", "domain logons"=>"No"}});
print Dumper(SambaRole->GetRole() eq "MEMBER");

SambaConfig->Import({global=>{security=>"ADS", "domain logons"=>"No"}});
print Dumper(SambaRole->GetRoleName());

