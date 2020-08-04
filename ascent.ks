// launches a ship into a westward suborbital trajectory with apoapsis = des_ap

print "launch guidance engaged".

/// des_ap is 100000

until APOAPSIS > des_ap {
	set pitch to 90 * (1 - SHIP:OBT:APOAPSIS / des_ap).
	set ap_throttle to (des_ap - SHIP:OBT:APOAPSIS) / 100.  // throttle vessel as ap approaches dev_ap, to attenuate apoapsis overshoot
	set R to ALTITUDE + SHIP:BODY:RADIUS.
	set weight to SHIP:MASS * SHIP:BODY:MU / (R*R).

	// conversion from metric tons (SHIP:MASS) to kg, cancels out with conversion from KPa (sea level pressure) to Pa
	set coef to (2 * CONSTANT:IdealGas * max(100, SHIP:BODY:ATM:ALTITUDETEMPERATURE(ALTITUDE)) * SHIP:MASS * SHIP:BODY:MU) / (5 * SHIP:BODY:ATM:MolarMass * SHIP:BODY:ATM:SeaLevelPressure * CONSTANT:AtmToKPa).  // coefficient used for calculating optimal speed and acceleration
	// TODO: replace SHIP:BODY:ATM:Scale with calculated scale height, or use KOS's builtin pressure function and approximate derivative
	set scale to 10000.
	set exp to CONSTANT:E ^ (ALTITUDE / scale). // e^alt/H, dimensionless pressure drop off
	// vopt is the velocity at which drag force is equal to the force of gravity on the ship
	set vopt to SQRT((coef * exp) / (R * R)).

	// formula for optimal acceleration @ optimal velocity; only useful for telemetry as acceleration can be feathered
	set aopt to 0.5 / SQRT(coef * exp / (R * R)) * coef * (-2 / R + 1 / scale ) * exp * SHIP:VERTICALSPEED / (R * R).
	if SHIP:AIRSPEED > vopt {
	  	set drag_throttle to SHIP:MASS * aopt / max(SHIP:AVAILABLETHRUST, 0.1).
	} ELSE {
	   set drag_throttle to 1.
	}
	// set drag_throttle to vopt - SHIP:AIRSPEED.

	print "Ap: " + APOAPSIS at (0, 19).
	print "ap_throttle " + ap_throttle at (0, 20).
	print "optimal velocity: " + vopt at (0, 21).
	print "drag throttle: " + drag_throttle at (0, 22).
	print "pitch: " + pitch at (0, 23).
	

	lock throttle to min(max(0, min(ap_throttle, drag_throttle)), 1).
	lock steering to heading(90, min(max(pitch, 0), 90)).
}

lock throttle to 0.
set SHIP:CONTROL:PILOTMAINTHROTTLE to 0.