// balanced landing autopilot that increases efficiency while sacrificing little safety
// parameter maxHeight

set touchdownv to 1.
print "landing at " + touchdownv + " m/s".

print "initiating powered decent".
set startv to  SHIP:VELOCITY:SURFACE:MAG.
set startalt to ALT:RADAR.
set old_alt to ALT:RADAR.
set old_seconds to TIME:SECONDS.
set p_vertvel to SHIP:VERTICALSPEED.

until (p_vertvel >= -0.01 AND SHIP:VELOCITY:SURFACE:MAG < 1 AND p_altitude < 10) or ABORT {
  
  // estimate terrain height
  set p_altitude to ALT:RADAR.
  set terrain to SHIP:ALTITUDE - ALT:RADAR.
  set R to terrain + SHIP:BODY:RADIUS.
  set g to SHIP:BODY:MU / (R + p_altitude/3) ^ 2.
  set g_adj to g - (SHIP:GROUNDSPEED * SHIP:GROUNDSPEED)/(SHIP:ALTITUDE + SHIP:BODY:RADIUS).  // gravity adjusted for centipetal force
  set accel to max(0.0001, SHIP:AVAILABLETHRUST)/SHIP:MASS.
  
  // estimate vertical speed based on radar point differential
  wait until TIME:SECONDS - old_seconds > 0.
  set new_seconds to TIME:SECONDS.
  set vert_est to (p_altitude - old_alt)/(new_seconds - old_seconds).
  set old_alt to p_altitude.
  set old_seconds to TIME:SECONDS.
  set p_vertvel to MIN(vert_est, SHIP:VERTICALSPEED).
  
  if accel > g {

    // copy in formulaes for theta and t
    set root to SQRT(accel*accel*(SHIP:GROUNDSPEED*SHIP:GROUNDSPEED + p_vertvel*p_vertvel) - g_adj*g_adj*SHIP:GROUNDSPEED*SHIP:GROUNDSPEED).
    
    // theta with gravity component
    set atanyg to -accel*SHIP:GROUNDSPEED + root.
    set atanxg to -g_adj*SHIP:GROUNDSPEED - accel*p_vertvel.
    
    // theta without gravity component
    set atany to -accel*SHIP:GROUNDSPEED + SQRT(accel*accel*(SHIP:GROUNDSPEED*SHIP:GROUNDSPEED + p_vertvel*p_vertvel)).
    set atanx to -accel*p_vertvel.
    
    set theta_g to 2*arctan2(atanyg, atanxg).
    set theta_nog to 2*arctan2(atany, atanx).
    
    // move both thetas into the 0 to 360 range
    until theta_g >= 0 {
      set theta_g to theta_g + 360.
    }
    set theta_g to mod(theta_g, 360).
    until theta_nog >= 0 {
      set theta_nog to theta_nog + 360.
    }
    set theta_nog to mod(theta_nog, 360).
    
    // interpolate between theta_g and theta_nog depending on fraction of height below maxHeight
    set interp to max(0, min(1, p_altitude/maxHeight)).
    set theta_optimal to theta_g*interp + theta_nog*(1-interp). // angle above the x axis to point the ship
    // notes: theta will be in degrees.
    
    set desired_vy to max(SQRT(2*max(0, p_altitude - 10)*(max(0, accel*sin(theta_optimal) - g_adj))), touchdownv). // the maximum vertical velocity that can be cancelled out at current altitude and thrust capacity at the current angle
    
    set num to p_vertvel*p_vertvel/(2*max(1, p_altitude - SHIP:VELOCITY:SURFACE:MAG)) + g_adj.
    set theta_emergency to arcsin(max(0, min(1, num/max(0.00001, accel)))).  // minimum angle that will allow the craft to lose its velocity before impact
    until theta_emergency >= 0 {
      set theta_emergency to theta_emergency + 360.
    }
    set theta_emergency to mod(theta_emergency, 360).
    set theta to max(theta_emergency, theta_optimal).
    
    // "x axis" is defined as the axis in the plane of the "up" vector and the ship's surface velocity vector, where the ship's x component of surface velocity is negative
    // in other words, "x axis" is a unit vector in the oposite direction of the ship's "ground" velocity
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
    set throt_alt to -desired_vy - p_vertvel. // makes sure ship decelerates as it decends. This is the main throttle limiter
    set throt_em to theta_emergency - theta_optimal.  // if emergency theta is substantially higher than the optimal theta, slow down
    set throt_vert to -p_vertvel. // only engage engines while ship is actually descending
    set throt_angle to max(0, SHIP:FACING:FOREVECTOR * desired_steering). // only throttles engines when the ship is facing the right direction
    set throt_actual to throt_angle * min(throt_vert, min(throt_speed, max(throt_em, throt_alt))).
    lock throttle to min(max(throt_actual, 0), 1).
    
	// control landing gear and RCS
	set GEAR to p_altitude < 1000.
	set RCS to throt_actual > -2 AND (throt_angle < 0.995 OR SHIP:ANGULARVEL:MAG > 0.06).
	
    // print telemetry
    print "g: " + g at (0, 21).
    print "a: " + accel at (0, 22).
    print "p_altitude: " + p_altitude at (0, 23).
    print "throttle: " + throt_actual at (0, 24).
    print "g_adj: " + g_adj at (0, 25).
    print "desired vy: " + desired_vy + " " at (0, 27).
    print "actual vy: " + p_vertvel at (0, 28).
    print "terrain: " + terrain at (0, 29).
    print "theta: " + theta_optimal + " " at (0, 30).
    print "theta_g: " + theta_g at (0, 31).
    print "theta_nog: " + theta_nog at (0, 32).
    print "theta_em: " + theta_emergency + " " at (0, 33).
  } else {
    print "Not enough thrust! Abort!" at (0, 21).
  }
}

if ABORT {
  set ABORT to false.
  run abort_landing.
} else {
  print "touchdown!".
  lock steering to UP.
  set shutdown to TIME:SECONDS + 10.
  lock throttle to 0.
  wait until TIME:SECONDS > shutdown.
  print "program ended".
} 
set SHIP:CONTROL:PILOTMAINTHROTTLE to 0.