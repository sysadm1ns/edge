#cookie.tcl - System to handle cookieops.

set edge(cookieenabled) 1

setudef flag cookieop
setudef flag cookiepunish

proc cookie:op {nick chan} { edge:op $nick $chan }

proc edge:op {nick chan {que "serv"} {force "0"}} {
 set hand [nick2hand $nick]
 if {[matchattr $hand o|o $chan] || $force==1} {
  if {[string match "*+cookieop*" [channel info $chan]]} {
   set cookie [cookie:make $nick $chan]
   set msg "MODE $chan +o-b $nick $cookie"
   putloglev 6 * "Opping $nick on $chan using cookie ($que - $force)"
  } else {
   pushmode $chan +o $nick
   putloglev 6 * "Opping $nick on $chan not using cookie ($que - $force)"
   return 0
  }
  switch -exact -- $que {
  "now" { putquick $msg -next }
  "quick" { putquick $msg }
  "serv" { putserv $msg }
  "help" { puthelp $msg }
  }
 } else {
 #aborting upping (no access for chan)
 }
}

proc edge:punish {nick chan level text} {
 global botnick
 if {[string match -nocase $botnick $nick]} { return 0 }
 #0 : No action
 switch -exact -- $level {
  "1" {
   #1 : deop
   pushmode $chan -o $nick
  }
  "2" {
   #2 : kick
   putquick "KICK $chan $nick :$text"
  }
  "3" {
   #3 : ban+kick
   putquick "KICK $chan $nick :$text"
   pushmode $chan +b [maskhost [getchanhost $nick]]
  }
  "4" {
   #4 : add as autodeop
   if {![validuser [nick2hand $nick]]} {
    adduser $nick [maskhost [getchanhost $nick]]
    set handle $nick
   } else {
    set handle [nick2hand $nick]
   }
   chattr $handle +d $chan
  }
  "5" {
   #5 : add as autokick
   if {![validuser [nick2hand $nick]]} {
    adduser $nick [maskhost [getchanhost $nick]]
    set handle $nick
   } else {
    set handle [nick2hand $nick]
   }
   chattr $handle +k $chan
  }
  "6" {
  #6 : level 4 and 5
  edge:punish $nick $chan 4 $text
  edge:punish $nick $chan 5 $text
  }
  "7" {
   #7 : as 6 + if a handle exists boot it
   edge:punish $nick $chan 6 $text
   set hand [nick2hand $nick]
   foreach user [whom *] {
    if {[string match [lindex $user 0] $hand]} {
     boot [lindex $user 0]@[lindex $user 1] $text
    }
   }
  }
  "8" {
   #8 : as 7 + remove partyline access
   edge:punish $nick $chan 7 $text
   chattr [nick2hand $nick] -p
  }
  "9" {
   #9 : as 8 + global +d
   edge:punish $nick $chan 7 $text
   chattr [nick2hand $nick] -p+d
  }
  "10" {
   #10 : as 9 + global +k
   edge:punish $nick $chan 9 $text
   chattr [nick2hand $nick] -p+dk
  }
 }
}

proc cookie:make {nick chan} {
 global edge botnick
 set nick [string tolower [join [lrange [split $nick] 0 end]]]
 set chan [string tolower [join [lrange [split $chan] 0 end]]]
 set nick [string tolower [encrypt $edge(basekey) $nick]]
 set ident [string tolower [encrypt $edge(seckey) $chan]]
 set ekey [string range [string tolower [getchanhost $botnick]] 0 7]
 set host [encrypt $ekey [unixtime]]
 set nick [string range $nick 0 6]
 set ident [string range $ident 0 8]
 return $nick!$ident@$host
}

proc cookie:check {cookie chan opper oped} {
 global edge
 set spacedhost [splitirchost $cookie]
 scan $spacedhost "%s %s %s" cnick cident chost
 set chan [string tolower [join [lrange [split $chan] 0 end]]]
 set opper [string tolower [join [lrange [split $opper] 0 end]]]
 set oped [string tolower [join [lrange [split $oped] 0 end]]]
 set cnick [string tolower [join [lrange [split $cnick] 0 end]]]
 set cident [string tolower [join [lrange [split $cident] 0 end]]]
 set chost [join [lrange [split $chost] 0 end]]
 set ekey [string range [string tolower [getchanhost $opper]] 0 7]
 set ctime [decrypt $ekey $chost]
 set onick [string tolower [encrypt $edge(basekey) $oped]]
 set oident [string tolower [encrypt $edge(seckey) $chan]]
 set otime [unixtime]
 set onick [string range $onick 0 6]
 set oident [string range $oident 0 8]
 if {![isnumber $ctime]} { return 0 }
 set time [expr $otime - $ctime]
 if {$cnick == $onick && $oident == $cident && $time>-100 || $time<100} { return 1 }
 if {$cnick == $onick && $oident == $cident && $time>-1000 || $time<1000} { return 2 }
 return 0
}

proc cookie:checkincoming {from keyword text} {
 global botnick edge
 set text [join [lrange [split $text] 0 end]]
 set chan [lindex $text 0]
 if {![validchan $chan]} { return 0 }
 set opper [lindex [splitirchost $from] 0]
 set chaninfo [channel info $chan]
 if {![string match "*+cookieop*" $chaninfo] || ![string match "*+cookiepunish*" $chaninfo] || ![isop $botnick $chan] || $botnick == $opper} { return 0 }
 set mode [lindex $text 1]
 set arg1 [lindex $text 2]
 set arg2 [lindex $text 3]
 set arg3 [lindex $text 4]
 set arg4 [lindex $text 5]
 set cookie1 ""
 set cookie2 ""
 set nick1 ""
 set nick2 ""
 switch -exact -- $mode {
  "+o" { set nick1 $arg1 }
  "+oo" { set nick2 $arg2 }
  "+o-b" { set nick1 $arg1 ; set cookie1 $arg2 }
  "+o-b+o-b" { set nick1 $arg1 ; set cookie1 $arg2 ; set nick2 $arg3 ; set cookie2 $arg4 }
  "+oo-bb" { set nick1 $arg1 ; set cookie1 $arg3 ; set nick2 $arg2 ; set cookie2 $arg4 }
  "-bb+oo" { set nick1 $arg3 ; set cookie1 $arg1 ; set nick2 $arg4 ; set cookie2 $arg2 }
  "-b+o-b+o" { set nick1 $arg2 ; set cookie1 $arg1 ; set nick2 $arg4 ; set cookie2 $arg3 }
  "-b+o" { set nick1 $arg2 ; set cookie1 $arg1 }
 }

 set h1 [nick2hand $nick1]
 set h2 [nick2hand $nick2]
 if {[matchattr $h1 b] && [islinked $h1]} { return 0 }
 if {[matchattr $h2 b] && [islinked $h2]} { return 0 }

 if {$nick1 != "" && $cookie1==""} { 
  putlog "$opper oped $nick1 on $chan without using cookie - punishing."
  edge:punish $opper $chan $edge(nocookie) "Wheres your cookie ?"
  edge:punish $nick1 $chan $edge(nocookie) "Wheres your cookie ?"
 }

 if {$nick2 != "" && $cookie2==""} { 
  putlog "$opper oped $nick2 on $chan without using cookie - punishing."
  edge:punish $opper $chan $edge(nocookie) "Wheres your cookie ?"
  edge:punish $nick2 $chan $edge(nocookie) "Wheres your cookie ?"
 }
 
 if {$nick1 !="" && $cookie1!=""} {
  set cok [cookie:check $cookie1 $chan $opper $nick1]
  if {$cok == 2} {
   putlog "$opper oped $nick1 on $chan using a lagged cookie - punishing" 
   edge:punish $opper $chan $edge(lagcookie) "Lag lag lag"
   edge:punish $nick1 $chan $edge(nocookie) "LAG PARTY"
  }
  if {$cok == 0} {
   putlog "$opper oped $nick1 on $chan using a \002invalid\002 cookie - punishing"
   edge:punish $opper $chan $edge(badcookie) "Silly hacker"
   edge:punish $nick1 $chan $edge(nocookie) "Go fetch"
  }
 }
 
 if {$nick2 !="" && $cookie2!=""} {
 putlog "$opper oped $nick2 on $chan using cookie : OK=[cookie:check $cookie2 $chan $opper $nick2]"
 }
 return 0
}

#edgeops.tcl - Opping script for the edge botpack ( www.codebin.dk )
#09-06-2003 Works as standalone
#09-06-2003 Tested on 1.6.13
#Mail bugs@codebin.dk if you find any errors while using this script
#if you can please incluse the .tcl set errorInfo

if {![info exists edge(limbo)]} { set edge(limbo) 0 }

if {$edge(limbo)!=1} {
 bind bot - edgeops bot:edgeops
 bind need - "*" edge:system:need 
 bind MODE - "*" edge:botop:mode
} else {
 catch { unbind bot - edgeops bot:edgeops }
}
