// aborts landing, and goes back into orbit
// hint: BACKSPACE activates ABORT action group in-game

set RCS to true.
lock steering to UP.
lock throttle to 1.
WAIT UNTIL SHIP:VERTICALSPEED > 0.

run launch_noat.