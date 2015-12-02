#protect.tcl
#A proctect TCL for Edge :)
#Protects against bot/owner deop and TO attempts.

setudef flag protect

proc edge:protect:raw:mode {from keyword text} {
 global edgeprot
 set chan [join [lindex $text 0]]
 if {![validchan $chan]} { return 0 }
 if {![lsearch -exact [channel info $chan] +protect]} { return 0 }
 set lst [splitirchost $from]
 set nick [join [lindex $lst 0]]
 set h [nick2hand $nick]
 if {[matchattr $h n] || [matchattr $h b]} { return 0 }
 if {![info exists edgeprot($nick$chan)]} { set edgeprot($nick$chan) 0 }
 set ident [join [lindex $lst 1]]
 set host [join [lindex $lst 2]]
 set modes [join [lindex $text 1]]
 set victims [lrange $text 2 end]

putloglev 8 * " TEST:2 >> N:$nick _ [lindex $lst 0] I:$ident H:$host"

 set i 0
 while {$i < [string length $modes]} {
  set char [string range $modes $i $i]
  if {$char == "+" || $char == "-"} {
   set mchar $char
  } else {
   lappend tmodes "$mchar$char"
  }
  incr i
 }
 set i 0
 foreach m $tmodes {
  if {$m == "-o"} {
   set handle [nick2hand [join [lindex $victims $i]]]
   if {[matchattr $handle b] || [matchattr $handle n]} { incr edgeprot($nick$chan) }
   incr i
  }
 }
 if {$edgeprot($nick$chan)>3} {
  putquick "KICK $chan $nick :Not so fast, little you."
  pushmode $chan +b *!*@[join [lindex [split [maskhost [getchanhost $nick]] "@"] 1]]
  putlog "Punished $nick@$chan for deopping a bot/+n user 3 times."
 }
 if {![string match "*unset edgeprot($nick$chan)*" [utimers]]} { utimer 30 "catch { unset edgeprot($nick$chan) }" }
 return 0
}
