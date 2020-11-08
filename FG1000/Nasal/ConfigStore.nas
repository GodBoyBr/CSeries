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
# Copyright (C) 2018 Stuart Buchanan
# FG1000 Configuration store
#
# This only stores configuration with pre-defined values
#

var ConfigStore = {

  # Layer display configuration:
  # enabled   - whether this layer has been enabled by the user
  # declutter - the maximum declutter level (0-3) that this layer is visible in
  # range     - the maximum range this layer is visible (configured by user)
  # max_range - the maximum range value that a user can configure for this layer.
  # static - whether this layer should be displayed on static maps (as opposed to the moving maps)
  # factory - name of the factory to use for creating the layer
  # priority - layer priority
  layerRanges : {
    DTO  : { enabled: 0, declutter: 3, range: 2000, max_range: 2000, static : 0, factory : canvas.SymbolLayer, priority : 4 },

    GRID : { enabled: 0, declutter: 1, range: 20, max_range: 2000, static : 1, factory : canvas.SymbolLayer, priority : 4  },
    DME  : { enabled: 1, declutter: 1, range: 150, max_range: 300, static : 1, factory : canvas.SymbolLayer, priority : 4  },
    VOR_FG1000  : { enabled: 1, declutter: 1, range: 150, max_range: 300, static : 1, factory : canvas.SymbolLayer, priority : 4  },
    NDB  : { enabled: 1, declutter: 1, range: 15, max_range: 30, static : 1, factory : canvas.SymbolLayer, priority : 4  },
    FIX  : { enabled: 1, declutter: 1, range: 15, max_range: 30, static : 1, factory : canvas.SymbolLayer, priority : 4  },
    RTE  : { enabled: 1, declutter: 3, range: 2000, max_range: 2000, static : 0, factory : canvas.SymbolLayer, priority : 4  },
    GPS  : { enabled: 1, declutter: 3, range: 2000, max_range: 2000, static : 0, factory : canvas.SymbolLayer, priority : 4  },
    WPT  : { enabled: 1, declutter: 3, range: 2000, max_range: 2000, static : 0, factory : canvas.SymbolLayer, priority : 4  },

    FLT  : { enabled: 1, declutter: 3, range: 2000, max_range: 2000, static : 1, factory : canvas.SymbolLayer, priority : 4  },

    WXR  : { enabled: 1, declutter: 2, range: 2000, max_range: 2000, static : 1, factory : canvas.SymbolLayer, priority : 4  },

    APT  : { enabled: 1, declutter: 2, range: 150, max_range: 300, static : 1, factory : canvas.SymbolLayer, priority : 4  },

    TFC  : { enabled: 0, declutter: 3, range: 150, max_range: 2000, static : 1, factory : canvas.SymbolLayer, priority : 4  },
    APS  : { enabled: 1, declutter: 3, range: 2000, max_range: 2000, static : 0,  factory : canvas.SymbolLayer, priority : 4  },

    STAMEN_terrain  : { enabled: 1, declutter: 3, range: 500, max_range: 2000, static : 1, factory : canvas.OverlayLayer, priority : 1  },
    OpenAIP : { enabled: 1, declutter: 1, range: 150, max_range: 300, static : 1, factory : canvas.OverlayLayer, priority : 1  },
    STAMEN  : { enabled: 1, declutter: 3, range: 500, max_range: 2000, static : 1, factory : canvas.OverlayLayer, priority : 1  },
  },

  configValues : {
    "DisplayUnitsNavAngle": ["MAGNETIC", "TRUE"] ,
    "DisplayUnitsDistanceAndSpeed": ["NAUTICAL", "METRIC"] ,
    "DisplayUnitsAltitude": ["FEET", "METERS"] ,
    "DisplayUnitsTemperature": ["CELCIUS", "FAHRENHEIT"] ,

    "BaroTransitionAlert": ["ON", "OFF"] ,
    "BaroTransitionAltitude": ["6000", "18000"] ,

    "AirspaceAlertBuffer": ["100", "200", "300", "400", "500", "750", "1000"] ,
    "AirspaceAlertClassB": ["OFF", "ON"] ,
    "AirspaceAlertClassC": ["OFF", "ON"] ,
    "AirspaceAlertClassD": ["OFF", "ON"] ,
    "AirspaceAlertRestricted": ["OFF", "ON"] ,
    "AirspaceAlertMOA": ["OFF", "ON"] ,
    "AirspaceAlertOther": ["OFF", "ON"] ,

    "ArrivalAlert": ["OFF", "ON"] ,
    "ArrivalDistance": ["0.0", "1.0", "2.0", "3.0", "4.0", "6.0", "8.0", "10.0"] ,
    "AudioAlertVoice": ["MALE", "FEMALE"] ,

    "PageNavigationChangeOnFirstClick": ["OFF", "ON"] ,
    "PageNavigationTimeout" : [0.5, 1.0, 2.0, 3.0] ,


    # MFD Header Fields
    #
    # Bearing (BRG)
    # Crosstrack Error (XTK)
    #	Distance (DIS)
    #	Desired Track (DTK)
    #	Endurance (END)
    #	En Route Safe Altitude (ESA)
    # Estimated Time of Arrival (ETA)
    #	Estimated Time En Route (ETE)
    # Fuel Over Destination (FOD)
    # Fuel On Board (FOB)
    # Ground Speed (GS)
    # Minimum Safe Altitude (MSA)
    # True Air Speed (TAS)
    # Track Angle Error (TKE)
    # Track (TRK)
    # Vertical Speed Required (VSR)

    "MFDHeader1": ["BRG", "XTK", "DIS", "DTK", "END", "ESA", "ETA", "ETE", "FOD", "FOB", "GS", "MSA", "TAS", "TKE", "TRK", "VSR"] ,
    "MFDHeader2": ["BRG", "XTK", "DIS", "DTK", "END", "ESA", "ETA", "ETE", "FOD", "FOB", "GS", "MSA", "TAS", "TKE", "TRK", "VSR"] ,
    "MFDHeader3": ["BRG", "XTK", "DIS", "DTK", "END", "ESA", "ETA", "ETE", "FOD", "FOB", "GS", "MSA", "TAS", "TKE", "TRK", "VSR"] ,
    "MFDHeader4": ["BRG", "XTK", "DIS", "DTK", "END", "ESA", "ETA", "ETE", "FOD", "FOB", "GS", "MSA", "TAS", "TKE", "TRK", "VSR"] ,

    # V-speeds (Cessna 182T)
    "Vx" : 54, # Short field takeoff, 2600lbs
    "Vy" : 78, # 4000ft, 3100lbs
    "Vr" : 78,
    "Vglide" : 70, # 2600lbs
    "Vne": 175,

    "Vx-visible" : 1,
    "Vy-visible" : 1,
    "Vr-visible" : 1,
    "Vglide-visible" : 1,
    "Vne-visible": 1,

  },

  new : func()
  {
    var obj ={
      parents : [ ConfigStore ],
      _values : {},
      _layerRanges : {},
    };

    foreach (var i; keys(ConfigStore.configValues)) {
      var values = ConfigStore.configValues[i];
      if (typeof(values) == "vector") obj.set(i, values[0]);
      if (typeof(values) == "scalar") obj.set(i, values);
    }

    # Special case defaults
    obj.set("MFDHeader1", "GS");
    obj.set("MFDHeader2", "DIS");
    obj.set("MFDHeader3", "ETE");
    # ESA should be the default, but it's not implemented right now, so use FOD
    #obj.set("MFDHeader4", "ESA");
    obj.set("MFDHeader4", "FOD");

    foreach (var i; keys(ConfigStore.layerRanges)) {
      obj._layerRanges[i] = ConfigStore.layerRanges[i];
    }

    return obj;
  },

  set : func(name, value) {
    # Validate name is something we know.
    assert(contains(ConfigStore.configValues, name), "ConfigStore does not contain name " ~ name);

    if (typeof(ConfigStore.configValues[name]) == "vector") {
      # Validate the value is part of the set of acceptable values
      var found = 0;
      foreach(var val; ConfigStore.configValues[name]) {
        if (value == val) {
          found =1;
          break;
        }
      }

      assert(found == 1,
        "Invalid value for " ~ name ~ ": " ~ value ~
        "(Should be one of " ~ string.join(", ", ConfigStore.configValues[name]) ~ ")");

      me._values[name] = value;
    }elsif (typeof(ConfigStore.configValues[name]) == "scalar") {
      # If not valid values, then anything goes.
      me._values[name] = value;
    } else {
      die("Unknown ConfigStore type " ~ typeof(ConfigStore.configValues[name]));
    }
  },

  get : func(name) {
    return me._values[name];
  },

  getLayer : func(name) {
    return me._layerRanges[name];
  },

  getLayerNames : func() {
    return keys(me._layerRanges);
  },

  isLayerEnabled : func(name) {
    return me._layerRanges[name].enabled;
  },
  setLayerEnabled : func(name, enabled) {
    me._layerRanges[name].enabled = enabled;
  },
  toggleLayerEnabled : func(name) {
    me._layerRanges[name].enabled = ! me._layerRanges[name].enabled;
  },

  configureLayer : func(layer, enabled, range) {
    me._layerRanges[layer].enabled = enabled;
    me._layerRanges[layer].range = math.min(range, me._layerRanges[layer].max_range);
  },

};
