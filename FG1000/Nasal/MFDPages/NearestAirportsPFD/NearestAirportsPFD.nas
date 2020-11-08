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
# NearestAirportsPFD
var NearestAirportsPFD =
{
  new : func (mfd, myCanvas, device, svg)
  {
    var obj = {
      parents : [
        NearestAirportsPFD,
        MFDPage.new(mfd, myCanvas, device, svg, "NearestAirportsPFD", "NRST - NEAREST AIRPORTS")
      ],
    };

    obj.setController(fg1000.NearestAirportsPFDController.new(obj, svg));

    # Dynamic elements.  There are 2 different sets of dynamic elements:
    #
    # Nearest Airports - this is a scrolling list of up to 25 airports within 200nm, shown 3 at a time.
    # Airport Information - A page of more detailed information displaying details of the selected airport
    #
    # Selection is via the ENT key or the FMS knob

    obj.airportSelect = PFD.GroupElement.new(
      obj.pageName,
      svg,
      [ "ID", "BRG", "DST", "APP", "CommsType", "CommsFreq", "RWY"],
      3,
      "ID",
      0,
      "ScrollBar",
      "Scroll",
      140
    );

    # Dynamic text elements for the Airport Info pane.
    obj.addTextElements(["InfoID", "InfoName",
      "InfoFacility",
      "InfoUsage", "InfoTime", "InfoAlt",
      "InfoRegion",
      "InfoLat", "InfoLon", "InfoBack"]);

    obj.setTextElement("InfoBack", "BACK");
    obj._visible = 0;
    obj._NO_AIRPORTS = "NONE WITHIN 200NM";
    obj.getElement("Group").setVisible(0);
    obj.getElement("Info").setVisible(0);

    return obj;
  },

  visible : func() {
    return me._visible;
  },
  toggleDisplay : func() {
    if (me.visible()) {
      me.offdisplay();
    } else {
      me.ondisplay();
    }
  },
  offdisplay : func() {
    me.getElement("Group").setVisible(0);
    me.getElement("Info").setVisible(0);
    me._visible = 0;
    me.getController().offdisplay();
  },
  ondisplay : func() {
    me._visible = 1;
    me.getController().ondisplay();
    me.displayNearest();
  },
  displayNearest : func() {
    me.getElement("Group").setVisible(1);
    me.getElement("Info").setVisible(0);
  },
  displayInfo : func() {
    me.getElement("Group").setVisible(0);
    me.getElement("Info").setVisible(1);
    me.highlightTextElement("InfoBack");
  },
  updateAirports : func(apts) {

    var airportlist = [];
    for (var i = 0; i < size(apts); i = i + 1) {
      var apt = apts[i];
      var crsAndDst = courseAndDistance(apt);

      # Display the course and distance in NM .
      var crs = sprintf("%i°", crsAndDst[0]);
      var dst = sprintf("%.1fnm", crsAndDst[1]);

      # We need to derive various non-trivial pieces of information:
      # - Maximum runway Length
      # - Approach type - VFR, ILS, NDB
      # - Approach, Tower or Unicom frequency

      var max_rwy = 0;
      var app_type = "VFR";
      var freq_type = "";
      var freq = "";

      foreach(var rwy; keys(apt.runways)) {
        var rwy_info = apt.runways[rwy];
        max_rwy = math.max(max_rwy, rwy_info.length);

        # This is the best we can do at present for approach types.
        if (rwy_info.ils_frequency_mhz != nil) app_type = "ILS";
      }

      var apt_comms = apt.comms();
      foreach (var c; apt_comms) {
        if (string.icmp(c.ident, "Approach") or
            string.icmp(c.ident, "APP")      or
            string.icmp(c.ident, "APPROACH")   ) {

          freq_type = "APPROACH";
          freq = sprintf("%.3f", c.frequency);

          # Fine - we've got the best possible frequency, so break out
          # to stop any Tower frequencies from over-writing.
          break;
        }

        if (string.icmp(c.ident, "Tower") or
            string.icmp(c.ident, "TWR")   or
            string.icmp(c.ident, "Tower")   ) {
          freq_type = "TOWER";
          freq = sprintf("%.3f", c.frequency);
        }

        # Only select a Unicom / Traffic if there's nothing found already
        if ((freq_type == "") and
            (string.icmp(c.ident, "Unicom") or
             string.icmp(c.ident, "UNICOM")    )) {
          freq_type = "UNICOM";
          freq = sprintf("%.3f", c.frequency);
        }
      }

      # Convert into something we can pass straight to the UIGroup.
      append(airportlist, {
        ID: apt.id,
        BRG: crs,
        DST: dst,
        APP: app_type,
        CommsType : freq_type,
        CommsFreq : freq,
        RWY : sprintf("%ift", 3.28 * max_rwy)
      });
    }


    if (size(airportlist) == 0) {
      # Blank value if in the middle of nowhere
      append(airportlist, {
        ID: me._NO_AIRPORTS,
        BRG: "",
        DST: "",
        APP: "",
        CommsType : "",
        CommsFreq : "",
        RWY : ""
      });
    }

    me.airportSelect.setValues(airportlist);
  },
  updateAirportData : func(apt) {

    if (apt == nil) return;

    me.setTextElement("InfoID", apt.id);
    me.setTextElement("InfoName", string.uc(apt.name));
    me.setTextElement("InfoFacility", "");

    if (string.imatch(apt.name, "private") or string.imatch(apt.name, "pvt")) {
      me.setTextElement("InfoUsage", "PRIVATE");
    } else  {
      me.setTextElement("InfoUsage", "PUBLIC");
    }

    me.setTextElement("InfoTime", "");
    me.setTextElement("InfoAlt", sprintf("%ift", 3.28 * apt.elevation));
    me.setTextElementLat("InfoLat", apt.lat);
    me.setTextElementLon("InfoLon", apt.lon);

  },
  getSelectedAirportID : func() {
    var id = me.airportSelect.getValue();
    if (id == me._NO_AIRPORTS) id = nil;
    return id;
  },
};
