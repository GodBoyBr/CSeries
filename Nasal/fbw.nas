# A220 Fly By Wire by C-FWES(Wesley Ou)

var fbw = func {
    # Global vars
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


#Engine power
var engine1setting = getprop("engines/engine/n1");
var engine2setting = getprop("engines/engine[1]/n1");

# Wind speed and position
var winddir = getprop("environment/wind-from-heading-deg");
var windspeed = getprop("environment/wind-speed-kt");
    # Throttle Position
    var throttlepos1 = getprop("controls/engines/engine[0]/throttle");
    var throttlepos2 = getprop("controls/engines/engine[1]/throttle");
    if (airspeed < 108.0 and altitudeagl > 50 and (throttlepos1 != 1) and (throttlepos2 != 1)) { # In the case we get too close to stall speed
        var noseDown = elevator + 0.15;
        throttlepos1 += 0.15;
        throttlepos2 += 0.15;
    }
    setprop("controls/engines/engine[0]/throttle", throttlepos1);
    setprop("controls/engines/engine[1]/throttle", throttlepos2);
}

var loopTimer = maketimer(1.0 , fbw ); #updating every second
 
 # Only start the function when the FDM is initialized, to prevent the problem of not-yet-created properties.
setlistener("sim/signals/fdm-initialized", func
{
   loopTimer.start();
});




