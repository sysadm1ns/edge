### Often used procs ###
proc isnumber {num} {
 if {$num==""} { return 0 }
 return [string is digit $num]
}

proc net:tcl {tcl} {
 global glbtclcmd
 set glbtclcmd "$tcl"
 dothetcl
}

proc dothetcl {} {
 uplevel #0 {
  global glbtclcmd
  catch $glbtclcmd tclresult
 }
 set glbtclcmd ""
}

proc getnonopped {chan} {
 global botnick
 if {![onchan $botnick $chan]} { return 0 }
 set nicks ""
 foreach anick [chanlist $chan] {
  if {![isop $anick $chan] && $botnick != $anick} { lappend nicks $anick  }
 }
 return $nicks
}

proc isperm {hand} {
 global owner
 set o [string tolower $owner]
 set hand [string tolower $hand]
 if {[lsearch [split $o] $hand]>-1} { return 1 } else { return 0 }
}

proc getopped {chan} {
#returns unkonwn ops.
 global botnick
 if {![onchan $botnick $chan]} { return 0 }
 set nicks ""
 set chanlist [chanlist $chan]
 foreach anick $chanlist {
  set hand [nick2hand $anick]
  set iso [expr [matchattr $hand b] + [matchattr $hand o|o $chan]]
  if {[isop $anick $chan] && $botnick != $anick && $iso == 0} { lappend nicks $anick  }
 }
 return $nicks
}

proc getnonvoiced {chan} {
 global botnick
 if {![onchan $botnick $chan]} { return 0 }
 set nicks ""
 foreach anick [chanlist $chan] {
  if {![isvoice $anick $chan] && $botnick != $anick} { lappend nicks $anick  }
 }
 return $nicks
}

proc shto {text {idx ""}} {
 if {$idx!=""} { putidx $idx $text } else { putlog $text }
}

proc getvoiced {chan} {
 global botnick
 if {![onchan $botnick $chan]} { return 0 }
 set nicks ""
 foreach anick [chanlist $chan] {
  if {[isvoice $anick $chan] && $botnick != $anick} { lappend nicks $anick  }
 }
 return $nicks
}

proc fstring {text length} {
 if {[isnumber $length]} {
  if {[string length $text] == $length || [string length $text] > $length} {
   return "[string range $text 0 [expr $length - 1]]"
  } else {
   set a [string length $text]
   set b $text
   while {$a < $length} {
    set b "$b "
    incr a
   }
  return "$b"
  }
 }
}

proc splitirchost {host} {
 #input nick!ident@host
 #output nick ident host
 set nickend [string first "!" $host]
 set identend [string first "@" $host]
 set nick [string range $host 0 [expr $nickend - 1]]
 set ident [string range $host [expr $nickend + 1] [expr $identend - 1]]
 set host [string range $host [expr $identend + 1] end]

 lappend res $nick
 lappend res $ident
 lappend res $host
 return $res
}

proc getunknown {chan} {
 global botnick
 if {![onchan $botnick $chan]} { return 0 }
 set nicks ""
 foreach anick [chanlist $chan] {
  if {[nick2hand $anick] == "*" && $botnick != $anick} { lappend nicks $anick  }
 }
 return $nicks
}

proc randstring {length} {
 set randstr ""
 for {set x 0} {$x < $length} {incr x} { append randstr [string index "abcdefgVWXhijklm345nopqNOPQRrstuvwxyzABCDEFGHIJKLMSTUYZ1267890" [rand 62]] }
 return $randstr
}

proc getnohits {proc} { set a [binds $proc] ; foreach g [split $a " "] {lappend h $g} ;return [lindex $h 3] }

proc ctcpr {nick type text} {
putserv "NOTICE $nick :\001$type $text\001"
}

proc req {hand flag {chan ""}} {
 if {![validchan $chan]} { set chan "" }
 if {$chan != ""} { set res [matchattr $hand $flag|$flag $chan] } else { set res [matchattr $hand $flag] }
 if {$res==0} { putlog "User dont have access to that command!" }
 return $res
#To use : if {![req o]} { return 0 }
}

proc edge:join {chan {key ""} {delay "0"}} {
 set chan [lindex [split $chan] 0]
 putloglev 6 * "CHAN = $chan"
 set k ""
 if {$delay > 0} {
	utimer $delay "do:join $chan $key"
} else {
	do:join $chan $key
}
}

proc edge:part {chan {delay ""}} {
 set chan [lindex [split $chan] 0]
 if {$chan == "" || ![validchan $chan]} { return 0 }
 if {$delay == ""} { set delay 0 }
 if {![isdynamic $chan]} { putlog "$chan is not dynamic, cannot remove." ; return 0 }
 if {$delay!=0} { utimer $delay "do:part $chan $key" } else { do:part $chan }
}

proc do:part {chan} {
 set chan [lindex [split $chan] 0]
 if {[validchan $chan]} { channel remove $chan }
}

proc do:join {chan {key ""}} {
 set chan [lindex [split $chan] 0]
 if {![validchan $chan]} {
  channel add $chan
  if {$key!=""} { putserv "JOIN $chan $key" }
 }
}

proc timer:em {m h d mm y} {
 global edge edgeops
 if {$edge(alimit)==1} {
  foreach chan [channels] {
   if {[string match "*+alimit*" [channel info $chan]]} {
    set rand [rand 20]
    utimer $rand "edge:alimit:check $chan"
   }
  }
 }
 if {$m == 30} {
  foreach chan [channels] { set edgeops(req$chan) 0 }
 }
 if {$edge(limbo)!=1} {
  foreach c [channels] { if {![botonchan $c] && [lsearch [channel info $c] +inactive]==-1} { putserv "WHO $c" } }
 }
}

proc banner {{idx ""}} {
 if {![file exists banner]} { return 0 }
 set fs [open banner r] 
 while {![eof $fs]} { 
  gets $fs line 
  if {$idx != ""} { putidx $idx $line } else { putlog $line }
 }
}

##Done often used procs ##