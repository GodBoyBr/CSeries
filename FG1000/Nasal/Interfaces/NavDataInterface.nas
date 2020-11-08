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
#
# Emesary interface to access nav data such as airport information, fixes etc.
#

var NavDataInterface = {

# Valid FMS Modes

FMS_MODES : {
  direct : 1,
  leg : 1,
  obs : 1,
},

new : func ()
{
  var obj = { parents : [ NavDataInterface ] };

  # Emesary
  obj._recipient = nil;
  obj._transmitter = emesary.GlobalTransmitter;
  obj._registered = 0;
  obj._defaultDTO = "";

  # List of recently use waypoints
  obj._recentWaypoints = std.Vector.new();

  # Some methods are really slow the first time they are called, typically
  # because they are populating some cached database.  Call them now to reduce
  # freezes in flight.
  var apts = obj.getNearestAirports();
  var navdata = obj.getNavDataWithinRange({type : "VOR"});
  return obj;
},

# Find the airports within 200nm and return them.
getNearestAirports : func()
{
  # To make this more efficient for areas with a high density of airports, we'll try
  # a small radius first and expand until we have reached 200nm or have 25 airports.
  var radius = 0;
  var apts = [];

  while ((radius <= 200) and (size(apts) < 25)) {
    radius = radius + 50;
    apts = findAirportsWithinRange(radius);
  }

  if (size(apts) > 25) {
    apts = subvec(apts, 0, 25);
  }

  return apts;
},

# Find the nearest nav aids of a given type within 200nm, to a maximum of 25.
getNavDataWithinRange: func(params)
{
  # To make this more efficient for areas with a high density of fixes, we'll try
  # a small radius first and expand until we have reached 200nm or have 25 nav aids.
  var radius = 0;
  var navdata = [];

  while ((radius <= 200) and (size(navdata) < 25)) {
    radius = radius + 50;
    if ((params["lat"] == nil) and (params["lon"] == nil)) {
      navdata = findNavaidsWithinRange(radius, params.type);
    } else {
      navdata = findNavaidsWithinRange(params.lat, params.lon, radius, params.type);
    }
  }

  if (size(navdata) > 25) {
    navdata = subvec(navdata, 0, 25);
  }

  return navdata;
},

# Find a specific airport by ID.  Return an array of airport objects
getAirportById : func(id)
{
  var apt = findAirportsByICAO(id, "airport");

  if ((apt != nil) and (! me._recentWaypoints.contains(id))) {
    me._recentWaypoints.insert(0, id);
  }

  return apt;
},

# Find an arbritrary piece of nav data by ID.  This searches based on the
# current location and returns an array of objects that match the id.
getNavDataById : func (id)
{
  # Check for airport first
  var navdata = findAirportsByICAO(id, "airport");

  # Check for Navaids.
  if (size(navdata) == 0) navdata = findNavaidsByID(id);

  # Check for fix.
  if (size(navdata) == 0) navdata = findFixesByID(id);

  # Check for a pseudo-fix in the flightplan
  if (size(navdata) == 0) {
    var fp = flightplan();
    if (fp != nil) {
      for (var i = 0; i < fp.getPlanSize(); i = i +1) {
        var wp = fp.getWP(i);
        if (wp.wp_name == id) {
          append(navdata, wp);
        }
      }
    }
  }

  if ((size(navdata) > 0) and (! me._recentWaypoints.contains(id))) {
    me._recentWaypoints.insert(0, id);
  }

  return navdata;
},

# Find a Nav Aid by ID.  This searches based on the
# current location and returns an array of objects that match the id.
getNavAidById : func (params)
{
  var id = params.id;
  var type = "all";
  if (params.type != nil) type = params.type;

  var navdata = findNavaidsByID(id, type);
  if ((size(navdata) > 0) and (! me._recentWaypoints.contains(id))) {
    me._recentWaypoints.insert(0, id);
  }
  return navdata;
},

# Retrieve the current flightplan and return it
getFlightplan : func ()
{
  return flightplan();
},

# Retrieve the checklists for this aircraft.
getChecklists : func()
{
  var checklists = {};
  var checklistprops = props.globals.getNode("/sim/checklists");

  if (checklistprops == nil) return nil;

  var groups = checklistprops.getChildren("group");

  if (size(groups) > 0) {
    foreach (var group; groups) {
      var grp = group.getNode("name", 1).getValue();
      checklists[grp] = {};
      foreach (var chklist; group.getChildren("checklist")) {
        var items = [];
        var title = chklist.getNode("title", 1).getValue();

        # Checklists can optionally be broken down into individual pages.
        foreach (var pg; chklist.getChildren("page")) {
          foreach (var item; pg.getChildren("item")) {
            var name = item.getNode("name", 1).getValue();
            var value = item.getNode("value", 1).getValue();
            append(items, { Name : name, Value: value, Checked: 0  });
          }
        }

        foreach (var item; chklist.getChildren("item")) {
          var name = item.getNode("name", 1).getValue();
          var value = item.getNode("value", 1).getValue();
          append(items, { Name : name, Value: value, Checked: 0 });
        }

        # items now contains a list of all the checklists for
        checklists[grp][title] = items;
      }
    }
  } else {
    # Checklist doesn't contain any groups, so try to split into Standard
    # and Emergency groups by looking at the checklist titles.

    foreach (var chklist; checklistprops.getChildren("checklist")) {
      var title = chklist.getNode("title", 1).getValue();
      var grp = "Standard";
      var items = [];
      if (find("emergency", string.lc(title)) != -1) {
        grp = "EMERGENCY";
      }

      # Checklists can optionally be broken down into individual pages.
      foreach (var pg; chklist.getChildren("page")) {
        foreach (var item; pg.getChildren("item")) {
          var name = item.getNode("name", 1).getValue();
          var value = item.getNode("value", 1).getValue();
          append(items, { Name : name, Value: value, Checked: 0  });
        }
      }

      foreach (var item; chklist.getChildren("item")) {
        var name = item.getNode("name", 1).getValue();
        var value = item.getNode("value", 1).getValue();
        append(items, { Name : name, Value: value, Checked: 0 });
      }

      # items now contains a list of all the checklists for
      checklists[grp][title] = items;
    }
  }

  return checklists;
},

insertWaypoint : func (data)
{
  assert(data["index"] != nil, "InsertWaypoint message with no index parameter");
  assert(data["wp"] != nil, "InsertWaypoint message with no wp parameter");

  var wp = data["wp"];
  var idx = int(data["index"]);

  # Simple data verification that we have the parameters we need
  assert(idx != nil, "InsertWaypoint index parameter does not contain an integer index");
  assert(wp.id != nil, "InsertWaypoint wp parameter does not contain an id");
  assert(wp.lat != nil, "InsertWaypoint wp parameter does not contain a lat");
  assert(wp.lon != nil, "InsertWaypoint wp parameter does not contain an lon");

  var newwp = createWP(wp.lat, wp.lon, wp.id);

  var fp = flightplan();
  fp.insertWP(newwp, idx);

  # Set a suitable name.
  if ((fp.id == nil) or (fp.id == "default-flightplan")) {
    var from = "????";
    var dest = "????";

    if ((fp.getWP(0) != nil) and (fp.getWP(0).wp_name != nil)) {
      from = fp.getWP(0).wp_name;
    }

    if ((fp.getWP(fp.getPlanSize() -1) != nil) and (fp.getWP(fp.getPlanSize() -1).wp_name != nil)) {
      dest = fp.getWP(fp.getPlanSize() -1).wp_name;
    }

    if (fp.departure   != nil) from = fp.departure.id;
    if (fp.destination != nil) dest = fp.destination.id;
    fp.id == from ~ " / " ~ dest;
  }

  # Activate flightplan
  if (fp.getPlanSize() == 2) fgcommand("activate-flightplan", props.Node.new({"activate": 1}));
},

# Retrieve the Airway waypoints on the current leg.
getAirwayWaypoints : func() {
  var fp = flightplan();
  if (fp != nil) {
    var current_wp = fp.currentWP();
    if ((current_wp != nil) and (fp.indexOfWP(current_wp) > 0)) {
      var last_wp = fp.getWP(fp.indexOfWP(current_wp) -1);
      return airwaysRoute(last_wp, current_wp);
    }
  }
  return nil;
},

# Return the recently seen waypoints, collected from previous calls to
# other nav data functions
getRecentWaypoints : func()
{
  return me._recentWaypoints.vector;
},

# Add an ID to the list of recent waypoints
addRecentWaypoint : func(id)
{
  if ((id != nil) and (! me._recentWaypoints.contains(id))) {
    me._recentWaypoints.insert(0, id);
  }
},

# Return the array of user waypoints.  TODO
getUserWaypoints : func()
{
  return [];
},

# Set up a DirectTo a given ID, with optional VNAV altitude offset.
setDirectTo : func(param)
{
  var id = param.id;
  var alt_ft = param.alt_ft;
  var offset_nm = param.offset_nm;

  var fp = flightplan();
  var wp_idx = -1;

  if (fp != nil) {
    # We've already got a flightplan, so see if this WP already exists.

    for (var i = 0; i < fp.getPlanSize(); i = i + 1) {
      var wp = fp.getWP(i);
      if ((wp.wp_name != nil) and (wp.wp_name == id)) {
        # OK, we're assuming that if the names actually match, then
        # they refer to the same ID.  So direct to that index.
        wp_idx = i;
        break;
      }
    }
  }

  if (wp_idx != -1) {
    # Found the waypoint in the plan, so use that as the DTO.
    var wp = fp.getWP(wp_idx);
    setprop("/instrumentation/gps/scratch/ident", wp.wp_name);
    setprop("/instrumentation/gps/scratch/altitude-ft", 0);
    setprop("/instrumentation/gps/scratch/latitude-deg", wp.lat);
    setprop("/instrumentation/gps/scratch/longitude-deg", wp.lon);
  } else {
    # No flightplan, or waypoint not found, so use the GPS DTO function.
    # Hokey property-based interface.
    setprop("/instrumentation/gps/scratch/ident", id);
    setprop("/instrumentation/gps/scratch/altitude-ft", alt_ft);
    setprop("/instrumentation/gps/scratch/latitude-deg", getprop("/position/latitude-deg"));
    setprop("/instrumentation/gps/scratch/longitude-deg", getprop("/position/longitude-deg"));
  }

  # Switch the GPS to DTO mode.
  setprop("/instrumentation/gps/command", "direct");
},

setFMSMode : func(mode) {
  if (NavDataInterface.FMS_MODES[mode] != nil) {
    # mode is valid, so simply set it as the GPS command
    setprop("/instrumentation/gps/command", mode);
  } else {
    die("Invalid FMS Mode " ~ mode);
  }
},

# Return the current DTO location to use
getCurrentDTO : func()
{
  return me._defaultDTO;
},

# Set the current DTO location to use
setDefaultDTO : func(id)
{
  me._defaultDTO = id;
},


# Find the nearest Air Route Traffic Control Center or equivalent.
# As we don't have that data right now, we simply return some placeholder
getNearestATRCC : func()
{
  var atrcc = {};
  atrcc.name = "NONE AVAILABLE";
  atrcc.lat = 0;
  atrcc.lon = 0;
  atrcc.brg = nil;
  atrcc.dis = nil;
  atrcc.freqs = [];  # an array of frequencies for the ATRCC
  return atrcc;
},

# Find the nearest Flight Service Station
# As we don't have that data right now, we simply return some placeholder
getNearestFSS : func()
{
  var fss = {};
  fss.name = "NONE AVAILABLE";
  fss.lat = nil;
  fss.lon = nil;
  fss.brg = nil;
  fss.dis = nil;
  fss.freqs = [];  # an array of frequencies for the ATRCC
  return fss;
},

# Find the nearest weather information.  We do this simply by picking up
# appropriate frequencies from the airports frequencies within 200nm.
getNearestWX : func()
{
  # To make this more efficient for areas with a high density of airports, we'll try
  # a small radius first and expand until we have reached 200nm or have 25 frequencies.
  var radius = 0;
  var freqs = [];

  while ((radius <= 200) and (size(freqs) < 25)) {
    freqs = [];
    radius = radius + 50;
    apts = findAirportsWithinRange(radius);
    foreach (var apt; apts) {
      var apt_comms = apt.comms();
      if (size(apt_comms) > 0) {
        # Airport has one or more frequencies assigned to it.
        foreach (var c; apt_comms) {
          if ((c.ident == "ATIS") or (c.ident == "ASOS")) {
            var freq = {
              id: apt.id,
              type : c.ident,
              freq: c.frequency,
              lat : apt.lat,
              lon : apt.lon,
            };

            append(freqs, freq);
          }
        }
      }
    }
  }

  return freqs;
},

RegisterWithEmesary : func()
{
  if (me._recipient == nil){
    me._recipient = emesary.Recipient.new("DataInterface");
    var controller = me;

    # Note that unlike the various keys, this data isn't specific to a particular
    # Device - it's shared by all.  Hence we don't check for the notificaiton
    # Device_Id.
    me._recipient.Receive = func(notification)
    {
      if (notification.NotificationType == notifications.PFDEventNotification.DefaultType and
          notification.Event_Id == notifications.PFDEventNotification.NavData and
          notification.EventParameter != nil)
      {
        var id = notification.EventParameter.Id;

        if (id == "NearestAirports") {
          notification.EventParameter.Value = controller.getNearestAirports();
          return emesary.Transmitter.ReceiptStatus_Finished;
        }
        if (id == "AirportByID") {
          notification.EventParameter.Value = controller.getAirportById(notification.EventParameter.Value);
          return emesary.Transmitter.ReceiptStatus_Finished;
        }
        if (id == "NavDataByID") {
          notification.EventParameter.Value = controller.getNavDataById(notification.EventParameter.Value);
          return emesary.Transmitter.ReceiptStatus_Finished;
        }
        if (id == "NavAidByID") {
          notification.EventParameter.Value = controller.getNavAidById(notification.EventParameter.Value);
          return emesary.Transmitter.ReceiptStatus_Finished;
        }
        if (id == "NavDataWithinRange") {
          notification.EventParameter.Value = controller.getNavDataWithinRange(notification.EventParameter.Value);
          return emesary.Transmitter.ReceiptStatus_Finished;
        }
        if (id == "Flightplan") {
          notification.EventParameter.Value = controller.getFlightplan();
          return emesary.Transmitter.ReceiptStatus_Finished;
        }
        if (id == "RecentWaypoints") {
          notification.EventParameter.Value = controller.getRecentWaypoints();
          return emesary.Transmitter.ReceiptStatus_Finished;
        }
        if (id == "AddRecentWaypoint") {
          controller.addRecentWaypoint(notification.EventParameter.Value);
          return emesary.Transmitter.ReceiptStatus_Finished;
        }
        if (id == "AirwayWaypoints") {
          notification.EventParameter.Value = controller.getAirwayWaypoints();
          return emesary.Transmitter.ReceiptStatus_Finished;
        }
        if (id == "UserWaypoints") {
          notification.EventParameter.Value = controller.getUserWaypoints();
          return emesary.Transmitter.ReceiptStatus_Finished;
        }
        if (id == "CurrentDTO") {
          notification.EventParameter.Value = controller.getCurrentDTO();
          return emesary.Transmitter.ReceiptStatus_Finished;
        }
        if (id == "SetDirectTo") {
          controller.setDirectTo(notification.EventParameter.Value);
          return emesary.Transmitter.ReceiptStatus_Finished;
        }
        if (id == "SetDefaultDTO") {
          controller.setDefaultDTO(notification.EventParameter.Value);
          return emesary.Transmitter.ReceiptStatus_Finished;
        }
        if (id == "SetFMSMode") {
          controller.setFMSMode(notification.EventParameter.Value);
          return emesary.Transmitter.ReceiptStatus_Finished;
        }
        if (id == "InsertWaypoint") {
          controller.insertWaypoint(notification.EventParameter.Value);
          return emesary.Transmitter.ReceiptStatus_Finished;
        }
        if (id == "GetChecklists") {
          notification.EventParameter.Value = controller.getChecklists();
          return emesary.Transmitter.ReceiptStatus_Finished;
        }
        if (id == "GetNearestATRCC") {
          notification.EventParameter.Value = controller.getNearestATRCC();
          return emesary.Transmitter.ReceiptStatus_Finished;
        }
        if (id == "GetNearestFSS") {
          notification.EventParameter.Value = controller.getNearestFSS();
          return emesary.Transmitter.ReceiptStatus_Finished;
        }
        if (id == "GetNearestWX") {
          notification.EventParameter.Value = controller.getNearestWX();
          return emesary.Transmitter.ReceiptStatus_Finished;
        }
      }
      return emesary.Transmitter.ReceiptStatus_NotProcessed;
    };
  }

  me._transmitter.Register(me._recipient);
  me._registered = 1;
},

DeRegisterWithEmesary : func()
{
  # remove registration from transmitter; but keep the recipient once it is created.
  if (me._registered == 1) me._transmitter.DeRegister(me._recipient);
  me._registered = 0;
},


start : func() {
  me.RegisterWithEmesary();
},
stop : func() {
  me.DeRegisterWithEmesary();
},

};
