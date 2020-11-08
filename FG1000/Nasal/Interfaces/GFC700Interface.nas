# Copyright 2019 Stuart Buchanan
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
# Emesary interface to set autopilot configuration.
#

var GFC700Interface = {

new : func ()
{
  var obj = { parents : [ GFC700Interface ] };

  # Emesary
  obj._recipient = nil;
  obj._transmitter = emesary.GlobalTransmitter;
  obj._registered = 0;

  obj._vertical_mode = globals.props.getNode("/autopilot/annunciator/vertical-mode", 1);
  obj._pitch_setting = globals.props.getNode("/autopilot/settings/target-pitch-deg", 1);
  obj._climb_setting = globals.props.getNode("/autopilot/settings/vertical-speed-fpm", 1);
  obj._speed_setting = globals.props.getNode("/autopilot/settings/target-speed-kt", 1);

  # State variables
  obj._vertical_mode_button = globals.props.getNode("/autopilot/vertical-mode-button", 1);
  obj._lateral_mode_button = globals.props.getNode("/autopilot/lateral-mode-button", 1);
  obj._ap_mode_button = globals.props.getNode("/autopilot/AP-mode-button", 1);
  obj._ap_enabled = globals.props.getNode("/autopilot/annunciator/autopilot-enabled", 1);;
  obj._fd_enabled = globals.props.getNode("/autopilot/annunciator/flight-director-enabled", 1);;

  return obj;
},

# Under the covers there are 3 FSMs, two of which run in parallel, and need
# separate input channels.
sendModeChange : func(value) {
  me._vertical_mode_button.setValue(value);
  me._lateral_mode_button.setValue(value);
  if (value == "AP") {
    me._ap_mode_button.setValue("AP");
  }
  return emesary.Transmitter.ReceiptStatus_Finished;
},

handleNoseUpDown : func(value) {
  var vertical_mode = me._vertical_mode.getValue();

  if (vertical_mode == "PIT") {
    me._pitch_setting.setValue(me._pitch_setting.getValue() + (value * 1));
  }

  if (vertical_mode == "VS") {
    me._climb_setting.setValue(me._climb_setting.getValue() + (value * 100));
    setprop("/autopilot/annunciator/vertical-mode-target",
          sprintf("%+ifpm", me._climb_setting.getValue())
    );
  }

  if (vertical_mode == "FLC") {
    # Note that the button is NOSE UP / NOSE DN, so pressing NOSE DN _increases_
    # speed, while NOSE UP _decreases_ speed.  So the speed setting is reversed
    # in comparison with setting direct pitch.
    me._speed_setting.setValue(me._speed_setting.getValue() - (value * 1));
    setprop("/autopilot/annunciator/vertical-mode-target",
          sprintf("%i kt", me._speed_setting.getValue())
    );
  }

  return emesary.Transmitter.ReceiptStatus_Finished;
},

setAPNavSource : func(src) {
  setprop("/autopilot/settings/nav-mode-source", src);
  #  Also need to do something to trigger a NAV change if we're in NAV mode already.
  return emesary.Transmitter.ReceiptStatus_Finished;
},

RegisterWithEmesary : func()
{
  if (me._recipient == nil){
    me._recipient = emesary.Recipient.new("AutopilotInterface");
    var controller = me;

    # Note that unlike the various keys, this data isn't specific to a particular
    # Device - it's shared by all.  Hence we don't check for the notificaiton
    # Device_Id.
    me._recipient.Receive = func(notification)
    {

      if (notification.NotificationType == notifications.PFDEventNotification.DefaultType and
          notification.Event_Id == notifications.PFDEventNotification.HardKeyPushed and
          notification.EventParameter != nil)
      {
        var id = notification.EventParameter.Id;
        var value = notification.EventParameter.Value;

        if (id == fg1000.FASCIA.AP )   return controller.sendModeChange("AP");
        if (id == fg1000.FASCIA.HDG)   return controller.sendModeChange("HDG");
        if (id == fg1000.FASCIA.NAV)   return controller.sendModeChange("NAV");
        if (id == fg1000.FASCIA.APR)   return controller.sendModeChange("APR");
        if (id == fg1000.FASCIA.VS )   return controller.sendModeChange("VS");
        if (id == fg1000.FASCIA.FLC)   return controller.sendModeChange("FLC");
        if (id == fg1000.FASCIA.FD )   return controller.sendModeChange("FD");
        if (id == fg1000.FASCIA.ALT)   return controller.sendModeChange("ALT");
        if (id == fg1000.FASCIA.VNV)   return controller.sendModeChange("VNV");
        if (id == fg1000.FASCIA.BC )   controller.sendModeChange("BC");
        if (id == fg1000.FASCIA.NOSE_UP)   return controller.handleNoseUpDown(1);
        if (id == fg1000.FASCIA.NOSE_DOWN)   return controller.handleNoseUpDown(-1);
      }

      if (notification.NotificationType == notifications.PFDEventNotification.DefaultType and
          notification.Event_Id == notifications.PFDEventNotification.FMSData and
          notification.EventParameter != nil)
      {
        foreach(var key; keys(notification.EventParameter)) {
          var val = notification.EventParameter[key];
          if (key == "AutopilotNAVSource")  return controller.setAPNavSource(val);
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
