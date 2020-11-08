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
# NearestAirports Controller
var NearestAirportsController =
{
  UIGROUP : {
    NONE : 0, # No group currently selected,
    APT  : 1,
    RNWY : 2,
    FREQ : 3,
    APR  : 4,
  },

  new : func (page, svg)
  {
    var obj = { parents : [ NearestAirportsController, MFDPageController.new(page) ] };

    # Current active UI group.
    obj.page = page;
    obj._currentGroup = NearestAirportsController.UIGROUP.NONE;
    obj._crsrToggle = 0;

    return obj;
  },

  selectAirports : func() {
    me.selectGroup(NearestAirportsController.UIGROUP.APT)
  },
  selectRunways : func() {
    me.selectGroup(NearestAirportsController.UIGROUP.RNWY);
  },
  selectFrequencies : func() {
    me.selectGroup(NearestAirportsController.UIGROUP.FREQ);
  },
  selectApproaches : func() {
    me.selectGroup(NearestAirportsController.UIGROUP.APR);
  },
  getSelectedGroup : func() {
    return me._currentGroup;
  },
  selectGroup : func(grp) {
    me._currentGroup = grp;
    if (grp == NearestAirportsController.UIGROUP.APT)  me.page.airportSelect.showCRSR()   else me.page.airportSelect.hideCRSR();
    if (grp == NearestAirportsController.UIGROUP.RNWY) me.page.runwaySelect.highlightElement()   else me.page.runwaySelect.unhighlightElement();
    if (grp == NearestAirportsController.UIGROUP.FREQ) me.page.freqSelect.showCRSR()     else me.page.freqSelect.hideCRSR();
    if (grp == NearestAirportsController.UIGROUP.APR)  me.page.approachSelect.showCRSR() else me.page.approachSelect.hideCRSR();
    me._crsrToggle = 1;
  },

  # Input Handling
  handleCRSR : func() {
    me._crsrToggle = (! me._crsrToggle);
    if (me._crsrToggle) {
      me.page.topMenu(me.page.device, me.page, nil);
      me.page.selectAirports();
      me.selectAirports();
    } else {
      # Hide the cursor and reset any highlighting
      me.page.resetCRSR();
    }
    return emesary.Transmitter.ReceiptStatus_Finished;
  },
  handleFMSInner : func(value) {
    if (me._crsrToggle == 1) {
      # Scroll through whatever is the current list

      if (me._currentGroup == NearestAirportsController.UIGROUP.APT) {
        me.page.airportSelect.incrSmall(value);
        var apt_id = me.page.getSelectedAirportID();

        var aptdata = me.getAirport(apt_id);
        me.page.updateAirportData(aptdata);
      }

      if (me._currentGroup == NearestAirportsController.UIGROUP.RNWY) {
        me.page.runwaySelect.incrSmall(value);
        # Need to manually update the runway information
        var apt_id = me.page.airportSelect.getValue();
        var rwy    = me.page.runwaySelect.getValue();

        if ((rwy != nil) and (rwy != "")) {
          var apt_info = me.getAirport(apt_id);

          if (apt_info != nil) {
            # Names in the runway selection are of the form "NNN-MMM", e.g. 11R-29L
            # We just want the first of these.
            var idx = find("-", rwy);
            if (idx != -1) {
              rwy = substr(rwy, 0, idx);
              var rwy_info = apt_info.runways[rwy];
              me.page.updateRunwayInfo(rwy_info);
            }
          }
        }
      }

      if (me._currentGroup == NearestAirportsController.UIGROUP.FREQ) me.page.freqSelect.incrSmall(value);
      if (me._currentGroup == NearestAirportsController.UIGROUP.APR)  me.page.approachSelect.incrSmall(value);

      return emesary.Transmitter.ReceiptStatus_Finished;
    } else {
      return me.page.mfd.SurroundController.handleFMSInner(value);
    }
  },
  handleFMSOuter : func(value) {
    if (me._crsrToggle == 1) {

      # The large knob only affects the Airport selection in cursor mode.
      # Question-mark over whether it does this when other groups
      # are selected.  Assumption now is that it doesn't - otherwise it would
      # be too easy to nudge it while trying to scroll through runways/approaches etc.

      if (me._currentGroup == NearestAirportsController.UIGROUP.APT) {
        me.page.airportSelect.incrLarge(value);
        var apt_id = me.page.getSelectedAirportID();
        var apt_info = me.getAirport(apt_id);
        me.page.updateAirportData(apt_info);
      }

      return emesary.Transmitter.ReceiptStatus_Finished;
    } else {
      return me.page.mfd.SurroundController.handleFMSOuter(value);
    }
  },
  handleEnter : func(value) {
    if (me._crsrToggle == 1) {
      if (me._currentGroup == NearestAirportsController.UIGROUP.APT) {
        # If the airport group is selected, the ENT key selects the next airport
        me.page.airportSelect.incrLarge(value);
        var apt_id = me.page.getSelectedAirportID();
        var apt_info = me.getAirport(apt_id);
        me.page.updateAirportData(apt_info);
        return emesary.Transmitter.ReceiptStatus_Finished;
      }

      if (me._currentGroup == NearestAirportsController.UIGROUP.RNWY) {
        # No effect if runways are selected
        return emesary.Transmitter.ReceiptStatus_Finished;
      }

      if (me._currentGroup == NearestAirportsController.UIGROUP.FREQ) {
        var freq = me.page.getSelectedFreq();
        if (freq != nil) {
          me.page.mfd.SurroundController.setStandbyNavComFreq(freq);
        }
        return emesary.Transmitter.ReceiptStatus_Finished;
      }

      if (me._currentGroup == NearestAirportsController.UIGROUP.APR) {
        # TODO Select the current Approach
        var appr = me.page.getSelectedApproach();
        if (appr != nil) print("NearestAirportController.handleEnter Approach selection " ~ appr);
      }
    } else {
      return emesary.Transmitter.ReceiptStatus_NotProcessed;
    }
  },

  handleRange : func(val)
  {
    # Pass any range entries to the NavMapController
    me.page.mfd.NavigationMap.getController().handleRange(val);
  },


  # Reset controller if required when the page is displayed or hidden
  ondisplay : func() {
    me._currentGroup = NearestAirportsController.UIGROUP.NONE;
    me.RegisterWithEmesary();
    me.getNearestAirports();
    me.page.mfd.NavigationMap.getController().enableDTO(1);
  },
  offdisplay : func() {
    me.page.mfd.NavigationMap.getController().enableDTO(0);
    me.DeRegisterWithEmesary();
  },

  getNearestAirports : func() {

    var notification = notifications.PFDEventNotification.new(
      "MFD",
      me.getDeviceID(),
      notifications.PFDEventNotification.NavData,
      {Id: "NearestAirports", Value: nil});

    var response = me._transmitter.NotifyAll(notification);

    if (! me._transmitter.IsFailed(response)) {
      me.page.updateAirports(notification.EventParameter.Value);
    } else {
      return nil;
    }
  },

  getAirport : func(id) {
    # Use Emesary to get the airport
    var notification = notifications.PFDEventNotification.new(
      "MFD",
      me.getDeviceID(),
      notifications.PFDEventNotification.NavData,
      {Id: "AirportByID", Value: id});

    var response = me._transmitter.NotifyAll(notification);

    if (! me._transmitter.IsFailed(response)) {
      var apt_list = notification.EventParameter.Value;
      if ((apt_list != nil) and (size(apt_list) > 0)) {
        return apt_list[0];
      } else {
        return nil;
      }
    } else {
      return nil;
    }
  },
};
