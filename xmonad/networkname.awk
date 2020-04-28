(NR>=2 && $4!="--") { print $1; exit }
ENDFILE             { print "no connection" }
