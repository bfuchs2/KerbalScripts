print "ascent guidance engaged".

//des_ap is 100000, vs is 10, ceil is 10000
lock throttle to 1.
until APOAPSIS > des_ap {
  set desv to max(vs*(1 - ALT:RADAR/(ceil-ALTITUDE + ALT:RADAR)), 0).
  set R to ALTITUDE + SHIP:BODY:RADIUS.
  set weight to SHIP:MASS * SHIP:BODY:MU / (R*R).
  set accel to (desv - SHIP:VERTICALSPEED)/vs.
  set pitch to arcsin((SHIP:MASS*accel + weight)/SHIP:AVAILABLETHRUST).
  
  set S to arcsin(weight/SHIP:AVAILABLETHRUST).
  //set pitch to S*(1 - VERTICALSPEED/desv). //old, more efficient but less safe method
  lock steering to heading(90, min(max(pitch, 0), 90)).
  print "S: " + S at (0, 19).
  print "vert: " + VERTICALSPEED at (0, 20).
  print "pitch: " + pitch at (0, 21).
  print "des_vs: " + desv at (0, 22).
}
  
lock throttle to 0.
set SHIP:CONTROL:PILOTMAINTHROTTLE to 0.