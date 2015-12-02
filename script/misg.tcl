#misg.tcl - each script must be enabled before it will work.
#Only few buildtin scripts for security, please visit http://eggdrop.nirc.dk for more scripts, and add them to the correct file.
#custom.conf = loaded by all bots
#botnick.conf = loaded by one nick only.

if {$edge(alimit)} { setudef flag alimit }

edge:addcmd 1 dcc -|- "_" changelog dcc:changelog "Shows changes since that version." ".changelog <version>"
proc dcc:changelog {h i a} {
 global edge changelog
 set build [lindex $a 0]
 if {$build==""} { putidx $i "Usage is .checkupdate build (Shows changes after that build)" ; return 0 }
 set changelog(build) $build
 set changelog(idx) $i
 set sock [egghttp:geturl $edge(changelogurl)$build callback:changelog]
}

proc callback:changelog {sock} {
 global edge changelog
 set buffer [egghttp:data $sock]
 egghttp:cleanup $sock
 foreach line [split $buffer "\n"] {
   regsub -all "<>" $line "" line
   set b [lindex $line 0]
   if {[string length $b]<4} { set b "0$b" }
   putidx $changelog(idx) "\002\[Changelog\]\002 \037$b\037 : [join [lrange $line 1 end]]"
 }
}


if {![info exists edge(alimit_grace)]} { set edge(alimit_grace) 5 }
if {![info exists edge(alimit_diff)]} { set edge(alimit_diff) 10 }

if {$edge(allvoice)} {
 setudef flag allvoice
 setudef flag allop
}

edge:addcmd 1 dcc -|- "_" massadduser dcc:massadduser "Adds all users on chan with flags" ".massadduser <chan> <flags>"
edge:addcmd 1 dcc -|- "_" smalljoin dcc:smalljoin "Joins chan with x bots" ".smalljoin <chan> <bots>"

proc dcc:smalljoin {h i a} {
 set chan [join [lindex $a 0]]
 set bots [join [lindex $a 1]]
 if {![isnumber $bots]} { putidx $i "Usage .smalljoin chan numberofbots" ; return 0 }
 set b [bots]
 set tb [llength $b]
 if {$tb < $bots} { putidx $i "There aint $bots bots linked !" ; return 0 }
 if {$tb == $bots} {
  putcmdlog "#$h# smalljoin $chan $bots (All bots joining)"
  putallbots "smalljoin $h $chan"
  return 0
 }
 #select $bots random bots...
 set i 1 ; set err 0 ; set its ""
 while {$i <= $bots} {
  set ra [rand $tb]
  if {$err > 50} {
   putidx $i "Proc looped 50times without returning list of bots, could be a bug !"
   return 0
  }
  if {[lsearch $ra $its]>-1} {
	continue
	incr err
	putloglev 4 * "Skipping [lindex $b $ra]"
  } else {
	  append its "$ra "
	  incr i
	  putloglev 4 * "[lindex $b $ra] added to list"
  }
 }
 #$its contains lindex now.
 foreach id $its { putbot [lindex $b $id] "smalljoin $h $chan" }
 putcmdlog "#$h# smalljoin $chan $bots (Bots joining : [join $its])"
}

bind bot - smalljoin bot:smalljoin

proc bot:smalljoin {frombot cmd a} {
 global edge
 set hand [join [lindex $a 0]]
 set chan [join [lindex $a 1]]
 if {$edge(limbo)==1} { return 0 }
 if {![validchan $chan]} { channel add $chan }
 putlog "$hand@$frombot smalljoin $chan"
}

proc dcc:massadduser {h i2 a} {
 set chan [join [lindex $a 0]]
 set flag [join [lindex $a 1]]
 if {![validchan $chan]} { putidx $i2 "Usage .massadduser #chan o" ; return 0 }
 set i 0 ; set k 0
 foreach user [chanlist $chan] {
  if {![validuser $user]} { adduser $user [maskhost [getchanhost $user]] ; incr i}
  chattr $user |+$flag $chan
  incr k
 }
 putidx $i2 "Added $i unknown users, gave $flag to $k users"
}

proc smalljoin {h i a} {

}

proc edge:allvoiceop:onjoin {chan nick} {
 #Surposed to be called 5-10 sec after nick join.
 global edge
 if {$edge(allvoice)==0} { return 0 }

 set mode ""
 set chinfo [channel info $chan]
 if {[string match "*+allop*" $chinfo] && [string match "*+allvoice*" $chinfo]} { set mode "+vo $nick $nick" }
 if {[string match "*+allop*" $chinfo] && ![string match "*+allvoice*" $chinfo] && ![isop $nick $chan]} { set mode "+o $nick" }
 if {![string match "*+allop*" $chinfo] && [string match "*+allvoice*" $chinfo] && ![isvoice $nick $chan]} { set mode "+v $nick" }
 if {$mode != ""} { putserv "MODE $chan $mode" }
}

proc getthelimit {chan} {
 if {![validchan $chan]} { return 0 }
 set modes [getchanmode $chan]
 if {[string match "*k*" $modes]} { set pos 2 } else { set pos 1 }
 if {![string match "*l*" $modes]} { set lim 0 } else { set lim [lindex $modes $pos] }
 return $lim
}

proc edge:alimit:check {chan} {
 global edge
 if {![info exists edge(changedlimitto)]} { set edge(changedlimitto) 0 }
 if {$edge(alimit)==0} { return 0 }
 if {[string match "*+alimit*" [channel info $chan]]} {
  set curlimit [getthelimit $chan]
  set inchan [llength [chanlist $chan]]
  set wantedlimit [expr $inchan + $edge(alimit_diff)]
  set s1 [expr $wantedlimit - $edge(alimit_grace)]
  set s2 [expr $wantedlimit + $edge(alimit_grace)]
  #Just joined ?
  if {$wantedlimit == 10} { return 0 }
  #Lagged ?
  if {$edge(changedlimitto) == $wantedlimit} { return 0 }

  if {$curlimit<$s1 || $curlimit>$s2} { putserv "MODE $chan +l $wantedlimit" ; set edge(changedlimitto) $wantedlimit}
 }
}

edge:addcmd 1 dcc -|- "_" removeallbans dcc:removeallbans "Removes all bans on chan" ".removeallbans <chan>"

proc dcc:removeallbans {h i a} {
 set chan [lindex [split $a] 0]
 if {[matchattr $h $chan]} {
  foreach ban [chanbans $chan] {
   pushmode $chan -b [lindex [split $ban] 0]
  }
 }
}

edge:addcmd 1 dcc n|- "_" linkall dcc:linkallbots "Attempt to link all unlinked bots" ".linkall"
edge:addcmd 1 dcc n|- "_" unlinkall dcc:unlinkallbots "Attempt to unlink all linked bots" ".unlinkall"

proc dcc:linkallbots {h i a} {
 putcmdlog "#$h# LinkAllBots"
 do:link:all:bots
}

proc dcc:unlinkallbots {h i a} {
 putcmdlog "#$h# UNLinkAllBots"
 foreach bot [userlist b] { if {[islinked $bot]} { unlink $bot } }
}

proc do:link:all:bots {} {
 set i 0
 foreach bot [userlist b] {
  if {![islinked $bot]} {
   utimer [expr $i * 2] "link $bot"
   incr i
  }
 }
}

proc chanpredef {h i a} {
 global lastbind botnick
 set chan [join [lindex $a 0]]
 if {![validchan $chan]} { putidx $i "Bad chan name." ; return 0 }
 if {$lastbind=="chanidle" || $lastbind=="chansecure" || $lastbind=="chanown"} {
  putallbots "chanpredef $chan $lastbind"
  chanpredef:bot $botnick chanpredef $lastbind"
  dccbroadcast "#$h# $lastbind $chan"
 }
}

proc noflood {chan} {
 channel set flood-chan 0:0
 channel set flood-ctcp 0:0
 channel set flood-join 0:0
 channel set flood-kick 0:0
 channel set flood-deop 0:0
 channel set flood-nick 0:0
}

proc getuserchanlist {chan} {
 set lst ""
 foreach user [userlist] {
  set chanflags [lindex [split [chattr $user $chan] "|"] 1]
  if {$chanflags != "-"} { append lst "$user " }
 } 
  return $lst
}

edge:addcmd 1 dcc -|- "_" nopasslist dcc:nopasslist "Lists all users with no password set." ".nopasslist \[chan\]"
proc dcc:nopasslist {h i a} {
 set chan [join [lindex $a 0]]
 putcmdlog "#$h# nopasslist $chan"
 if {[validchan $chan]} {
  #Find all users with flags on chan
  set list [getuserchanlist $chan]
 } else {
  set list [userlist]
 }
  foreach user $list {
   if {[passwdok $user ""]} { putlog "$user has empty password!" }
  }
}
edge:addcmd 1 dcc -|- "_" listusers dcc:listusers "Lists all users on chan" ".listusers <chan>"
proc dcc:listusers {h i a} {
 set chan [join [lindex $a 0]]
 if {![validchan $chan]} {
  putidx $i "Invalid chan, usage .listusers #chan (.match * 999 for all users)"
  return 0
 }
 putcmdlog "#$h# listusers $chan"
 set lst [getuserchanlist $chan]
 putidx $i "Users in $chan : $lst"
}

proc chanpredef:bot {frombot cmd a} {
 set chan [lindex [split $a] 0]
 set thetype [lindex [split $a] 1]
 set type ""
 switch -exact -- $thetype {
  "chanidle" { set type $edge(chanidle) ; noflood $chan }
  "chansecure" { set type $edge(chansecure) ; noflood $chan }
  "chanown" { set type $edge(chanown) ; noflood $chan }
 }
 if {$type!=""} {
  foreach setting $type {
   channel set $chan $setting
  }
 }
}

edge:addcmd 1 dcc -|- "_" bitchcheck dcc:bitchcheck "Lists all users without +o on #chan (or global)" ".bitchcheck <chan>"
proc dcc:bitchcheck {h i a} {
 set chan [join [lindex $a 0]]
 if {![validchan $chan]} {
  putidx $i "No such channel defined."
  putidx $i "Usage .bitchcheck #chan"
  return 0
 }
 set users [chanlist $chan]
 set lst ""
 foreach usr $users {
  set a [matchattr o|o $usr $chan]
  set hand [nick2hand $usr]
  if {$hand != ""} { set b [matchattr o|o $hand $chan] } else { set b 0 }
  set total [expr $a + $b]
  if {$total == 0 && [isop $usr $chan]} { append lst "$usr " }
 }
 putcmdlog "#$h# bitchcheck $chan"
 putidx $i "[llength $lst] bad users : $lst"
}


bind filt - -user* control:del:user
bind filt - chattr* control:chattr
bind filt - rehash control:rehash

bind evnt - prerehash control:rehash
bind evnt - prerestart control:rehash

proc control:rehash {type} {
global edge
 if {[info exists edge(loadslave)]} { unset edge(loadslave) }
 if {[info exists edge(startslave)]} { unset edge(startslave) }
}

proc control:chattr {i text} {
 set handle [join [lindex [split $text] 1]]
 set flags [join [lindex [split $text] 2]]
 if {[string match "*n*" $text] && ![isperm [idx2hand $i]]} { putidx $i "What?  You need '.help'" ; return 1 }
 return $text
}

proc control:del:user {i text} {
 set delhandle [join [lindex [split $text] 1]]
 set ourhandle [idx2hand $i]
 if {![isperm $ourhandle] && [matchattr $delhandle n]} { putidx $i "What?  You need '.help'" ; return 1 }
 return $text
}

#netmass.tcl

proc net:mass {modechar times reasonlength chan arg} {
 if {$reasonlength == 0} {
  set nicks $arg
  set reason ""
 } else {
  set reason [lrange $arg 0 [expr $reasonlength - 1]]
  set nicks [lrange $arg $reasonlength end]
 }
 if {$times > 1} {
 for {set x 0} {$x < $times} {incr x} { lappend nicks $nicks }
 }
 set splitnr 15
 if {$modechar == "+kkkk"} {
  set splitnr 3
  set modechar ""
  set whattype "4kick"
  putquick "MODE $chan +mi" -next
 } else {
  set modechar "$modechar "
  set whattype "4mode"
 }
 #start giving bot commands out.
 set botlist [getoppedbots $chan]
 if {[llength $botlist] == 0} {
  putlog "Mass mode failed, not enough opped bots on $chan"
  return 0
 }
 if {[llength $nicks] == 0} {
  putlog "Mass mode failed, no nicks to $modechar on $chan"
  return 0
 }
 set botnr 0
 set dodeop ""
 foreach anick $nicks {
  lappend dodeop $anick
  if {[lindex $dodeop $splitnr] != ""} {
   putbot [lindex $botlist $botnr] "netmassdo $whattype $chan $modechar$dodeop"
   set dodeop ""
 if {[expr $botnr + 1] == [llength $botlist]} { set botnr 0 } else { set botnr [expr $botnr + 1] }
  }
 }
 if {[expr $botnr + 1] == [llength $botlist]} { set botnr 0 } else { set botnr [expr $botnr + 1] }
 putbot [lindex $botlist $botnr] "netmassdo $whattype $chan $modechar$dodeop"
 set dodeop ""
}

bind bot - netmassdo netmass:bot
proc netmass:bot {frombot cmd arg} {
 #4kick/4mode chan modechar deoplist
 set a [split $arg]
 set type [lindex $a 0]
 set chan [lindex $a 1]
 set modechar [lindex $a 2]
 set nicks [lrange $arg 3 end]

 if {$type=="4mode"} {
  putquick "MODE $chan $modechar [lrange $nicks 0 3]"
  putquick "MODE $chan $modechar [lrange $nicks 4 7]"
  putquick "MODE $chan $modechar [lrange $nicks 8 11]"
  putquick "MODE $chan $modechar [lrange $nicks 12 15]"
 }

 if {$type=="4kick"} {
  set nicks [lrange $arg 2 6]
  set reason [lrange $arg 7 end]
  putquick "KICK $chan [lindex $nicks 0] :$reason"
  putquick "KICK $chan [lindex $nicks 1] :$reason"
  putquick "KICK $chan [lindex $nicks 2] :$reason"
  putquick "KICK $chan [lindex $nicks 3] :$reason"
 }
}

proc dcc:netmass {h i a} {
 set a [split $a]
 set type [lindex $a 0]
 set chan [lindex $a 1]
 if {$chan == ""} { set type "default" }
 if {![validchan $chan] && $chan != ""} {
  putidx $i "Invalid chan $chan"
  return 0
 }
 if {![req $h n $chan]} { return 0 }
 switch -exact -- $type {
  "op" {
   dccbroadcast "#$h# NetMass $type $chan"
   putloglev 8 * "NetMass TYPE:$type CHAN:$chan LENGTH:[llength [getoppedbots $chan]] BOTS:[getoppedbots $chan]"
   putdcc $i "Mass opping $chan using [llength [getoppedbots $chan]] opped bots"
   net:mass +oooo 1 0 $chan [getnonopped $chan]
  }
  "deop" {
   dccbroadcast "#$h# NetMass $type $chan"
   putdcc $i "Mass deopping $chan using [llength [getoppedbots $chan]] opped bots"
   net:mass -oooo 1 0 $chan [getopped $chan]
  }
  "voice" {
   dccbroadcast "#$h# NetMass $type $chan"
   putdcc $i "Mass voiceing $chan using [llength [getoppedbots $chan]] opped bots"
   net:mass +vvvv 1 0 $chan [getnonvoiced $chan]
  }
  "devoice" {
   dccbroadcast "#$h# NetMass $type $chan"
   putdcc $i "Mass devoiceing $chan using [llength [getoppedbots $chan]] opped bots"
   net:mass -vvvv 1 0 $chan [getvoiced $chan]
  }
  "kick" {
   set reason [lrange $a 2 end]
   set reasonlength [llength $reason]
   append reason " " [getunknown $chan]
   dccbroadcast "#$h# NetMass $type $chan $reason"
   putdcc $i "Mass kicking $chan using [llength [getoppedbots $chan]] opped bots"
   net:mass +kkkk 1 $reasonlength $chan $reason
  }
  "kickops" {
   set reason [lrange $a 2 end]
   set reasonlength [llength $reason]
   append reason " " [getopped $chan]
   dccbroadcast "#$h# NetMass $type $chan $reason"
   putdcc $i "Mass kicking ops on $chan using [llength [getoppedbots $chan]] opped bots"
   net:mass +kkkk 1 $reasonlength $chan $reason
  }
  "default" {
   putidx $i "Invalid command. Usage.: .netmass command chan"
   putidx $i "Commands are op deop voice devoice kick kickops"
   return 0
  }
 }
}