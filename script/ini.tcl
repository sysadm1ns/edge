##   PROCEDURE:   ini_read <ini file> <section> <item>
##   PROCEDURE:   ini_write <ini file> <section> <item> [value]
##   PROCEDURE:   ini_remove <ini file> <section> [item]


proc ini_read {file section item} {
 if {![file exists $file]} { return "\;" }
 set fp [open $file r]
 set look 0
 while {![eof $fp]} {
  set line [gets $fp]
  if {$look==1} {
   set newline [split $line "="]
   if {[string match -nocase $item [join [lindex $newline 0]]]} {
    close $fp
    return [join [lindex $newline 1]]
   }
  }
  if {"\[$section\]"==$line} { set look 1 }
 }
 close $fp
 return "\;"
}

proc ini_write {inifile section item value} {
# Look for [$section] then set ok 0
# at next [(.*)] if ok==0 write entry and [] to new file
  set section [string tolower [join [lindex [list [split $section]] 0]]]
  set item [join [lindex [list [split $item]] 0]]
  set value [join [lrange [split $value] 0 end]]
  if {[lindex $inifile 0] == "" || [lindex $section 0] == "" || [lindex $item 0] == ""} { return 0 }
  if {![file exists $inifile] || [file size $inifile] == 0} {
    set filew [open $inifile w]
    puts $filew "\[$section\]"
    puts $filew "[string tolower $item]=$value"
    close $filew; return 1
  }
  set fileo [open $inifile r]
  set cursect ""; set sect ""
  while {![eof $fileo]} {
    set rline [string trim [gets $fileo]]
    if {$rline != "" || [string index $rline 0] != "\;"} {
      if {[string index $rline 0] == "\[" && [string index $rline [expr [string length $rline] - 1]] == "\]"} {
        set cursect [string tolower [string range $rline 1 [expr [string length $rline] - 2]]]
        lappend sect $cursect
      } {
        set im [string tolower [string range $rline 0 [expr [string first = $rline] - 1]]]
        set vl [string range $rline [expr [string first = $rline] + 1] end]
        lappend [join "ini $cursect" ""]($im) $vl
      }
    }
  }
  close $fileo; unset fileo
  if {[lsearch $sect $section] == -1} { lappend sect $section }
  set [join "ini $section" ""]([string tolower $item]) $value
  set fileo [open $inifile w]
  foreach sct $sect {
    puts $fileo "\[$sct\]"
    foreach ite [array names [join "ini $sct" ""]] {
      set ite [lindex $ite 0]
      set valu [set [join "ini $sct" ""]($ite)]
      if {$ite != ""} {
        puts $fileo "$ite=[join $valu]"
      }
    }
    puts $fileo ""
  }
  close $fileo
  return 1
}

proc ini_remove { inifile section item } {
# Look for [$section] then set ok 0
# look for item=
  set section [string tolower [lindex [list [split $section]] 0]]
  set item [lindex [list [split $item]] 0]
  if {[lindex $inifile 0] == ""} { return 0 }
  if {![file exists $inifile]} { return 0 }
  if {$section == ""} { return 0 }
  set fileo [open $inifile r]
  set cursect ""; set sect ""
  while {![eof $fileo]} {
    set rline [string trim [gets $fileo]]
    if {$rline != "" || [string index $rline 0] != "\;"} {
      if {[string index $rline 0] == "\[" && [string index $rline [expr [string length $rline] - 1]] == "\]"} {
        set cursect [string tolower [string range $rline 1 [expr [string length $rline] - 2]]]
        lappend sect $cursect
      } {
        set im [string tolower [string range $rline 0 [expr [string first = $rline] - 1]]]
        set vl [string range $rline [expr [string first = $rline] + 1] end]
        lappend [join "ini $cursect" ""]($im) $vl
      }
    }
  }
  close $fileo; unset fileo
  set sesect [lsearch $sect $section]
  if {$sesect == -1} {
    return 0
  } {
    if {$item == ""} { set sect [lreplace $sect $sesect $sesect] }
  }
  set seitem [lsearch [array names [join "ini $section" ""]] $item]
  if {$seitem != -1} {
    unset [join "ini $section" ""]($item)
    if {[llength [array names [join "ini $section" ""]]] == 1} {
      set sect [lreplace $sect $sesect $sesect]
    }
  }
  if {[llength $sect] == 0} { file delete $inifile; return 1 }
  set fileo [open $inifile w]
  foreach sct $sect {
    puts $fileo "\[$sct\]"
    foreach ite [array names [join "ini $sct" ""]] {
      set ite [lindex $ite 0]
      set valu [set [join "ini $sct" ""]($ite)]
      if {$ite != "" && [lindex $valu 0] != ""} {
        puts $fileo "$ite=[join $valu]"
      }
    }
    puts $fileo ""
  }
  close $fileo
  return 1
}
