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
# AirportInfo Controller
var AirportInfoController =
{
  # Vertical ranges, and labels.
  # Unlike some other map displays, we keep the range constant at 4nm an change
  # the ScreenRange to zoom in.  Otherwise as we zoom in, the center of the
  # runways moves out of the range of the display and they are not drawn.
  # Ranges are scaled to the display height with range 1 displaying 4nm vertically.
  # 2000nm = 12,152,000ft.
  RANGES : [{range: 4/500/6076.12, label: "500ft"},
            {range: 4/750/6076.12, label: "750ft"},
            {range: 4/1000/6076.12, label: "1000ft"},
            {range: 4/1500/6076.12, label: "1500ft"},
            {range: 4/2000/6076.12, label: "2000ft"},
            {range: 8, label: "0.5nm"},
            {range: 5.33, label: "0.75nm"},
            {range: 4, label: "1nm"},
            {range: 2, label: "2nm"},
            {range: 1.33, label: "3nm"},
            {range: 1, label: "4nm"},
            {range: 0.66, label: "6nm"},
            {range: 0.5, label: "8nm"},
            {range: 0.4, label: "10nm"} ],

  UIGROUP : {
    APT  : 0,
    RNWY : 1,
    FREQ : 2,
  },

  new : func (page, svg)
  {
    var obj = { parents : [ AirportInfoController, MFDPageController.new(page)] };
    obj.airport = "";
    obj.runway = "";
    obj.runwayIdx = -1;
    obj.info = nil;
    obj.page = page;
    obj.crsrToggle = 0;
    obj._currentGroup = AirportInfoController.UIGROUP.APT;
    obj.current_zoom = 7;

    obj.setZoom(obj.current_zoom);

    return obj;
  },

  selectAirport : func() {
    me.selectGroup(AirportInfoController.UIGROUP.APT)
  },
  selectRunways : func() {
    me.selectGroup(AirportInfoController.UIGROUP.RNWY);
  },
  selectFrequencies : func() {
    me.selectGroup(AirportInfoController.UIGROUP.FREQ);
  },
  getSelectedGroup : func() {
    return me._currentGroup;
  },
  selectGroup : func(grp) {
    me._currentGroup = grp;
    if (grp == AirportInfoController.UIGROUP.APT)  me.page.airportEntry.highlightElement() else me.page.airportEntry.unhighlightElement();
    if (grp == AirportInfoController.UIGROUP.RNWY) me.page.runwaySelect.highlightElement()   else me.page.runwaySelect.unhighlightElement();
    if (grp == AirportInfoController.UIGROUP.FREQ) me.page.freqSelect.showCRSR()     else me.page.freqSelect.hideCRSR();
    me._crsrToggle = 1;
  },

  setAirport : func(id)
  {
    if (id == me.airport) return;
    var apt = me.getAirport(id);

    if (apt != nil)  {
      me.airport = id;

      # Set up the default ID if the user presses DTO.
      me.setDefaultDTOWayPoint(id);
      me.info = apt;
    }

    # Reset airport display.  We do this irrespective of whether the id
    # is valid, as it allows us to clear any bad user input from the ID field
    me.page.displayAirport(me.info);
  },
  setRunway : func(runwayID)
  {
    me.page.displayRunway(me.info.runways[runwayID]);
  },

  # Control functions for Input
  zoomIn : func() {
    me.setZoom(me.current_zoom -1);
  },
  zoomOut : func() {
    me.setZoom(me.current_zoom +1);
  },
  handleRange : func(val)
  {
    var incr_or_decr = (val > 0) ? 1 : -1;
    me.setZoom(me.current_zoom + incr_or_decr);
  },
  setZoom : func(zoom) {
    if ((zoom < 0) or (zoom > (size(me.RANGES) - 1))) return;
    me.current_zoom = zoom;
    me.page.setZoom(me.RANGES[zoom].range * fg1000.MAP_PARTIAL.HEIGHT, me.RANGES[zoom].label);
  },
  handleCRSR : func() {
    me.crsrToggle = (! me.crsrToggle);
    if (me.crsrToggle) {
      me.selectAirport();
    } else {
      me.page.resetCRSR();
    }
    return emesary.Transmitter.ReceiptStatus_Finished;
  },
  handleFMSInner : func(value) {
    if (me.crsrToggle == 1) {
      if (me._currentGroup == AirportInfoController.UIGROUP.APT) {
        me.page.airportEntry.incrSmall(value);
      }

      if (me._currentGroup == AirportInfoController.UIGROUP.RNWY) {
        me.page.runwaySelect.incrSmall(value);
        var val = me.page.runwaySelect.getValue();
        if (val != nil) {
          # Selection values are of the form "06L-12R".  We need to set the
          # runway to the left half.
          var idx = find("-", val);
          if (idx != -1) {
            var rwy = substr(val, 0, idx);
            me.setRunway(rwy);
          }
        }
      }

      if (me._currentGroup == AirportInfoController.UIGROUP.FREQ) {
        me.page.freqSelect.incrSmall(value);
      }

      return emesary.Transmitter.ReceiptStatus_Finished;
    } else {
      return me.page.mfd.SurroundController.handleFMSInner(value);
    }
  },
  handleFMSOuter : func(value) {
    if (me.crsrToggle == 1) {
      if ((me._currentGroup == AirportInfoController.UIGROUP.APT) and me.page.airportEntry.isInEdit()) {
        me.page.airportEntry.incrLarge(value);
      } else {
        var incr_or_decr = (value > 0) ? 1 : -1;
        var idx = math.mod(me._currentGroup + incr_or_decr, size(AirportInfoController.UIGROUP));
        me.selectGroup(idx);
      }

      return emesary.Transmitter.ReceiptStatus_Finished;
    } else {
      return me.page.mfd.SurroundController.handleFMSOuter(value);
    }
  },
  handleEnter : func(value) {
    if (me.crsrToggle == 1) {
      if ((me._currentGroup == AirportInfoController.UIGROUP.APT) and me.page.airportEntry.isInEdit()) {
        var aptname = me.page.airportEntry.enterElement();
        me.setAirport(aptname);
      }

      if (me._currentGroup == AirportInfoController.UIGROUP.FREQ) {
        me.page.mfd.SurroundController.setStandbyNavComFreq(me.page.freqSelect.getValue());
      }

      return emesary.Transmitter.ReceiptStatus_Finished;
    } else {
      return emesary.Transmitter.ReceiptStatus_NotProcessed;
    }
  },
  handleClear : func(value) {
    if ((me.crsrToggle == 1) and
        (me._currentGroup == AirportInfoController.UIGROUP.APT) and
        me.page.airportEntry.isInEdit()) {
        me.page.airportEntry.clearElement();
        return emesary.Transmitter.ReceiptStatus_Finished;
    } else {
      return emesary.Transmitter.ReceiptStatus_NotProcessed;
    }
  },

  handleStringInput : func(value) {
    me.selectAirport();
    me.page.airportEntry.clearElement();
    me.page.airportEntry.setValue(value);
    me.setAirport(value);
    me.page.resetCRSR();
    return emesary.Transmitter.ReceiptStatus_Finished;
  },

  # Reset controller if required when the page is displayed or hidden
  ondisplay : func() {
    me.RegisterWithEmesary();

    if (me.airport == "") {
      # Initial airport is our current location.
      # Needs to be done here as the data provider may not be set up when
      # we are created.

      # Use Emesary to get the airport
      var notification = notifications.PFDEventNotification.new(
        "MFD",
        me.getDeviceID(),
        notifications.PFDEventNotification.NavData,
        {Id: "NearestAirports", Value: nil});

      var response = me._transmitter.NotifyAll(notification);
      var retval = notification.EventParameter.Value;

      if ((! me._transmitter.IsFailed(response)) and (size(retval) > 0)) {
        var current_apt = retval[0];
        me.setAirport(current_apt.id);
      }
    }
  },
  offdisplay : func() {
    me.DeRegisterWithEmesary();
  },

  getAirport : func(id) {
    # Use Emesary to get the airport
    var notification = notifications.PFDEventNotification.new(
      "MFD",
      me.getDeviceID(),
      notifications.PFDEventNotification.NavData,
      {Id: "AirportByID", Value: id});

    var response = me._transmitter.NotifyAll(notification);
    var retval = notification.EventParameter.Value;

    if ((! me._transmitter.IsFailed(response)) and (size(retval) > 0)) {
      return retval[0];
    } else {
      return nil;
    }
  },
};
