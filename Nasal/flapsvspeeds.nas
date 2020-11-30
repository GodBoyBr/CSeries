 # Create initial announced variables at startup of the sim
    V1 = 1.0;
    VR = 2.0;
    V2 = 3.0;
	V12 = 0.0;
	VR2 = 0.0;
	V22 = 0.0;

 
 # The actual function
setlistener("sim/signals/fdm-initialized", func
{
settimer(vspeeds, 1);
});

 var vspeeds = func {
 
        # Create/populate variables at each function cycle
        # Retrieve total aircraft weight and convert to kg.      
 	WT = getprop("yasim/gross-weight-lbs")*0.0004535;
 	flaps = getprop("controls/flight/flaps");

    # Calculate V-speeds with flaps 40
 
 	V1 = (0.01*(WT-190.0))+95;
 	VR = (0.01*(WT-190.0))+110;
 	V2 = (0.01*(WT-190.0))+130;
	setprop("/instrumentation/adc/reference/flaps/v1", V1);
 	setprop("/instrumentation/adc/reference/flaps/vr", VR);
 	setprop("/instrumentation/adc/reference/flaps/v2", V2); 

	 # Flaps 30
	V12 = (0.01*(WT-190.0))+97;
 	VR2 = (0.01*(WT-190.0))+112;
 	V22 = (0.01*(WT-190.0))+132;
	setprop("/instrumentation/adc/reference/V1", V12);
 	setprop("/instrumentation/adc/reference/VR", VR2);
 	setprop("/instrumentation/adc/reference/V2", V22); 
 	
 
        # Export the calculated V-speeds to the property-tree, for further use
 
        # Repeat the function each second
 	settimer(vspeeds, 1);
 }
 
 # Only start the function when the FDM is initialized, to prevent the problem of not-yet-created properties.
 # setlistener("/sim/signals/fdm-initialized", vspeeds);
