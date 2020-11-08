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
# Navigation Map Styles
var NavigationMapStyles =
{
  new : func() {
    var obj = { parents : [ NavigationMapStyles ]};
    obj.Styles = {};
    obj.loadStyles();
    return obj;
  },

  getStyle : func(type) {
    return me.Styles[type];
  },

  setStyle : func(type, name, value) {
    me.Styles[type][name] = value;
  },

  loadStyles : func() {
    me. clearStyles();
    me.Styles.DME = {};
    me.Styles.DME.debug = 1; # HACK for benchmarking/debugging purposes
    me.Styles.DME.animation_test = 0; # for prototyping animated symbols

    me.Styles.DME.scale_factor = 0.4; # 40% (applied to whole group)
    me.Styles.DME.line_width = 3.0;
    me.Styles.DME.color_tuned = [0,1,0]; #rgb
    me.Styles.DME.color_default = [1,1,0];  #rgb

    me.Styles.APT = {};
    me.Styles.APT.scale_factor = 0.4; # 40% (applied to whole group)
    me.Styles.APT.line_width = 3.0;
    me.Styles.APT.color_default = [0,0.6,0.85];  #rgb
    me.Styles.APT.label_font_color = me.Styles.APT.color_default;
    me.Styles.APT.label_font_size=28;

    me.Styles.TFC = {};
    me.Styles.TFC.scale_factor = 0.4; # 40% (applied to whole group)

    me.Styles.WPT = {};
    me.Styles.WPT.scale_factor = 0.5; # 50% (applied to whole group)

    me.Styles.RTE = {};
    me.Styles.RTE.line_width = 2;

    me.Styles.FLT = {};
    me.Styles.FLT.line_width = 3;

    me.Styles.FIX = {};
    me.Styles.FIX.color = [0,0,0];  # Black outline
    me.Styles.FIX.fill_color = [1,1,1,1]; # White fill
    me.Styles.FIX.scale_factor = 0.5; # 50%

    me.Styles.FIX.text_offset = [0, -12];
    me.Styles.FIX.text_color = [0,0,0,1]; # Black text ...
    me.Styles.FIX.text_bgcolor = [1,1,1,1]; # ... on a white background
    me.Styles.FIX.text_mode = canvas.Text.TEXT + canvas.Text.FILLEDBOUNDINGBOX;
    me.Styles.FIX.text_padding = 2;
    me.Styles.FIX.text_alignment = 'center-bottom';

    me.Styles.NDB = {};
    me.Styles.NDB.scale_factor = 0.5; # 60%
    me.Styles.NDB.dash_array = [1,1];
    me.Styles.NDB.text_offset = [0, -12];
    me.Styles.NDB.text_color = [0,0,0,1]; # Black text ...
    me.Styles.NDB.text_bgcolor = [1,1,1,1]; # ... on a white background
    me.Styles.NDB.text_mode = canvas.Text.TEXT + canvas.Text.FILLEDBOUNDINGBOX;
    me.Styles.NDB.text_padding = 2;
    me.Styles.NDB.text_alignment = 'center-bottom';

    me.Styles.VOR_FG1000 = {};
    me.Styles.VOR_FG1000.line_width = 1;
    me.Styles.VOR_FG1000.scale_factor = 1.0;
    me.Styles.VOR_FG1000.circle_radius = 128;
    me.Styles.VOR_FG1000.icon_color = [0.0,0.0,0.5];
    me.Styles.VOR_FG1000.circle_color = [0.2,0.8,0.8];
    me.Styles.VOR_FG1000.text_offset = [0, -12];
    me.Styles.VOR_FG1000.text_color = [0,0,0,1]; # Black text ...
    me.Styles.VOR_FG1000.text_bgcolor = [1,1,1,1]; # ... on a white background
    me.Styles.VOR_FG1000.text_mode = canvas.Text.TEXT + canvas.Text.FILLEDBOUNDINGBOX;
    me.Styles.VOR_FG1000.text_padding = 2;
    me.Styles.VOR_FG1000.text_alignment = 'center-bottom';
    me.Styles.VOR_FG1000.font_size = 14;

    me.Styles.APS = {};
    me.Styles.APS.scale_factor=0.3;
    me.Styles.APS.svg_path = "Aircraft/Instruments-3d/FG1000/Icons/APSmodel.svg";
  },

  clearStyles : func() {
    me.Styles = {};
  },

};
