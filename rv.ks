clearscreen.
set target_distance to 100. // distance (in meters) to get the two crafts within
set max_rel_v to 0.01. // relative velocity (in m/s) to get the two crafts within
set firing to FALSE. // whether or not the engines are active
if NOT SHIP:HASTARGET {
  print "set ship target before running rendez-vous program"
} else {
  until (SHIP:POSITION - SHIP:TARGET:POSITION):MAG < target_distance {

    set x to SHIP:POSITION - SHIP:TARGET:POSITION.
    set v to SHIP:VELOCITY:ORBIT - SHIP:TARGET:VELOCITY:ORBIT.
    set R_ship to SHIP:ALTITUDE + SHIP:BODY:RADIUS.
    set R_targ to SHIP:TARGET:ALTITUDE + SHIP:BODY:RADIUS.
    set g to SHIP:BODY:MU/(R_ship * R_ship)*(SHIP:POSITION - SHIP:BODY:POSITION):NORMALIZED 
      - SHIP:BODY:MU/(R_targ * R_targ)*(SHIP:TARGET:POSITION - SHIP:BODY:POSITION):NORMALIZED.
    set accel to max(0.0001, SHIP:AVAILABLETHRUST)/SHIP:MASS.
  
    // regardless of saving fuel, as we approach the target, we have to slow down
    set allowed_rvel to SQRT(x:MAG*accel:MAG/5).
    
    // binary search to find optimal time to approach
    set tmax to SHIP:ORBIT:PERIOD / 5.
    set tmin to 1.
    set v_min to V(20, 20, 20).
    set v_max to V(10, 0, 0).
    while (v_max - v_min):MAG > 0.001 {
      set tmid to (tmax + tmin) / 2.
      
      // find velocity and velocity detivative at this time-target
      set velocity to  -(x + 0.5*g*tmid*tmid)/tmid - v.
      set v_min to -(x + 0.5*g*tmin*tmin)/tmin - v.
      set v_max to -(x + 0.5*g*tmax*tmax)/tmax - v.
      
      // multipliers used to calculate velocity derivative
      set dv_mult1 to -2*(x - 0.5*g*tmid*tmid)/tmid - v.
      set dv_mult2 to x/(tmid*tmid) + 0.5*g.
      set dv_mult3 to g*tmid.
      set velocity_derivative = 0.5 / velocity:mag * (dv_mult1:x*dv_mult2:x*dv_mult3:x + dv_mult1:y*dv_mult2:y*dv_mult3:y + dv_mult1:z*dv_mult2:z*dv_mult3:z).
      
      if velocity_derivative > 0 OR v_max:MAG > allowed_rvel{
        set tmax to tmid.
      } else {
        set tmin to tmid.
      }
    } // the optimal velocity change is "velocity"
    
    lock steering to velocity.
    set throt to velocity/accel.
    if vang(velocity, SHIP:FACING:FOREVECTOR) < 3 AND (velocity > 2 or (firing AND velocity > 0.02)) {
      lock throttle to throt.
    }
    
    // print telemetry
    print "distance: " + x:MAG at (0, 20).
    print "relative v: " + v:MAG at (0, 21).
    print "target time: " + tmid at (0, 22).
    print "relative g: " + g:MAG at (0, 23).
  }
  
  // we've arrived at the target, time to slow down
  until (v < 0.01) {
    print "arriving at target".
    set x to SHIP:POSITION - SHIP:TARGET:POSITION.
    set v to SHIP:VELOCITY:ORBIT - SHIP:TARGET:VELOCITY:ORBIT.
    set g to SHIP:BODY:MU/(R_ship * R_ship)*(SHIP:POSITION - SHIP:BODY:POSITION):NORMALIZED 
      - SHIP:BODY:MU/(R_targ * R_targ)*(SHIP:TARGET:POSITION - SHIP:BODY:POSITION):NORMALIZED.
    set accel to max(0.0001, SHIP:AVAILABLETHRUST)/SHIP:MASS.
    
    lock steering to v.
    lock throttle to v:MAG/accel.
    
    // print telemetry
    print "distance: " + x:MAG at (0, 20).
    print "relative v: " + v:MAG at (0, 21).
    print "relative g: " + g:MAG at (0, 23).
  }
  
  lock throttle to 0.
  set SHIP:CONTROL:PILOTMAINTHROTTLE to 0.
  print "rendez-vous complete".
}