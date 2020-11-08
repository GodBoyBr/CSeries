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
# NearestAirportsPFD Controller
var NearestAirportsPFDController =
{
  MODE : {
    NONE    : 0, # Nothing displayed
    NEAREST : 1, # Nearest Airports pane visible
    INFO    : 2, # Airport Info pane visible
  },

  new : func (page, svg)
  {
    var obj = { parents : [ NearestAirportsPFDController, MFDPageController.new(page) ] };

    # Current active UI group.
    obj.page = page;
    obj._mode = NearestAirportsPFDController.MODE.NONE;
    obj._crsrToggle = 0;
    return obj;
  },

  selectNearest : func() {
    me.selectGroup(NearestAirportsPFDController.MODE.NEAREST)
  },
  selectInfo : func() {
    me.selectGroup(NearestAirportsPFDController.MODE.INFO);
  },
  selectNone : func() {
    me.selectGroup(NearestAirportsPFDController.MODE.NONE);
  },
  getSelectedMode : func() {
    return me._mode;
  },
  selectGroup : func(grp) {
    me._mode = grp;
    if (grp == NearestAirportsPFDController.MODE.NONE) {
      me.page.offdisplay();
    }
    if (grp == NearestAirportsPFDController.MODE.NEAREST) {
      me.page.displayNearest();
    }
    if (grp == NearestAirportsPFDController.MODE.INFO) {
      var aptdata = me.getAirport(me.page.getSelectedAirportID());
      me.page.updateAirportData(aptdata);
      me.page.displayInfo();
    }
  },

  # Input Handling
  handleCRSR : func(value) {
    me._crsrToggle = (! me._crsrToggle);
    if (me._crsrToggle) {
      me.page.airportSelect.showCRSR();
    } else {
      # Hide the cursor and reset any highlighting
      me.page.airportSelect.hideCRSR();
    }
    return emesary.Transmitter.ReceiptStatus_Finished;
  },
  handleFMSInner : func(value) {
    if (me._crsrToggle and (me._mode == NearestAirportsPFDController.MODE.NEAREST)) {
      # Scroll through the nearest airports list
      me.page.airportSelect.incrSmall(value);
      return emesary.Transmitter.ReceiptStatus_Finished;
    } else {
      return emesary.Transmitter.ReceiptStatus_NotProcessed;
    }
  },
  handleFMSOuter : func(value) {
    return me.handleFMSInner(value);
  },
  handleEnter : func(value) {
    if (me._mode == NearestAirportsPFDController.MODE.NEAREST) {
      # Enable the cursor if it's not already enabled.
      me._crsrToggle = 1;
      me.page.airportSelect.showCRSR();

      # Load the current airport and display it
      if (me.page.getSelectedAirportID() != nil) {
        me.selectInfo();
      }
      return emesary.Transmitter.ReceiptStatus_Finished;
    } else if (me._mode == NearestAirportsPFDController.MODE.INFO) {
      # Pressing Enter on the Info window hides the info window and selects the
      # next airport on the list.
      # Load the current airport and display it
      me.selectNearest();
      me.page.airportSelect.incrSmall(1);
      return emesary.Transmitter.ReceiptStatus_Finished;
    } else {
      return emesary.Transmitter.ReceiptStatus_NotProcessed;
    }
  },
  handleClear : func(value) {
    if (me._mode == NearestAirportsPFDController.MODE.NEAREST) {
      # Finished - unload the page.
      me.page.offdisplay();
      return emesary.Transmitter.ReceiptStatus_Finished;
    } else if (me._mode == NearestAirportsPFDController.MODE.INFO) {
      # Pressing Clear on the Info window hides the info window and selects the
      # next airport on the list, just like Enter
      # Load the current airport and display it
      me.selectNearest();
      me.page.airportSelect.incrSmall(1);
      return emesary.Transmitter.ReceiptStatus_Finished;
    } else {
      return emesary.Transmitter.ReceiptStatus_NotProcessed;
    }
  },

  # Reset controller if required when the page is displayed or hidden
  ondisplay : func() {
    me.RegisterWithEmesary();
    me.getNearestAirportsPFD();
    me.selectNearest();
  },
  offdisplay : func() {
    me.DeRegisterWithEmesary();
  },

  getNearestAirportsPFD : func() {
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
