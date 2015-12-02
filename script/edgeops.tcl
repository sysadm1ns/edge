#Some checks if edgeops is running as standalone
if {![info exists edge(encrypted)]} { set edge(encrypted) 0 }
if {![info exists edge(cookieenabled)]} { set edge(cookieenabled) 0 }
if {![info exists edge(autoaddhosts)]} { set edge(autoaddhosts) 0 }

if {$edge(cookieenabled)==0} {
 proc edge:op {nick chan {que "serv"} {force "0"}} {
  set msg "MODE $chan +o $nick"
  switch -exact -- $que {
  "now" { putquick $msg -next }
  "quick" { putquick $msg }
  "serv" { putserv $msg }
  "help" { puthelp $msg }
  }
 }
  if {$edge(limbo)==0} { bind join -|- * edge:ops:on:join }
  proc edge:ops:on:join {nick uhost handle chan} {
	set chan [lindex [split $chan] 0]
	edgeops:check $nick $chan $handle
  }
}

proc getoppedbots {chan} {
 set chan [lindex [split $chan] 0]
 set bots [chanlist $chan b|]
 set obots ""
 foreach b $bots { if {[islinked $b] && [isop $b $chan]} { lappend obots $b } }
 return $obots
}

proc edgeopslog {text} { putloglev 2 * "\002EdgeOps\002 $text" }

proc edgeops:check {nick chan handle} {
 if {[matchattr $handle b] && [islinked $handle]} { putebot $handle "edgeops offer op $chan" }
}

proc randomize {input} {
 if {$input == ""} { return "" }
 set x 0
 set y [llength $input]
 while {$x < $y} {
  set rand [rand [llength $input]]
  set string [split [lindex $input $rand]]
  lappend output $string
  regsub -all "$string" $input "" input
  incr x 1
 }
 return "$output"
}

proc putedgebot {chan text} {
 set bots ""
 foreach b [getoppedbots $chan] {
  if {[islinked $b]} { lappend bots $b }
 }
 if {$bots==""} { return 0 }
 set bot [lindex $bots [rand [llength $bots]]]
 putebot $bot $text
 return $bot
}

proc putebot {bot text} {
 global edge
 if {$edge(encrypted)==0 || [matchattr $bot E]} {
  putbot $bot $text
 } else {
  dcc_encrypt $bot $text
 }
}

proc putebots {text} {
 global edge
 if {$edge(encrypted)==1} {
  foreach b [bots] { dcc_encrypt $b $text }
 } else {
  putallbots $text
 }
}

bind link - * edge:check:on:link
proc edge:check:on:link {bot via} { edge:check:chan:needs }

proc edge:check:chan:needs {} {
	foreach chan [channels] {
		if {![botonchan $chan]} { putserv "JOIN $chan" } ; #Then eggdrop will request whatever it needs (invite, key, unban, limit)
		if {[botonchan $chan] && ![botisop $chan]} { edge:system:need $chan op }
	}
}

proc edge:system:need {chan type} {
set chan [lindex [split $chan] 0]
global edgeops botnick
 if {![validchan $chan]} { return 0 }
 if {![info exists edgeops(req$chan)]} { set edgeops(req$chan) 0 }
 incr edgeops(req$chan)
 if {$edgeops(req$chan)==20} {edgeopslog "Halting further requests for $chan"}
 if {![string match "*unset edgeops(req$chan)*" [utimers]]} { utimer 15 "catch { unset edgeops(req$chan) }" }
 if {$edgeops(req$chan)>20} { return 0 }
#Description: this bind is triggered on certain events, like when the bot needs operator status 
#or the key for a channel. 
#The types are: op, unban, invite, limit, and key; the mask is 
#matched against '#channel type' and can contain wildcards. flags are ignored.
 
 #If more than 20 requests have been sent in 30mins, halt until var is reset.
 if {$type=="limit" || $type=="invite" || $type=="key" || $type=="unban"} {
  putebots "edgeops req $type $chan $botnick"
  edgeopslog "Requested $type for $chan (All bots)"
 } else {
  set b [putedgebot $chan "edgeops req $type $chan $botnick"]
  if {$b != 0} { edgeopslog "Requested $type for $chan from $b" }
 }
# if {$type != "op" && $type != "key" && ![info exist edgeops(RELAX$chan)]} { utimer 3 "putserv \"JOIN $chan\"" ; lappend edge(relax) $chan ; if {![string match "*edgeops(RELAX$chan)*" [timers]]} { timer 5 "catch { unset edgeops(RELAX$chan) }" } }
#Uncommenting causes hammering.
}

proc edge:fast:op {chan b} {
set chan [lindex [split $chan] 0]
 foreach bot [chanlist $chan b|] {
  if {![isop $bot $chan]} { edge:op $bot $chan "quick" }
 }
}

proc rset:tmp:offer:var {chan} {
set chan [lindex [split $chan] 0]
 global edge edgeops
 catch { unset edgeops(offerop$chan) }
 catch { unset edgeops(offerkey$chan) }
 catch { unset edgeops(offerinvite$chan) }
 catch { unset edgeops(offerlimit$chan) }
}

 if {$edge(limbo)==0} { bind kick - * edgeops:check:me:kicked }
 proc edgeops:check:me:kicked {knick uhost handle chan target reason} {
  global nick
  if {$nick == $nick} { rset:tmp:offer:var $chan }
 }

proc edge:botop:mode {nick uhost handle chan mode victim} {
set chan [lindex [split $chan] 0]
 global botnick
 switch -exact -- $mode {
  "+o" { 
   if {[string match "*+nomanop*" [channel info $chan]]} {

    #Should allow people to op bots and only punish non-bots.
    set victimhand [nick2hand $victim]
    if {[matchattr $victimhand b]} { return 0 }

    set h [nick2hand $victim]
    if {![matchattr $handle b] && $botnick != $nick && $botnick != $victim && $botnick != $h && [onchan $nick $chan] && [isop $nick $chan]} {
     if {[llength [getoppedbots $chan]]<=1} { return 0 }
     pushmode $chan -o $nick
     pushmode $chan -o $victim
    }
   }
   if {$victim == $botnick && ![matchattr $handle b]} {
    if {[getoppedbots $chan]==""} { edge:fast:op $chan b }
   }
  }
  "-o" { 
   if {$victim == $botnick && ![matchattr $handle b]} { edge:system:need $chan op ; rset:tmp:offer:var $chan }
  }
 }
}

proc getkey {chan} {
set chan [lindex [split $chan] 0]
 if {![validchan $chan]} { return 0 }
 return [lindex [getchanmode $chan] 1]
}

proc bot:edgeops {frombot cmd arg} {
 global edgeops botnick edge {strict-host}
 if {[matchattr $frombot R]} { return 0 }
 if {$edge(encrypted)==1 && ![matchattr $frombot E]} {
  set arg [dcc_decrypt $frombot $arg]
 }
 set a1 [split $arg]
 set arg1 [lindex $a1 0]
 set arg2 [lindex $a1 1]
 set arg3 [lindex $a1 2]
 set arg4 [lindex $a1 3]

 if {![validchan $arg3]} { return 0 }
 if {![info exists edgeops($arg1$arg2$arg3)]} { set edgeops($arg1$arg2$arg3) "" }
 set ed $edgeops($arg1$arg2$arg3)
 if {![string match "*unset edgeops($arg1$arg2$arg3)*" [utimers]]} { utimer 15 "catch { unset edgeops($arg1$arg2$arg3) }" }
 if {$arg1 == "offer"} { 
  putloglev 2 * "Got $arg2 $arg1 from $frombot on $arg3"
  if {$arg2=="unban"} {
   if {![onchan $botnick $arg3] && [validchan $arg3] && $ed==""} {
    set edgeops($arg1$arg2$arg3) "$frombot"
    putebot $frombot "edgeops give $arg2 $arg3 $botnick"
    edgeopslog "Accepted unban offer from $frombot on $arg3"
   }
  }
  if {$arg2=="op"} {
   if {![botisop $arg3] && $ed==""} {
    edgeopslog "Accepting op offer from $frombot on $arg3"
    set edgeops($arg1$arg2$arg3) "$frombot"
    putebot $frombot "edgeops give $arg2 $arg3 $botnick"
   } else {
    putloglev 2 * "no-need-for Op offer from $frombot on $arg3 ([botisop $arg3] - $ed)"
    utimer 10 "catch { unset edgeops($arg1$arg2$arg3) }"
   }
  }
  if {$arg2=="invite" || $arg2=="limit"} {
   if {![onchan $botnick $arg3] && [validchan $arg3] && $ed==""} {
    set edgeops($arg1$arg2$arg3) "$frombot"
    putebot $frombot "edgeops give $arg2 $arg3 $botnick"
    edgeopslog "Accepted $arg2 offer from $frombot on $arg3"
   }
  }
  if {$arg2=="key"} {
   if {![onchan $botnick $arg3] && [validchan $arg3]} {
    putserv "JOIN $arg3 $arg4"
   }
  }
 }
 if {$arg1 == "cancel"} { catch { unset edgeops(req$arg2$arg3) } }
 if {![validchan $arg3]} { return 0 }
 if {$arg1 == "give"} {
  if {![botisop $arg3]} { putebot $frombot "edgeops cancel $arg2 $arg3" ; return 0 }
  if {$arg2 == "op"} { edge:op $arg4 $arg3 quick }
  if {$arg2 == "limit"} { putquick "MODE $arg3 -l" }
  if {$arg2 == "invite"} { putquick "INVITE $arg4 $arg3" }
  if {$arg2 == "unban"} {
   foreach ban [chanbans $arg3] {
   set ban [lindex $ban 0]
    if {[string match $ban $arg4![getchanhost $arg4]]} {
     pushmode $arg3 -b $ban
    }
   }
  }
  if {$frombot != $arg4} { set er "(Using nick $arg4)" } else { set er "" }
  edgeopslog "Gave $arg2 to $frombot@$arg3 $er"
 }
 if {$arg1 == "req"} {
  #arg2 = type
  #arg3 = chan
  #arg4 = currentnick
  if {[onchan $arg4]} {
  #checking hosts if nick is on a channel with me, if not lets just hope hosts matches.
   if {[nick2hand $arg4] != $frombot} {
    if {$edge(autoaddhosts) && $arg4 != "" && [validuser $frombot]} {
     set h [getchanhost $arg4]
     if {[string index $h 0]=="~"} {
      if {${strict-host}==0} {
	      set h [string range $h 1 end]
      }
     }
     set newhost $arg4!$h

     if {![info exists edge(deloldhost)]} { set edge(deloldhost) 0 }

     if {$edge(deloldhost)} {
	foreach h [gethosts $frombot] { delhost $frombot $h }
     }

     addhost $frombot $newhost
     putlog "\[\002Edgeops\002\] Added host $newhost to $frombot"
    } else {
     putlog "$frombot wants to get $arg2 on $arg3 - but host of $arg4 dont match its handle. ($frombot != [nick2hand $arg4])"
     return 0
    }
   }
  }
  if {$arg2 != "key"} { 
   if {![botisop $arg3]} { return 0 }
   putebot $frombot "edgeops offer $arg2 $arg3"
   edgeopslog "Offered $frombot $arg on $arg3"
  }
  if {$arg2 == "key"} { if {[botonchan $arg3]} { putebot $frombot "edgeops offer key $arg3 [getkey $arg3]" } }
 }
}