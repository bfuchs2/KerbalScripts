set des_ap to 100000.
run ascent.

set t to ETA:APOAPSIS + TIME:SECONDS.
run circularize.

run exenode.