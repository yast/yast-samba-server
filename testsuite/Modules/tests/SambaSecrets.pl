#!/usr/bin/perl

use SambaSecrets;
use Data::Dumper;

## fake modules
#sub SCR::Read { shift; print "SCR::Read(",join(", ", @_),")\n"; return $read;}
#sub SCR::Execute { shift; print "SCR::Execute(",join(", ", @_),")\n";return $exec;}
sub SCR::Read { return $read;}
sub SCR::Execute { return $exec;}

$secret="{\nkey = \"x\"\ndata = \"ok\"\n}\n{\nkey = \"SECRETS/\$DOMTRUST.ACC/BAMBUS\"\ndata = \"\\01\\01\\00\\00\\00\"\n}\n{\nkey = \"SECRETS/LDAP_BIND_PW/abc\"\ndata = \"ok\\00\"\n}\n";
$secret_corrupted="{\ndata = \"\\01\"\n}\n";

## Read()
$read = undef;
print Dumper(!SambaSecrets->Read());

$read = {};
print Dumper(!SambaSecrets->Read());

$read = {size=>8};
$exec = undef;
print Dumper(!SambaSecrets->Read());

$read = {size=>8};
$exec = {exit => 256};
print Dumper(!SambaSecrets->Read());

$read = {size=>8};
$exec = {exit => 0, stdout=>$secret_corrupted};
print Dumper(!SambaSecrets->Read());

$read = {size=>8};
$exec = {exit => 0, stdout=>$secret};
print Dumper(SambaSecrets->Read());

$read = {size=>8};
$exec = {exit => 0, stdout=>$secret};
print Dumper(SambaSecrets->Read());

print Dumper($SambaSecrets::Secrets);

## GetKey()
$SambaSecrets::Secrets = undef;
$read = undef;
print Dumper(!SambaSecrets->GetKey("x"));

$SambaSecrets::Secrets = undef;
$read = {size=>8};
$exec = {exit => 0, stdout=>$secret};
print Dumper(SambaSecrets->GetKey("x"));
print Dumper(SambaSecrets->GetKey("x"));


## GetLDAPBindPw()
$SambaSecrets::Secrets = undef;
$read = undef;
print Dumper(!SambaSecrets->GetLDAPBindPw("abc"));

$SambaSecrets::Secrets = undef;
$read = {size=>8};
$exec = {exit => 0, stdout=>$secret};
print Dumper(SambaSecrets->GetLDAPBindPw("abc"));

print Dumper(!SambaSecrets->GetLDAPBindPw("xyz"));

## GetTrustedDomains
$SambaSecrets::Secrets = undef;
$read = undef;
print Dumper(!SambaSecrets->GetTrustedDomains());

$SambaSecrets::Secrets = undef;
$read = {size=>8};
$exec = {exit => 0, stdout=>$secret};
print Dumper(SambaSecrets->GetTrustedDomains());
print Dumper(SambaSecrets->GetTrustedDomains());


## WriteLDAPBindPw()
$exec = undef;
print Dumper(!SambaSecrets->WriteLDAPBindPw());

$exec = {exit => 1, stderr => "error"};
print Dumper(!SambaSecrets->WriteLDAPBindPw("secret"));

$exec = {exit => 0};
print Dumper(SambaSecrets->WriteLDAPBindPw("secret"));

