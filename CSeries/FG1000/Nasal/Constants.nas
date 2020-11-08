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
# Constants to define the display area, for placement of elements.  We
# could try to do something with a layout, but the position and size of
# elements is fixed.  Can't be member variables of MFD as they are
# self-referential.

var DISPLAY = { WIDTH : 1024, HEIGHT  : 768 };
var HEADER_HEIGHT = 56;
var FOOTER_HEIGHT = 25;
var EIS_WIDTH     = 150;

# Size of data display on the right hand side of the MFD
var DATA_DISPLAY = {
  WIDTH  : 300,
  HEIGHT : DISPLAY.HEIGHT - HEADER_HEIGHT - FOOTER_HEIGHT,
  X      : DISPLAY.WIDTH  - 300,
  Y      : HEADER_HEIGHT,
};

# Map dimensions when the data display is not present
var MAP_FULL =  {
  CENTER : { X : ((DISPLAY.WIDTH - EIS_WIDTH) / 2 + EIS_WIDTH),
             Y : ((DISPLAY.HEIGHT - HEADER_HEIGHT - FOOTER_HEIGHT) / 2 + HEADER_HEIGHT), },
  X      : EIS_WIDTH,
  Y      : HEADER_HEIGHT,
  WIDTH  : DISPLAY.WIDTH - EIS_WIDTH,
  HEIGHT : DISPLAY.HEIGHT - HEADER_HEIGHT - FOOTER_HEIGHT,
};

# Map dimensions when the data display is present
var MAP_PARTIAL = {
  X      : EIS_WIDTH,
  Y      : HEADER_HEIGHT,
  WIDTH  : DISPLAY.WIDTH - EIS_WIDTH - DATA_DISPLAY.WIDTH,
  HEIGHT : DISPLAY.HEIGHT - HEADER_HEIGHT - FOOTER_HEIGHT,
  CENTER : { X : ((DISPLAY.WIDTH - EIS_WIDTH - DATA_DISPLAY.WIDTH) / 2 + EIS_WIDTH),
             Y : ((DISPLAY.HEIGHT - HEADER_HEIGHT - FOOTER_HEIGHT) / 2 + HEADER_HEIGHT), },
};

# Frequency limits.  We're assuming we're on 8.33kHz
var MIN_COM_FREQ = 118.000;
var MAX_COM_FREQ = 137.000;

var COM_833_SPACING = [
0.000, 0.005, 0.010, 0.015, 0.025, 0.030, 0.035, 0.040, 0.050, 0.055, 0.060, 0.065, 0.075, 0.080, 0.085, 0.090,
0.100, 0.105, 0.110, 0.115, 0.125, 0.130, 0.135, 0.140, 0.150, 0.155, 0.160, 0.165, 0.175, 0.180, 0.185, 0.190,
0.200, 0.205, 0.210, 0.215, 0.225, 0.230, 0.235, 0.240, 0.250, 0.255, 0.260, 0.265, 0.275, 0.280, 0.285, 0.290,
0.300, 0.305, 0.310, 0.315, 0.325, 0.330, 0.335, 0.340, 0.350, 0.355, 0.360, 0.365, 0.375, 0.380, 0.385, 0.390,
0.400, 0.405, 0.410, 0.415, 0.425, 0.430, 0.435, 0.440, 0.450, 0.455, 0.460, 0.465, 0.475, 0.480, 0.485, 0.490,
0.500, 0.505, 0.510, 0.515, 0.525, 0.530, 0.535, 0.540, 0.550, 0.555, 0.560, 0.565, 0.575, 0.580, 0.585, 0.590,
0.600, 0.605, 0.610, 0.615, 0.625, 0.630, 0.635, 0.640, 0.650, 0.655, 0.660, 0.665, 0.675, 0.680, 0.685, 0.690,
0.700, 0.705, 0.710, 0.715, 0.725, 0.730, 0.735, 0.740, 0.750, 0.755, 0.760, 0.765, 0.775, 0.780, 0.785, 0.790,
0.800, 0.805, 0.810, 0.815, 0.825, 0.830, 0.835, 0.840, 0.850, 0.855, 0.860, 0.865, 0.875, 0.880, 0.885, 0.890,
0.900, 0.905, 0.910, 0.915, 0.925, 0.930, 0.935, 0.940, 0.950, 0.955, 0.960, 0.965, 0.975, 0.980, 0.985, 0.990,
];

var NAV_SPACING = [
0.000, 0.025, 0.050, 0.075,
0.100, 0.125, 0.150, 0.175,
0.200, 0.225, 0.250, 0.275,
0.300, 0.325, 0.350, 0.375,
0.400, 0.425, 0.450, 0.475,
0.500, 0.525, 0.550, 0.575,
0.600, 0.625, 0.650, 0.675,
0.700, 0.725, 0.750, 0.775,
0.800, 0.825, 0.850, 0.875,
0.900, 0.925, 0.950, 0.975,
];

var MIN_NAV_FREQ = 108.000;
var MAX_NAV_FREQ = 118.000;

# Constants for the hard-buttons on the fascia
var FASCIA = {
  NAV_VOL : 0,
  NAV_ID : 1,
  NAV_FREQ_TRANSFER :2,
  NAV_OUTER : 3,
  NAV_INNER : 4,
  NAV_TOGGLE : 5,
  HEADING : 6,
  HEADING_PRESS : 7,

  # Joystick
  RANGE : 8,
  JOYSTICK_HORIZONTAL : 9,
  JOYSTICK_VERTICAL : 10,

  #CRS/BARO
  BARO : 11,
  CRS : 12,
  CRS_CENTER : 13,

  COM_OUTER : 14,
  COM_INNER : 15,
  COM_TOGGLE : 16,

  COM_FREQ_TRANSFER : 17,
  COM_FREQ_TRANSFER_HOLD :18,  # Auto-tunes to 121.2 when pressed for 2 seconds

  COM_VOL: 19,
  COM_VOL_TOGGLE: 20,

  DTO : 21,
  FPL : 22,
  CLR : 23,
  CLR_HOLD: 24, # Holding the CLR button for 2 seconds on the MFD displays the Nav Map

  FMS_OUTER : 25,
  FMS_INNER : 26,
  FMS_CRSR  : 27,

  MENU : 28,
  PROC : 29,
  ENT : 30,

  ALT_OUTER : 31,
  ALT_INNER : 32,

  # Autopilot controls
  AP  : 33,
  HDG : 34,
  NAV : 35,
  APR : 36,
  VS  : 37,
  FLC : 38,
  FD  : 39,
  ALT : 40,
  VNV : 41,
  BC  : 42,
  NOSE_UP : 43,
  NOSE_DOWN : 44,

  JOYSTICK_PRESS : 45,

  # GDU 1045 Autopilot keys
  YD : 46,

  # Useability helpers to avoid having to use the FMS knobs to spell airport IDs etc.
  KEY_INPUT : 47,
  STRING_INPUT: 48,
};

var SURFACE_TYPES = {
  1 : "HARD SURFACE",  # Asphalt
  2 : "HARD SURFACE", # Concrete
  3 : "TURF",
  4 : "DIRT",
  5 : "GRAVEL",
  #  Helipads
  6 : "HARD SURFACE",  # Asphalt
  7 : "HARD SURFACE", # Concrete
  8 : "TURF",
  9 : "DIRT",
  0 : "GRAVEL",
};

# Vertical ranges, and labels.
# 28 ranges from 500ft to 2000nm, measuring the vertical map distance.
# Vertical size of the map (once the nav box and softkey area is removed) is 689px.
# 2000nm = 12,152,000ft.
var RANGES = [{range: 500/6076.12, label: "500ft"},
          {range: 750/6076.12, label: "750ft"},
          {range: 1000/6076.12, label: "1000ft"},
          {range: 1500/6076.12, label: "1500ft"},
          {range: 2000/6076.12, label: "2000ft"},
          {range: 0.5, label: "0.5nm"},
          {range: 0.75, label: "0.75nm"},
          {range: 1, label: "1nm"},
          {range: 2, label: "2nm"},
          {range: 3, label: "3nm"},
          {range: 4, label: "4nm"},
          {range: 6, label: "6nm"},
          {range: 8, label: "8nm"},
          {range: 10, label: "10nm"},
          {range: 12, label: "12nm"},
          {range: 15, label: "15nm"},
          {range: 20, label: "20nm"},
          {range: 25, label: "25nm"},
          {range: 30, label: "30nm"},
          {range: 40, label: "40nm"},
          {range: 50, label: "50nm"},
          {range: 75, label: "75nm"},
          {range: 100, label: "100nm"},
          {range: 200, label: "200nm"},
          {range: 500, label: "500nm"},
          {range: 1000, label: "1000nm"},
          {range: 1500, label: "1500nm"},
          {range: 2000, label: "2000nm"}, ];

var ORIENTATIONS = [
  { label: "NORTH UP" },
  { label: "TRK UP" },
  { label: "DTK UP" },
  { label: "HDG UP" },
];

# Mapping from transponder mode integer values to transponder mode strings, as an array.
# Index values can be found in http://wiki.flightgear.org/Transponder#Knob.2FFunctional_Modes
# String values are menuitem labels on the PFD itself.
var TRANSPONDER_MODES = [ "OFF", "STBY", "TEST", "GND", "ON", "ALT"];
