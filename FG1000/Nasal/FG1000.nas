# Copyright 2018 Stuart Buchanan
# This file is part of FlightGear.
#
# FlightGear is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 2 of the License, or
# (at your option) any later version.
#
# FlightGear is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with FlightGear.  If not, see <http://www.gnu.org/licenses/>.
#
# FG1000 Base clearStyles

print("\n############");
print("#  FG1000  #");
print("############\n");

io.include("Constants.nas");
io.include("Commands.nas");

var nasal_dir = getprop("/sim/fg-root") ~ "/Aircraft/Instruments-3d/FG1000/Nasal/";

io.load_nasal(nasal_dir ~ '/ConfigStore.nas', "fg1000");
io.load_nasal(nasal_dir ~ '/MFDPage.nas', "fg1000");
io.load_nasal(nasal_dir ~ '/MFDPageController.nas', "fg1000");
io.load_nasal(nasal_dir ~ '/PFD.nas', "fg1000");
io.load_nasal(nasal_dir ~ '/MFD.nas', "fg1000");
io.load_nasal(nasal_dir ~ '/GUI.nas', "fg1000");
io.load_nasal(nasal_dir ~ '/NavMap.nas', "fg1000");

var FG1000 = {

_instance : nil,

# Factory method
getOrCreateInstance : func(EIS_Class = nil, EIS_SVG = nil) {
  if (FG1000._instance == nil) {
    FG1000._instance = FG1000.new(EIS_Class, EIS_SVG);
  }

  return FG1000._instance;
},

new : func(EIS_Class = nil, EIS_SVG = nil) {
  var obj = {
    parents : [FG1000],
    displays : {}
  };

  if (EIS_Class == nil) {
    # Load the default EIS class.
    var nasal_dir = getprop("/sim/fg-root") ~ "/Aircraft/Instruments-3d/FG1000/Nasal/";
    io.load_nasal(nasal_dir ~ '/EIS/EIS-C182T.nas', "fg1000");
    io.load_nasal(nasal_dir ~ '/EIS/EISController.nas', "fg1000");
    io.load_nasal(nasal_dir ~ '/EIS/EISStyles.nas', "fg1000");
    io.load_nasal(nasal_dir ~ '/EIS/EISOptions.nas', "fg1000");
    obj.EIS_Class = fg1000.EIS;
  } else {
    obj.EIS_Class = EIS_Class;
  }

  if (EIS_SVG == nil) {
    obj.EIS_SVG = "/Aircraft/Instruments-3d/FG1000/MFDPages/EIS-C182T.svg";
  } else {
    obj.EIS_SVG = EIS_SVG;
  }

  obj.ConfigStore = fg1000.ConfigStore.new();

  return obj;
},

setEIS : func(EIS_Class, EIS_SVG) {
  me.EIS_Class = EIS_Class;
  me.EIS_SVG = EIS.SVG;
},

getDisplay : func(index) {
  return me.displays[index];
},

# Add an MFD, optionally setting the index. Returns the index of the MFD.
addMFD : func(index=nil, targetcanvas=nil) {

  if (index == nil) {
    index = size(keys(me.displays));
  } else if (me.displays[index] != nil) {
    print("FG1000 Index " ~ index ~ " already exists!");
    return index;
  }

  if (targetcanvas == nil) {
    targetcanvas = canvas.new({
            "name" : "MFD Canvas",
            "size" : [1024, 768],
            "view" : [1024, 768],
            "mipmapping": 0,
          });
  }

  targetcanvas.set("visible", 0);

  var mfd = fg1000.MFDDisplay.new(me, me.EIS_Class, me.EIS_SVG, targetcanvas, index);
  me.displays[index] = mfd;
  return index;
},

# Add a PFD, optionally setting the index. Returns the index of the PFD.
addPFD : func(index=nil, targetcanvas=nil) {

  if (index == nil) {
    index = size(keys(me.displays));
  } else if (me.displays[index] != nil) {
    print("FG1000 Index " ~ index ~ " already exists!");
    return index;
  }

  if (targetcanvas == nil) {
    targetcanvas = canvas.new({
            "name" : "PFD Canvas",
            "size" : [1024, 768],
            "view" : [1024, 768],
            "mipmapping": 0,
          });
  }

  targetcanvas.set("visible", 0);

  var pfd = fg1000.PFDDisplay.new(me, me.EIS_Class, me.EIS_SVG, targetcanvas, index);
  me.displays[index] = pfd;
  return index;
},

# Display the PFD/MFD on a particular target_object (defaults to "Screen{index}")
display : func(index, target_object=nil) {
  if (me.displays[index] == nil) {
    print("displayMFD: unknown display index " ~ index);
    return;
  }

  if (target_object == nil) target_object = "Screen" ~ index;

  var targetcanvas = me.displays[index].getCanvas();
  targetcanvas.addPlacement({"node": target_object});
},

displayGUI : func(index, scale=1.0) {
  if (me.displays[index] == nil) {
    print("displayMFD: unknown display index " ~ index);
    return;
  }

  var mfd_canvas = me.displays[index].getCanvas();
  mfd_canvas.set("visible", 1);
  var gui = fg1000.GUI.new(me.displays[index], mfd_canvas, index, scale);
},

getConfigStore : func() {
  return me.ConfigStore;
},

setVisible : func(index = nil, visible = 1) {
  if (index == nil) {
    foreach(var display; values(me.displays)) {
      display.getCanvas().set("visible", visible);
    }
  } else {
    if (me.displays[index] == nil) {
      print("displayMFD: unknown display index " ~ index);
    } else {
      me.displays[index].getCanvas().set("visible", visible);
    }
  }
},

show : func(index = nil) {
  me.setVisible(index, 1);
},

hide : func(index = nil) {
  me.setVisible(index, 0);
},

};
