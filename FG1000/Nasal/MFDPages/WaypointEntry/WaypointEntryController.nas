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
# WaypointEntry Controller
var WaypointEntryController =
{
  new : func (page, svg)
  {
    var obj = { parents : [ WaypointEntryController, MFDPageController.new(page)] };
    obj.id = "";
    obj.page = page;
    obj._wpentry_displayed = 0;
    obj._destination = nil;

    obj._cursorElements = [
      obj.page.IDEntry,
    ];

    obj._activateIndex = size(obj._cursorElements) - 1;

    obj._selectedElement = 0;

    # Whether the WaypointSubmenuGroup is enabled
    obj._waypointSubmenuVisible = 0;

    return obj;
  },

  setCursorElement : func(value) {

    for (var i = 0; i < size(me._cursorElements); i = i+1) {
      me._cursorElements[i].unhighlightElement();
    }

    if (value < 0) value = 0;
    if (value > (size(me._cursorElements) -1)) value = size(me._cursorElements) -1;
    me._selectedElement = value;
    me._cursorElements[me._selectedElement].highlightElement();
  },

  nextCursorElement : func(value) {
    var incr_or_decr = (value > 0) ? 1 : -1;
    me.setCursorElement(me._selectedElement + incr_or_decr);
  },

  handleCRSR : func() {
    if (! me._wpentry_displayed) return emesary.Transmitter.ReceiptStatus_NotProcessed;

    # No effect, but shouldn't be passed to underlying page?
    return emesary.Transmitter.ReceiptStatus_Finished;
  },
  updateWaypointSubmenu : func() {
    var type = me.page.WaypointSubmenuSelect.getValue();

    var items = [];

    if (type == "FPL") {
      # Get the contents of the flightplan and display the list of waypoints.
      var fp = me.getNavData("Flightplan");

      for (var i = 0; i < fp.getPlanSize(); i = i + 1) {
        var wp = fp.getWP(i);
        if (wp.wp_name != nil) append(items, wp.wp_name);
      }
    }

    if (type == "NRST") {
      # Get the nearest airports
      var apts = me.getNavData("NearestAirports");

      for (var i = 0; i < size(apts); i = i + 1) {
        var apt = apts[i];
        if (apt.id != nil) append(items, apt.id);
      }
    }

    if (type == "RECENT") {
      # Get the set of recent waypoints
      items = me.getNavData("RecentWaypoints");
    }

    if (type == "USER") {
      items = me.getNavData("UserWaypoints");
    }

    if (type == "AIRWAY") {
      var airways  = me.getNavData("AirwayWaypoints");
      if (airways != nil) {
        foreach (var wp; airways) {
          if (wp.wp_name != nil) append(items, wp.wp_name);
        }
      }
    }

    if ((items != nil) and (size(items) > 0)) {
      # At this point we have a vector of waypoint names. We need to convert
      # this into a vector of { "WaypointSubmenuScroll" : [name] } hashes for consumption by the
      # list of waypoints
      var groupitems = [];
      foreach (var item; items) {
        append(groupitems, { "WaypointSubmenuScroll" : item } );
      }

      # Now display them!
      me.page.WaypointSubmenuScroll.setValues(groupitems);
    } else {
      # Nothing to display
      me.page.WaypointSubmenuScroll.setValues([]);
    }
  },

  getNavData : func(type, value=nil) {
    # Use Emesary to get a piece from the NavData system, using the provided
    # type and value;
    var notification = notifications.PFDEventNotification.new(
      "MFD",
      me.getDeviceID(),
      notifications.PFDEventNotification.NavData,
      {Id: type, Value: value});

    var response = me._transmitter.NotifyAll(notification);

    if (! me._transmitter.IsFailed(response)) {
      return notification.EventParameter.Value;
    } else {
      return nil;
    }
  },

  setFMSData : func(type, value=nil) {
    # Use Emesary to set a piece of data in the NavData system, using the provided
    # type and value;
    var notification = notifications.PFDEventNotification.new(
      "MFD",
      me.getDeviceID(),
      notifications.PFDEventNotification.FMSData,
      {Id: type, Value: value});

    var response = me._transmitter.NotifyAll(notification);

    if (me._transmitter.IsFailed(response)) {
      print("WaypointEntryController.setNavData() : Failed to set Nav Data " ~ value);
      debug.dump(value);
    }
  },

  handleRange : func(val)
  {
    if (! me._wpentry_displayed) return emesary.Transmitter.ReceiptStatus_NotProcessed;

    if (me.page.WaypointEntryChart != nil) {
      return me.page.WaypointEntryChart.handleRange(val);
    } else {
      return emesary.Transmitter.ReceiptStatus_NotProcessed;
    }
  },

  handleFMSInner : func(value) {
    if (! me._wpentry_displayed) return emesary.Transmitter.ReceiptStatus_NotProcessed;

    if (me._waypointSubmenuVisible) {
      # We're in the Waypoint Submenu, in which case the inner FMS knob
      # selects between the different waypoint types.
      me.page.WaypointSubmenuSelect.highlightElement();
      me.page.WaypointSubmenuSelect.incrSmall(value);
      # Now update the Scroll group with the new type of waypoints
      me.updateWaypointSubmenu();
    } else if ((me._selectedElement == 0) and (! me.page.IDEntry.isInEdit()) and (value == -1)) {
      # The WaypointSubmenuGroup group is displayed if the small FMS knob is rotated
      # anti-clockwise as an initial rotation where the ID Entry is not being editted.
      me._cursorElements[0].unhighlightElement();

      me.page.WaypointSubmenuGroup.setVisible(1);
      me.page.WaypointSubmenuSelect.highlightElement();
      me._waypointSubmenuVisible = 1;
      me.updateWaypointSubmenu();
    } else {
      # We've already got something selected, and we're not in the
      # WaypointSubmenuGroup, so increment it.
      me._cursorElements[me._selectedElement].incrSmall(value);
    }

    return emesary.Transmitter.ReceiptStatus_Finished;
  },

  handleFMSOuter : func(value) {
    if (! me._wpentry_displayed) return emesary.Transmitter.ReceiptStatus_NotProcessed;

    if (me._waypointSubmenuVisible) {
      # We're in the Waypoint Submenu, in which case the outer FMS knob
      # selects between the different waypoints in the Waypoint Submenu.
      me.page.WaypointSubmenuSelect.unhighlightElement();
      me.page.WaypointSubmenuScroll.showCRSR();
      me.page.WaypointSubmenuScroll.incrLarge(value);
    } else if (me._cursorElements[me._selectedElement].isInEdit()) {
      # If we're editing an element, then get on with it!
      me._cursorElements[me._selectedElement].incrLarge(value);
    } else {
      me.nextCursorElement(value);
    }

    return emesary.Transmitter.ReceiptStatus_Finished;
  },

  handleEnter : func(value) {
    if (! me._wpentry_displayed) return emesary.Transmitter.ReceiptStatus_NotProcessed;

    if (me._waypointSubmenuVisible) {
      # If we're in the Waypoint Submenu, then take whatever is highlighted
      # in the scroll list, load it and hide the Waypoint submenu
      var id = me.page.WaypointSubmenuScroll.getValue();
      if (id != nil) me.loadDestination(id);
      me.page.WaypointSubmenuGroup.setVisible(0);
      me._waypointSubmenuVisible = 0;
    } else if (me.page.IDEntry.isInEdit()) {
      # If we're editing an element, complete the data entry, then load it.
      me.page.IDEntry.enterElement();
      me.loadDestination(me.page.IDEntry.getValue());
    } else {
      # Pass the entered waypoint to the surrounding page TODO
      me.setFMSData("SetWaypointEntry", me._destination);

      me._wpentry_displayed = 0;
      me.page.offdisplay();

      return emesary.Transmitter.ReceiptStatus_Finished;
    }

    return emesary.Transmitter.ReceiptStatus_Finished;
  },

  handleClear : func(value) {
    if (! me._wpentry_displayed) return emesary.Transmitter.ReceiptStatus_NotProcessed;

    if (me._waypointSubmenuVisible) {
      # If we're in the Waypoint Submenu, then this clears it.
      me.page.WaypointSubmenuGroup.setVisible(0);
      me._waypointSubmenuVisible = 0;
    } else if (me._cursorElements[me._selectedElement].isInEdit()) {
      me._cursorElements[me._selectedElement].clearElement();
    } else {
      # Cancel the entire Waypoint Entry page.
      me._wpentry_displayed = 0;
      me.page.offdisplay();
    }
    return emesary.Transmitter.ReceiptStatus_Finished;
  },

  handleStringInput : func(value) {
    if (! me._wpentry_displayed) return emesary.Transmitter.ReceiptStatus_NotProcessed;
    me.page.IDEntry.clearElement();
    me.page.IDEntry.setValue(value);
    me.loadDestination(me.page.IDEntry.getValue());
    return emesary.Transmitter.ReceiptStatus_Finished;
  },

  # Reset controller if required when the page is displayed or hidden
  # Note that we explicitly do NOT RegisterWithEmesary/DeRegisterWithEmesary!
  # This page should RegisterWithEmesary at start of day instead.
  ondisplay : func() {
    # On initial display we simply display a blank destination
    me._wpentry_displayed = 1;
    me.loadDestination(nil);
  },

  offdisplay : func() {
    me._wpentry_displayed = 0;
  },

  loadDestination : func(id) {
    if ((id == nil) or (id == "")) {
      me._destination = nil;
    } else {
      # Use Emesary to get the destination
      var notification = notifications.PFDEventNotification.new(
        "MFD",
        me.getDeviceID(),
        notifications.PFDEventNotification.NavData,
        {Id: "NavDataByID", Value: id});

      var response = me._transmitter.NotifyAll(notification);
      var retval = notification.EventParameter.Value;

      if ((! me._transmitter.IsFailed(response)) and (size(retval) > 0)) {
        var destination = retval[0];
        # set the course and distance to the destination if required

        # Some elements don't have names
        var name = destination.id;
        if (defined("destination.name")) name = destination.name;

        var point = { lat: destination.lat, lon: destination.lon };
        var (course, dist) = courseAndDistance(point);

        me._destination = {
          id: destination.id,
          name: name,
          lat: destination.lat,
          lon: destination.lon,
          course : course,
          range_nm : dist,
        };
      }
    }


    me.page.displayDestination(me._destination);
  },
};
