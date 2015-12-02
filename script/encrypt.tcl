#encrypt.tcl 
#methods for encrypting stuff in edge :)

set edge(encrypted) 1

proc dcc_encrypt {bot text} {
 set bot [string tolower $bot]
 #bot should be the bot that should recieve the message.
 #Set all 4 values to random chars, use .tcl randstring 20 in the dcc chat if you want the bot to make some.
 global edge
 set arg1 [join [lindex [split $text] 0]]
 set arg2 [join [lindex [split $text] 1]]
 if {$arg1 == ""} { return 0 }
 set hash1 [md5 $bot]
 set hash2 [encrypt $edge(basekey) $hash1]
 set hash3 [encrypt $edge(seckey) $arg1]
 set hash4 [encrypt $edge(repeatkey) $arg2]
 set timehash [encrypt $edge(lowkey) [unixtime]]
 set rtimestamp 1337
 set txt [join [lrange $text 1 end]]
 set texthash [encrypt $rtimestamp $txt]
 set msg "$arg1 $hash2 $hash3 $hash4 $timehash $texthash"
 putbot $bot $msg
}

proc dcc_decrypt {bot text} {
 global edge
 set bot [string tolower $bot]
 #bot should be the bot that send the message.
 set hash2 [lindex $text 0]
 set hash3 [lindex $text 1]
 set hash4 [lindex $text 2]
 set timehash [lindex $text 3]
 set texthash [lrange $text 4 end]
 set rtimestamp 1337

 set text [decrypt $rtimestamp $texthash]
 set res2 [decrypt $edge(basekey) $hash2]
 #res2 skal være lig med [md5 $bot]
 set res3 [decrypt $edge(seckey) $hash3]
 #res3 skal være lig med [join [lindex $text 0]]
 set res4 [decrypt $edge(repeatkey) $hash4]
 #res4 skal være lig med [join [lindex $text 1]]

 return $text
}