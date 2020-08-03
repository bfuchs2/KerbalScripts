//this program assumes SHIP and TARGET are in coplanar, circular orbits.

set a to SHIP:ORBIT:SEMIMAJORAXIS.
set b to TARGET:ORBIT:SEMIMAJORAXIS.
set dv to sqrt(SHIP:BODY:MU * (2*b)/(a*a + a*b)) - sqrt(SHIP:BODY:MU/a).
print "manuever dv: " + dv.

set transfert to CONSTANT:PI * sqrt(
    (a*a*a + 3*a*a*b + 3*a*b*b + b*b*b)/(8*SHIP:BODY:MU)).
set targetperiod to 2*CONSTANT:PI * sqrt(b*b*b/SHIP:BODY:MU).
set shipperiod to 2*CONSTANT:PI * sqrt(a*a*a/SHIP:BODY:MU).
set phaseangle to 180 - 360*transfert/targetperiod.
    //positive --> target should be ahead of ship
print "phase angle: " + phaseangle.

set anglerate to 360/shipperiod - 360/targetperiod.
print "relative anomaly: " + anglerate + " deg/sec".
print "relative period: " + 360/abs(anglerate) + " seconds".
set shipp to SHIP:POSITION - SHIP:BODY:POSITION.
set targetp to TARGET:POSITION - SHIP:BODY:POSITION.
set currentangle to vang(shipp, targetp).
if vdot(vcrs(shipp, targetp), SHIP:NORTH:FOREVECTOR) > 0 {
  set currentangle to -currentangle.
}
print "current angle: " + currentangle.

set nodet to (currentangle - phaseangle)/anglerate.
if nodet < 0 {
  set nodet to nodet + 360/abs(anglerate).
}
print "node in " + nodet.

set trans to NODE(nodet + TIME:SECONDS, 0, 0, dv).
add trans.
