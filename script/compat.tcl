##COMPAT.tcl##
proc gethosts {hand} { getuser $hand HOSTS }
proc addhost {hand host} { setuser $hand HOSTS $host }
proc chpass {hand pass} { setuser $hand PASS $pass }
proc chnick {oldnick newnick} { chhandle $oldnick $newnick }
proc getxtra {hand} { getuser $hand XTRA }
proc setinfo {hand info} { setuser $hand INFO $info }
proc getinfo {hand} { getuser $hand INFO }
proc getaddr {hand} {getuser $hand BOTADDR }
proc setaddr {hand addr} { setuser $hand BOTADDR $addr }
proc getdccdir {hand} { getuser $hand DCCDIR }
proc setdccdir {hand dccdir} { setuser $hand DCCDIR $dccdir }
proc getcomment {hand} { getuser $hand COMMENT }
proc setcomment {hand comment} { setuser $hand COMMENT $comment }
proc getemail {hand} { getuser $hand XTRA email }
proc setemail {hand email} { setuser $hand XTRA EMAIL $email }
proc getchanlaston {hand} { lindex [getuser $hand LASTON] 1 }
proc time {} { strftime "%H:%M" }
proc date {} { strftime "%d %b %Y" }
proc setdnloads {hand {c 0} {k 0}} { setuser $hand FSTAT d $c $k }
proc getdnloads {hand} { getuser $hand FSTAT d }
proc setuploads {hand {c 0} {k 0}} { setuser $hand FSTAT u $c $k }
proc getuploads {hand} { getuser $hand FSTAT u }
bind dcc - nick *dcc:handle
bind dcc t chnick *dcc:chhandle