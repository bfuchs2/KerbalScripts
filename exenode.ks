// executes the next manuever node

clearscreen.

set node to NEXTNODE.
set startdir to node:DELTAV:NORMALIZED.
set burndv to node:DELTAV:MAG.
run burn_stat.
print "burn time: " + burnt.
LOCK STEERING to node:DELTAV.
LOCK THROTTLE to 0.
until node:ETA <= burnt/2+1 {
  print "burn in " + (node:ETA - burnt/2 - 1) at (0, 16).
}

set startt to TIME:SECONDS.
LOCK THROTTLE to min(node:DELTAV:MAG*SHIP:MASS/(1+SHIP:AVAILABLETHRUST), 1).
until vdot(startdir, node:DELTAV) <= 0 {
  print "executing manuever... " + round(100*(1 - node:DELTAV:MAG/burndv)) + " %" at (0, 17).
}
print "engine shutdown".
print "burn completed with efficiency " + LN(mstart/mend)/LN(mstart/SHIP:MASS).
lock throttle to 0.
print "actual burn time: " + (TIME:SECONDS - startt).
set SHIP:CONTROL:PILOTMAINTHROTTLE to 0.
