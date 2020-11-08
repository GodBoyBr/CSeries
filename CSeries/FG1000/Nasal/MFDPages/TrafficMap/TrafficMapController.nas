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
# Traffic Map Controller
var TrafficMapController =
{
  # Altitude levels levels.
  ALTS : { ABOVE  : { label: "ABOVE",  ceiling_ft: 9000, floor_ft: 2700 },
           NORMAL : { label: "NORMAL", ceiling_ft: 2700, floor_ft: 2700 },
           BELOW  : { label: "BELOW",  ceiling_ft: 2700, floor_ft: 9000 },
           UNREST : { label: "UNRESTRICTED", ceiling_ft: 9000, floor_ft: 9000 }},


   # Three ranges available
   # 2nm
   # 2nm / 6nm
   # 6nm / 12nm
   #
   # TODO:  Currently we simply use the outer range, and display the inner
   # range as 1/3 of the outer.  Doing this properly, we should display
   # different inner rings.
   RANGES : [ {range: 2, inner_label: nil, outer_label: "2nm"},
              {range: 6, inner_label: "2nm", outer_label: "6nm"},
              {range: 12, inner_label: "4nm", outer_label: "12nm"} ],


  new : func (page, svg)
  {
    var obj = { parents : [ TrafficMapController, MFDPageController.new(page) ] };
    obj.range = 1;
    obj.alt = "NORMAL";
    obj.operating = 0;
    obj.flight_id = 0;
    obj.page = page;
    obj.page.setScreenRange(689/2.0);

    # Emesary
    obj._recipient = nil;

    obj.setZoom(obj.range);
    obj.setAlt(obj.alt);
    obj.setOperate(obj.operating);
    return obj;
  },
  zoomIn : func() {
    me.setZoom(me.current_zoom -1);
  },
  zoomOut : func() {
    me.setZoom(me.current_zoom +1);
  },
  setZoom : func(zoom) {
    if ((zoom < 0) or (zoom > (size(me.RANGES) - 1))) return;
    me.current_zoom = zoom;
    me.page.setRange(
      me.RANGES[zoom].range,
      me.RANGES[zoom].inner_label,
      me.RANGES[zoom].outer_label);
  },
  setAlt : func(alt) {
    if (me.ALTS[alt] == nil) return;
    me.page.setAlt(me.ALTS[alt].floor_ft, me.ALTS[alt].ceiling_ft, me.ALTS[alt].label);
    me.alt = alt;
  },
  setOperate : func(enabled) {
    me.page.setOperate(enabled);
    me.operating = enabled;
  },
  setFlightID : func(enabled) {
    me.flight_id = enabled;
    me.page.Options.setOption("TFC", "display_id", enabled);
  },
  toggleFlightID : func() {
    me.setFlightID(! me.flight_id);
  },
  isEnabled : func(label) {
    # Cheeky little function that returns whether the alt or operation mode
    # matches the label.  Used to highlight current settings in softkeys
    if (label == me.alt) return 1;
    if (me.operating and label == "OPERATE") return 1;
    if (me.operating == 0 and label == "STANDBY") return 1;
    if (me.flight_id == 1 and label == "FLT ID") return 1;
    return 0;
  },
  handleRange : func(val)
  {
    var incr_or_decr = (val > 0) ? 1 : -1;
    me.setZoom(me.current_zoom + incr_or_decr);
  },

  # Reset controller if required when the page is displayed or hidden
  ondisplay : func() {
    me.RegisterWithEmesary();
  },
  offdisplay : func() {
    me.DeRegisterWithEmesary();
  },
};
