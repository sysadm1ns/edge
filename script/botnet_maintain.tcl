proc checkhub {} {
 global edge
 set hubname [join [lindex [split $edge(myhub)] 0]]
 set hubip [join [lindex [split $edge(myhub)] 1]]
 set hubport [join [lindex [split $edge(myhub)] 2]]
 set hubhost [join [lindex [split $edge(myhub)] 3]]

 if {$hubname != ""} {
  if {![validuser $hubname]} {
   putlog "$hubname is unknown to me, and set as hub in edge.conf - Adding"
   addbot $hubname $hubip:$hubport/$hubport
   chattr $hubname +fo
   botattr $hubname +ghp
   if {$hubhost != ""} { addhost $hubname $hubhost }
  }

  if {![islinked $hubname] && ![string match -nocase $edge(nick) $hubname]} {
   putlog "Attempting to link $hubname"
   link $hubname
  }
 }
}
