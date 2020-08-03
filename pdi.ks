set touchdownv to 1.
print "landing at " + touchdownv + " m/s".
lock steering to -SHIP:VELOCITY:SURFACE.

print "initiating powered decent".
set startv to SHIP:VELOCITY:SURFACE:MAG.
set startalt to ALT:RADAR.
until SHIP:VERTICALSPEED >= -0.01 and SHIP:VELOCITY:SURFACE:MAG < 1{
  set terrain to SHIP:ALTITUDE - ALT:RADAR.
  set lower to TIME:SECONDS.
  set upper to TIME:SECONDS + ETA:PERIAPSIS.
  until upper - lower < 0.1 {
    set mid to (lower + upper)/2.
    set pos to SHIP:BODY:ALTITUDEOF(positionat(SHIP, mid)) - terrain.
    if pos > 0 {
      set lower to mid.
    } else {
      set upper to mid.
    }
  }
  set impactt to (upper + lower)/2.
  print "impact in " + round(impactt-TIME:SECONDS) + " seconds" at (0, 20).
  set dx to (positionat(SHIP, impactt) - SHIP:POSITION):MAG.
  set R to terrain + SHIP:BODY:RADIUS.
  set srfweight to SHIP:MASS * SHIP:BODY:MU / (R*R).
  set burndv to SHIP:VELOCITY:SURFACE:MAG. //velocityat(SHIP, impactt):SURFACE:MAG.
  set accel to max(0.0001, SHIP:AVAILABLETHRUST-srfweight)/SHIP:MASS.
  set burndx to burndv*burndv/(2*accel).
  set desv to max(sqrt(2*max(ALT:RADAR-20, 0)*accel), touchdownv).
  set vact to SHIP:VELOCITY:SURFACE:MAG.
  if SHIP:VERTICALSPEED > 0 {
    set vact to -vact.
  }
  set desacc to (vact - desv).
  lock throttle to min(max(desacc, 0), 1).
  print "desv: " + desv at (0, 21).
  print "vactual: " + vact at (0, 22).
  print "altitude: " + ALT:RADAR at (0, 23).
  print "throttle: " + desacc at (0, 24).
}
print "touchdown!".
lock steering to UP.
set shutdown to TIME:SECONDS + 10.
lock throttle to 0.
wait until TIME:SECONDS > shutdown.
print "program ended".
set SHIP:CONTROL:PILOTMAINTHROTTLE to 0.