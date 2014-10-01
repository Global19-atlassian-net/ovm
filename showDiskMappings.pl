#!/usr/bin/perl

use strict;

my $cli = '/u01/app/oracle/ovm-manager-3/ovm_cli/expectscripts/eovmcli admin adminPassword';

#List of regexps to ignore some of the physical disks, that normally do not belong to a VM
# (physical boot LUNs, repository LUNs, server pool LUNs):
my @ignoredDisks = qw(lun_OVMprod_dpp-f1-ovms\d+_boot lun_OVMprod_PoolStore lun_OVMprod_RepoStore\d+);

################################# You most likely don't need changes below.


my (%phydsk, %vm, %phydskvms);

foreach my $line (`$cli "list physicalDisk"`)
{	#  id:0004fb00001800005120a342f2e5e61b  name:dtv-clc2-fra1
	next if  $line !~ /\s+id:(\S+)\s+name:(.+?)$/ ;
	$phydsk{$1}=$2;
}
die "No physical disks found\n" unless %phydsk;
printf "%d physical disks found\n", scalar keys %phydsk;

foreach my $line (`$cli "list vm"`)
{	#  id:0004fb00000600007ea7a06224d83172  name:dtv-otmapp1
	next if  $line !~ /\s+id:(\S+)\s+name:(.+?)$/ ;
	$vm{$1}=$2;
}
die "No virtual machines found\n" unless %vm;
printf "%d virtual machines found\n", scalar keys %vm;

print "Pulling list of disk mappings for each vm...\n";
foreach my $vmid (sort {$vm{$a} cmp $vm{$b}} keys %vm)
{	my $disks;
	foreach my $line (`$cli "show vm id=$vmid"`)
	{	#  VmDiskMapping 1 = 0004fb0000130000a82385bb78d8c5b4
		next if  $line !~ /\s+VmDiskMapping \d+ = (\S+)/i ;
		$disks++;
		
		foreach my $linem (`$cli "show vmdiskMapping id=$1"`)
		{	#  Virtual Disk Id = 0004fb00001800000ff01c26b6307261  [ddv-otmapp1_20140610083323_20140611053043_20140612101118]
			next if  $linem !~ /\s+Virtual Disk Id = (\S+)\s+/i ;
			printf "$vm{$vmid}\t\t: %s disk id $1 found.\n", ($phydsk{$1} ? 'physical':'virtual');
			push @{ $phydskvms{$1} }, $vm{$vmid}  if $phydsk{$1};
		}
		
	}
	print "WARN: No disks found for vm $vm{$vmid}\n" unless $disks;
}

print "\nReport of physical disks usage by vms:\n";
DSK: foreach my $id (sort {$phydsk{$a} cmp $phydsk{$b}} keys %phydsk)
{	my $name = $phydsk{$id};
	foreach my $re (@ignoredDisks)
	{	next DSK if $name =~ /^$re$/	}

	print "Disk $name id=$id:";
	print $phydskvms{$id} ?   "\t\t". join(', ', @{ $phydskvms{$id} } ) : "\n\t\t*** NO Vms assigned";
	print "\n";
}

exit;

## check for script updates at https://github.com/Tagar/ovm 

