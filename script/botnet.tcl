#botnet.tcl

edge:addcmd 1 dcc -|- "_" net dcc:net "Botnet wide commands" ".net command"
edge:addcmd 0 dcc -|- "net" join dcc:net "Joins a channel" ".net join <chan> \[key\]"
edge:addcmd 0 dcc -|- "net" part dcc:net "Parts a channel" ".net part <chan>"
edge:addcmd 0 dcc -|- "net" say dcc:net "PRIVMSG a nick or channel using all bots in botnet" ".net say <target> <msg>"
edge:addcmd 0 dcc -|- "net" notice dcc:net "NOTICE a nick or channel using all bots in botnet" ".net notice <target> <msg>"
edge:addcmd 0 dcc -|- "net" act dcc:net "/me a nick or channel using all bots in botnet" ".net act <target> <msg>"
edge:addcmd 0 dcc -|- "net" ctcp dcc:net "CTCP a nick or channel using all bots in botnet (Will most likely get your bots klined)" ".net ctcp <target> <msg>"
edge:addcmd 0 dcc -|- "net" ctcpr dcc:net "CTCP-REPLY a nick or channel using all bots in botnet (Will most likely get your bots klined)" ".net ctcpr <target> <msg>"
edge:addcmd 0 dcc -|- "net" hash dcc:net "Rehashes all bots" ".net rehash"
edge:addcmd 0 dcc -|- "net" save dcc:net "Makes all bots save their userfile" ".net save"
edge:addcmd 0 dcc -|- "net" chanset dcc:net "Sets channel settings for all linked bots" ".net chanset <#chan> <settings>"
edge:addcmd 0 dcc -|- "servers" servers dcc:net "Lists each bot and its IRC-server and hostname (if limbo no.irc is used as server)" ".net servers"
edge:addcmd 0 dcc -|- "net" backup dcc:net "Makes all bots backup their userfile" ".net backup"
edge:addcmd 0 dcc -|- "net" nettcl dcc:net "Makes all bots perform the tcl (permanent owners only)" ".net nettcl <command>"
edge:addcmd 0 dcc -|- "net" netdelaytcl dcc:net "Makes all bots perform the tcl after delay secs (permanent owners only)" ".net nettcl <delay> <command>"
edge:addcmd 0 dcc -|- "net" clrque dcc:net "Flushes all queues on all bots (Useful during botwar i.e.)" ".net clrque"
edge:addcmd 0 dcc -|- "net" update dcc:net "Makes all linked bots download changed files, based on their own files." ".net update"
edge:addcmd 0 dcc -|- "net" nick dcc:net "Makes all linked bots change nick, wither to altnick or random." ".net nick \[rand\]"
edge:addcmd 0 dcc -|- "net" chancheck dcc:net "Makes all linked bots join all locally channels not marked +nocc." ".net chancheck"

bind bot - net bot:net

proc dcc:net {h i a} {
#This proc will send the data to all bots regardless of the users local status
#The recieving bot will then decide if they wil execute the command or not.
  global botnick edge
  set msg ""
  set a1 [split $a]
  set cmd [lindex $a1 0]
  set arg1 [lindex $a1 1]
  set arg2 [lindex $a1 2]
  set rest1 [join [lrange $a1 1 end]]

if {$cmd == "join" && $edge(permjoin)==1 && ![isperm $h]} { putidx $i "No access to that command!" ; return 0 }
if {$cmd == "part" && $edge(permpart)==1 && ![isperm $h]} { putidx $i "No access to that command!" ; return 0 }
if {$cmd == "dump" && $edge(permdump)==1 && ![isperm $h]} { putidx $i "No access to that command!" ; return 0 }
if {$cmd == "chanset" && $edge(permchanset)==1 && ![isperm $h]} { putidx $i "No access to that command!" ; return 0 }
if {$cmd == "nick" && $edge(permnick)==1 && ![isperm $h]} { putidx $i "No access to that command!" ; return 0 }
if {$cmd == "say" && $edge(permsay)==1 && ![isperm $h]} { putidx $i "No access to that command!" ; return 0 }  
  
  switch -exact -- $cmd {
   "uptime" { 
	set edge(tempupt1) 0
	set edge(tempupt2) 0
	set edge(tempidx) $i
	set edge(botleft) [expr [llength [bots]] + 1]
	set msg "uptime $i"
	dccbroadcast "#$h# net uptime"
   }
   "lag" {
	set edge(templag) 9999
	set edge(botleft) [expr [llength [bots]] + 1]
	set msg "lag $i [unixtime]"
	set edge(tempidx) $i
	dccbroadcast "#$h# net lag"
   }
   "say" {
	if {![validchan $arg1]} {
		dccbroadcast "#$h# net say $rest1"
	}
	if {[validchan $arg1]} {
		if {[lsearch [channel info $arg1] +secret]==-1} {
			dccbroadcast "#$h# net say $rest1"
		}
	}
	set msg "say $rest1"
   }
   "version" {
	#putidx $i "Edge version - build - rlsdate - eggdrop version"
	set msg "version $i"
	dccbroadcast "#$h# net version"
   }
   "notice" {
	   set quiet 0
	   if {[validchan $arg1]} {
		   set quiet 1
		   if {[lsearch [channel info $arg1] +secret]==-1} { set quiet 0 }
	   }
	   if {$quiet == 0} { dccbroadcast "#$h# net notice $rest1" }
	   set msg "notice $rest1"
   }
   "act" {
	   set quiet 0
	   if {[validchan $arg1]} {
		   set quiet 1
		   if {[lsearch [channel info $arg1] +secret]==-1} { set quiet 0 }
	   }
	   if {$quiet == 0} { dccbroadcast "#$h# net act $rest1" }
	   set msg "act $rest1"
   }
   "ctcp" {
	   set quiet 0
	   if {[validchan $arg1]} {
		   set quiet 1
		   if {[lsearch [channel info $arg1] +secret]==-1} { set quiet 0 }
	   }
	   if {$quiet == 0} { dccbroadcast "#$h# net ctcp $rest1" }
	   set msg "ctcp $rest1"
   }
   "ctcpr" {
	   set quiet 0
	   if {[validchan $arg1]} {
		   set quiet 1
		   if {[lsearch [channel info $arg1] +secret]==-1} { set quiet 0 }
	   }
	   if {$quiet == 0} { dccbroadcast "#$h# net ctcpr $rest1" }
	   set msg "ctcpr $rest1"
   }
   "join" {
	   set chan [lindex [split $rest1] 0]
	   set key [lindex [split $rest1] 1]
	   putloglev 6 * "CHAN = $chan - rest1=$rest1"
	   if {$chan == "" || ![string match *[string index $chan 0]* "#?!"]} {
		putidx $i "Usage: .net join <chan>"
		putidx $i "If your chan really is valid, msg MORA on efnet with the channame (since edge checks if the channame \"looks valid\""
		return 0
	   }
	   set msg "join $chan $key"
	   dccbroadcast "#$h# net join $chan $key"
   }
   "part" {
	   set chan [lindex [split $arg1] 0]
	   putloglev 6 * "CHAN = $chan - arg1=$arg1"
	   set quiet 0
	   if {[validchan $chan]} {
		   set quiet 1
		   if {[lsearch [channel info $arg1] +secret]==-1} { set quiet 0 }
	   } else {
		putidx $i "I dont know that chan, but asking linked bots to part anyway"
	   }
	   if {$quiet == 0} { dccbroadcast "#$h# net part $chan" }
	   set msg "part $chan"
   }
   "hash" {
	   dccbroadcast "#$h# net hash"
	   set msg "hash"
   }
   "save" {
	dccbroadcast "#$h# net save"
	set msg "save"
   }
   "chanset" {
	    if {[string match "*need-*" $rest1]} {
		    putidx $i "Edge cant handle need-* settings using .net yet :|"
		    return 0
	    }
	   set quiet 0
	   if {[validchan $arg1]} {
		   set quiet 1
		   if {[lsearch [channel info $arg1] +secret]==-1} { set quiet 0 }
	   }
	   if {$quiet == 0} { dccbroadcast "#$h# net chanset $rest1" }
	    set msg "chanset $rest1"
   }
   "backup" {
	set msg "backup"
	dccbroadcast "#$h# net backup"
   }
   "nettcl" {
	   set msg "nettcl $rest1"
	   dccbroadcast "#$h# net nettcl $rest1"
   }
   "netdelaytcl" {
	   set msg "netdelaytcl $rest1"
	   dccbroadcast "#$h# net netdelaytcl $rest1"
   }
   "clrque" {
	   set msg "clrque"
	   dccbroadcast "#$h# net clrque"
   }
   "update" {
	   set msg "update $arg1"
	   dccbroadcast "#$h# net update"
   }
   "nick" {
	   set msg "nick $arg1"
	   dccbroadcast "#$h# net nick"
   }
   "dump" {
	   set msg "dump $rest1"
	   dccbroadcast "#$h# net dump"
   }
   "servers" {
	   set msg "servers $i"
	   dccbroadcast "#$h# net servers"
   }
   "chancheck" { 
	    set channels ""
	    foreach c [channels] { if {![string match "*+nocc*" [channel info $c]]} { lappend channels $c }}
	    set msg "chancheck $channels"
    	   dccbroadcast "#$h# net chancheck"
   }
   "default" { putidx $i "Invalid command, see .help net" }
  }
  if {$msg != ""} {
   putallbots "net $h $msg"
   bot:net $botnick net "$h $msg"
  }
}

proc cset {chan setting {arg1 ""} {arg2 ""} {arg3 ""} {arg4 ""} {arg5 ""}} {
putloglev 5 * "chanset $chan $setting $arg1 $arg2 $arg3 $arg4 $arg5"
 if {$arg5 != ""} { channel set $chan $setting $arg1 $arg2 $arg3 $arg4 $arg5 ; return 0 }
 if {$arg4 != ""} { channel set $chan $setting $arg1 $arg2 $arg3 $arg4 ; return 0 }
 if {$arg3 != ""} { channel set $chan $setting $arg1 $arg2 $arg3 ; return 0 }
 if {$arg2 != ""} { channel set $chan $setting $arg1 $arg2 ; return 0 }
 if {$arg1 != ""} { channel set $chan $setting $arg1 ; return 0 }
 channel set $chan $setting
}

proc bot:net {frombot cmd a} {
global botnick edge update nick altnick uptime {server-online} version server
if {[matchattr $frombot R]} { return 0 }
	set a1 [split $a]
	set hand [lindex $a1 0]
	set arg1 [lindex $a1 1]
	set arg2 [lindex $a1 2]
	set arg3 [lindex $a1 3]
	set arg4 [lindex $a1 4]
	set arg5 [lindex $a1 5]
	set arg6 [lindex $a1 6]
	set plus3 [lrange $a1 3 end]


switch -exact -- $arg1 {
	"join" {
		if {$edge(limbo)} { return 0 }
		if {$edge(permjoin)==1 && ![isperm $hand]} { return 0 }
	}
	"part" {
		if {$edge(limbo)} { return 0 }
		if {$edge(permpart)==1 && ![isperm $hand]} { return 0 }
	}
	"dump" {
		if {$edge(limbo)} { return 0 }
		if {$edge(permdump)==1 && ![isperm $hand]} { return 0 }
	}
	"nick" {
		if {$edge(limbo)} { return 0 }
		if {$edge(permnick)==1 && ![isperm $hand]} { return 0 }
	}
	"notice" {
		if {$edge(limbo)} { return 0 }
	}
	"act" {
		if {$edge(limbo)} { return 0 }
	}
	"ctcp" {
		if {$edge(limbo)} { return 0 }
	}
	"ctcpr" {
		if {$edge(limbo)} { return 0 }
	}
	"say" {
		if {$edge(limbo)} { return 0 }
		if {$edge(permsay)==1 && ![isperm $hand]} { return 0 }
	}
	"chanset" {
		if {$edge(permchanset)==1 && ![isperm $hand]} { return 0 }
	}
}

  switch -exact -- $arg1 {
  "lag" {
   if {$frombot != $botnick} {
    putbot $frombot "net $hand lagreply $arg2 $arg3"
   } else {
    bot:net $botnick net "$hand lagreply $arg2 $arg3"
   }
  }
  "lagreply" {
   putidx $arg2 "\002\[\002Lag\002\]\002 $frombot lag [expr [unixtime] - $arg3] secs."
   set edge(botleft) [expr $edge(botleft) - 1]
   if {[expr [unixtime] - $arg3] < [lindex [split $edge(templag) "|"] 0]} { set edge(templag) "[expr [unixtime] - $arg3]|$botnick" }
   if {$edge(botleft) == 0} {
    putidx $edge(tempidx) "Lowest lag : $edge(templag)"
   }
  }
  "servers" {
   if {$edge(limbo)==1} { set s "no.irc" } else { set s $server }
   if {$frombot != $botnick} {
    putbot $frombot "net $hand serversreply $arg2 $s [exec uname -n]"
   } else {
    bot:net $botnick net "$hand serversreply $arg2 $s [exec uname -n]"
   }
  }
  "serversreply" {
   putidx $arg2 "\[SERVER\] $frombot $arg3 $arg4"
  }
  "uptime" {
   set serverupt ${server-online}
   set botupt $uptime
   set shellupt [exec uptime]
   if {$frombot != $botnick} {
    putbot $frombot "net $hand uptimereply $arg2 $botupt $serverupt $shellupt"
   } else {
    bot:net $botnick net "$hand uptimereply $arg2 $botupt $serverupt $shellupt"
   }
  }
  "uptimereply" {
   if {$arg3 > [lindex [split $edge(tempupt1) "|"] 0]} { set edge(tempupt1) "$frombot|$arg3" }
   if {$arg4 > [lindex [split $edge(tempupt2) "|"] 0]} { set edge(tempupt2) "$frombot|$arg4" }
   putidx $arg2 "\002\[\002Uptime\002\]\002 $frombot : [duration [expr [unixtime] - $arg3]] [duration [expr [unixtime] - $arg4]]"
   set edge(botleft) [expr $edge(botleft) - 1]
   if {$edge(botleft) == 0} {
    set bot1 [lindex [split $edge(tempupt1) "|"] 0]
    set bot2 [duration [expr [unixtime] - [lindex [split $edge(tempupt1) "|"] 1]]]
    set bot3 [lindex [split $edge(tempupt2) "|"] 0]
    set bot4 [duration [expr [unixtime] - [lindex [split $edge(tempupt2) "|"] 1]]]
    putidx $edge(tempidx) "Best uptime : Bot: $bot1 $bot2 - Server: $bot3 $bot4"
   }
  }
  "say" {
   if {![req $hand o $arg2]} { return 0 }
   putserv "PRIVMSG $arg2 :$plus3"
   }
  "version" {
   if {$frombot != $botnick} {
    putbot $frombot "net $hand versionreply $arg2 $edge(version) $edge(build) $edge(rlsdate) $version"
   } else {
     bot:net $botnick net "$hand versionreply $arg2 $edge(version) $edge(build) $edge(rlsdate) $version"
   }
  }
  "versionreply" {
   set clr ""
   if {$arg4 != $edge(build)} { set clr "\0037" }
   if {$arg3 != $edge(version)} { set clr "\0034" }
   putidx $arg2 "\[VERSION\] $clr $frombot : $arg3 - $arg4 - $arg5 - $arg6\003"
  }
  "notice" {
   if {![req $hand o $arg2]} { return 0 }
   putserv "NOTICE $arg2 :$plus3"
  }
  "act" {
   if {![req $hand o $arg2]} { return 0 }
   putserv "PRIVMSG $arg2 :\001ACTION $plus3\001"
  }
  "ctcp" { 
   if {![req $hand o $arg2]} { return 0 }
   putserv "PRIVMSG $arg2 :\001$plus3\001"
  }
  "ctcpr" {
   if {![req $hand o $arg2]} { return 0 }
   putserv "NOTICE $arg2 :\001$plus3\001"
  }
  "join" {
  if {![req $hand n]} { return 0 }
  edge:join $arg2 $arg3 $arg4
  }
  "part" { 
   if {![req $hand n]} { return 0 }
   edge:part $arg2 $arg3
  }
  "dump" {
   putserv "[join [lrange $a1 2 end]]"
  }
  "hash" { if {![req $hand n]} { return 0 } ; rehash }
  "save" { if {![req $hand n]} { return 0 } ; save }
  "chanset" {
   if {![req $hand n|n $arg2]} { return 0 }
   if {[validchan $arg2]} {
    set i 0
    while {$i < [llength $plus3]} {
     set setting [lindex $plus3 $i]
     set fill "idle-kick stopnethack aop-delay revenge-mode ban-time exempt-time invite-time"

     if {[string match "chanmode" $setting]} {
      set f 0
      if {[string match "*l*" $a1]} { incr f }
      if {[string match "*k*" $a1]} {
	cset $arg2 chanmode -k
	incr f
      }
      set a1 [lindex $plus3 [expr $i + 1]]
      set a2 [lindex $plus3 [expr $i + 2]]
      set a3 [lindex $plus3 [expr $i + 3]]
      cset $arg2 $setting "$a1 $a2 $a3"
      if {$f==2} { set i [expr $i + 3] }
      if {$f==1} { set i [expr $i + 2] }
      if {$f==0} { set i [expr $i + 1] }
      incr i
      continue
     }
     if {[string match "*flood-*" $setting] || [lsearch [split $fill] $setting]>-1} {
      cset $arg2 $setting [lindex $plus3 [expr $i + 1]] ; incr i
     } else {
      cset $arg2 $setting
     }
     incr i
     #needs a dynamic way of seeing if set is a variable (int) or flag
    }
   }
  }
  "backup" { if {![req $hand n]} { return 0 } ; backup }
  "nettcl" {if {[isperm $hand] && [matchattr $hand n]} { net:tcl [lrange [split $a] 2 end] }}
  "netdelaytcl" {if {[isperm $hand] && [matchattr $hand n]} { utimer $arg2 "net:tcl $plus3" }}
  "clrque" {
	putloglev 8 * "ClearQueue command from $hand ([req $hand n])"
	  if {![req $hand n]} { return 0 }
	  clearqueue all
  }
  "nick" {
   if {![req $hand n]} { return 0 }
   if {$arg2 == "rand"} {
    set altnick $nick
    set nick [randstring 7]
   } else {
    set temp $altnick 
    set altnick $nick
    set nick $temp
   }
  }
  "chancheck" {
   if {![req $hand n]} { return 0 }
   foreach c [lrange $a1 2 end] {
    if {![validchan $c]} { channel add $c }
   }
  }
  "update" {
   if {![req $hand n]} { return 0 }
    set edge(chknick) ""
    if {$arg2 == "-force"} {
	do:update $edge(files)
    } else {
	    set sock [egghttp:geturl $update(check) callback:checkupdate] 
    }
  }
 }
}