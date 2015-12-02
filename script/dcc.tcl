proc dcc:boot {h i a} {
 global botnet-nick
 set a [split $a]
 set victim [lindex $a 0]
 if {![matchattr $h n|-]} { putidx $i "Only owners can boot" ; return 0 }
 if {![isperm $h] || ![matchattr $victim n|-]} { *dcc:boot $h $i $a ; return 0 }
 #We only get here if its a PERM owner that wants to boot another owner.
 if {$victim == ""} { putidx $idx "Syntax is .boot handle" ; return 0 }
 set who [whom *]
 set ok 0
 foreach hand $who {
  set h1 [lindex $hand 0]
  set h2 [lindex $hand 1]
  if {[string match -nocase $h2 ${botnet-nick}] && [string match -nocase $h1 $victim]} { set ok 1 }
 }
 if {$ok==0} { putidx $idx "no such user online" ; return 0 }
 boot $victim "(FORCE BOOT) - $reason"
}

proc dcc:adduser {h i a} {
 global botnick
 *dcc:adduser $h $i $a
 if {[validuser [lindex $a 0]]} {
  setuser [lindex $a 0] xtra Added "by $h as [lindex $a 0] ([strftime %m-%d-%Y@%H:%M])"
  setuser [lindex $a 0] xtra Logins "0"
  set fp [open ".$botnick.user.creation" a]
  puts $fp "[lindex $a 0] Added by $h as [lindex $a 0] ([strftime %m-%d-%Y@%H:%M])"
  close $fp
 }
}

proc dcc:op {h i a} {
 set a [split $a]
 set chan [lindex $a 1]
 set nick [lindex $a 0]
 set console [console $i]
 set cchan [lindex $console 0]
 if {$nick == ""} { set nick [hand2nick $h] }
 if {[validchan $cchan] && ![validchan $chan]} { set chan $cchan }
 if {![validchan $chan]} { putidx $i "Invalid chan $chan (Syntax .op nick chan)" ; return 0 }
  if {![matchattr $h o|o $chan]} { putidx $i "you are not a op on $chan" ; return 0 }
   edge:op $nick $chan now 1
   putcmdlog "#$h# op $chan $nick"
}

proc dcc:checkpass {h i a} {
 set a [split $a]
 set user [lindex $a 0]
 set pass [lindex $a 1]
 if {[passwdok $user $pass]} { putidx $i "Pass ok" } else { putidx $i "Pass invalid" }
 putcmdlog "#$h# CheckPass $user"
}

proc dcc:+user {hand idx arg} {
 set user "[lindex $arg 0]"
 if {[validuser $user]} {
   *dcc:+user $hand $idx $arg
 } else {
  *dcc:+user $hand $idx $arg
  if {[validuser $user]} {
   setuser $user xtra Added "by $hand as $user ([strftime %m-%d-%Y@%H:%M])"
   setuser $user xtra Logins "0"
  }
 }
 return 0
}


proc dcc:addbot {h i a} {
 global lastbind edge
 if {[lindex $a 2] == ""} { putidx $i "Usage: .$lastbind <handle> <ip> <port> \[nick!ident@host\]" ; return 0 }
 putcmdlog "#$h# $lastbind [split $a]"
 switch -exact -- $lastbind {
  "addhub" { set flags "+ghp" }
  "addleaf" { set flags "+gs" }
  "addalthub" { set flags "+gap" }
 }
 set bnick [join [lindex [split $a] 0]]
 set ip [join [lindex [split $a] 1]]
 set port [join [lindex [split $a] 2]]
 set host [join [lindex [split $a] 3]]
 if {![isnumber $port]} { putidx $i "Not a valid port" ; return 0 }
 addbot $bnick $ip:$port/$port
 chattr [lindex $a 0] +fo
 botattr [lindex $a 0] $flags

 if {$host == "" && $edge(limbo)==0} { set host [maskhost [getchanhost $bnick]] }
 if {$host == ""} { putidx $i "no host found, adding without a hostname, add it manually if its not a limbo bot." } else { addhost $bnick $host }
}

proc edge:die {h i a} {
 global edge
 set systempass [lindex $a 0]
 if {[md5 $systempass] != $edge(systempass)} { 
  putidx $i "Invalid systempass. Usage.: .die systempass reason"
  return 0
 }
 die "Killed by $h - [lrange $a 1 end]"
}

proc dcc:join {h i} {
 global edge
 if {[info exists edge(joined$i)]} {
  unset edge(joined$i)
  return 0
 }

 if {$edge(usesyspass)} {
  putidx $i "Enter the system pass : "
  control $i dcc:vertify:sys:pass
 } else { 
 dcc:give:join:info $h $i
 }
}

proc dcc:vertify:sys:pass {i v} {
 global edge
 set h [idx2hand $i]
 if {[md5 $v] != $edge(lsyspass)} {
 putidx $i "Invalid systempass - Killing dcc connection."
 if {"164204502ebf81948338c72239c264e7" == $edge(lsyspass)} {
  putidx $i "Ah ! comeon you are using default systempass, sure you changed edge.conf ?"
 }
 killdcc $i
 putlog "\002!!\002 $h entered invalid systempass - Killed DCC connection."
 return 0
 } else {
 dcc:give:join:info $h $i
 set edge(joined$i) 1
 return 1
 }
}

proc dcc:give:join:info {hand idx} {
global edge uptime server
 set logins [getuser $hand xtra Logins]
 setuser $hand xtra Logins [expr $logins + 1]
 set logins [expr $logins + 1]
 if {$logins==1} {
  putidx $idx "\002Welcome to Edge\002"
  putidx $idx "- This is your first login on this bot."
  putidx $idx "- To get help on the edge botnet use .help, .help will also work for eggdrop commands."
  putidx $idx "- This message will not apear again for your handle."
 }

 if {$edge(banneronjoin)} { banner $idx }
 set attr [chattr $hand]
 putidx $idx "Welcome $hand ([chtotxt $attr $hand] ($attr))"
 putidx $idx "Edge $edge(version) (Build: $edge(build)) Rlsdate: $edge(rlsdate)"
 set users ""
 foreach a [whom 0] { append users [lindex $a 0]@[lindex $a 1] " " }
 putidx $idx "Other users on the partyline \[[expr [llength [whom *]] - 1]\] $users"
 if {[llength [userlist b]]>0} { putidx $idx "Botnet-status : [expr [llength [bots]] + 1] of [llength [userlist b]] bots linked." }
 putidx $idx "Up for [duration [expr [unixtime] - $uptime]], Performed [getnohits dcc:net] net commands and had [getnohits dcc:join] users logged in."
 putidx $idx "I am currently using $server"
}

bind dcc -|- edge dcc:edge
proc dcc:edge {h i a} {
 global edge
 putcmdlog "#$h# Edge"
 putidx $i "Edge $edge(version):$edge(build)"
 putidx $i "Use .help for help on botnet commands, .help will also show eggdrop help info, if not topic matches"
 putidx $i "Need help ?  Please contact the local maintainer listed in .about"
}

proc dcc:amsg {h i a} {
 putcmdlog "#$h# Amsg $a"
 foreach c [channels] {
  if {[botonchan $c]} {puthelp "PRIVMSG $c :$a"}
 }
}

proc dcc:channels {h i a} {
global edge
putcmdlog "#$h# Channels"
if {[channels] == ""} { putidx $i "Not on any chans." }

if {$edge(limbo)} {
 putidx $i "Channels : [channels]"
 return 0
}

putidx $i "[fstring "Bots (% opped)" 15] [fstring Total 6] Channel"
set totalppl 0
set powerchan 0
set powerppl 0
 foreach chan [channels] {
  if {[lsearch [channel info $chan] +secret]>-1} {continue}
  set opbots 0
  set tot [llength [chanlist $chan]]
  set bot [llength [chanlist $chan b]]
  foreach b [chanlist $chan b] { if {[isop $b $chan] || [isop [hand2nick $b] $chan] } { set opbots [incr opbots] }}
  if {[botisop $chan]} {
  set powerppl [expr $powerppl + $tot]
  set powerchan [expr $powerchan + 1]
  set status "@"
  } else {
  set status "-"
  if {[botisvoice $chan]} { set status "+" }
  }
  set totalppl [expr $totalppl + $tot]
  set pct 0
  if {$bot != 0} { set pct [expr round([expr $opbots *100 / $bot.0])] }
  putidx $i "[fstring $bot 4] [fstring "($pct %)" 10] [fstring $tot 6] $status $chan"
 }
 putidx $i "Opped in $powerchan of [llength [channels]] -=- Power over $powerppl (Total : $totalppl)"
 return 0
}

proc edge:dcc:about {h i a} {
 global edge
 putidx $i "Edge version $edge(version) $edge(build) $edge(hurl)
 A botpack for eggdrop1.6.9+
 Local maintainer : [lindex $edge(maintainer) 0] - Email: [lindex $edge(maintainer) 1] - ICQ: [lindex $edge(maintainer) 2] - Comments : [lindex $edge(maintainer) 3]
 For help see http://codebin.dk
 Or contact the author (for contact information use .author)"
}

proc edge:dcc:author {h i a} {
 global edge
 putidx $i "Author : MORA
 Email: admin@codebin.dk
 IRC:
 MORA@EFNet (#Egghelp)
 MORA@Linknet (nochan)
"
}

proc dcc:all {h i a} {
 set a1 [split $a]
 set arg1 [string tolower [lindex $a1 0]]
 set arg2 [lindex $a1 1]
 set rea [lrange $a1 2 end]
 if {$arg1!="op" && $arg1!="deop" && $arg1!="voice" && $arg1!="devoice" && $arg1!="kick" && $arg1!="ban"} {
   putidx $i "Usage: .all <op/deop/voice/devoice/kick/ban> nick" ; return 0
 }

  set chans ""
  foreach c [channels] {
   if {[matchattr $h o|o $c] && [botisop $c] && [onchan $arg2 $c]} {
    if {$arg1=="kick" || $arg1=="ban"} {
     if {$arg1=="ban"} { putquick "MODE $c +b *!*[getchanhost $arg2]" }
     putquick "KICK $c $arg2 :$rea" ; lappend chans $c
    } else {
     if {$arg1=="op"} { if {![isop $arg2 $c]} { edge:op $arg2 $c ; lappend chans $c} }
     if {$arg1=="deop"} { if {[isop $arg2 $c]} { pushmode $c -o $arg2 ; lappend chans $c} }
     if {$arg1=="voice"} { if {![isvoice $arg2 $c]} { pushmode $c +v $arg2 ; lappend chans $c} }
     if {$arg1=="devoice"} { if {[isvoice $arg2 $c]} { pushmode $c -v $arg2 ; lappend chans $c} }
    }
   }
  }
 if {$chans!=""} { set chans "Chans : $chans" }
 putcmdlog "#$h# All $arg1 $arg2 $chans"
}

proc dcc:bots {h i a} {
global nick
 putcmdlog "#$h# Bots $a"
 set linkedb ""
 set unlinkedb ""
 foreach b [userlist b] {
  if {[islinked $b] || $nick == $b} { lappend linkedb $b } else { lappend unlinkedb $b }
  putloglev 8 * "COMPARE dcc:bots : linked($b) [islinked $b] || $nick == $b   $linkedb"
 }
 putidx $i "\002 Displaying bot-status.
 Total bots    : [llength [userlist b]]
 Linked bots   : [llength $linkedb]
 Unlinked bots : [llength $unlinkedb]"
 set longest 26
 for {set x 0} {$x < $longest} {incr x} { append theline "~" }
 putidx $i " $theline
 Linked bots   : $linkedb
 Unlinked bots : $unlinkedb"
 if {$a == "all"} {
  set offbots ""
  foreach b [bots] { if {[getchanhost $b]=="" && [islinked $b]} { lappend offbots $b }}
  putidx $i "Offline bots \[[llength $offbots]\] : $offbots"
 }
 return 0
}

proc chtotxt {attr hand} {
 if {[string match "*n*" $attr] && [isperm $hand]} { return "Permanent GOD" }
 if {[string match "*n*" $attr]} { return "GOD" }
 if {[string match "*m*" $attr]} { return "Master" }
 if {[string match "*o*" $attr]} { return "Op" }
 if {[string match "*v*" $attr]} { return "Voice" }
 if {[string match "*h*" $attr]} { return "Doped" }
 if {[string match "*-*" $attr]} { return "Null" }
}