// parameter maxHeight, slope

set touchdownv to 1.
print "landing at " + touchdownv + " m/s".

print "initiating powered decent".
set startv to SHIP:VELOCITY:SURFACE:MAG.
set startalt to ALT:RADAR.
set terrain to maxHeight.
until SHIP:VERTICALSPEED >= -0.01 and SHIP:VELOCITY:SURFACE:MAG < 1 {
  // estimate terrain height
  set p_altitude to ALT:RADAR.
  //set terrain to min((SHIP:ALTITUDE - ALT:RADAR)*(1 - slope*SHIP:GROUNDSPEED/SHIP:VERTICALSPEED), maxHeight).
  set terrain to SHIP:ALTITUDE - ALT:RADAR.
  
  set R to terrain + SHIP:BODY:RADIUS.
  set g to SHIP:BODY:MU / (R + p_altitude/3) ^ 2.
  set accel to max(0.0001, SHIP:AVAILABLETHRUST)/SHIP:MASS.
  
  if accel > g {

    // copy in formulaes for theta and t
    set root to SQRT(accel*accel*(SHIP:GROUNDSPEED*SHIP:GROUNDSPEED + SHIP:VERTICALSPEED*SHIP:VERTICALSPEED) - g*g*SHIP:GROUNDSPEED*SHIP:GROUNDSPEED).
    
    // theta with gravity component
    set atany to -accel*SHIP:GROUNDSPEED + root.
    set atanx to -g*SHIP:GROUNDSPEED - accel*SHIP:VERTICALSPEED.
    
    // theta without gravity component
    // set atany to -accel*SHIP:GROUNDSPEED + SQRT(accel*accel*(SHIP:GROUNDSPEED*SHIP:GROUNDSPEED + SHIP:VERTICALSPEED*SHIP:VERTICALSPEED)).
    // set atanx to -accel*SHIP:VERTICALSPEED.
    
    set theta to 2*arctan2(atany, atanx). // angle above the x axis to point the ship
    // notes: theta will be in degrees. "x axis" is defined as the axis in the plane of the "up" vector and the ship's surface velocity vector with no vertical component, where the ship's x component of surface velocity is negative
    
    set t to (-SHIP:GROUNDSPEED*root + accel*(SHIP:GROUNDSPEED*SHIP:GROUNDSPEED + SHIP:VERTICALSPEED*SHIP:VERTICALSPEED) + g*SHIP:GROUNDSPEED*SHIP:VERTICALSPEED)/(accel*root - accel*accel*SHIP:GROUNDSPEED + accel*g*SHIP:VERTICALSPEED + g*g*SHIP:GROUNDSPEED).
    set t2 to (-SHIP:GROUNDSPEED*root - accel*(SHIP:GROUNDSPEED*SHIP:GROUNDSPEED + SHIP:VERTICALSPEED*SHIP:VERTICALSPEED) - g*SHIP:GROUNDSPEED*SHIP:VERTICALSPEED)/(accel*root + accel*accel*SHIP:GROUNDSPEED - accel*g*SHIP:VERTICALSPEED - g*g*SHIP:GROUNDSPEED).
    
    set desired_vy to SQRT(2*max(0, p_altitude - 10/max(0.001, sin(theta)))*(max(0, accel*sin(theta) - g))). // the maximum vertical velocity that can be cancelled out at current altitude and thrust capacity
    
    // orient ship around angle theta
    set yaxis to (SHIP:POSITION - SHIP:BODY:POSITION):NORMALIZED. // unit vector pointing straight away from the body's surface
    set zaxis to VCRS(yaxis, SHIP:VELOCITY:SURFACE):NORMALIZED. // normal vector, up cross velocity
    set desired_steering to yaxis.
    if zaxis:MAG = 0 {
      lock steeting to UP.
    } else {
      set xaxis to VCRS(yaxis, zaxis):NORMALIZED. // unit vector in the x direction (against ground velocity)
      set desired_steering to xaxis*cos(theta) + yaxis*sin(theta).
      lock steering to desired_steering.
    }
    
    // there are multiple throttle limiters
    set throt_speed to SHIP:VELOCITY:SURFACE:MAG - touchdownv. // makes sure ship maintains a speed above touchdownv
    set throt_alt to -desired_vy - SHIP:VERTICALSPEED. // makes sure ship decelerates as it decends. This is the main throttle limiter
    set throt_angle to SHIP:FACING:FOREVECTOR * desired_steering. // only throttles engines when the ship is facing the right direction
    set throt_actual to min(throt_speed * throt_angle, throt_alt * throt_angle).
    lock throttle to min(max(throt_actual, 0), 1).
    
    print "g: " + g at (0, 21).
    print "a: " + accel at (0, 22).
    print "p_altitude: " + p_altitude at (0, 23).
    print "throttle: " + throt_actual at (0, 24).
    print "y: " + atany at (0, 25).
    print "x: " + atanx at (0, 26).
    print "theta: " + theta at (0, 27).
    print "time: " + t at (0, 28).
    print "t2: " + t2 at (0, 29).
    print "desired: " + desired_vy at (0, 30).
    print "terrain: " + terrain at (0, 31).
    print "sea level: "  + SHIP:ALTITUDE at (0, 32).
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