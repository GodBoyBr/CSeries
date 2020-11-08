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
# ActiveFlightPlanNarrow
var ActiveFlightPlanNarrow =
{
  SHORTCUTS : [ "FPL", "NRST", "RECENT", "USER", "AIRWAY" ],

  new : func (mfd, myCanvas, device, svg)
  {
    var obj = {
      parents : [
        ActiveFlightPlanNarrow,
        MFDPage.new(mfd, myCanvas, device, svg, "ActiveFlightPlanNarrow", "FPL - ACTIVE FLIGHT PLAN")
      ],
      current_flightplan : nil,
    };

    # Scrolling list of waypoints. We have _two_ lists here as we use one
    # Arrow highlight element to show the current leg, and another to allow
    # the FMS knob to highlight a waypoint for insertion/deletion or to make
    # active.
    obj.flightplanList = PFD.GroupElement.new(
      obj.pageName,
      svg,
      [ "Header", "Leg", "DTK", "DIS", "ALT"],
      11,
      "Leg",
      0,
      "ScrollTrough",
      "ScrollThumb",
      180
    );

    obj.currentLegIndicator = PFD.GroupElement.new(
      obj.pageName,
      svg,
      [ "Arrow"],
      11,
      "Arrow",
      1,
    );

    obj.Map = fg1000.NavMap.new(
      obj,
      obj.getElement("NavMap"),
      #[360, 275],
      #[fg1000.MAP_PARTIAL.CENTER.X, fg1000.MAP_PARTIAL.CENTER.Y],
      [860,400],
      #"rect(345, 233, -345, -233)",
      "",
      -50,
      2);

    obj.topMenu(device, obj, nil);

    obj.setController(fg1000.ActiveFlightPlanNarrowController.new(obj, svg));

    return obj;
  },
  offdisplay : func() {
    me._group.setVisible(0);

    # Reset the menu colours.  Shouldn't have to do this here, but
    # there's not currently an obvious other location to do so.
    for(var i = 0; i < 12; i +=1) {
      var name = sprintf("SoftKey%d",i);
      me.device.svg.getElementById(name ~ "-bg").setColorFill(0.0,0.0,0.0);
      me.device.svg.getElementById(name).setColor(1.0,1.0,1.0);
    }
    me.getElement("NavMap").setVisible(0);
    me.Map.setVisible(0);
    me.getController().offdisplay();
  },
  ondisplay : func() {
    me._group.setVisible(1);
    me.mfd.setPageTitle(me.title);
    me.getElement("NavMap").setVisible(1);
    me.Map.setVisible(1);
    me.getController().ondisplay();
  },
  topMenu : func(device, pg, menuitem) {
    pg.clearMenu();
    pg.resetMenuColors();
    pg.addMenuItem(0, "ENGINE", pg, pg.mfd.EIS.engineMenu);
    pg.addMenuItem(2, "MAP", pg, pg.mfd.NavigationMap.mapMenu);

    device.updateMenus();
  },

  # Update the FlightPlan display with an updated flightplan.
  setFlightPlan : func(fp, current_wp) {
    var elements = [];
    var arrowElements = [];

    if (fp == nil) {
      me.flightplanList.setValues([]);
      me.flightplanList.setCRSR(0);
      me.flightplanList.displayGroup();
      me.currentLegIndicator.setValues([]);
      me.currentLegIndicator.setCRSR(0);
      me.currentLegIndicator.displayGroup();
      return;
    }

    for (var i = 0; i < fp.getPlanSize(); i = i + 1) {
      var wp = fp.getWP(i);

      var element = {
        Header : "",
        Leg : "",
        DTK : "",
        DIS : "",
        ALT : "_____ft",
      };

      if (wp.wp_name != nil) {
        element.Leg = substr(wp.wp_name, 0, 7);
      } else {
        element.Leg = "____";
      }

      if (i == 0) {
        element.DIS = "";
        element.DTK = "";
        element.ALT = "_____ft";
      } else if (i < current_wp) {
        # Passed waypoints are blanked out on the display
        element.DIS = "___nm";
        element.DTK = "___°";
        element.ALT = "_____ft";
      } else {
        if (wp.leg_distance != nil) element.DIS = sprintf("%.1fnm", wp.leg_distance);
        if (wp.leg_bearing != nil) element.DTK = sprintf("%03d°", wp.leg_bearing);
        if (wp.alt_cstr_type != nil) element.ALT = sprintf("%dft", wp.alt_cstr);
      }

      append(elements, element);
      append(arrowElements, { Arrow : i});
    }

    me.flightplanList.setValues(elements);
    me.currentLegIndicator.setValues(arrowElements);

    if (current_wp == -1) {
      me.flightplanList.setCRSR(0);
      me.currentLegIndicator.setCRSR(0);
    } else {
      me.flightplanList.setCRSR(current_wp);
      me.currentLegIndicator.setCRSR(current_wp);
    }

    me.flightplanList.displayGroup();
    me.currentLegIndicator.displayGroup();

    # Determine a suitable name to display, using the flightplan name if there is one,
    # but falling back to the flightplan departure / destination airports, or failing
    # that the IDs of the first and last waypoints.
    if ((fp.id == nil) or (fp.id == "default-flightplan")) {
      var from = "????";
      var dest = "????";

      if ((fp.getWP(0) != nil) and (fp.getWP(0).wp_name != nil)) {
        from = fp.getWP(0).wp_name;
      }

      if ((fp.getWP(fp.getPlanSize() -1) != nil) and (fp.getWP(fp.getPlanSize() -1).wp_name != nil)) {
        dest = fp.getWP(fp.getPlanSize() -1).wp_name;
      }

      if (fp.departure   != nil) from = fp.departure.id;
      if (fp.destination != nil) dest = fp.destination.id;
      me.getElement("Name").setText(from ~ " / " ~ dest);
    } else {
      me.getElement("Name").setText(fp.id);
    }
  },
};
