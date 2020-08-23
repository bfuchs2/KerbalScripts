// launches a ship into a westward suborbital trajectory with apoapsis = des_ap

print "launch guidance engaged".

/// des_ap is 100000

until APOAPSIS > des_ap {
	set pitch to 90 * (1 - SHIP:OBT:APOAPSIS / des_ap).
	set ap_throttle to max(0.01, (des_ap - SHIP:OBT:APOAPSIS) / 100).  // throttle vessel as ap approaches dev_ap, to attenuate apoapsis overshoot
	set R to ALTITUDE + SHIP:BODY:RADIUS.
	set weight to SHIP:MASS * SHIP:BODY:MU / (R*R).

	// conversion from metric tons (SHIP:MASS) to kg, cancels out with conversion from KPa (sea level pressure) to Pa
	set coef to (2 * CONSTANT:IdealGas * max(100, SHIP:BODY:ATM:ALTITUDETEMPERATURE(ALTITUDE)) * SHIP:MASS * SHIP:BODY:MU) / (100 * SHIP:BODY:ATM:MolarMass * CONSTANT:AtmToKPa).  // coefficient used for calculating optimal speed and acceleration
	// TODO: replace SHIP:BODY:ATM:Scale with calculated scale height, or use KOS's builtin pressure function and approximate derivative
	// vopt is the velocity at which drag force is equal to the force of gravity on the ship
	set vopt to SQRT(coef / (max(0.0001, SHIP:BODY:ATM:ALTITUDEPRESSURE(ALTITUDE)) * R * R)).

	set drag_throttle to vopt - SHIP:AIRSPEED.

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