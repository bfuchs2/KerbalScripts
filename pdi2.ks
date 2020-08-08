set touchdownv to 1.
print "landing at " + touchdownv + " m/s".

print "initiating powered decent".
set startv to SHIP:VELOCITY:SURFACE:MAG.
set startalt to ALT:RADAR.
until SHIP:VERTICALSPEED >= -0.01 and SHIP:VELOCITY:SURFACE:MAG < 1 {
  set terrain to SHIP:ALTITUDE - ALT:RADAR.
  
  set R to terrain + SHIP:BODY:RADIUS.
  set g to SHIP:BODY:MU / (R * ALT:RADAR/3) ^ 2.
  set accel to max(0.0001, SHIP:AVAILABLETHRUST)/SHIP:MASS.
  
  if accel > g {

    // copy in formulaes for theta and t
    set root to MATH:SQRT(accel*accel*(SHIP:GROUNDSPEED*SHIP:GROUNDSPEED + SHIP:VERTICALSPEED*SHIP:VERTICALSPEED) - g*g*SHIP:GROUNDSPEED*SHIP:GROUNDSPEED).
    set theta to 2*arctan2(accel*SHIP:GROUNDSPEED + root, g*SHIP:GROUNDSPEED - accel*SHIP:VERTICALSPEED). // angle above the x axis to point the ship
    // notes: theta will be in degrees. "x axis" is defined as the axis in the plae of the "up" vector and the ship's surface velocity vector with no vertical component, where the ship's x component of surface velocity is negative
    
    set t to (SHIP:GROUNDSPEED*root + accel*(SHIP:GROUNDSPEED*SHIP:GROUNDSPEED + SHIP:VERTICALSPEED*SHIP:VERTICALSPEED) - g*SHIP:GROUNDSPEED*SHIP:VERTICALSPEED)/(accel*root + accel*accel*SHIP:GROUNDSPEED + accel*g*SHIP:VERTICALSPEED - g*g*SHIP:GROUNDSPEED).
    
    set desired_alt to SHIP:VERTICALSPEED*SHIP:VERTICALSPEED/(2*accel*MATH:SIN(theta)). // the maximum altitude that can be cancelled out at max thrust with this landing pattern
    
    set throt to desired_alt - SHIP:RADAR.
    lock throttle to min(max(desacc, 0), 1).
    
    // orient ship around angle theta
    set yaxis to (SHIP:POSITION - SHIP:BODY:POSITION):NORMALIZED. // unit vector pointing straight away from the body's surface
    set zaxis to VCRS(yaxis, SHIP:VELOCITY:SURFACE):NORMALIZED. // normal vector, up cross velocity
    if zaxix:MAG = 0 {
      lock steeting to UP.
    } else {
      set xaxis to VCRS(yaxis, zaxis):NORMALIZED. // unit vector in the x direction (against ground velocity)
      lock steering to xaxis*cos(theta) + yaxis*sin(theta).
    }
    
    print "g: " + g at (0, 21).
    print "a: " + accel at (0, 22).
    print "altitude: " + ALT:RADAR at (0, 23).
    print "throttle: " + throt at (0, 24).
  } else {
    print "Not enough thrust! Abort!" at (0, 21).
  }
}
print "touchdown!".
lock steering to UP.
set shutdown to TIME:SECONDS + 10.
lock throttle to 0.
wait until TIME:SECONDS > shutdown.
print "program ended".
set SHIP:CONTROL:PILOTMAINTHROTTLE to 0.