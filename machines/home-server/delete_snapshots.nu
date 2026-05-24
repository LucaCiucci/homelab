#!/usr/bin/env nu

let ssd = "/mnt/rpi-data"
let snapshots_dir = $ssd | path join .snapshots

let snapshots_to_delete = ls $snapshots_dir
    | get name
    | sort
    | input list --multi

if $snapshots_to_delete == null {
    print "No snapshots to delete."
    exit 0
}

print "The following snapshots will be deleted:"
$snapshots_to_delete | print
print "Are you sure you want to delete these snapshots? (y/n)"
if (input) != "y" {
    print "Aborting snapshot deletion."
    exit 0
}

for snapshot in $snapshots_to_delete {
    sudo btrfs subvolume delete $snapshot
}
