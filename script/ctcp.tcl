proc edge:ctcp:version {nick uhost handle dest keyword text} {
 global edge versions
 set randomversion [lindex $versions [rand [llength $versions]]]
 ctcpr $nick VERSION "Edge:$edge(version):$edge(build) $randomversion"
}

proc edge:ctcp:custom:version {nick uhost handle dest keyword text} {
 global edge versions
 ctcpr $nick VERSION "$edge(customctcp)"
}

proc edge:ctcp:time {nick uhost handle dest keyword text} {
 ctcpr $nick TIME "TIME f0r y0u t0 D13!!!"
}
