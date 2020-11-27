# Create initial variables
fuelL = 0.0;
fuelR = 0.0;

setlistener("sim/signals/fdm-initialized", func
{
settimer(balancefuel, 1);
});

var balancefuel = func {
    fuelL = getprop("/consumables/fuel/tank/level-lbs");
    fuelR = getprop("/consumables/fuel/tank[1]/level-lbs");

    setprop("/consumables/fuel/tank/level-lbs", fuelR);
}