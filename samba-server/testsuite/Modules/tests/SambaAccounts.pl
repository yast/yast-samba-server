#!/usr/bin/perl

use SambaAccounts;
use Data::Dumper;

## test agent
use YaST::YCP qw(:DATA);
YaST::YCP::Import("Testsuite");
my $r_ok = {target=>{tmpdir=>"/tmp"}};
my $w_ok = {target=>{string=>Boolean(1)}};
my $w_err = {target=>{string=>Boolean(0)}};
my $e_err = {target=>{bash=>8, remove=>8, bash_output=>{exit=>8}}};
my $e_ok = {target=>{bash=>0, remove=>0, bash_output=>{exit=>0}}};

## fake modules
sub Mode::autoinst {$autoinst}


## Import()/Export()
SambaAccounts->Import([{user=>"gizo", lmhash=>"lmsecret",nthash=>"ntsecret"}, {user=>"tux"}, {passwd=>"bad record"}]);
foreach(@{SambaAccounts->Export()}) {
    print("user\t",($_->{user}||"<undef>"),":",($_->{lmhash}||"<undef>"),":",($_->{nthash}||"<undef>"),"\n");
}

SambaAccounts->Import();
print Dumper(SambaAccounts->Export());
print Dumper(!SambaAccounts->GetModified());


## Read()/Write()
print Dumper(SambaAccounts->Read()); # do nothing

SambaAccounts->Import([{user=>"root"},{user=>"t.u.x.",nthash=>"xxx",lmhash=>"aaa"}]);
Testsuite->Init([$r_ok, $w_err, {}],undef);
print Dumper(!SambaAccounts->Write());

Testsuite->Init([$r_ok, $w_ok, $e_err],undef);
print Dumper(!SambaAccounts->Write());

Testsuite->Init([$r_ok, $w_ok, $e_ok],undef);
print Dumper(!SambaAccounts->Write());


## UserAdd()/UserExists()
SambaAccounts->UserAdd("tux", "xut");

$autoinst=1;
print Dumper(!SambaAccounts->UserExists("e.t."));

$autoinst=0;
Testsuite->Init([{}, {}, $e_ok],undef);
print Dumper(SambaAccounts->UserExists("alf"));
print Dumper(SambaAccounts->UserExists("alf"));

