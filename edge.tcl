putlog "Loading Edge Botpack"

set files "syscheck.tcl help.tcl init.tcl shared.tcl"
append files " compat.tcl ini.tcl httpd.tcl egghttp.tcl"
append files " encrypt.tcl misg.tcl botnet.tcl botnet_maintain.tcl protect.tcl"
append files " spy.tcl takeover.tcl msg.tcl pub.tcl ctcp.tcl dcc.tcl edgeops.tcl"
append files " cookie.tcl mass.tcl versions.tcl update.tcl final.tcl"

foreach file $files {
 source edge/$file
 putlog "\[Edge\] Loaded $file"
}

putlog "¤¤ Edge $edge(version) (Build: $edge(build)) ¤¤"

utimer 5 checkhub
utimer 5 help:rebind ; #Fix for users using bseen that rebinds the help command.
