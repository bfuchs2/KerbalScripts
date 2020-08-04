// circularizes the current vessel using a node at time t
// this is most efficient with t = ETA:PERIAPSIS + TIME:SECONDS, or ETA:APOAPSIS + TIME:SECONDS

//parameter t. (global time in seconds)
set burnpos to positionat(SHIP, t) - SHIP:BODY:POSITION.
set burnalt to burnpos:mag - SHIP:BODY:RADIUS.
set sdesired to sqrt(ship:body:mu / burnpos:mag).
set vactual to velocityat(SHIP, t):orbit.
set normal to vcrs(burnpos, vactual).
set vdesired to vcrs(normal, burnpos):NORMALIZED * sdesired.
set radial to vectorexclude(vactual, vdesired).
set prog to (vectorexclude(radial, vdesired) - vactual).

set solution to NODE(t, radial:MAG, 0, prog:MAG).
if vang(vactual, burnpos) < 90 {
  print "reversing radial".
  set solution:RADIALOUT to -solution:RADIALOUT.
}
if vdesired:MAG < vactual:MAG {
  print "reversing prograde".
  set solution:PROGRADE to -solution:PROGRADE.
}
add solution.
print "circularizing...".
print "actual velocity: " + vactual:MAG.
print "desired velocity: " + vdesired:MAG.
print "burnalt: " + burnalt.
print "steering losses: " + radial:MAG/(prog+radial):MAG.
print "gravity losses: " + vdot(solution:DELTAV, burnpos)/(solution:DELTAV:MAG * burnpos:MAG).

