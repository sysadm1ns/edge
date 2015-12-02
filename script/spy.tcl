#spy.tcl :D
#.spy on id
#.spy off \[id\]


bind dcc n|- spy dcc:spy

proc dcc:spy {h i a} {
 global edgespy
 if {![isperm $h]} { putidx $i "What?  You need '.help'" ; return 0 }
 set action [join [lindex [split $a] 0]]
 set arg [join [lindex [split $a] 1]]
 switch -exact -- $action {
  "on" {
   if {![isnumber $arg] || ![valididx $arg]} { putidx $i "Usage .spy on idx" ; return 0 }
   set edgespy($arg) $i
   putidx $i "Added your spy for $arg"
  }
  "off" {
   if {[isnumber $arg]} {
    catch { unset edgespy($arg) }
    putidx $i "Removed spy for $arg"
   } else {
    edge:kill:spy $i
    putidx $i "Removed all spys for your idx"
   }
  }
  "default" {
  
  }
 }
}

proc edge:kill:spy {idx} {
 global edgespy
 set names [array names edgespy]
 foreach name $names {
  if {$edgespy($name) == $idx} { array unset edgespy $name }
 }
}

bind filt - * edge:spy:filt

proc edge:spy:filt {i text} {
 global edgespy
 if {[info exists edgespy($i)]} {
  if {![valididx $edgespy($i)]} {
   unset edgespy($i)
  } else {
   putidx $edgespy($i) "\[SPY\] ($i) $text"
  }
 }
 return $text
}

bind chof - * edge:spy:cleanup
proc edge:spy:cleanup {h i} { edge:kill:spy $i }
