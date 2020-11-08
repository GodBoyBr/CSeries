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
# VORInfo
var VORInfo =
{
  new : func (mfd, myCanvas, device, svg)
  {
    var obj = {
      parents : [
        VORInfo,
        MFDPage.new(mfd, myCanvas, device, svg, "VORInfo", "WPT - VOR INFORMATION")
      ],
    };

    # Dynamic text elements in the SVG file.  In the SVG these have an "NDBInfo" prefix.
    textelements = [
      "ID",
      "Type",
      "Facility",
      "NearestCity",
      "Class", # Low Altitude / High Altitude / Terminal
      "MagVar",
      "Region",
      "Lat",
      "Lon",
      "Freq",
      "AirportID",
      "AirportCRS",
      "AirportDST"
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
    obj.dataEntry = PFD.DataEntryElement.new(obj.pageName, svg, "ID", "", 3, "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789");

    obj.Map = fg1000.NavMap.new(
      obj,
      obj.getElement("NavMap"),
      [860,400],
      "",
      -50,
      0,
      1);


    obj.topMenu(device, obj, nil);
    obj.update(nil, nil);

    obj.setController(fg1000.VORInfoController.new(obj, svg));

    return obj;
  },

  update : func(navdata, aptdata) {
    if (navdata != nil) {
      me.setTextElement("ID",  navdata.id);

      var type = "VOR";
      if (navdata.vortac) type = "VORTAC";
      if (navdata.dme) type = "VOR-DME";

      me.setTextElement("Type", type);
      me.setTextElement("Facility", "");
      me.setTextElement("NearestCity", "");
      me.setTextElement("Class", "");
      me.setTextElementMagVar("MagVar", navdata.magvar);
      me.setTextElement("Region", "");

      me.setTextElementLat("Lat", navdata.lat);
      me.setTextElementLon("Lon", navdata.lon);
      me.setTextElementNavFreq("Freq", navdata.frequency / 100.0);

      me.Map.getController().setPosition(navdata.lat, navdata.lon);
      me.Map.show();
    } else {
      me.setTextElement("ID",  "###");
      me.setTextElement("Type", "_______");
      me.setTextElement("Facility", "_______");
      me.setTextElement("NearestCity", "_______");
      me.setTextElement("Class", "_______");
      me.setTextElement("MagVar", "");
      me.setTextElement("Region", "_______");

      me.setTextElementLat("Lat", nil);
      me.setTextElementLon("Lon", nil);
      me.setTextElementNavFreq("Freq", "");
      me.Map.hide();
    }

    if (aptdata != nil) {
      var crsAndDst = courseAndDistance(navdata, aptdata);
      me.setTextElement("AirportID", aptdata.id);
      me.setTextElementBearing("AirportCRS", aptdata.crs);
      me.setTextElementDistance("AirportDST", aptdata.dst);
    } else {
      me.setTextElement("AirportID", "____");
      me.setTextElementBearing("AirportCRS", "");
      me.setTextElementDistance("AirportDST", "");
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
