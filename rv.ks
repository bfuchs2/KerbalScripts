clearscreen.
set target_distance to 50. // distance (in meters) to get the two crafts within
set x to V(100, 100, 100).
set tmax to SHIP:ORBIT:PERIOD / 5.
set max_rel_v to 0.01. // relative velocity (in m/s) to get the two crafts within
set firing to FALSE. // whether or not the engines are active
if NOT HASTARGET {
  print "set ship target before running rendez-vous program".
} else {
  until x:MAG < target_distance {

    set x to SHIP:POSITION - TARGET:POSITION.
    set v to SHIP:VELOCITY:ORBIT - TARGET:VELOCITY:ORBIT.
    set R_ship to SHIP:ALTITUDE + SHIP:BODY:RADIUS.
    set R_targ to TARGET:ALTITUDE + SHIP:BODY:RADIUS.
    set g to SHIP:BODY:MU/(R_ship * R_ship)*(SHIP:POSITION - SHIP:BODY:POSITION):NORMALIZED 
      - SHIP:BODY:MU/(R_targ * R_targ)*(TARGET:POSITION - SHIP:BODY:POSITION):NORMALIZED.
    set accel to max(0.0001, SHIP:AVAILABLETHRUST)/SHIP:MASS.
  
    // regardless of saving fuel, as we approach the target, we have to slow down
    set allowed_rvel to SQRT(x:MAG*accel/5).
    // TODO set minimum velocity towards target
    set min_rvel to 10.
    
    // binary search to find optimal time to approach
    set tmax to tmax * 2.
    set tmin to 1.
    set v_min to V(20, 20, 20).
    set v_max to V(10, 0, 0).
    until (tmax - tmin) < 10 {
      set tmid to (tmax + tmin) / 2.
      set t1 to tmid + 1.
      
      // find velocity and velocity detivative at this time-target
      set dv to  -(x + 0.5*g*tmid*tmid)/tmid - v.
      set dv_1 to -(x + 0.5*g*t1*t1)/t1 - v.
      set v_min to -(x + 0.5*g*tmax*tmax)/tmax.
      set v_max to -(x + 0.5*g*tmin*tmin)/tmin.
      
      // multipliers used to calculate velocity derivative
      // set dv_mult1 to -2*(x - 0.5*g*tmid*tmid)/tmid - v.
      // set dv_mult2 to x/(tmid*tmid) + 0.5*g.
      // set dv_mult3 to g*tmid.
      // set velocity_derivative to 0.5 / dv:mag * (dv_mult1:x*dv_mult2:x*dv_mult3:x + dv_mult1:y*dv_mult2:y*dv_mult3:y + dv_mult1:z*dv_mult2:z*dv_mult3:z).
      
      
      if v_min:MAG < min_rvel {
        set tmax to tmid.
      } else if v_max:MAG > allowed_rvel {
        set tmin to tmid.
      } else if dv_1:MAG < dv:MAG {
        set tmin to tmid.
      } else {
        set tmax to tmid.
      }
    } // the optimal velocity change is "velocity"
    
    lock steering to dv.
    set throt to 0.3 * dv:MAG/accel.
    set v_ang to vang(dv, SHIP:FACING:FOREVECTOR).
    if (v_ang < 7 AND dv:MAG > 2) OR (firing AND dv:MAG > 0.02) {
      lock throttle to throt.
      set firing to TRUE.
    } else {
      lock throttle to 0.
      set firing to FALSE.
    }
    
    // print telemetry
    print "distance: " + x:MAG at (0, 20).
    print "relative v: " + v:MAG at (0, 21).
    print "target time: " + tmid at (0, 22).
    print "relative g: " + g:MAG at (0, 23).
    print "des v: " + v_max:MAG at (0, 24).
    print "dv: " + dv:MAG at (0, 25).
    print "v_ang: " + v_ang at (0, 26).
  }
  
  // we've arrived at the target, time to slow down
  print "arriving at target".
  until (v:MAG < 0.01) {
    set x to SHIP:POSITION - TARGET:POSITION.
    set v to SHIP:VELOCITY:ORBIT - TARGET:VELOCITY:ORBIT.
    set g to SHIP:BODY:MU/(R_ship * R_ship)*(SHIP:POSITION - SHIP:BODY:POSITION):NORMALIZED 
      - SHIP:BODY:MU/(R_targ * R_targ)*(TARGET:POSITION - SHIP:BODY:POSITION):NORMALIZED.
    set accel to max(0.0001, SHIP:AVAILABLETHRUST)/SHIP:MASS.
    
    set v_ang to vang(-v, SHIP:FACING:FOREVECTOR).    
    lock steering to -v.
    if v_ang < 3 {
      lock throttle to v:MAG/accel.
    } else {
      lock throttle to 0.
    }
    
    // print telemetry
    print "distance: " + x:MAG at (0, 20).
    print "relative v: " + v:MAG at (0, 21).
    print "relative g: " + g:MAG at (0, 23).
  }
  
  lock throttle to 0.
  set SHIP:CONTROL:PILOTMAINTHROTTLE to 0.
  print "rendez-vous complete".
}