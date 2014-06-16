#!/usr/bin/perl

use strict;

my $cli = '/u01/app/oracle/ovm-manager-3/ovm_cli/expectscripts/eovmcli admin OVMadminPassword';

my (%phydsk, %vm, %phydskvms);

foreach my $line (`$cli "list physicalDisk"`)
{	#  id:0004fb00001800005120a342f2e5e61b  name:dtv-clc2-fra1
	next if  $line !~ /\s+id:(\S+)\s+name:(\S+)$/ ;
	$phydsk{$1}=$2;
}
die "No physical disks found\n" unless %phydsk;

foreach my $line (`$cli "list vm"`)
{	#  id:0004fb00000600007ea7a06224d83172  name:dtv-otmapp1
	next if  $line !~ /\s+id:(\S+)\s+name:(\S+)$/ ;
	$vm{$1}=$2;
}
die "No virtual machines found\n" unless %phydsk;

print "Collected physical disks list and vms list.\n";
print "Pulling list of disks for each vm...\n";
for my $vmid (keys %vm)
{	my $disks;
	foreach my $line (`$cli "show vm id=$vmid"`)
	{	#  VmDiskMapping 1 = 0004fb0000130000a82385bb78d8c5b4
		next if  $line !~ /\s+VmDiskMapping \d+ = (\S+)$/i ;
		$disks++;
		
		foreach my $linem (`$cli "show vmdiskMapping id=$1"`)
		{	#  Virtual Disk Id = 0004fb00001800000ff01c26b6307261  [ddv-otmapp1_20140610083323_20140611053043_20140612101118]
			next if  $linem !~ /\s+Virtual Disk Id = (\S+)\s+/i ;
			printf "$vm{$vmid}: %s disk id $1 found.\n", ($phydsk{$1} ? 'physical':'virtual');
			push @{ $phydskvms{$1} }, $vm{$vmid}  if $phydsk{$1};
		}
		
	}
	print "WARN: No disks found for vm $vm{$vmid}\n" unless $disks;
}

print "Report of physical disks usage by vms:\n";
foreach my $id (keys %phydsk)
{	print "Disk id=$id name=$phydsk{$id}:\n";
	my $vms = $phydskvms{$id} ? join(', ', @{ $phydskvms{$id} } ) : 'NO Vms assigned';
	print "        $vms\n";
}

