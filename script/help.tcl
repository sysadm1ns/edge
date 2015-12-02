#help.tcl 

proc help:rebind {} {
 catch { unbind dcc -|- help *dcc:help }
 catch { bind dcc -|- help edge:help }
}

set edge(help) ""

proc findcmd {type sub} {
 global edge
 set blist ""
 foreach line $edge(help) {
  if {[string tolower [lindex $line 0]] == $type && [lindex $line 3] == $sub} { lappend blist [lindex $line 2] }
 }
 return $blist
}

proc nicedis {text cols} {
 set lin ""
 set bl ""
 foreach t $text {
  if {$lin==""} { set lin [fstring $t 15] } else { set lin "$lin [fstring $t 15]" }
  if {[llength $lin]==$cols} { lappend bl "$lin" ; set lin "" }
 }
 if {$lin !=""} { lappend bl "$lin" }
 return $bl
}

proc edge:help {h i a} {
 global edge botnick
 set a [split $a]
 if {[lindex $a 0] == "egg"} { *dcc:help $h $i [lrange $a 1 end] ; return 0 }
 putcmdlog "#$h# Help $a"
 set arg1 [lindex $a 0] ; #net
 set arg2 [lindex $a 1] ; #join
 if {$arg2==""} { set arg2 "_" }
 if {$arg1 == ""} {
  putidx $i "## DCC"
  foreach g [nicedis [findcmd dcc "_"] 4] { putidx $i $g }
  putidx $i "## MSG"
  foreach line $edge(help) { if {[string tolower [lindex $line 0]] == "msg" && [lindex $line 3] == "_"} { putidx $i "/msg $botnick [lindex $line 5]" } }
  putidx $i "Hint: To have the help directed to egghelp even if a edge command match, use .help egg <command>"
 } else {
  set found 0
  foreach line $edge(help) {
  if {$arg2 == "_"} {
	  set v1 [lindex $line 2]
	  set v2 [lindex $line 3]
  } else {
	  set v1 [lindex $line 3]
	  set v2 [lindex $line 2]
  }
   if {[lindex $line 0]=="dcc" && $v1==$arg1 && $v2 == $arg2} {
    set found 1
    if {$arg2=="_"} { set a1 $arg1 } else { set a1 "$arg1 $arg2" }
    putidx $i "##Help for [lindex $line 0] command $a1"
    putidx $i "Access : [lindex $line 1]"
    putidx $i "Usage: [lindex $line 5]"
    putidx $i "Description : [lindex $line 4]"
    if {$arg2 == "_"} {
     set cmds [findcmd dcc [lindex $line 2]]
     if {[llength $cmds]>0} { putidx $i "Subcommands for [lindex $line 2] : $cmds" }
    }
   }
  }
 if {$found == 0} { *dcc:help $h $i $a }
 }
}

proc edge:addcmd {bind type flag sub cmd proc usage desc} {
 global edge
 if {$bind} { bind $type $flag $cmd $proc }
 lappend edge(help) "\"$type\" \"$flag\" \"$cmd\" \"$sub\" \"$usage\" \"$desc\""
}