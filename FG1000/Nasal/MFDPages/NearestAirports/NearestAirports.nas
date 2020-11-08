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
# NearestAirports
var NearestAirports =
{
  new : func (mfd, myCanvas, device, svg)
  {
    var obj = {
      parents : [
        NearestAirports,
        MFDPage.new(mfd, myCanvas, device, svg, "NearestAirports", "NRST - NEAREST AIRPORTS")
      ],
    };

    obj.setController(fg1000.NearestAirportsController.new(obj, svg));

    # Dynamic elements.  There are 4 different sets of dynamic elements:
    #
    # Nearest Airports - this is a scrolling list of up to 25 airports within 200nm, shown 5 at a time.
    # Runways - just a single scroll element
    # Frequencies - 3 displayed in a scrolling list
    # Approaches - 3 displayed in a scrolling list
    #
    # Selection is via softkeys, the FMS knob, or via the page menu.

    obj.airportSelect = PFD.GroupElement.new(
      obj.pageName,
      svg,
      [ "Arrow", "ID", "CRS", "DST"],
      5,
      "Arrow",
      1,
      "AirportScrollBar",
      "AirportScroll",
      100
    );

    obj.runwaySelect = PFD.ScrollElement.new(obj.pageName, svg, "RunwayID", [36,18]); # Dummy values

    obj.freqSelect = PFD.GroupElement.new(
      obj.pageName,
      svg,
      ["FreqLabel", "Freq"],
      3,
      "Freq",
      0,
      "FreqScrollBar",
      "FreqScroll",
      75
    );

    obj.approachSelect = PFD.GroupElement.new(
      obj.pageName,
      svg,
      ["Approach"],
      3,
      "Approach",
      0,
      "ApproachScrollBar",
      "ApproachScroll",
      75
    );

    # Other dynamic text elements
    obj.addTextElements(["Name", "Alt", "RunwaySurface", "RunwayDimensions"]);

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

  # Function to highlight the APT softkey - used when CRSR is pressed to indicate
  # that we're editing the airports selection.
  selectAirports : func() {
    me.resetMenuColors();
    var bg_name = sprintf("SoftKey%d-bg",4);
    var tname = sprintf("SoftKey%d",4);
    me.device.svg.getElementById(bg_name).setColorFill(0.5,0.5,0.5);
    me.device.svg.getElementById(tname).setColor(0.0,0.0,0.0);
  },

  # Clear any cursor, highlights.  Used when exiting from CRSR mode
  resetCRSR : func() {
    me.airportSelect.hideCRSR();
    me.runwaySelect.unhighlightElement();
    me.freqSelect.hideCRSR();
    me.approachSelect.hideCRSR();
    me.resetMenuColors();
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
  updateAirports : func(apts) {

    if (apts == nil) return;

    var airportlist = [];
    for (var i = 0; i < size(apts); i = i + 1) {
      var apt = apts[i];
      var crsAndDst = courseAndDistance(apt);

      # Display the course and distance in NM .
      var crs = sprintf("%i°", crsAndDst[0]);
      var dst = sprintf("%.1fnm", crsAndDst[1]);

      # Convert into something we can pass straight to the UIGroup.
      append(airportlist, {
        Arrow : apt.id,
        ID: apt.id,
        CRS: crs,
        DST: dst,
      });
    }

    me.airportSelect.setValues(airportlist);

    if (size(airportlist) > 0) {
      me.updateAirportData(apts[0]);
      #me.airportSelect.showCRSR();
    } else {
      #me.airportSelect.hideCRSR();
      me.setTextElement("Name", "NONE WITHIN 200NM");
      me.setTextElement("Alt", "");
    }
  },
  updateAirportData : func(apt) {

    if (apt == nil) return;

    me.setTextElement("Name", apt.name);
    me.setTextElement("Alt", sprintf("%ift", M2FT * apt.elevation));

    # Set up the runways list, but ignoring reciprocals so we don't get
    # runways displayed twice.
    var rwys = [];
    var recips = {};
    foreach(var rwy; sort(keys(apt.runways), string.icmp)) {
      var rwy_info = apt.runways[rwy];
      if (recips[rwy_info.id] == nil) {
        var lbl = rwy_info.id ~ "-" ~ rwy_info.reciprocal.id;
        append(rwys, lbl);
        recips[rwy_info.reciprocal.id] = 1;
      }
    }

    if (size(rwys) > 0) {
      me.runwaySelect.setValues(rwys);
      me.updateRunwayInfo(apt.runways[keys(apt.runways)[0]]);
    } else {
      me.runwaySelect.setValues([""]);
      me.updateRunwayInfo(nil);
    }

    var freqarray = [];

    # Add Comm Frequencies
    var apt_comms = apt.comms();
    if (size(apt_comms) > 0) {
      # Airport has one or more frequencies assigned to it.
      var freqs = {};
      foreach (var c; apt_comms) {
        freqs[c.ident] = sprintf("%.3f", c.frequency);
      }

      foreach (var c; sort(keys(freqs), string.icmp)) {
        append(freqarray, {FreqLabel: c, Freq: freqs[c]});
      }
    }

    # Add any ILS frequencies as well
    foreach(var rwy; sort(keys(apt.runways), string.icmp)) {
      var rwy_info = apt.runways[rwy];
      if (rwy_info.ils_frequency_mhz != nil) {
        var label = "ILS " ~ rwy_info.id;
        var freq  = sprintf("%.3f", rwy_info.ils_frequency_mhz);
        append(freqarray, {FreqLabel: label, Freq: freq});
      }
    }

    me.freqSelect.setValues(freqarray);

    # Approaches
    var approachList = apt.getApproachList();
    me.approachSelect.setValues(approachList);

    # Display the DTO line to the airport
    me.mfd.NavigationMap.getController().setDTOLineTarget(apt.lat, apt.lon);
  },
  updateRunwayInfo : func(rwy_info) {
    if (rwy_info != nil ) {
      var dim = sprintf("%ift x %ift", 3.28 * rwy_info.length, 3.28 * rwy_info.width);
      me.setTextElement("RunwayDimensions", dim);
      me.setTextElement("RunwaySurface", SURFACE_TYPES[rwy_info.surface]);
    } else {
      me.setTextElement("RunwayDimensions", "");
      me.setTextElement("RunwaySurface", "");
    }
  },
  getSelectedAirportID : func() {
    return me.airportSelect.getValue();
  },
  getSelectedRunway : func() {
    return me.runwaySelect.getValue();
  },
  getSelectedFreq : func() {
    return me.freqSelect.getValue();
  },
  getSelectedApproach : func() {
    return me.approachSelect.getValue();
  },

  topMenu : func(device, pg, menuitem) {
    pg.clearMenu();
    pg.resetMenuColors();
    pg.addMenuItem(0, "ENGINE", pg, pg.mfd.EIS.engineMenu);
    pg.addMenuItem(2, "MAP", pg, pg.mfd.NavigationMap.mapMenu);
    pg.addMenuItem(4, "APT", pg,
      func(dev, pg, mi) { pg.getController().selectAirports(); device.updateMenus(); }, # callback
      func(svg, mi) { pg.display_toggle(device, svg, mi, NearestAirportsController.UIGROUP.APT); }
    );

    pg.addMenuItem(5, "RNWY", pg,
      func(dev, pg, mi) { pg.getController().selectRunways(); device.updateMenus(); }, # callback
      func(svg, mi) { pg.display_toggle(device, svg, mi, NearestAirportsController.UIGROUP.RNWY); }
    );

    pg.addMenuItem(6, "FREQ", pg,
      func(dev, pg, mi) { pg.getController().selectFrequencies(); device.updateMenus(); }, # callback
      func(svg, mi) { pg.display_toggle(device, svg, mi, NearestAirportsController.UIGROUP.FREQ); }
    );

    pg.addMenuItem(7, "APR", pg,
      func(dev, pg, mi) { pg.getController().selectApproaches(); device.updateMenus(); }, # callback
      func(svg, mi) { pg.display_toggle(device, svg, mi, NearestAirportsController.UIGROUP.APR); }
    );

    device.updateMenus();
  },
};
