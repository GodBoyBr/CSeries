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
# Generic PropertyPublisher classes for the FG1000 MFD using Emesary
# Publishes property values to Emesary for consumption by the MFD
#
#  Two variants:
#  - PeriodicPropertyPublisher which publishes on a periodic basis
#  - TriggeredPropertyPublisher which publishes based on listening to properties
#    but also publishes all properties on a periodic basis to ensure new clients
#    receive property state.
#

var PropMap = {
  new : func(name, property)
  {
    var obj = { parents : [ PropMap ] };
    obj._name = name;
    obj._prop = globals.props.getNode(property, 1);
    return obj;
  },

  getName : func() { return me._name; },
  getPropPath : func() { return me._prop.getPath(); },
  getValue : func() {
    var val = me._prop.getValue();
    if (val == nil) val = 0;
    return val;
  },
  getProp: func() { return me._prop; },
};

var PeriodicPropertyPublisher =
{
  new : func (notification, period=0.25) {
    var obj = {
      parents : [ PeriodicPropertyPublisher ],
      _notification : notification,
      _period : period,
      _propmaps : [],
    };

    obj._transmitter = emesary.GlobalTransmitter;

    return obj;
  },

  addPropMap : func(name, prop) {
    append(me._propmaps, PropMap.new(name, prop));
  },

  publish : func() {
    var data = {};

    foreach (var propmap; me._propmaps) {
      var name = propmap.getName();
      data[name] = propmap.getValue();
    }

    var notification = notifications.PFDEventNotification.new(
      "MFD",
      1,
      me._notification,
      data);

    me._transmitter.NotifyAll(notification);
  },

  start : func() {
    me._timer = maketimer(me._period, me, me.publish);
    me._timer.start();
  },
  stop : func() {
    if(me._timer != nil) me._timer.stop();
    me._timer = nil;
  },
};

var TriggeredPropertyPublisher =
{
  new : func (notification, period=5) {
    var obj = {
      parents : [ TriggeredPropertyPublisher ],
      _notification : notification,
      _period : period,
      _propmaps : {},
      _listeners : [],
      _timer: nil,
    };

    obj._transmitter = emesary.GlobalTransmitter;

    return obj;
  },

  addPropMap : func(name, prop) {
    me._propmaps[prop] = name;
  },

  publish : func(propNode) {
    var data = {};
    var name = me._propmaps[propNode.getPath()];
    assert(name != nil, "Unable to find property map for " ~ name);
    data[name] = propNode.getValue();

    var notification = notifications.PFDEventNotification.new(
      "MFD",
      1,
      me._notification,
      data);

    me._transmitter.NotifyAll(notification);
  },

  publishAll : func() {
    var data = {};

    foreach (var prop; keys(me._propmaps)) {
      var name = me._propmaps[prop];
      var value = props.globals.getNode(prop, 1).getValue();
      data[name] = value;
    }

    var notification = notifications.PFDEventNotification.new(
      "MFD",
      1,
      me._notification,
      data);

    me._transmitter.NotifyAll(notification);
  },


  start : func() {
    foreach (var prop; keys(me._propmaps)) {
      # Set up a listener triggering on create (to ensure all values are set at
      # start of day) and only on changed values.  These are the last two
      # arguments to the setlistener call.
      var listener = setlistener(prop, func(p) { me.publish(p); }, 1, 1);
      append(me._listeners, listener);
    }

    me._timer = maketimer(me._period, me, me.publishAll);
    me._timer.start();
  },

  stop : func() {
    foreach (var l; me._listeners) {
      # In some circumstances we may not have a valid listener ID, so we
      # just ignore the problem.
      var err = [];
      call( func removelistener(l), nil, err);
      if (size(err)) print("Ignoring error : " ~ err[0]);
    }

    if(me._timer != nil) me._timer.stop();
    me._timer = nil;
  },
};
