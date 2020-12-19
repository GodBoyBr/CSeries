# A220 Fly By Wire by C-FWES(Wesley Ou)
# Control Surface Constants
# Aileron
var aileron = getprop("controls/flight/aileron");

# Elevator
var elevator = getprop("controls/flight/elevator");

# Elevator Trim
var elevatortrim = getprop("controls/flight/elevator-trim");

# Pitch
var pitch = getprop("orientation/pitch-deg");

# Roll
var roll = getprop("orientation/roll-deg");

# Airspeed
var airspeed = getprop("velocities/airspeed-kt");

# Altitude AGL
var altitudeagl = getprop("position/altitude-agl-ft");

# Throttle Position
var throttlepos1 = getprop("controls/engines/engine[0]/throttle");
var throttlepos2 = getprop("controls/engines/engine[1]/throttle");

# Wind speed and position
var winddir = getprop("environment/wind-from-heading-deg");
var windspeed = getprop("environment/wind-speed-kt");