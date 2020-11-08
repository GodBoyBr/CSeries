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
# MFD Surround
#
# Header fields at the top of the page
#
# PageGroup navigation, displayed in the bottom right of the
# FMS, and controlled by the FMS knob

# Set of pages, references by SVG ID
var PAGE_GROUPS = [

  { label: "MapPageGroupLabel",
          group: "MapPageGroup",
          pages: [ "NavigationMap", "TrafficMap", "Stormscope", "WeatherDataLink", "TAWSB"],
  },
  { label: "WPTGroupLabel",
          group: "WPTPageGroup",
          pages: [ "AirportInfo", "IntersectionInfo", "NDBInfo", "VORInfo", "UserWPTInfo"],
  },

  { label: "AuxGroupLabel",
          group: "AuxPageGroup",
          pages: [ "TripPlanning", "Utility", "GPSStatus", "XMRadio", "SystemStatus"],
  },

  { label: "FPLGroupLabel",
          group: "FPLPageGroup",
          pages: [ "ActiveFlightPlanNarrow", "FlightPlanCatalog", "StoredFlightPlan"],
  },

  { label: "LstGroupLabel",
          group: "LstPageGroup",
          pages: [ "Checklist"],
  },

  { label: "NrstGroupLabel",
          group: "NrstPageGroup",
          pages: [ "NearestAirports", "NearestIntersections", "NearestNDB", "NearestVOR", "NearestUserWaypoints", "NearestFrequencies", "NearestAirspaces"],
  }
];

# Mapping for header labels to specific FMS or ADC messages, and sprintf formatting
# to use
var HEADER_MAPPING = {
  "BRG" : { message : "FMSLegBearingMagDeg",      format : "%d°"},
  "XTK" : { message : "FMSLegCourseError",        format : "%.1fnm"},
  "DIS" : { message : "FMSDistance",              format : "%.1fnm"},
  "DTK" : { message : "FMSLegDesiredTrack",       format : "%d°"},
  "END" : { message : "EnduranceHrs",             format : "%.1fhrs"},
  "ESA" : { message : "EnRouteSafeAltitude",      format : "%dft"},    # TODO
  "ETA" : { message : "FMSEstimatedTimeArrival",  format : ""},        # TODO
  "ETE" : { message : "FMSEstimatedTimeEnroute",     format : ""},
  "FOD" : { message : "FMSFuelOverDestination",      format : "%dgal"},
  "FOB" : { message : "FuelOnBoard",                 format : "%dgal"},
  "GS"  : { message : "FMSGroundspeed",              format : "%dkts"},
  "MSA" : { message : "MinimumSafeAltitude",         format : "%dft"},    # TODO
  "TAS" : { message : "ADCTrueAirspeed",             format : "%dkts"},
  "TKE" : { message : "FMSLegTrackErrorAngle",       format : "%d°"},
  "TRK" : { message : "FMSLegTrack",                 format : "%d°"},
  "VSR" : { message : "FMSLegVerticalSpeedRequired", format : "%dfpm"},   # TODO
};

# Style element use for the AP Status indicator.  This is normally green text
# on a black background, but is highlighted when disengaged as black text on a yellow
# background for 5 seconds.
var AP_STATUS_STYLE = {
  CURSOR_BLINK_PERIOD : 0.5,
  HIGHLIGHT_COLOR :  "#ffff00",
  HIGHLIGHT_TEXT_COLOR : "#000000",
  NORMAL_TEXT_COLOR : "#00ff00",
};

# Style element for use by the flight director modes and armed indicators.
# This is normally green text on a black background, but when highlighted is
# black text on a green background
var FD_STATUS_STYLE = {
  CURSOR_BLINK_PERIOD : 0.5,
  HIGHLIGHT_COLOR :  "#00ff00",
  HIGHLIGHT_TEXT_COLOR : "#000000",
  NORMAL_TEXT_COLOR : "#00ff00",
};

var Surround =
{
  new : func (mfd, myCanvas, device, svg, pfd=0)
  {
    var obj = { parents : [
      Surround,
      MFDPage.new(mfd, myCanvas, device, svg, "Surround", ""),
    ] };

    obj.pfd = pfd;

    var textElements = [
      "Comm1StandbyFreq", "Comm1SelectedFreq",
      "Comm2StandbyFreq", "Comm2SelectedFreq",
      "Nav1StandbyFreq", "Nav1SelectedFreq",
      "Nav2StandbyFreq", "Nav2SelectedFreq",
      "Nav1ID", "Nav2ID",
    ];

    var fdTextElements = ["HeaderAPLateralArmed", "HeaderAPLateralActive", "HeaderAPVerticalArmed", "HeaderAPVerticalActive", "HeaderAPVerticalReference"];

    obj.addTextElements(textElements);

    if (pfd) {
      obj.addTextElements(["HeaderFrom", "HeaderTo", "LegDistance", "LegBRG"]);
      obj.addTextElements(fdTextElements, FD_STATUS_STYLE);
      obj.setTextElements(fdTextElements, "");
      obj._apStatus = PFD.TextElement.new(obj.pageName, svg, "HeaderAPStatus", "", AP_STATUS_STYLE);
      obj._dto = PFD.HighlightElement.new(obj.pageName, svg, "HeaderDTO", "DTO");
      obj._leg = PFD.HighlightElement.new(obj.pageName, svg, "HeaderActiveLeg", "Leg");
      obj._old_lateral_armed = nil;  # We store the previous armed values so we can detect a transtion from armed to active.
      obj._old_vertical_armed = nil;
      obj._ap_on = 0;
    } else {
      obj.addTextElements(["Header1Label", "Header1Value",
                            "Header2Label", "Header2Value",
                            "Header3Label", "Header3Value",
                            "Header4Label", "Header4Value"]);
    }

    obj._comm1selected = PFD.HighlightElement.new(obj.pageName, svg, "Comm1Selected", "Comm1");
    obj._comm2selected = PFD.HighlightElement.new(obj.pageName, svg, "Comm2Selected", "Comm2");

    obj._nav1selected = PFD.HighlightElement.new(obj.pageName, svg, "Nav1Selected", "Nav1");
    obj._nav2selected = PFD.HighlightElement.new(obj.pageName, svg, "Nav2Selected", "Nav2");

    obj._comm1failed = PFD.HighlightElement.new(obj.pageName, svg, "Comm1Failed", "Comm1");
    obj._comm2failed = PFD.HighlightElement.new(obj.pageName, svg, "Comm2Failed", "Comm2");

    obj._nav1failed = PFD.HighlightElement.new(obj.pageName, svg, "Nav1Failed", "Nav1");
    obj._nav2failed = PFD.HighlightElement.new(obj.pageName, svg, "Nav2Failed", "Nav2");

    obj._canvas = myCanvas;
    obj._menuVisible = 0;
    obj._selectedPageGroup = 0;
    obj._selectedPage = 0;

    obj._elements = {};

    foreach (var pageGroup; PAGE_GROUPS) {
      var group = svg.getElementById(pageGroup.group);
      var label = svg.getElementById(pageGroup.label);
      assert(group != nil, "Unable to find element " ~ pageGroup.group);
      assert(label != nil, "Unable to find element " ~ pageGroup.label);
      obj._elements[pageGroup.group] = group;
      obj._elements[pageGroup.label] = label;

      foreach(var pg; pageGroup.pages) {
        var page = svg.getElementById(pg);
        assert(page != nil, "Unable to find element " ~ pg);
        obj._elements[pg] = page;
      }
    }

    # Timers to control when to hide the menu after inactivity, and when to load
    # a new page.
    obj._hideMenuTimer = maketimer(3, obj, obj.hideMenu);
    obj._hideMenuTimer.singleShot = 1;

    obj._loadPageTimer = maketimer(0.5, obj, obj.loadPage);
    obj._loadPageTimer.singleShot = 1;

    obj.hideMenu();

    obj.setController(fg1000.SurroundController.new(obj, svg, pfd));
    return obj;
  },

  handleNavComData : func(data) {
    foreach(var name; keys(data)) {
      var val = data[name];

      if (name == "Comm1SelectedFreq") me.setTextElement("Comm1SelectedFreq", sprintf("%0.03f", val));
      if (name == "Comm1StandbyFreq") me.setTextElement("Comm1StandbyFreq", sprintf("%0.03f", val));
      if (name == "Comm1Serviceable") {
        if (val == 1) {
          me._comm1failed.setVisible(0);
        } else {
          me._comm1failed.setVisible(1);
        }
      }

      if (name == "Comm2SelectedFreq") me.setTextElement("Comm2SelectedFreq", sprintf("%0.03f", val));
      if (name == "Comm2StandbyFreq") me.setTextElement("Comm2StandbyFreq", sprintf("%0.03f", val));
      if (name == "Comm2Serviceable") {
        if (val == 1) {
          me._comm2failed.setVisible(0);
        } else {
          me._comm2failed.setVisible(1);
        }
      }

      if (name == "CommSelected") {
        if (val == 1) {
          me._comm1selected.setVisible(1);
          me._comm2selected.setVisible(0);
        } else {
          me._comm1selected.setVisible(0);
          me._comm2selected.setVisible(1);
        }
      }

      if (name == "Nav1SelectedFreq") me.setTextElement("Nav1SelectedFreq", sprintf("%0.03f", val));
      if (name == "Nav1StandbyFreq") me.setTextElement("Nav1StandbyFreq", sprintf("%0.03f", val));
      if (name == "Nav1Serviceable") {
        if (val == 1) {
          me._nav1failed.setVisible(0);
        } else {
          me._nav1failed.setVisible(1);
        }
      }

      if (name == "Nav2SelectedFreq") me.setTextElement("Nav2SelectedFreq", sprintf("%0.03f", val));
      if (name == "Nav2StandbyFreq") me.setTextElement("Nav2StandbyFreq", sprintf("%0.03f", val));
      if (name == "Nav2Serviceable") {
        if (val == 1) {
          me._nav2failed.setVisible(0);
        } else {
          me._nav2failed.setVisible(1);
        }
      }

      if (name == "NavSelected") {
        if (val == 1) {
          me._nav1selected.setVisible(1);
          me._nav2selected.setVisible(0);
        } else {
          me._nav1selected.setVisible(0);
          me._nav2selected.setVisible(1);
        }
      }

      if (name == "Nav1ID") me.setTextElement("Nav1ID", val);
      if (name == "Nav2ID") me.setTextElement("Nav2ID", val);

      # TODO - COM Volume - display the current volume for 2 seconds in place of the
      # standby frequency.


    }
  },

  # Update Header data with FMS or ADC data.
  updateHeaderData : func(data) {

    if (me.pfd) {
      # From, To, leg distance and leg bearing headers
      if (data["FMSLegID"]) {
        if (data["FMSLegID"] == "") {
          # No Leg, so hide the headers
          me.setTextElement("HeaderTo", "");
          me.setTextElement("HeaderFrom", "");
          me._dto.setVisible(0);
          me._leg.setVisible(0);
        } else {
          me.setTextElement("HeaderTo", data["FMSLegID"]);
          me._leg.setVisible(1);

          if (data["FMSMode"] == "dto") {
            me.setTextElement("HeaderFrom", "");
            me._dto.setVisible(1);
          } else {
            me._dto.setVisible(0);
            me.setTextElement("HeaderFrom", data["FMSPreviousLegID"]);
          }
        }
      }

      # When the Autopilot Heading or Altitude modes moves from armed to active we flash the appropriate annunicator for 10 seconds.
      # Unfortunately as we use a TriggeredPropertyPublisher, we won't have both the HeaderAP[Vertical|Lateral]Active and HeaderAP[Vertical|Lateral]Armed
      # values at the same time so have to save off any change in the armed values to check against.

      if ((data["AutopilotHeadingMode"] != nil) and
          (data["AutopilotHeadingMode"] != me.getTextValue("HeaderAPLateralActive"))) {

        me.setTextElement("HeaderAPLateralActive", data["AutopilotHeadingMode"]);

        if ((data["AutopilotHeadingMode"] != "") and
            ((data["AutopilotHeadingMode"] == me._old_lateral_armed) or
             (data["AutopilotHeadingMode"] == me.getTextValue("HeaderAPLateralArmed"))))
        {
          # Transition from an armed mode to a new mode, so flash
          me.highlightTextElement("HeaderAPLateralActive", 10);
        }
      }

      if ((data["AutopilotAltitudeMode"] != nil) and
          (data["AutopilotAltitudeMode"] != me.getTextValue("HeaderAPVerticalActive"))) {

        me.setTextElement("HeaderAPVerticalActive", data["AutopilotAltitudeMode"]);

        if ((data["AutopilotAltitudeMode"] != "") and
            ((data["AutopilotAltitudeMode"] == me._old_vertical_armed) or
             (data["AutopilotAltitudeMode"] == me.getTextValue("HeaderAPVerticalArmed"))))
        {
          # Transition from an armed mode to a new mode, so flash
          me.highlightTextElement("HeaderAPVerticalActive", 10);
        }
      }

      if (data["AutopilotHeadingModeArmed"] != nil) {
        if (data["AutopilotHeadingModeArmed"] != me.getTextValue("HeaderAPLateralArmed")) me._old_lateral_armed = me.getTextValue("HeaderAPLateralArmed");
        me.setTextElement("HeaderAPLateralArmed", data["AutopilotHeadingModeArmed"]);
      }

      if (data["AutopilotAltitudeModeArmed"] != nil) {
        if (data["AutopilotAltitudeModeArmed"] != me.getTextValue("HeaderAPVerticalArmed")) me._old_lateral_armed = me.getTextValue("HeaderAPVerticalArmed");
        me.setTextElement("HeaderAPVerticalArmed", data["AutopilotAltitudeModeArmed"]);
      }

      # When the Autopilot is disengaged, the AP status element flashes for 5 seconds before disappearing
      if (data["AutopilotEnabled"] != nil) {

        if ((data["AutopilotEnabled"] == 1) and (me._ap_on == 0)) {
          # Toggle the AP on, stopping any flashing that might be occurring.
          me._apStatus.unhighlightElement();
          me._apStatus.setValue("AP");
          me._ap_on = 1;
        }

        if ((data["AutopilotEnabled"] == 0) and me._ap_on) {
          # Toggle the AP off, by flashing the AP Status element for 5 seconds before removing it.
          # Only do this if we're not already flashing.
          me._ap_on = 0;
          me._apStatus.highlightElement(5.0, "");
        }
      }

      if (data["AutopilotTargetVertical"] != nil) me.setTextElement("HeaderAPVerticalReference", data["AutopilotTargetVertical"]);
      if (data["FMSLegDesiredTrack"]) me.setTextElement("LegBRG", sprintf("%i°", data["FMSLegDesiredTrack"]));
      if (data["FMSLegDistanceNM"]) me.setTextElement("LegDistance", sprintf("%.1fnm", data["FMSLegDistanceNM"]));
    } else {
      # MFD - 4 configurable Headers
      var headers = ["Header1", "Header2", "Header3", "Header4"];
      foreach (var header; headers) {

        # Get the currently configured heading and set the surround to display it.
        var label = me.mfd.ConfigStore.get("MFD" ~ header);
        assert(label != nil, "No header configured in ConfigStore for " ~ header);
        me.setTextElement(header ~ "Label", label);

        # Determine how it maps to Emesary data notifications
        var mapping = HEADER_MAPPING[label];
        assert(mapping != nil, "No header mapping for " ~ label);

        if (data[mapping.message] != nil) {
          # Format and display the value
          var value = sprintf(mapping.format, data[mapping.message]);

          if (mapping.message == "FMSEstimatedTimeEnroute") {
            # Special case to format time strings.
            var hrs = int(data[mapping.message]);
            var mins = int(60*(data[mapping.message] - hrs));
            var secs = int(3600*(data[mapping.message] - hrs - mins/60));

            if (hrs == 0) {
              value = sprintf("%d:%02d", mins, secs);
            } else {
              value = sprintf("%d:%02d", hrs, mins);
            }
          }
          me.setTextElement(header ~ "Value", value);
        }
      }
    }
  },

  getCurrentPage : func()
  {
    var currentpage = PAGE_GROUPS[me._selectedPageGroup].pages[me._selectedPage];
    return me.getMFD().getPage(currentpage);
  },

  # Go to a define page in the MFD.  Only valid for MFDs, and mainly used as
  # a useability shortcut to avoid having to use the FMS knobs.
  goToPage : func(group, page)
  {
    # Not valid for the PFD.
    if (me.pfd) return;

    # Values may be passed as names or indices.
    if (int(group) == nil) {
      for (var i = 0; i < size(PAGE_GROUPS); i = i + 1) {
        if (group == PAGE_GROUPS[i].group) {
          me._selectedPageGroup = i;
        }
      }
    } else {
      assert(group < size(PAGE_GROUPS), "Page Group index " ~ group ~ " out of bounds");
      me._selectedPageGroup = group;
    }

    if (int(page) == nil) {
      for (var j = 0; j < size(PAGE_GROUPS[me._selectedPageGroup].pages); j = j + 1) {
        if (page == PAGE_GROUPS[me._selectedPageGroup].pages[j]) {
          me._selectedPage = j;
        }
      }
    } else {
      assert(page < size(PAGE_GROUPS[me._selectedPageGroup].pages), "Page Group index " ~ group ~ " out of bounds");
      me._selectedPage = page;
    }

    # Now we've updated the selected pages, then load it
    me.loadPage();
  },

  # Function to change a page based on the selection
  loadPage : func()
  {
    # Not valid for the PFD.
    if (me.pfd) return;

    var pageToLoad = PAGE_GROUPS[me._selectedPageGroup].pages[me._selectedPage];
    var page = me.getMFD().getPage(pageToLoad);

    assert(page != nil, "Unable to find page " ~ pageToLoad);
    me.device.selectPage(page);
  },
  incrPageGroup : func(val) {
    var incr_or_decr = (val > 0) ? 1 : -1;
    me._selectedPageGroup = math.mod(me._selectedPageGroup + incr_or_decr, size(PAGE_GROUPS));
    me._selectedPage = 0;
  },
  incrPage : func(val) {
    var incr_or_decr = (val > 0) ? 1 : -1;
    me._selectedPage = math.mod(me._selectedPage + incr_or_decr, size(PAGE_GROUPS[me._selectedPageGroup].pages));
  },
  showMenu : func()
  {
    # Not valid for the PFD.
    if (me.pfd) return;
    
    foreach(var pageGroup; PAGE_GROUPS)
    {
      if (PAGE_GROUPS[me._selectedPageGroup].label == pageGroup.label)
      {
        # Display the page group and highlight the label
        me._elements[pageGroup.group].setVisible(1);
        me._elements[pageGroup.label].setVisible(1);
        me._elements[pageGroup.label].setColor(0.7,0.7,1.0);

        foreach (var page; pageGroup.pages)
        {
          # Highlight the current page.
          if (pageGroup.pages[me._selectedPage] == page) {
            me._elements[page].setColor(0.7,0.7,1.0);
          } else {
            me._elements[page].setColor(0.7,0.7,0.7);
          }
        }
      }
      else
      {
        # Hide the pagegroup and unhighlight the label on the bottom
        me._elements[pageGroup.group].setVisible(0);
        me._elements[pageGroup.label].setVisible(1);
        me._elements[pageGroup.label].setColor(0.7,0.7,0.7);
      }
    }
    me._menuVisible = 1;
    me._hideMenuTimer.stop();
    me._hideMenuTimer.restart(3);
    me._loadPageTimer.stop();
    me._loadPageTimer.restart(0.5);

  },
  hideMenu : func()
  {
    foreach(var pageGroup; PAGE_GROUPS)
    {
      me._elements[pageGroup.group].setVisible(0);
      me._elements[pageGroup.label].setVisible(0);
    }
    me._menuVisible = 0;
  },
  isMenuVisible : func()
  {
    return me._menuVisible;
  },


};
