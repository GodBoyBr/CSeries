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
# AirportInfo Styles
var AirportInfoStyles =
{
  new : func() {
    var obj = { parents : [ AirportInfoStyles ]};
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
    me.clearStyles();
    me.Styles.RWY = {};
    me.Styles.RWY.text_color = [0,0,0,1]; # Black text ...
    me.Styles.RWY.text_bgcolor = [1,1,1,1]; # ... on a white background
    me.Styles.RWY.text_mode = canvas.Text.TEXT + canvas.Text.FILLEDBOUNDINGBOX;
    me.Styles.RWY.text_padding = 1;
    me.Styles.RWY.text_alignment = 'center-center';
    me.Styles.RWY.text_size = 14;
    me.Styles.RWY.show_labels= 1;

    me.Styles.APT = {};
    me.Styles.APT.scale_factor = 0.4; # 40% (applied to whole group)
    me.Styles.APT.line_width = 3.0;
    me.Styles.APT.color_default = [0,0.6,0.85];  #rgb
    me.Styles.APT.label_font_color = me.Styles.APT.color_default;
    me.Styles.APT.label_font_size=28;

  },

  clearStyles : func() {
    me.Styles = {};
  },

};
