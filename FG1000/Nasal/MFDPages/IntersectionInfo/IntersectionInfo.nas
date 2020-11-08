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
# IntersectionInfo
var IntersectionInfo =
{
  new : func (mfd, myCanvas, device, svg)
  {
    var obj = {
      parents : [
        IntersectionInfo,
        MFDPage.new(mfd, myCanvas, device, svg, "IntersectionInfo", "WPT - INTERSECTION INFORMATION")
      ],
    };

    # Dynamic text elements in the SVG file.  In the SVG these have an "IntersectionInfo" prefix.
    textelements = [
      "ID",
      "Region",
      "Lat",
      "Lon",
      "VORID",
      "VORCRS",
      "VORDST"
    ];

    obj.addTextElements(textelements);

    # Data Entry information.  Keyed from the name of the element, which must
    # be one of the textelements above.  Each data element maps to a set of
    # text elements in the SVG of the form [PageName][TextElement]{0...n}, each
    # representing a single character for data entry.
    #
    # .size is the number of characters of data entry
    # .chars is the set of characters, used to scroll through using the small
    # FMS knob.
    obj.dataEntry = PFD.DataEntryElement.new(obj.pageName, svg, "ID", "", 5, "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789");

    obj.Map = fg1000.NavMap.new(
      obj,
      obj.getElement("NavMap"),
      [860,400],
      "",
      -50,
      0,
      1);

    obj.topMenu(device, obj, nil);

    obj.setController(fg1000.IntersectionInfoController.new(obj, svg));
    obj.update(nil,nil);

    return obj;
  },

  update : func(navdata, vordata) {
    if (navdata != nil) {
      me.setTextElementLat("Lat", navdata.lat);
      me.setTextElementLon("Lon", navdata.lon);
      me.setTextElement("ID",  navdata.id);

      me.Map.getController().setPosition(navdata.lat, navdata.lon);
      me.Map.show();
    } else {
      me.setTextElementLat("Lat", nil);
      me.setTextElementLon("Lon", nil);
      me.setTextElement("ID",  "#####");
      me.Map.hide();
    }

    if (vordata != nil) {
      var crsAndDst = courseAndDistance(navdata, vordata);
      me.setTextElement("VORID", vordata.id);
      me.setTextElementBearing("VORCRS", vordata.crs);
      me.setTextElementDistance("VORDST", vordata.dst);
    } else {
      me.setTextElement("VORID", "");
      me.setTextElement("VORCRS", "");
      me.setTextElement("VORDST", "");
    }
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
    pg.addMenuItem(0, "ENGINE", pg.mfd.EIS, pg.mfd.EIS.engineMenu);
    pg.addMenuItem(2, "MAP", pg.mfd.NavigationMap, pg.mfd.NavigationMap.mapMenu);
    device.updateMenus();
  },
};
