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
# WaypointEntry page.  This is an overlay, sitting on whatever page the user
# is on already. Hence it is not called in the normal way, but instead
# explicitly called by Flightplan pages to insert a waypoint.

var WaypointEntry =
{
  SHORTCUTS : [ "FPL", "NRST", "RECENT", "USER", "AIRWAY" ],

  new : func (mfd, myCanvas, device, svg)
  {
    var obj = {
      parents : [
        WaypointEntry,
        MFDPage.new(mfd, myCanvas, device, svg, "WaypointEntry", "")
      ],
      symbols : {},
    };

    obj.crsrIdx = 0;

    # Dynamic text elements in the SVG file.  In the SVG these have an "WaypointEntry" prefix.
    textelements = [
         "Name",
         "City",
         "Region",
         "LocationBRG",
         "LocationDIS",
         "LocationLat",
         "LocationLon",
    ];

    obj.addTextElements(textelements);

    obj._SVGGroup.setInt("z-index", 9);

    # Data Entry information.  Keyed from the name of the element, which must
    # be one of the textelements above.  Each data element maps to a set of
    # text elements in the SVG of the form [PageName][TextElement]{0...n}, each
    # representing a single character for data entry.
    #
    # .size is the number of characters of data entry
    # .chars is the set of characters, used to scroll through using the small
    # FMS knob.
    obj.IDEntry = PFD.DataEntryElement.new(obj.pageName, svg, "ID", "", 4, "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789");

    # The Shortcut window.  This allows the user to scroll through a set of lists
    # of waypoints.
    obj.WaypointSubmenuGroup = obj._SVGGroup.getElementById("WaypointEntryWaypointSubmenuGroup");
    assert(obj.WaypointSubmenuGroup != nil, "Unable to find WaypointEntryWaypointSubmenuGroup");
    obj.WaypointSubmenuGroup.setVisible(0);
    obj.WaypointSubmenuSelect = PFD.ScrollElement.new(obj.pageName, svg, "WaypointSubmenuSelect", WaypointEntry.SHORTCUTS);
    obj.WaypointSubmenuScroll = PFD.GroupElement.new(obj.pageName, svg, [ "WaypointSubmenuScroll" ] , 4, "WaypointSubmenuScroll", 0, "WaypointSubmenuScrollTrough" , "WaypointSubmenuScrollThumb", 60);

    # The Airport Chart - only displayed on the MFD variant (where thre's if there's a Map SVG element present)
    if (obj.elementExists("Map")) {
      obj.WaypointEntryChart = fg1000.NavMap.new(obj, obj.getElement("Map"), [860,440], "rect(-160px, 160px, 160px, -160px)", 0, 2, 1);
    } else {
      obj.WaypointEntryChart = nil;
    }

    obj.setController(fg1000.WaypointEntryController.new(obj, svg));
    return obj;
  },

  displayDestination : func(destination) {
    if (destination != nil) {
      # Display a given location
      if (me.WaypointEntryChart != nil) {
        me.WaypointEntryChart.setVisible(1);
        me.WaypointEntryChart.getController().setPosition(destination.lat,destination.lon);
      }
      me.setTextElement("Name", string.uc(destination.name));
      me.setTextElement("City", "");
      me.setTextElement("Region", "");
      me.setTextElement("LocationBRG", "" ~ sprintf("%03d°", destination.course));
      me.setTextElement("LocationDIS", sprintf("%d", destination.range_nm) ~ "nm");
      me.setTextElementLat("LocationLat", destination.lat);
      me.setTextElementLon("LocationLon", destination.lon);
      me.IDEntry.setValue(destination.id);
    } else {
      if (me.WaypointEntryChart != nil) me.WaypointEntryChart.setVisible(0);
      me.setTextElement("Name", "___");
      me.setTextElement("City", "____________");
      me.setTextElement("Region", "____________");
      me.setTextElement("LocationBRG", "___°");
      me.setTextElement("LocationDIS", "__._nm");
      me.setTextElement("LocationLat", "_ __°__.__'");
      me.setTextElement("LocationLon", "____°__.__'");
      me.IDEntry.setValue("####");
    }
  },

  offdisplay : func() {
    me._group.setVisible(0);
    if (me.WaypointEntryChart != nil) me.WaypointEntryChart.setVisible(0);
    me.getElement("Group").setVisible(0);
    me.getController().offdisplay();
  },
  ondisplay : func() {
    me._group.setVisible(1);
    me.getElement("Group").setVisible(1);
    me.getController().ondisplay();
  },
};
