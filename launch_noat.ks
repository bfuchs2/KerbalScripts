set des_ap to 12000.
set vs to 40.
set ceil to 5000.
run ascent_noat.

set t to ETA:APOAPSIS + TIME:SECONDS.
run circularize.

run exenode.