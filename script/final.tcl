source $edge(serverfile)

if {[file exists "custom.tcl"]} { source custom.tcl }

if {$server == "" && $edge(limbo) == 0} {
 set bserv [join [lindex [split [lindex $servers [rand [llength $servers]]] ":"] 0]]
 putlog "Not online, jumping to random server ($bserv)"
 jump $bserv
}

if {[expr [unixtime] - $uptime]<10} { banner }

if {[info exists edge(oldbuild)]} {
 putlog "Update from $edge(oldbuild) detected, run .changelog $edge(oldbuild) to see changes"
 unset edge(oldbuild)
}
