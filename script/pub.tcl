proc edge:pub:join {nick uhost handle chan} {
 global edge
 set nick [lindex [split $nick] 0]
 set chan [lindex [split $chan] 0]
 set a [expr [string match "*+allop*" [channel info $chan]] + [string match "*+allvoice*" [channel info $chan]]]
 if {$edge(allvoice)==1 && $a>0} {
  set rand [expr [rand $edge(autovoiceopdelay)]+1]
  utimer $rand "edge:allvoiceop:onjoin $chan $nick"
 }
 if {[string match "*+cookieautoop*" [channel info $chan]]} {
  if {![string match "*+cookieop*" [channel info $chan]]} { channel set $chan +cookieop }
  set rand [expr [rand $edge(autocookieopdelay)]+1]
  if {[matchattr $handle o|o $chan]} { utimer $rand "edge:op $nick $chan serv 1" }
 }
 edgeops:check $nick $chan $handle
}