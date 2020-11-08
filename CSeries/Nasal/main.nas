###############################################################################
##
##  Nasal for CSeries - main
##
###############################################################################

############################################
# Global loop function
# If you need to run nasal as loop, add it in this function
############################################
global_system = func{

#Select Bleed Source

var bleedL=getprop("/controls/pneumatic/l-bleed");
var bleedR=getprop("/controls/pneumatic/r-bleed");
var bleedA=getprop("/controls/pneumatic/APU-bleed");

if(bleedL==1 and getprop("/engines/engine/n1")>=50 ){
    setprop("controls/pneumatic/bleed-source", 1);
}else if(bleedR == 1 and getprop("/engines/engine[1]/n1") >=50 ){
    setprop("controls/pneumatic/bleed-source", 3);
}else if(bleedA == 1 and getprop("/engines/apu/running") ==1 ){
    setprop("controls/pneumatic/bleed-source", 2);
}else{
    setprop("controls/pneumatic/bleed-source", 0);
}



#Lights
if(getprop("/systems/electrical/outputs/nav-lights")>=15){
setprop("/systems/electrical/outputs/nav-lights-norm", 1);
}else{
setprop("/systems/electrical/outputs/nav-lights-norm", 0);
}
if(getprop("/systems/electrical/outputs/beacon")>=15){
setprop("/systems/electrical/outputs/beacon-norm", 1);
}else{
setprop("/systems/electrical/outputs/beacon-norm", 0);
}
if(getprop("/systems/electrical/outputs/strobe")>=15){
setprop("/systems/electrical/outputs/strobe-norm", 1);
}else{
setprop("/systems/electrical/outputs/strobe-norm", 0);
}
if(getprop("/systems/electrical/outputs/logo-light")>=15){
setprop("/sim/model/lights/logo-lightmap", 1);
}else{
setprop("/sim/model/lights/logo-lightmap", 0);
}
#function for APU knob
if(getprop("/engines/apu/running")){
setprop("/controls/APU/knob", getprop("/controls/APU/off-on") );
setprop("/controls/APU/knob2", 0);
}else{
setprop("/controls/APU/knob2", getprop("/controls/APU/off-on"));
setprop("/controls/APU/knob", 0);
};
#set bleed automatically
#if(getprop("/controls/electric/engine/generator")){
#setprop("/controls/pneumatic/bleed-air", 1);
#}else if(getprop("/controls/electric/APU-generator")){
#setprop("/controls/pneumatic/bleed-air", 2);
#}else if(getprop("/controls/electric/engine[1]/generator")){
#setprop("/controls/pneumatic/bleed-air", 3);
#}
#external power
if(getprop("/controls/ext-avail") == 1){
setprop("/controls/ext-run", getprop("/controls/electric/external-power"));
}else{
setprop("/controls/ext-run", 0);
}



  settimer(global_system, 0);

}



##########################################
# SetListerner must be at the end of this file
##########################################
var nasalInit = setlistener("/sim/signals/fdm-initialized", func{

  settimer(global_system, 2);
 # settimer(tyresmoke, 2);
  removelistener(nasalInit);
});
