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
# NearestIntersections
var NearestIntersections =
{
  new : func (mfd, myCanvas, device, svg)
  {
    var obj = {
      parents : [
        NearestIntersections,
        MFDPage.new(mfd, myCanvas, device, svg, "NearestIntersections", "NRST - NEAREST INTERSECTIONS")
      ],
    };

    obj.setController(fg1000.NearestIntersectionsController.new(obj, svg));

    # Dynamic elements.  There is a single dynamic element containing the list of
    # the 25 nearest intersections.
    obj.select = PFD.GroupElement.new(
      obj.pageName,
      svg,
      [ "Arrow", "ID", "CRS", "DST"],
      11,
      "Arrow",
      1,
      "ScrollTrough",
      "ScrollThumb",
      250 - 116
    );

    # Other dynamic text elements
    obj.addTextElements(["Lat", "Lon", "VORID", "VORFreq", "VORCRS", "VORDST"]);

    obj.topMenu(device, obj, nil);

    return obj;
  },

  # Indicate which group is selected by colour of the softkeys
  display_toggle : func(device, svg, mi, group) {
    var bg_name = sprintf("SoftKey%d-bg",mi.menu_id);
    if (me.getController().getSelectedGroup() == group) {
      device.svg.getElementById(bg_name).setColorFill(0.5,0.5,0.5);
      svg.setColor(0.0,0.0,0.0);
    } else {
      device.svg.getElementById(bg_name).setColorFill(0.0,0.0,0.0);
      svg.setColor(1.0,1.0,1.0);
    }
    svg.setText(mi.title);
    svg.setVisible(1); # display function
  },

  showCRSR : func() {
    me.select.showCRSR();
  },

  hideCRSR : func() {
    me.select.hideCRSR();
  },

  offdisplay : func() {
    # The Nearest... pages use the underlying navigation map.
    me.mfd.NavigationMap.offdisplayPartial();

    # Reset the menu colours.  Shouldn't have to do this here, but
    # there's not currently an obvious other location to do so.
    me.resetMenuColors();

    me.getController().offdisplay();
  },
  ondisplay : func() {
    me.getController().ondisplay();

    # The Nearest... pages use the underlying navigation map.
    me.mfd.NavigationMap.ondisplayPartial();

    me.mfd.setPageTitle(me.title);
  },
  updateNavData : func(navdata) {

    if ((navdata == nil) or (size(navdata) == 0)) return;

    var navDataList = [];
    for (var i = 0; i < size(navdata); i = i + 1) {
      var nav = navdata[i];
      var crsAndDst = courseAndDistance(nav);

      # Display the course and distance in NM .
      var crs = sprintf("%i°", crsAndDst[0]);
      var dst = sprintf("%.1fnm", crsAndDst[1]);

      # Convert into something we can pass straight to the UIGroup.
      append(navDataList, {
        Arrow : nav.id,
        ID: nav.id,
        CRS: crs,
        DST: dst,
      });
    }

    me.select.setValues(navDataList);

    if (size(navDataList) > 0) {
      me.updateNavDataItem(navdata[0]);
    } else {
      me.setTextElement("Lat", "NONE WITHIN 200NM");
      me.setTextElement("VORID", "");
      me.setTextElement("VORFreq", "");
      me.setTextElement("VORCRS", "");
      me.setTextElement("VORDST", "");
    }
  },
  updateNavDataItem : func(nav) {
    if (nav == nil) return;

    me.setTextElementLat("Lat", nav.lat);
    me.setTextElementLon("Lon", nav.lon);

    # Determine the nearest VOR, and the bearing and distance TO the VOR,
    var vordata = me.getController().getNearestNavData("vor");

    if ((vordata != nil ) and (size(vordata) > 0)) {
      var crsAndDst = courseAndDistance(nav, vordata[0]);
      var crs = sprintf("%i°", crsAndDst[0]);
      var dst = sprintf("%.1fnm", crsAndDst[1]);
      me.setTextElement("VORID", vordata[0].id);
      me.setTextElement("VORFreq", sprintf("%.2f", vordata[0].frequency / 100.0));
      me.setTextElement("VORCRS", crs);
      me.setTextElement("VORDST", dst);
    } else {
      me.setTextElement("VORID", "");
      me.setTextElement("VORFreq", "");
      me.setTextElement("VORCRS", "");
      me.setTextElement("VORDST", "");
    }

    # Display the DTO line to the airport
    me.mfd.NavigationMap.getController().setDTOLineTarget(nav.lat, nav.lon);
  },

  topMenu : func(device, pg, menuitem) {
    pg.clearMenu();
    pg.resetMenuColors();
    pg.addMenuItem(0, "ENGINE", pg.mfd.EIS, pg.mfd.EIS.engineMenu);
    pg.addMenuItem(2, "MAP", pg.mfd.NavigationMap, pg.mfd.NavigationMap.mapMenu);

    device.updateMenus();
  },
};
