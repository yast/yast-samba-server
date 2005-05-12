#!/usr/bin/perl

use SambaService;
use Data::Dumper;

## test agent
=x
use YaST::YCP qw(:DATA);
YaST::YCP::Import("Testsuite");
my $r_ok = {target=>{tmpdir=>"/tmp"}};
my $w_ok = {target=>{string=>Boolean(1)}};
my $w_err = {target=>{string=>Boolean(0)}};
my $e_err = {target=>{bash=>8, remove=>8, bash_output=>{exit=>8}}};
my $e_ok = {target=>{bash=>0, remove=>0, bash_output=>{exit=>0}}};
=cut
=disable
## fake modules
sub Service::Enabled {$enabled}
sub Service::Status {$status}
sub Service::Start {print "Service->Start($_[1])\n"; $start}
sub Service::Stop {print "Service->Stop($_[1])\n"; $stop}
sub Service::RunInitScript {print "Service->RunInitScript($_[1], $_[2])\n"; $restart}
sub Service::Adjust {print "Service->Adjust($_[1], $_[2])\n"; $adjust}


## Export/Import()
SambaService->Import();
print Dumper(
    SambaService->Export(),
    !SambaService->GetModified());

SambaService->Import("Enabled");
print Dumper(
    SambaService->Export(),
    !SambaService->GetModified());

SambaService->Import("Off");
print Dumper(
    SambaService->Export(),
    !SambaService->GetModified());


## Set/GetServiceAutostart(); GetModified()
$SambaService::Modified=0;
$SambaService::Service=0;
SambaService->SetServiceAutoStart(); # undef => ON
print Dumper(
    SambaService->GetServiceAutoStart(),
    SambaService->GetModified());

$SambaService::Modified=0;
$SambaService::Service=0;
SambaService->SetServiceAutoStart(0);
print Dumper(
    !SambaService->GetServiceAutoStart(),
    !SambaService->GetModified());

$SambaService::Modified=0;
$SambaService::Service=1;
SambaService->SetServiceAutoStart(0);
print Dumper(
    !SambaService->GetServiceAutoStart(),
    SambaService->GetModified());

$SambaService::Modified=0;
$SambaService::Service=1;
SambaService->SetServiceAutoStart(1);
print Dumper(
    SambaService->GetServiceAutoStart(),
    !SambaService->GetModified());


## Read()/Write()
$SambaService::Modified=1;
$enabled = 0;
print Dumper(
    SambaService->Read(),
    !SambaService->GetModified(),
    !SambaService->GetServiceAutoStart());
    
$SambaService::Modified=1;
$SambaService::Service=1;
$adjust = 1;
print Dumper(
    SambaService->Write(),
    !SambaService->GetModified());

$SambaService::Modified=0;
print Dumper(SambaService->Write());

$SambaService::Modified=1;
$SambaService::Service=0;
$adjust = 0;
print Dumper(!SambaService->Write());


## StartStopNow()
$status = 1;
$start = 0;
print Dumper(!SambaService->StartStopNow(1));

$status = 1;
$start = 1;
print Dumper(SambaService->StartStopNow(1));

$status = 0;
$restart = 0;
print Dumper(!SambaService->StartStopNow(1));

$status = 0;
$restart = 1;
print Dumper(SambaService->StartStopNow(1));

$status = 0;
$stop = 0;
print Dumper(!SambaService->StartStopNow(0));

$status = 0;
$stop = 1;
print Dumper(SambaService->StartStopNow(0));

$status = 1;
print Dumper(SambaService->StartStopNow(0));
