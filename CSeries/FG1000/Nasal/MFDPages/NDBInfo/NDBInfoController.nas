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
# NDBInfo Controller
var NDBInfoController =
{
  new : func (page, svg)
  {
    var obj = {
      parents : [ NDBInfoController, MFDPageController.new(page) ],
      _crsrToggle : 0,
      _recipient : nil,
      _page : page,
    };

    return obj;
  },

  # Input Handling
  handleCRSR : func() {
    me._crsrToggle = (! me._crsrToggle);
    if (me._crsrToggle) {
      me._page.dataEntry.highlightElement();
    } else {
      me._page.dataEntry.unhighlightElement();
    }
    return emesary.Transmitter.ReceiptStatus_Finished;
  },
  handleFMSInner : func(value) {
    if (me._crsrToggle == 1) {
      me._page.dataEntry.incrSmall(value);
      return emesary.Transmitter.ReceiptStatus_Finished;
    } else {
      return me._page.mfd.SurroundController.handleFMSInner(value);
    }
  },
  handleFMSOuter : func(value) {
    if (me._crsrToggle == 1) {
      me._page.dataEntry.incrLarge(value);
      return emesary.Transmitter.ReceiptStatus_Finished;
    } else {
      return me._page.mfd.SurroundController.handleFMSOuter(value);
    }
  },
  handleEnter : func(value) {
    if (me._crsrToggle == 1) {
      var id = me._page.dataEntry.enterElement();
      me.getNDB(id);
      return emesary.Transmitter.ReceiptStatus_Finished;
    } else {
      return emesary.Transmitter.ReceiptStatus_NotProcessed;
    }
  },
  handleClear : func(value) {
    if (me._crsrToggle == 1) {
      me._page.dataEntry.clearElement();
      return emesary.Transmitter.ReceiptStatus_Finished;
    } else {
      return emesary.Transmitter.ReceiptStatus_NotProcessed;
    }
  },
  handleRange : func(val)
  {
    # Pass any range entries to the NavMapController
    me._page.Map.handleRange(val);
  },

  # Retrieve intersection information for the provided id and display it.
  getNDB : func(id) {
    var navdata = nil;
    var aptdata = nil;

    # Use Emesary to get the intersection
    var notification = notifications.PFDEventNotification.new(
      "MFD",
      me.getDeviceID(),
      notifications.PFDEventNotification.NavData,
      {Id: "NavAidByID", Value: { id: id, type : "ndb" } } );

    var response = me._transmitter.NotifyAll(notification);
    var retval = notification.EventParameter.Value;

    if ((!me._transmitter.IsFailed(response)) and (size(retval) > 0)) {

      # Simply take the first value.  Should handle duplicates.
      navdata = retval[0];

      debug.dump(navdata);

      # Get the nearest Airport to the intersection
      var params = { lat: navdata.lat,
                     lon: navdata.lon,
                     type : "airport" };

      notification = notifications.PFDEventNotification.new(
        "MFD",
        me.getDeviceID(),
        notifications.PFDEventNotification.NavData,
        {Id: "NavDataWithinRange", Value: params });

      response = me._transmitter.NotifyAll(notification);
      retval = notification.EventParameter.Value;

      if ((!me._transmitter.IsFailed(response)) and (size(retval) > 0)) {
        var crsAndDst = courseAndDistance(navdata, retval[0]);
        aptdata = {};
        aptdata.id = retval[0].id;
        aptdata.crs = crsAndDst[0];
        aptdata.dst = crsAndDst[1];
      }
    }

    # Display the retrieved data.
    me._page.update(navdata, aptdata);
  },

  handleStringInput : func(value) {
    me._page.dataEntry.clearElement();
    me._page.dataEntry.setValue(value);
    me.getNDB(value);
    me._page.dataEntry.unhighlightElement();
    return emesary.Transmitter.ReceiptStatus_Finished;
  },

  # Reset controller if required when the page is displayed or hidden
  ondisplay : func() {
    me.RegisterWithEmesary();
    if (me._page.dataEntry.getValue() != "") me.getNDB(me._page.dataEntry.getValue());
  },
  offdisplay : func() {
    me.DeRegisterWithEmesary();
  },

};
