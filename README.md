ovm
===

Different scripts related to Oracle VM

1. showDiskMappings.pl reports physical disks that are not assigned to any VMs or OVM templates.
   This can happen if you deleted a VM or a templates with a physical disk; OVM wouldn't delete
   physical disks automatically (e.g. through a storage plugin like NetApp OVM plugin), neither
   Oracle VM Manager has a way to report orphaned physical disks (unlike virtual disks).
   This script solves this gap and reports physical LUNs that are not used by any of the VMs or
   templates.
