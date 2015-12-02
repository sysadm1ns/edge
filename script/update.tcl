#update.tcl - System to check if there are new files avaliable.
#update(url) is the dir where the tcls are stored.
#update(check) is the file that (when called via http) will tell what the filesizes are.

set update(url) "http://edge09.codebin.dk/files/"
set update(check) "http://edge09.codebin.dk/edge.php"

bind dcc n|- checkupdate dcc:checkupdate

proc dcc:checkupdate {h i a} {
 global edge update
 set edge(chknick) $i
 set sock [egghttp:geturl $update(check) callback:checkupdate]
}

proc callback:checkupdate {sock} {
 global edge
 set edge(getfiles) ""
 set buffer [egghttp:data $sock]
 egghttp:cleanup $sock
 foreach line [split $buffer "\n"] {
  regsub -all "<>" $line "" line
  set file [lindex $line 0]
  if {![file exists edge/$file]} { shto "\002$file dont exist\002" $edge(chknick) ; lappend edge(getfiles) $file ; continue }
  if {[lindex $line 1] != [file size edge/$file]} {
   set t [expr [unixtime] - [lindex $line 2]]
   if {$t < 600} {
        shto "\0034\002 Warning: \002\003 File $file is less than 10minutes old, its recommended that you wait a while before updateing, to be sure all bugs are fixed in it." $edge(chknick)
   }
   shto "\002$file changed.\002" $edge(chknick)
   lappend edge(getfiles) $file
  }
 }
 if {$edge(getfiles) == ""} { shto "All files up to date." $edge(chknick) } else { 
  if {$edge(chknick)!=""} {
   putidx $edge(chknick) "File list saved, you will have to do .update within 1 minute."
  } else {
   do:update $edge(getfiles)
  }
 }
 if {![string match "*utimer 60 resetgetfiles*" [timers]]} { utimer 60 resetgetfiles }
}

proc resetgetfiles {} {
 global edge
 if {$edge(getfiles) != ""} { putidx $edge(chknick) "Stored file list deleted, you will have to run .checkupdate again" }
 set edge(chknick) ""
 set edge(getfiles) ""
}

 set edge(getfiles) ""

 bind dcc n|- update dcc:update
 
 proc dcc:update {h i a} {
  global edge
  if {$a == "-beta"} {
	if {![info exists edge(betaok)]} {
		putidx $i "\002WARNiNG\002 You are about to download a beta version of Edge, this is work-in-progress and while it will probaly work, it could crash your bot with no fix out ..."
		putidx $i "\002WARNiNG\002 Trigger .update -beta again if you really want to continue."
		set edge(betaok) 1
		return 0
	} else {
		if {![info exists edge(botid)]} {
			putidx $i "edge(botid) is not set!  you need a botid for beta to work, sign up for beta testing on codebin.dk"
			return 0
		}
		putidx $i "\002BETA\002 Downloading beta files."
		do:beta:update
	}
  }
    
  if {$a == "-force"} {
	putidx $i "Forceing bot to update all files."
	do:update $edge(files)
  } else {
	  if {$edge(getfiles)==""} { putidx $i "Error - You must run .checkupdate first.  (net update/remote update/force update dont require .checkupdate first)" ; return 0 }
  }
  putcmdlog "#$h# Update in progess : [llength $edge(getfiles)] file(s) being updated."
  do:update $edge(getfiles)
 }

 proc do:update {filelist} {
  global edge update
   set edge(oldbuild) $edge(build)
   set url $update(url)
   foreach file [split $filelist] {
   if {[file exists $file]} { file delete $file.1 }
   catch { exec wget $url$file }
   if {[file exists $file]} {
    file rename -force $file edge/$file
    putlog "$file updated."
   } else {
    putlog "Update of $file failed."
   }
  }
  set sock [egghttp:geturl $update(check) callback:vertifyupdate]
 } 

proc callback:vertifyupdate {sock} {
 global edge
 set ok 0
 set buffer [egghttp:data $sock]
 egghttp:cleanup $sock
 foreach line [split $buffer "\n"] {
  regsub -all "<>" $line "" line
  set file [lindex $line 0]
  if {![file exists edge/$file]} {
	putlog "Update of $file failed (file dont exist)"
	set ok 1
	break
  }
  if {[lindex $line 1] != [file size $file]} {
  	putlog "Update of $file failed (Wrong filename)"
	set ok 1
	break
  }
 }
 if {$ok == 0} { 
  putlog "!!! Update done - Rehashing !!!"
  save
  backup
  #Saving before possible crash eh :)
  utimer 2 "rehash"
  utimer 30 "edge:clean:dupes"
  set edge(getfiles) ""
 } else { 
  dccbroadcast "Error in update - rehash halted, you should retry update in a few minutes.."
 }
}

proc edge:clean:dupes {} {
 foreach file [glob *] {
  set end [string range $file [expr [string length $file]-2] end]
  if {$end==".1" || $end==".2" || $end==".3" || $end==".4" || $end==".5" || $end==".6" || $end==".7" || $end==".8" || $end==".9"} {
   catch { file delete $file }
  }
 } 
}