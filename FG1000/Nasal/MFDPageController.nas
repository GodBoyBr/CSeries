## Copyright 2018 Stuart Buchanan
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
# Standard MFDPage Controller
#
# This should be extended by specific page controllers and the handle...()
# methods over-ridden to provide specific functions for the MFD buttons.

var MFDPageController = {

new : func (page)
{
  var obj = { parents : [ MFDPageController ] };

  # Emesary
  obj._recipient = nil;
  obj._page = page;
  obj._transmitter = emesary.GlobalTransmitter;
  obj._registered = 0;
  return obj;
},

# Default handlers for all the Fascia hardkeys.  These should be over-ridden
# as required by specific page function.

#
handleNavVol          : func (value) { return me.page.mfd.SurroundController.handleNavVol(value); },
handleNavID           : func (value) { return me.page.mfd.SurroundController.handleNavID(value); },
handleNavFreqTransfer : func (value) { return me.page.mfd.SurroundController.handleNavFreqTransfer(value); },
handleNavOuter        : func (value) { return me.page.mfd.SurroundController.handleNavOuter(value); },
handleNavInner        : func (value) { return me.page.mfd.SurroundController.handleNavInner(value); },
handleNavToggle       : func (value) { return me.page.mfd.SurroundController.handleNavToggle(value); },
handleHeading         : func (value) { return me.page.mfd.SurroundController.handleHeading(value); },
handleHeadingPress    : func (value) { return me.page.mfd.SurroundController.handleHeadingPress(value); },

# Joystick
handleRange              : func (value) { return emesary.Transmitter.ReceiptStatus_NotProcessed; },
handleJoystickHorizontal : func (value) { return emesary.Transmitter.ReceiptStatus_NotProcessed; },
handleJoystickHorizontal : func (value) { return emesary.Transmitter.ReceiptStatus_NotProcessed; },

#CRS/BARO
handleBaro      : func (value) { return me.page.mfd.SurroundController.handleBaro(value); },
handleCRS       : func (value) { return me.page.mfd.SurroundController.handleCRS(value);  },
handleCRSCenter : func (value) { return me.page.mfd.SurroundController.handleCRSCenter(value); },

handleComOuter  : func (value) { return me.page.mfd.SurroundController.handleComOuter(value); },
handleComInner  : func (value) { return me.page.mfd.SurroundController.handleComInner(value); },
handleComToggle : func (value) { return me.page.mfd.SurroundController.handleComToggle(value); },

handleComFreqTransfer     : func (value) { return me.page.mfd.SurroundController.handleComFreqTransfer(value); },
handleComFreqTransferHold : func (value) { return me.page.mfd.SurroundController.handleComFreqTransferHold(value); }, # Auto-tunes to 121.2 when pressed for 2 seconds

handleComVol       : func (value) { return me.page.mfd.SurroundController.handleComVol(value); },
handleComVolToggle : func (value) { return me.page.mfd.SurroundController.handleComVolToggle(value); },

handleDTO       : func (value) { return emesary.Transmitter.ReceiptStatus_NotProcessed; },


handleFPL       : func (value) {
  var fppage = me._page.getMFD().getPage("ActiveFlightPlanNarrow");
  if (fppage != nil) {
    me._page.getDevice().selectPage(fppage);
    return emesary.Transmitter.ReceiptStatus_Finished;
  } else {
    return emesary.Transmitter.ReceiptStatus_NotProcessed;
  }
},

handleClear     : func (value) { return emesary.Transmitter.ReceiptStatus_NotProcessed; },

# Holding the Clear button goes straight to the Navigation Map page.
handleClearHold : func (value) {
  var mappage = me._page.getMFD().getPage("NavigationMap");
  assert(mappage != nil, "Unable to find NavigationMap page");
  me._page.getDevice().selectPage(mappage);
  return emesary.Transmitter.ReceiptStatus_Finished;
},

# By default, the FMS knobs will select a new page.
handleFMSOuter : func (value) { return me.page.mfd.SurroundController.handleFMSOuter(value); },
handleFMSInner : func (value) { return me.page.mfd.SurroundController.handleFMSInner(value); },
handleCRSR     : func (value) { return emesary.Transmitter.ReceiptStatus_NotProcessed; },

handleMenu  : func (value) { return emesary.Transmitter.ReceiptStatus_NotProcessed; },
handleProc  : func (value) { return emesary.Transmitter.ReceiptStatus_NotProcessed; },
handleEnter : func (value) { return emesary.Transmitter.ReceiptStatus_NotProcessed; },

handleAltOuter  : func (value) { return me.page.mfd.SurroundController.handleAltOuter(value); },
handleAltInner : func (value) { return me.page.mfd.SurroundController.handleAltInner(value); },

handleKeyInput : func (value) { return emesary.Transmitter.ReceiptStatus_NotProcessed; },
handleStringInput : func (value) { print("Not handling " ~ value); return emesary.Transmitter.ReceiptStatus_NotProcessed; },

RegisterWithEmesary : func()
{
  if (me._recipient == nil){
    me._recipient = emesary.Recipient.new(me._page.pageName ~ "Controller_" ~ me._page.device.designation);
    var pfd_obj = me._page.device;
    var controller = me;
    me._recipient.Receive = func(notification)
    {
      if (notification.NotificationType == notifications.PFDEventNotification.DefaultType and
          notification.Device_Id == pfd_obj.device_id) {
        if (notification.Event_Id == notifications.PFDEventNotification.HardKeyPushed
            and notification.EventParameter != nil)
        {
          var id = notification.EventParameter.Id;
          var value = notification.EventParameter.Value;

          #printf("Button pressed " ~ id ~ " " ~ value);

          if (id == fg1000.FASCIA.NAV_VOL)             return controller.handleNavVol(value);
          if (id == fg1000.FASCIA.NAV_ID)              return controller.handleNavID(value);
          if (id == fg1000.FASCIA.NAV_FREQ_TRANSFER)   return controller.handleNavFreqTransfer(value);
          if (id == fg1000.FASCIA.NAV_OUTER)           return controller.handleNavOuter(value);
          if (id == fg1000.FASCIA.NAV_INNER)           return controller.handleNavInner(value);
          if (id == fg1000.FASCIA.NAV_TOGGLE)          return controller.handleNavToggle(value);
          if (id == fg1000.FASCIA.HEADING)             return controller.handleHeading(value);
          if (id == fg1000.FASCIA.HEADING_PRESS)       return controller.handleHeadingPress(value);

          # Joystick
          if (id == fg1000.FASCIA.RANGE)               return controller.handleRange(value);
          if (id == fg1000.FASCIA.JOYSTICK_HORIZONTAL) return controller.handleJoystickHorizontal(value);
          if (id == fg1000.FASCIA.JOYSTICK_VERTICAL)   return controller.handleJoystickHorizontal(value);

          #CRS/BARO
          if (id == fg1000.FASCIA.BARO)         return controller.handleBaro(value);
          if (id == fg1000.FASCIA.CRS)          return controller.handleCRS(value);
          if (id == fg1000.FASCIA.CRS_CENTER)   return controller.handleCRSCenter(value);

          if (id == fg1000.FASCIA.COM_OUTER)    return controller.handleComOuter(value);
          if (id == fg1000.FASCIA.COM_INNER)    return controller.handleComInner(value);
          if (id == fg1000.FASCIA.COM_TOGGLE)   return controller.handleComToggle(value);

          if (id == fg1000.FASCIA.COM_FREQ_TRANSFER)        return controller.handleComFreqTransfer(value);
          if (id == fg1000.FASCIA.COM_FREQ_TRANSFER_HOLD)   return controller.handleComFreqTransferHold(value); # Auto-tunes to 121.2 when pressed for 2 seconds

          if (id == fg1000.FASCIA.COM_VOL)          return controller.handleComVol(value);
          if (id == fg1000.FASCIA.COM_VOL_TOGGLE)   return controller.handleComVolToggle(value);

          if (id == fg1000.FASCIA.DTO)       return controller.handleDTO(value);
          if (id == fg1000.FASCIA.FPL)       return controller.handleFPL(value);
          if (id == fg1000.FASCIA.CLR)       return controller.handleClear(value);
          if (id == fg1000.FASCIA.CLR_HOLD)  return controller.handleClearHold(value);

          if (id == fg1000.FASCIA.FMS_OUTER)   return controller.handleFMSOuter(value);
          if (id == fg1000.FASCIA.FMS_INNER)   return controller.handleFMSInner(value);
          if (id == fg1000.FASCIA.FMS_CRSR)   return controller.handleCRSR(value);

          if (id == fg1000.FASCIA.MENU)   return controller.handleMenu(value);
          if (id == fg1000.FASCIA.PROC)   return controller.handleProc(value);
          if (id == fg1000.FASCIA.ENT)    return controller.handleEnter(value);

          if (id == fg1000.FASCIA.ALT_OUTER)   return controller.handleAltOuter(value);
          if (id == fg1000.FASCIA.ALT_INNER)   return controller.handleAltInner(value);

          if (id == fg1000.FASCIA.KEY_INPUT)   return controller.handleKeyInput(value);
          if (id == fg1000.FASCIA.STRING_INPUT)   return controller.handleStringInput(value);

          # Autopilot controls - ignore for now as like to be handled elsewhere
          #if (id == fg1000.FASCIA.AP )   return controller.handle(value);
          #if (id == fg1000.FASCIA.HDG)   return controller.handle(value);
          #if (id == fg1000.FASCIA.NAV)   return controller.handle(value);
          #if (id == fg1000.FASCIA.APR)   return controller.handle(value);
          #if (id == fg1000.FASCIA.VS )   return controller.handle(value);
          #if (id == fg1000.FASCIA.FLC)   return controller.handle(value);
          #if (id == fg1000.FASCIA.FD )   return controller.handle(value);
          #if (id == fg1000.FASCIA.ALT)   return controller.handle(value);
          #if (id == fg1000.FASCIA.VNV)   return controller.handle(value);
          #if (id == fg1000.FASCIA.BC )   return controller.handle(value);
          #if (id == fg1000.FASCIA.NOSE_UP)   return controller.handle(value);
          #if (id == fg1000.FASCIA.NOSE_DOWN)   return controller.handle(value);
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

# Set up the default waypoint to use if the DirectTo button is pressed
setDefaultDTOWayPoint : func(id)
{
  # Use Emesary to set the default DTO waypoint
  var notification = notifications.PFDEventNotification.new(
    "MFD",
    me.getDeviceID(),
    notifications.PFDEventNotification.NavData,
    {Id: "SetDefaultDTO", Value: id});

  var response = me._transmitter.NotifyAll(notification);
  if (me._transmitter.IsFailed(response)) print("Failed to set Default DTO waypoint");
},

getDeviceID : func() {
    return me._page.mfd.getDeviceID();
},

# Simply query of the NavDataInterface
getNavData : func(queryID, value=nil) {
  # Use Emesary to get the requested data
  var notification = notifications.PFDEventNotification.new(
    "MFD",
    me.getDeviceID(),
    notifications.PFDEventNotification.NavData,
    {Id: queryID, Value: value});

  var response = me._transmitter.NotifyAll(notification);

  if (! me._transmitter.IsFailed(response)) {
    return notification.EventParameter.Value;
  } else {
    return nil;
  }
},

};
