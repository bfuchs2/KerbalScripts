// calculates some statistics about the next maneuver node, and sets them as global variables for use by other scripts

//parameter burndv (m/s)
//TODO calc dv and isp for each stage

set maxflow to 0.
set mstart to SHIP:MASS.
LIST ENGINES IN leng.
FOR eng IN leng {
  IF eng:AVAILABLETHRUST > 0 {
    set flow to eng:AVAILABLETHRUST / (CONSTANT:g0 * eng:ISP).  // flow rate for each engine, kg/s
    set maxflow to flow + maxflow.
  }
}

set mend to mstart.
set burnt to 0.
if maxflow > 0 {
  set isp to SHIP:AVAILABLETHRUST / (9.81 * maxflow).  // ship's total Isp, s
  set mend to mstart * CONSTANT:E ^ (- burndv / 9.81 / isp).  // the estimated final mass after the ship completes the burn, kg
  set has_fuel to mend > SHIP:DRYMASS.  // true if the ship has enough fuel to complete the burn
  set burnt to max(0, (SHIP:MASS - mend) / maxflow).  // the time required to complete the burn, s
}