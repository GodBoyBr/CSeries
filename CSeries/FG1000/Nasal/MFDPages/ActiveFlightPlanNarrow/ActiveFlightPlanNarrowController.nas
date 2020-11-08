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
# ActiveFlightPlanNarrow Controller
var ActiveFlightPlanNarrowController =
{
  new : func (page, svg)
  {
    var obj = {
      parents : [ ActiveFlightPlanNarrowController, MFDPageController.new(page) ],
      _crsrToggle : 0,
      _recipient : nil,
      _page : page,
      _fp_current_wp : 0,
      _fp_active : 0,
      _current_flightplan : nil,
      _fprecipient : nil,
      transmitter : nil,
      _waypointSubmenuVisible : 0,
    };

    obj._current_flightplan = obj.getNavData("Flightplan");
    if (obj._current_flightplan != nil) {
      obj._fp_current_wp = obj._current_flightplan.current;
      obj._page.setFlightPlan(obj._current_flightplan, obj._fp_current_wp);
    } else {
      obj._page.setFlightPlan(nil, nil);
    }

    return obj;
  },

  # Input Handling
  handleCRSR : func() {
    me._crsrToggle = (! me._crsrToggle);
    if (me._crsrToggle) {
      me._page.flightplanList.showCRSR();
    } else {
      me._page.flightplanList.hideCRSR();
    }
    return emesary.Transmitter.ReceiptStatus_Finished;
  },
  handleFMSInner : func(value) {
    if (me._crsrToggle == 1) {
      # Enable the WaypointEntry window
      me._page.mfd._WaypointEntry.ondisplay();

      # Also directly pass in the message.  This is because the WaypointEntry page
      # is above this in the Emesary stack, and as it was not displayed, it won't
      # have picked up the message to display either an entry box or the submenu.
      me._page.mfd._WaypointEntry.getController().handleFMSInner(value);
      return emesary.Transmitter.ReceiptStatus_Finished;
    } else {
      # Pass to the page group controller to display and scroll through the page group menu
      return me._page.mfd.SurroundController.handleFMSInner(value);
    }
  },
  handleFMSOuter : func(value) {
    if (me._crsrToggle == 1) {
      me._page.flightplanList.incrLarge(value);
      return emesary.Transmitter.ReceiptStatus_Finished;
    } else {
      # Pass to the page group controller to display and scroll through the page group menu
      return me._page.mfd.SurroundController.handleFMSOuter(value);
    }
  },
  handleEnter : func(value) {
    if (me._crsrToggle == 1) {
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

  # Handle the user entry of a waypoint. We now need to insert it into the
  # flightplan at the point after the selected waypoint, then update the
  # flightplan.  This should cause a cascade of Emesary updates, which will
  # subsequently update this display (and any others).
  handleWaypointEntry : func(data) {
    assert(data.id != nil, "handleWaypointEntry called with invalid hash");
    # Place this after the current index
    var params  = {
      index : me._page.flightplanList.getCRSR() + 1,
      wp : data
    };

    # Update the FMS with the new flightplan via Emesary
    var notification = notifications.PFDEventNotification.new(
      "MFD",
      me.getDeviceID(),
      notifications.PFDEventNotification.NavData,
      {Id: "InsertWaypoint", Value: params});

    var response = me._transmitter.NotifyAll(notification);

    if (me._transmitter.IsFailed(response)) {
      print("ActiveFlightPlanNarrowController.handleWaypointEntry() : Failed to set FMS Data " ~ params);
      debug.dump(params);
    } else {
      # The flightplan has changed.  For some reason this isn't triggering an
      # update from the flightplan delegate, so we'll just trigger an update
      # ourselves.
      var notification = notifications.PFDEventNotification.new(
        "MFD",
        1,
        notifications.PFDEventNotification.FMSData,
        {"FMSFlightPlanEdited" : 1});

      var response = me._transmitter.NotifyAll(notification);

      if (me._transmitter.IsFailed(response)) {
        print("ActiveFlightPlanNarrowController.handleWaypointEntry() : Failed to set FMS Data " ~ params);
        debug.dump(params);
      }
    }

    # Critically, only this page should handle the waypoint entry.
    return emesary.Transmitter.ReceiptStatus_Finished;
  },

  # Handle update to the FMS information.  Note that there is no guarantee
  # that the entire set of FMS data will be available.
  handleFMSData : func(data) {
    var update_fp = 0;
    var reload_fp = 0;

    if (data["FMSLegID"] != nil) me._leg_id = data["FMSLegID"];

    if ((data["FMSFlightPlanSequenced"] != nil) and (data["FMSFlightPlanSequenced"] !=  me._fp_current_wp)) {
      me._fp_current_wp = data["FMSFlightPlanSequenced"];
      update_fp = 1;
    }

    if (data["FMSFlightPlanEdited"] != nil) {
      reload_fp = 1;
    }

    if ((data["FMSFlightPlanActive"] != nil) and (data["FMSFlightPlanActive"] != me._fp_active)) {
      me._fp_active = data["FMSFlightPlanActive"];
      if (me._fp_active) {
        reload_fp = 1;
      } else {
        # No flightplan active, so we will display nothing.
        me._current_flightplan = nil;
        me._fp_current_wp = -1;
        update_fp = 1;
      }
    }

    if ((data["FMSFlightPlanCurrentWP"] != nil) and (data["FMSFlightPlanCurrentWP"] !=  me._fp_current_wp)) {
      me._fp_current_wp = data["FMSFlightPlanCurrentWP"];
      update_fp = 1;
    }

    if (reload_fp) {
      # The flightplan has changed in some way, so reload it.
      me._current_flightplan = me.getNavData("Flightplan");
      if (me._current_flightplan != nil) {
        me._fp_current_wp = me._current_flightplan.current;
        update_fp = 1;
      }
    }

    if (update_fp) {
      #me._current_flightplan = me.getNavData("Flightplan");
      me._page.setFlightPlan(me._current_flightplan, me._fp_current_wp);
    }

    return emesary.Transmitter.ReceiptStatus_OK;
  },

  # Reset controller if required when the page is displayed or hidden
  ondisplay : func() {
    me.RegisterWithEmesary();
    me.FPRegisterWithEmesary();
  },
  offdisplay : func() {
    me.DeRegisterWithEmesary();
    me.FPDeRegisterWithEmesary();
  },

  FPRegisterWithEmesary : func(transmitter = nil){
    if (transmitter == nil)
      transmitter = emesary.GlobalTransmitter;

    if (me._fprecipient == nil){
      me._fprecipient = emesary.Recipient.new("ActiveFlightPlanNarrowController_" ~ me._page.device.designation);
      var pfd_obj = me._page.device;
      var controller = me;
      me._fprecipient.Receive = func(notification)
      {

        if (notification.Device_Id == pfd_obj.device_id and
            notification.NotificationType == notifications.PFDEventNotification.DefaultType and
            notification.Event_Id == notifications.PFDEventNotification.FMSData and
            notification.EventParameter != nil and
            notification.EventParameter["Id"] == "SetWaypointEntry")
        {
          # Special case where THIS DEVICE has displayed the WaypointEntry page and
          # we are now receiving the entered waypoint.  In this case we need to
          # determine where to enter it in the flightplan and update it.
          return controller.handleWaypointEntry(notification.EventParameter.Value);
        }

        if (notification.NotificationType == notifications.PFDEventNotification.DefaultType and
            notification.Event_Id == notifications.PFDEventNotification.FMSData and
            notification.EventParameter != nil)
        {
          return controller.handleFMSData(notification.EventParameter);
        }

        return emesary.Transmitter.ReceiptStatus_NotProcessed;
      };
    }
    transmitter.Register(me._fprecipient);
    me.transmitter = transmitter;
  },
  FPDeRegisterWithEmesary : func(transmitter = nil){
      # remove registration from transmitter; but keep the recipient once it is created.
      if (me.transmitter != nil)
        me.transmitter.DeRegister(me._fprecipient);
      me.transmitter = nil;
  },

  getNavData : func(type, value=nil) {
    # Use Emesary to get a piece from the NavData system, using the provided
    # type and value;
    var notification = notifications.PFDEventNotification.new(
      "MFD",
      me._page.mfd.getDeviceID(),
      notifications.PFDEventNotification.NavData,
      {Id: type, Value: value});

    var response = me._transmitter.NotifyAll(notification);

    if (! me._transmitter.IsFailed(response)) {
      return notification.EventParameter.Value;
    } else {
      return nil;
    }
  },
};
