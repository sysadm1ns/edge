proc edge:msg:op {nick uhost handle arg} {
 global botnick edge
 if {[info exists edge(nomsgop)]} { if {$edge(nomsgop) == 1} { putlog "$nick tryied to msg op (Disabled)" ; return 0 } }
 set a1 [split $arg]
 set arg1 [lindex $a1 0]
 if {![passwdok $handle $arg1]} {
  putcmdlog "#$nick!$uhost ($handle)# Failed op (Invalid pass)"
  return 0
 }
 if {[validchan $arg1]} {
  set chan [lindex $arg1]
  set iso [matchattr $handle o|o $chan]
  if {[isop $botnick $chan] && ![isop $nick $chan] && $iso != 0 && [onchan $nick $chan]} { edge:op $nick $chan quick }
  putcmdlog "#$handle# MSG OP (Chan only - $chan)"
  return 0
 }
  set chans ""
  foreach chan [channels] {
  set iso [matchattr $handle o|o $chan]
  if {[isop $botnick $chan] && ![isop $nick $chan] && $iso != 0 && [onchan $nick $chan]} {
   edge:op $nick $chan
   append chans $chan " "
  }
 }
 if {$chans==""} { set opped "Not opped in any chans." }
 if {$chans!=""} { set opped "Opped in $chans" }
 putcmdlog "#$handle# MSG OP -=- $opped"
 return 0
}