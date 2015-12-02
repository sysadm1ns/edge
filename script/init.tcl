if {![info exists edge(loadslave)]} { set edge(loadslave) "\0034MASTER\003" }
if {![info exists edge(startslave)]} { set edge(startslave) "\0034MASTER\003" }

#Init variables
set edge(hurl) "http://edge.codebin.dk/"
set edge(changelogurl) "http://www.codebin.dk/edge/changes.php?build="

set edge(rlsdate) "20041216"
set edge(version) 0.9.1
set edge(build) 0930

set mod-path "modules/"
set help-path "help/"
set text-path "text/"
loadmodule blowfish
loadmodule dns
loadmodule channels
loadmodule console
loadmodule share
loadmodule transfer
if {$edge(limbo) != 1} {
 loadmodule server
 loadmodule ctcp
 loadmodule irc
 bind time - "* * * * *" timer:em
} else {
  set nick-len 9
}

set nick $edge(nick)
if {$edge(altnick)==""} {
	set altnick [string range $nick 0 [expr {${nick-len} - 2}]]-
} else {
	set altnick $edge(altnick)
}
set username $nick
set realname $edge(realname)
set my-ip $edge(ip)

if {[info exists edge(natip)]} { if {$edge(natip)!=""} { set nat-ip "$edge(natip)" } }
if {[info exists edge(natrange)]} { if {$edge(natrange)!=""} { set reserved-portrange "$edge(natrange)" } }
if {[info exists edge(ip6)]} { set my-ip6 $edge(ip6) }

if {![info exists edge(autocookieopdelay)]} { set edge(autocookieopdelay) 13 }
if {![info exists edge(autovoiceopdelay)]} { set edge(autovoiceopdelay) 6 }

if {[info exists edge(hostname)]} {
if {$edge(hostname)!=""} {
set my-hostname "$edge(hostname)"
} else {
set my-hostname "0"
}
}

listen $edge(port) all

set owner $edge(owner)
set userfile "$nick.user"
set chanfile "$nick.chan"
set notefile "$nick.notes"
set tempfile "$nick.temp"
set distfile "$nick.dist"
set edge(inifile) "sys.edge.values"
set temp-path "/tmp"
logfile msbxco * "logs/$nick.log"
set log-time 1
set keep-all-logs 0
set logfile-suffix ".%d%b%Y"
set switch-logfiles-at 100
set quiet-save 1

set timezone $edge(timezone)
set offset $edge(timeoffset)
if {![info exist max-logs]} { set max-logs 10 }
set max-logsize 0
set quick-logs 0
set allow-resync 0
set resync-time 5
set override-bots 1
set console "mcobxs"
set sort-users 0
set userfile-perm 0600
set whois-fields "Added Logins"
set remote-boots 1
set share-unlinks 1
set protect-telnet 1
set dcc-sanitycheck 1
set ident-timeout 3
set require-p 1
set open-telnets 0
set stealth-telnets 1
set use-telnet-banner 0
set connect-timeout 15
set dcc-flood-thr 10
set telnet-flood 5:60
set paranoid-telnet-flood 1
set resolve-timeout 15
set ignore-time 15
set hourly-updates 23
set notify-newusers "$owner"
set default-flags ""
set die-on-sighup 0
set die-on-sigterm 1
set must-be-owner 1
set max-dcc 500
set enable-simul 1
set allow-dk-cmds 0
set dupwait-timeout 5
set ban-time 0
set exempt-time 60
set invite-time 60
set force-expire 0
set share-greet 1
set use-info 1
set global-flood-chan 0:0
set global-flood-deop 5:5
set global-flood-kick 5:7
set global-flood-join 0:0
set global-flood-ctcp 0:0
set global-flood-nick 0:0
set global-aop-delay 5:30
set global-idle-kick 0
set global-chanmode "nt"
set global-stopnethack-mode 0
set global-revenge-mode 0

set global-chanset {
        -autoop         +dynamicbans
        -bitch          +cycle
        -autovoice	+dontkickops    
        -greet		+dynamicinvites
        -revengebot     +enforcebans
	-seen		+dynamicexempts
        -inactive       +nodesynch
        -protectfriends +protectops
        -revenge        +shared         
        -secret        	+userbans       
	-statuslog	+userexempts
	+userinvites    
}

set keep-nick 1
set strict-host 0
set quiet-reject 1
set lowercase-ctcp 0
set answer-ctcp 1
set flood-msg 10:5
set flood-ctcp 4:60
set ctcp-mode 2
set never-give-up 1
set strict-servernames 0
set server-cycle-wait 25
set server-timeout 25
set servlimit 0
set check-stoned 1
set use-console-r 0
set debug-output 0
set serverror-quit 1
set max-queue-msg 150
set trigger-on-ignore 0
set double-mode 0
set double-server 0
set double-help 0
set bounce-bans 1
set bounce-modes 0
set max-bans 20
set max-modes 30
set kick-fun 0
set ban-fun 0
set learn-users 0
set wait-split 600
set wait-info 180
set mode-buf-length 200
set no-chanrec-info 0
set bounce-exempts 0
set bounce-invites 0
set max-exempts 20
set max-invites 20
set prevent-mixing 1
set share-compressed 1
set compress-level 9
set console-autosave 1
set force-channel 0
set info-party 0

setudef flag nocc
setudef flag nomanop
setudef flag cookieautoop

if {$edge(limbo)} {
 set server ""
 set botnet-nick $nick
 set botnetnick $nick
 set botnick $nick
} else {
 edge:addcmd 1 dcc o|- "_" amsg dcc:amsg "Sends a message to all channels" ".amsg message"
 edge:addcmd 1 dcc -|- "_" channels dcc:channels "Shows the channels the bot is on" ".channels"
 edge:addcmd 1 dcc -|- "_" all dcc:all "Channel wide command" ".all <op/deop/voice/devoice/kick/ban> nick"
 bind raw - MODE edge:protect:raw:mode
 bind raw - MODE cookie:checkincoming

 if {![info exists edge(silentctcp)]} { set edge(silentctcp) 0 }
 if {![info exists edge(customctcp)]} { set edge(customctcp) "" }

 if {$edge(silentctcp)==0} {
	 bind ctcp - TIME edge:ctcp:time
	if {$edge(customctcp)!=""} {
         bind ctcp - VERSION edge:ctcp:custom:version
	} else {
	 bind ctcp - VERSION edge:ctcp:version
	}
 }


 bind join -|- * edge:pub:join
 catch { unbind msg - ident *msg:ident }
 catch { unbind msg - addhost *msg:addhost }
 catch { unbind dcc n|- die *dcc:die }
 catch { unbind msg - notes *msg:notes }
 catch { unbind msg - whois *msg:whois }
 catch { unbind msg - who *msg:who }
 catch { unbind msg - voice *msg:voice }
 catch { unbind msg - status *msg:status }
 catch { unbind msg - save *msg:save }
 catch { unbind msg - reset *msg:reset }
 catch { unbind msg - rehash *msg:rehash }
 catch { unbind msg - memory *msg:memory }
 catch { unbind msg - jump *msg:jump }
 catch { unbind msg - info *msg:info }
 catch { unbind msg - die *msg:die }
 catch { unbind msg  - op *msg:op }
 edge:addcmd 1 msg -|- "_" op edge:msg:op "" "op pass"
 catch { unbind msg - ident *msg:ident }
 catch { unbind msg - addhost *msg:addhost }
 catch { unbind dcc o|o op *dcc:op }
 edge:addcmd 1 dcc -|- "_" "netmass" dcc:netmass "Performs mass modes using entire botnet" ".netmass <deop/op/voice/devoice/kick> <chan>"
 edge:addcmd 1 dcc -|- "_" "mass" dcc:mass "Performs mass modes locally (use .netmass to utialize the entire net)" ".mass <deop/op/voice/devoice/kick/ban> <chan>"
 edge:addcmd 1 dcc -|- "_" chanidle chanpredef "Sets channel to \002idle\002 settings" ".chanidle #chan"
 edge:addcmd 1 dcc -|- "_" chansecure chanpredef "Sets channel to \002secure\002 settings" ".chansecure #chan"
 edge:addcmd 1 dcc -|- "_" chanown chanpredef "Sets channel to \002own\002 settings (only know ops)" ".chanown #chan"
 bind dcc o|o op dcc:op
 setudef flag nocc
}

catch { unbind dcc t|- boot *dcc:boot }
bind dcc t|- boot dcc:boot
catch { unbind dcc n set *dcc:set }
catch { unbind dcc m|- +user *dcc:+user }
catch { unbind dcc -|- bots *dcc:bots }
catch { unbind dcc m|m adduser *dcc:adduser }

edge:addcmd 1 dcc m|m "_" adduser dcc:adduser "Adds a new user to eggdrop." ".adduser nick"
edge:addcmd 1 dcc m|- "_" +user dcc:+user "Adds a new user to eggdrop" ".+user handle \[host\]"
edge:addcmd 1 dcc -|- "_" checkpass dcc:checkpass "Checks a pass against the userfile" ".checkpass handle pass"
edge:addcmd 1 dcc n|- "_" addhub dcc:addbot "Adds a hub to the botnet" ".addhub handle ip port nick!ident@host"
edge:addcmd 1 dcc n|- "_" addalthub dcc:addbot "Adds a altetrnative hub to the botnet" ".addalthub handle ip port nick!ident@host"
edge:addcmd 1 dcc n|- "_" addleaf dcc:addbot "Adds a leaf to the botnet" ".addleaf handle ip port nick!ident@host"
edge:addcmd 1 dcc n|- "_" die edge:die "Kills the bot" ".die systempass reason"
edge:addcmd 1 dcc -|- "_" about edge:dcc:about "Misc info" ".about"
edge:addcmd 1 dcc -|- "_" author edge:dcc:author "Author info" ".author"
edge:addcmd 1 dcc -|- "_" bots dcc:bots "Shows bot status" ".bots <all>"

bind chon - * dcc:join
bind filt - "\001ACTION *\001" filt:dcc_action
bind filt - "CTCP_MESSAGE \001ACTION *\001" filt:dcc_action2
bind filt - "/me *" filt:telnet_action
proc filt:dcc_action {idx text} { return ".me [string trim [join [lrange [split $text] 1 end]] \001]" }
proc filt:dcc_action2 {idx text} { return ".me [string trim [join [lrange [split $text] 2 end]] \001]" }
proc filt:telnet_action {idx text} { return ".me [join [lrange [split $text] 1 end]]" }

catch { unbind ctcp - TIME *ctcp:TIME }
catch { unbind ctcp - CLIENTINFO *ctcp:CLIENTINFO }
catch { unbind ctcp - USERINFO *ctcp:USERINFO }
catch { unbind ctcp - VERSION *ctcp:VERSION }
catch { unbind ctcp - ERRMSG *ctcp:ERRMSG }
catch { unbind ctcp - ECHO *ctcp:ECHO }
catch { unbind ctcp - FINGER *ctcp:FINGER }

