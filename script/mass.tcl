#mass.tcl

proc mass {type chan {arg ""}} {
 if {$type == "kick"} {
  putquick "MODE $chan +mi" -next
  set nicklist [getunknown $chan]
  foreach anick $nicklist { putquick "KICK $chan $anick :$arg" }
  return 0
 }
  switch -exact -- $type {
  "op" {
   set modechar "+oooo"
   set nicklist [getnonopped $chan]
  }
  "deop" {
   set modechar "-oooo"
   set nicklist [getopped $chan]
  }
  "voice" {
   set modechar "+vvvv"
   set nicklist [getnonvoiced $chan]
  }
  "devoice" {
   set modechar "-vvvv"
   set nicklist [getvoiced $chan]
  }
 }
 set dostuff ""
 set nicklist [lrange [split $nicklist] 0 end]
 foreach anick $nicklist {
  lappend dostuff $anick
  if {[lindex $dostuff 3] != ""} {
   putquick "MODE $chan $modechar $dostuff"
   set dostuff ""
  }
 }
 putquick "MODE $chan $modechar $dostuff"
}

proc dcc:mass {h i a} {
 set a [split $a]
 set type [lindex $a 0]
 set chan [lindex $a 1]
 if {![validchan $chan]} {
  putidx $i "Invalid chan $chan"
  return 0
 }
 if {![req $h n $chan]} { return 0 }

 if {![matchattr $h o|o $chan]} { putidx $i "You dont have access to that chan" ; return 0 }
 switch -exact -- $type {
  "op" {
   putcmdlog "#$h# Mass $type $chan"
   mass op $chan
  }
  "deop" {
   putcmdlog "#$h# Mass $type $chan"
   mass deop $chan
  }
  "voice" {
   putcmdlog "#$h# Mass $type $chan"
   mass voice $chan
  }
  "devoice" {
   putcmdlog "#$h# Mass $type $chan"
   mass devoice $chan
  }
  "kick" {
   set reason [lrange $a 2 end]
   putcmdlog "#$h# Mass $type $chan"
   mass kick $chan $reason
  }
  "default" {
   putidx $i "Invalid type."
   return 0
  }
 }
}