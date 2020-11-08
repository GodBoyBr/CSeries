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
# Generic class to update properties from Emesary for the MFD
#
# In the simplest cases where the Emesary EventParameter for the specified
# Event ID is a hash whose values can be mapped directly to property values,
# it can be used directly.  For more complex cases, the handleNotificationEvent
# method should be over-ridden, and should return
# emesary.Transmitter.ReceiptStatus_OK or equivalent ReceiptStatus value.

var PropertyUpdater =
{
  PropMap : {
    new : func(name, property)
    {
      var obj = { parents : [ PropertyUpdater.PropMap ] };
      obj._name = name;
      obj._prop = globals.props.getNode(property, 1);
      return obj;
    },

    getName  : func()    { return me._name; },
    getValue : func()    { return me._prop.getValue(); },
    setValue : func(val) { me._prop.setValue(val); },
  },

  new : func (notificationType, eventID) {
    var obj = {
      parents : [ PropertyUpdater ],
      _notificationType : notificationType,
      _eventID : eventID,
      _recipient : nil,
      _transmitter : nil,
      _registered : 0,
      _propmaps : {},
    };

    obj._transmitter = emesary.GlobalTransmitter;

    return obj;
  },

  addPropMap : func(name, prop) {
    me._propmaps[name] = PropertyUpdater.PropMap.new(name, prop);
  },

  handleNotificationEvent : func(eventParameters) {

    var retval = emesary.Transmitter.ReceiptStatus_NotProcessed;
    foreach(var name; keys(eventParameters)) {
      var value = eventParameters[name];
      if (me._propmaps[name] != nil) {
        if (me._propmaps[name].getValue() != value) {
          # Only update on a true change.  Otherwise if there is a Publisher
          # on this property, we risk creating a never ending loop between
          # the Publisher and this Updater
          me._propmaps[name].setValue(value);
        }
        retval = emesary.Transmitter.ReceiptStatus_OK;
      }
    }

    return retval;
  },

  RegisterWithEmesary : func(){

    if (me._recipient == nil){
      me._recipient = emesary.Recipient.new("PropertyUpdater");
      var notificationtype = me._notificationType;
      var eventID = me._eventID;
      var controller = me;
      # Note that we don't care about the device we receive the update from.
      me._recipient.Receive = func(notification)
      {
        if (notification.NotificationType == notificationtype and
            notification.Event_Id == eventID and
            notification.EventParameter != nil)
        {
            return controller.handleNotificationEvent(notification.EventParameter);
        }
        return emesary.Transmitter.ReceiptStatus_NotProcessed;
      };
    }
    me._transmitter.Register(me._recipient);
    me._registered = 1;
  },
  DeRegisterWithEmesary : func(transmitter = nil){
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
