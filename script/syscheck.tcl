#syscheck.tcl
#
#Performs a series of tests to see if the system is ready to run.

set edge(init) [clock clicks]

if {$edge(servernet) == ""} {
 if {![file exists servers.tcl]} {
	die "You are not using a central serverlist, and theres no servers.tcl in your edge dir!"
 }
}

if {![info exists edge(conf)]} { set edge(conf) "" }
if {$edge(conf) != 9} {
die "Incompatible edge config ( $edge(conf) ), exiting."
}