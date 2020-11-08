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
# Surround Controller
var SurroundController =
{
  new : func (page, svg, pfd)
  {
    var obj = {
      parents : [ SurroundController ],
      _recipient : nil,
      _page : page,
      _pfd : pfd,
      _comselected : 1,
      _navselected : 1,
      _com1active  : 0.0,
      _com1standby : 0.0,
      _com2active  : 0.0,
      _com2standby : 0.0,
      _nav1active  : 0.0,
      _nav1standby : 0.0,
      _nav1radial : 0.0,
      _nav1_heading_deg : 0.0,
      _nav2active  : 0.0,
      _nav2standby : 0.0,
      _nav2radial : 0.0,
      _nav2_heading_deg : 0.0,
      _pressure_settings_inhg : 0.0,
      _selected_alt_ft : 0.0,
      _heading_bug_deg : 0.0,
      _heading_deg : 0.0,
    };

    obj.RegisterWithEmesary();
    return obj;
  },

  del : func() {
    me.DeRegisterWithEmesary();
  },

  # Helper function to notify the Emesary bridge of a NavComData update.
  sendNavComDataNotification : func(data) {
    var notification = notifications.PFDEventNotification.new(
      "MFD",
      me._page.mfd.getDeviceID(),
      notifications.PFDEventNotification.NavComData,
      data);

    me.transmitter.NotifyAll(notification);
  },

  # Helper function to notify the Emesary bridge of a FMSData update.
  sendFMSDataNotification : func(data) {
    var notification = notifications.PFDEventNotification.new(
      "MFD",
      me._page.mfd.getDeviceID(),
      notifications.PFDEventNotification.FMSData,
      data);

    me.transmitter.NotifyAll(notification);
  },

  handleNavComData : func(data) {

    # Store off particularly important data for control.
    if (data["CommSelected"] != nil) me._comselected = data["CommSelected"];
    if (data["NavSelected"] != nil)  me._navselected = data["NavSelected"];

    if (data["Comm1SelectedFreq"] != nil) me._com1active  = data["Comm1SelectedFreq"];
    if (data["Comm1StandbyFreq"] != nil)  me._com1standby = data["Comm1StandbyFreq"];
    if (data["Comm2SelectedFreq"] != nil) me._com2active  = data["Comm2SelectedFreq"];
    if (data["Comm2StandbyFreq"] != nil)  me._com2standby = data["Comm2StandbyFreq"];

    if (data["Nav1SelectedFreq"] != nil) me._nav1active  = data["Nav1SelectedFreq"];
    if (data["Nav1StandbyFreq"] != nil)  me._nav1standby = data["Nav1StandbyFreq"];
    if (data["Nav1RadialDeg"] != nil)  me._nav1radial = data["Nav1RadialDeg"];
    if (data["Nav1HeadingDeg"] != nil)  me._nav1_heading_deg = data["Nav1HeadingDeg"];

    if (data["Nav2SelectedFreq"] != nil) me._nav2active  = data["Nav2SelectedFreq"];
    if (data["Nav2StandbyFreq"] != nil)  me._nav2standby = data["Nav2StandbyFreq"];
    if (data["Nav2RadialDeg"] != nil)  me._nav2radial = data["Nav2RadialDeg"];
    if (data["Nav2HeadingDeg"] != nil)  me._nav2_heading_deg = data["Nav2HeadingDeg"];

    # pass through to the page
    me._page.handleNavComData(data);
    return emesary.Transmitter.ReceiptStatus_OK;
  },

  handleFMSADCData : func(data) {
    if (data["ADCPressureSettingInHG"] != nil) me._pressure_settings_inhg = data["ADCPressureSettingInHG"];
    if (data["FMSSelectedAlt"] != nil) me._selected_alt_ft = data["FMSSelectedAlt"];
    if (data["FMSHeadingBug"] != nil) me._heading_bug_deg = data["FMSHeadingBug"];
    if (data["ADCHeadingMagneticDeg"] != nil) me._heading_deg = data["ADCHeadingMagneticDeg"];

    # Pass FMS and ADC data straight to the page to display in the header fields
    me._page.updateHeaderData(data);
    return emesary.Transmitter.ReceiptStatus_OK;
  },

  handleSelectPageByID : func(notification) {
    me._page.goToPage(notification.Group, notification.Page);
    return emesary.Transmitter.ReceiptStatus_Finished;
  },

  #
  # Handle the various COM and NAV controls at the top left and top right of the Fascia
  #
  handleNavVol : func (value) {
    var data={};

    if (me._navselected == 1) {
      data["Nav1Volume"] = value;
    } else {
      data["Nav2Volume"] = value;
    }

    me.sendNavComDataNotification(data);
    return emesary.Transmitter.ReceiptStatus_Finished;
  },

  handleNavID : func (value) {
    var data={};

    if (me._navselected == 1) {
      data["Nav1AudioID"] = value;
    } else {
      data["Nav1AudioID"] = value;
    }

    me.sendNavComDataNotification(data);
    return emesary.Transmitter.ReceiptStatus_Finished;
  },

  # Swap active and standby Nav frequencies.  Note that we don't update internal state here - we
  # instead pass updated NavComData notification data which will be picked up by the underlying
  # updaters to map to properties, and this controller itself.
  handleNavFreqTransfer : func (value)
  {
    var data={};

    if (me._navselected == 1) {
      data["Nav1SelectedFreq"] = me._nav1standby;
      data["Nav1StandbyFreq"] = me._nav1active;
    } else {
      data["Nav2SelectedFreq"] = me._nav2standby;
      data["Nav2StandbyFreq"] = me._nav2active;
    }

    me.sendNavComDataNotification(data);
    return emesary.Transmitter.ReceiptStatus_Finished;
  },

  # Outer Nav dial updates the integer portion of the selected standby
  # NAV frequency only, and wrap on limits - leaving the fractional part unchanged.
  handleNavOuter : func (value) {
    var incr_or_decr = (value > 0) ? 1000.0 : -1000.0;
    var data={};

    # Determine the new value, wrapping within the limits.
    var datakey = "";
    var freq = 0;
    var old_freq = 0;

    if (me._navselected == 1) {
      datakey = "Nav1StandbyFreq";
      old_freq = me._nav1standby;
    } else {
      datakey = "Nav2StandbyFreq";
      old_freq = me._nav2standby;
    }

    old_freq = math.round(old_freq * 1000);
    freq = old_freq + incr_or_decr;

    # Wrap if out of bounds
    if (freq > (fg1000.MAX_NAV_FREQ * 1000)) freq = freq - (fg1000.MAX_NAV_FREQ - fg1000.MIN_NAV_FREQ) * 1000;
    if (freq < (fg1000.MIN_NAV_FREQ * 1000)) freq = freq + (fg1000.MAX_NAV_FREQ - fg1000.MIN_NAV_FREQ) * 1000;

    # Convert back to a frequency to 3 decimal places.
    data[datakey] = sprintf("%.3f", freq/1000.0);
    me.sendNavComDataNotification(data);
    return emesary.Transmitter.ReceiptStatus_Finished;
  },

  # Inner Nav dial updates the fractional portion of the selected standby
  # NAV frequency only - leaving the integer part unchanged.  Even if it
  # increments past 0.975.
  handleNavInner  : func (value) {
    var incr_or_decr = (value > 0) ? 25 : -25;
    var data={};

    # Determine the new value, wrapping within the limits.
    var datakey = "";
    var freq = 0;
    var old_freq = 0;
    if (me._navselected == 1) {
      datakey = "Nav1StandbyFreq";
      old_freq = me._nav1standby;
    } else {
      datakey = "Nav2StandbyFreq";
      old_freq = me._nav2standby;
    }

    old_freq = math.round(old_freq * 1000);
    freq = old_freq + incr_or_decr;

    # Wrap on decimal by handling case where the integer part has changed
    if (int(old_freq/1000) < int(freq/1000)) freq = freq - 1000;
    if (int(old_freq/1000) > int(freq/1000)) freq = freq + 1000;

    data[datakey] = sprintf("%.3f", freq/1000.0);
    me.sendNavComDataNotification(data);
    return emesary.Transmitter.ReceiptStatus_Finished;
  },

  # Switch between Nav1 and Nav2.
  handleNavToggle : func ()
  {
    var data={};

    if (me._navselected == 1) {
      data["NavSelected"] = 2;
    } else {
      data["NavSelected"] = 1;
    }

    me.sendNavComDataNotification(data);
    return emesary.Transmitter.ReceiptStatus_Finished;
  },

  setNav : func(value) {
    var data={};
    data["NavSelected"] = value;
    me.sendNavComDataNotification(data);
    return emesary.Transmitter.ReceiptStatus_Finished;
  },

  # Outer COM dial changes the integer value of the standby selected COM
  # frequency, wrapping on limits.  Leaves the fractional part unchanged
  handleComOuter : func (value) {
    var incr_or_decr = (value > 0) ? 1000.0 : -1000.0;
    var data={};

    # Determine the new value, wrapping within the limits.
    var datakey = "";
    var freq = 0;
    var old_freq = 0;

    if (me._comselected == 1) {
      datakey = "Comm1StandbyFreq";
      old_freq = me._com1standby;
    } else {
      datakey = "Comm2StandbyFreq";
      old_freq = me._com2standby;
    }

    old_freq = math.round(old_freq * 1000);
    freq = old_freq + incr_or_decr;

    # Wrap if out of bounds
    if (freq > (fg1000.MAX_COM_FREQ * 1000)) freq = freq - (fg1000.MAX_COM_FREQ - fg1000.MIN_COM_FREQ) * 1000;
    if (freq < (fg1000.MIN_COM_FREQ * 1000)) freq = freq + (fg1000.MAX_COM_FREQ - fg1000.MIN_COM_FREQ) * 1000;

    # Convert back to a frequency to 3 decimal places.
    data[datakey] = sprintf("%.3f", freq/1000.0);
    me.sendNavComDataNotification(data);
    return emesary.Transmitter.ReceiptStatus_Finished;
  },

  # Inner COM dial changes the fractional part of the standby selected COM frequency,
  # wrapping on limits and leaving the integer part unchanged.
  handleComInner  : func (value) {
    var incr_or_decr = (value > 0) ? 1 : -1;
    var data={};

    var datakey = "";
    var freq = 0;
    var old_freq = 0;
    if (me._comselected == 1) {
      datakey = "Comm1StandbyFreq";
      old_freq = me._com1standby;
    } else {
      datakey = "Comm2StandbyFreq";
      old_freq = me._com2standby;
    }

    old_freq = math.round(old_freq * 1000);
    var integer_part = int(old_freq / 1000) * 1000;
    var fractional_part = old_freq - integer_part;

    # 8.33kHz frequencies are complicated - we need to do a lookup to find
    # the current and next frequencies
    var idx = 0;
    for (var i=0; i < size(fg1000.COM_833_SPACING); i = i + 1) {
      if (math.round(fg1000.COM_833_SPACING[i] * 1000) == fractional_part) {
        idx = i;
        break;
      }
    }

    idx = math.mod(idx + incr_or_decr, size(fg1000.COM_833_SPACING));
    freq = integer_part + fg1000.COM_833_SPACING[idx] * 1000;
    data[datakey] = sprintf("%.3f", freq/1000.0);
    me.sendNavComDataNotification(data);
    return emesary.Transmitter.ReceiptStatus_Finished;
  },

  # Switch between COM1 and COM2
  handleComToggle : func (value) {
    var data={};

    if (me._comselected == 1) {
      data["CommSelected"] = 2;
    } else {
      data["CommSelected"] = 1;
    }

    me.sendNavComDataNotification(data);
    return emesary.Transmitter.ReceiptStatus_Finished;
  },

  # Swap active and standby Com frequencies.  Note that we don't update internal state here - we
  # instead pass updated NavComData notification data which will be picked up by the underlying
  # updaters to map to properties, and this controller itself.
  handleComFreqTransfer : func (value) {
    var data={};

    if (me._comselected == 1) {
      data["Comm1SelectedFreq"] = me._com1standby;
      data["Comm1StandbyFreq"] = me._com1active;
    } else {
      data["Comm2SelectedFreq"] = me._com2standby;
      data["Comm2StandbyFreq"] = me._com2active;
    }

    me.sendNavComDataNotification(data);
    return emesary.Transmitter.ReceiptStatus_Finished;
  },

  # Auto-tunes the ACTIVE COM channel to 121.2 when pressed for 2 seconds
  handleComFreqTransferHold : func (value) {
    var data={};

    if (me._comselected == 1) {
      data["Comm1SelectedFreq"] = 121.00;
    } else {
      data["Comm2SelectedFreq"] = 121.00;
    }

    me.sendNavComDataNotification(data);
    return emesary.Transmitter.ReceiptStatus_Finished;
  },

  handleComVol : func (value) {
    var data={};

    if (me._comselected == 1) {
      data["Comm1Volume"] = value;
    } else {
      data["Comm2Volume"] = value;
    }

    me.sendNavComDataNotification(data);
    return emesary.Transmitter.ReceiptStatus_Finished;
  },

  handleComVolToggle : func (value) {
  },

  handleBaro : func(value) {
    var incr_or_decr = (value > 0) ? 1 : -1;
    var press = me._pressure_settings_inhg + (incr_or_decr * 0.01);
    var data = {};
    data["FMSPressureSettingInHG"] = sprintf("%.2f", press);
    me.sendFMSDataNotification(data);
    return emesary.Transmitter.ReceiptStatus_Finished;
  },

  handleCRS : func(value) {
    var incr_or_decr = (value > 0) ? 1 : -1;
    var data={};

    if (me._navselected == 1) {
      data["Nav1RadialDeg"] = math.mod(me._nav1radial + incr_or_decr, 360);
    } else {
      data["Nav2RadialDeg"] = math.mod(me._nav2radial + incr_or_decr, 360);
    }

    me.sendNavComDataNotification(data);
    return emesary.Transmitter.ReceiptStatus_Finished;
  },

  handleCRSCenter : func(value) {
    var data = {};
    if (me._navselected == 1) {
      data["Nav1RadialDeg"] = me._nav1_heading_deg;
    } else {
      data["Nav2RadialDeg"] = me._nav2_heading_deg;
    }

    me.sendNavComDataNotification(data);
    return emesary.Transmitter.ReceiptStatus_Finished;
  },

  handleAltInner : func(value) {
    var incr_or_decr = (value > 0) ? 1 : -1;
    var alt = int(me._selected_alt_ft + incr_or_decr * 100);
    if (alt < 0) alt = 0;
    var data = {};
    data["FMSSelectedAlt"] = alt;
    me.sendFMSDataNotification(data);
    return emesary.Transmitter.ReceiptStatus_Finished;
  },

  handleAltOuter : func(value) {
    var incr_or_decr = (value > 0) ? 1 : -1;
    var alt = int(me._selected_alt_ft + incr_or_decr * 1000);
    if (alt < 0) alt = 0;
    var data = {};
    data["FMSSelectedAlt"] = alt;
    me.sendFMSDataNotification(data);
    return emesary.Transmitter.ReceiptStatus_Finished;
  },

  handleHeading : func(value) {
    var incr_or_decr = (value > 0) ? 1 : -1;
    var hdg = me._heading_bug_deg + incr_or_decr;
    hdg = math.mod(hdg, 360);
    var data = {};
    data["FMSHeadingBug"] = sprintf("%i", hdg);
    me.sendFMSDataNotification(data);
    return emesary.Transmitter.ReceiptStatus_Finished;
  },

  handleHeadingPress : func(value) {
    var data = {};
    data["FMSHeadingBug"] = me._heading_deg;
    me.sendFMSDataNotification(data);
    return emesary.Transmitter.ReceiptStatus_Finished;
  },

  # These methods are slightly unusual in that they are called by other
  # controllers when the CRSR is not active.  Hence they aren't referenced
  # in the RegisterWithEmesary call below.
  #
  handleFMSOuter : func(val)
  {
    if (me._pfd) return emesary.Transmitter.ReceiptStatus_NotProcessed;
    if (me._page.isMenuVisible()) {
      # Change page group
      me._page.incrPageGroup(val);
    }
    me._page.showMenu();
    return emesary.Transmitter.ReceiptStatus_Finished;
  },

  handleFMSInner : func(val)
  {
    if (me._pfd) return emesary.Transmitter.ReceiptStatus_NotProcessed;
    if (me._page.isMenuVisible()) {
      # Change page group
      me._page.incrPage(val);
    }
    me._page.showMenu();
    return emesary.Transmitter.ReceiptStatus_Finished;
  },

  RegisterWithEmesary : func(transmitter = nil){
    if (transmitter == nil)
      transmitter = emesary.GlobalTransmitter;

    if (me._recipient == nil){
      me._recipient = emesary.Recipient.new("SurroundController_" ~ me._page.device.designation);
      var pfd_obj = me._page.device;
      var controller = me;
      me._recipient.Receive = func(notification)
      {
        # Note that in general we don't care about the device that the data comes from.
        if (notification.NotificationType == notifications.PFDEventNotification.DefaultType) {

          if (notification.Event_Id == notifications.PFDEventNotification.NavComData
              and notification.EventParameter != nil)
          {
            return controller.handleNavComData(notification.EventParameter);
          }

          if (((notification.Event_Id == notifications.PFDEventNotification.FMSData) or
               (notification.Event_Id == notifications.PFDEventNotification.ADCData)   )
              and notification.EventParameter != nil)
          {
            return controller.handleFMSADCData(notification.EventParameter);
          }

          if (notification.Device_Id == pfd_obj.device_id and
              notification.Event_Id == notifications.PFDEventNotification.SelectPageById)
          {
            return controller.handleSelectPageByID(notification.EventParameter);
          }
        }
        return emesary.Transmitter.ReceiptStatus_NotProcessed;
      };
    }
    transmitter.Register(me._recipient);
    me.transmitter = transmitter;
  },
  DeRegisterWithEmesary : func(transmitter = nil){
      # remove registration from transmitter; but keep the recipient once it is created.
      if (me.transmitter != nil)
        me.transmitter.DeRegister(me._recipient);
      me.transmitter = nil;
  },

  # Used by other pages to set the current standby NAV or COM frequency by pressing ENT
  setStandbyNavComFreq : func(value) {
    var data={};

    # Determine whether this is NAV or COM based on the frequency itself

    if (value < fg1000.MAX_NAV_FREQ) {
      # Nav frequency
      if (value > fg1000.MAX_NAV_FREQ) return;
      if (value < fg1000.MIN_NAV_FREQ) return;

      # TODO: If we're in approach phase then this should update the Active
      # frequency
      if (me._navselected == 1) {
        data["Nav1StandbyFreq"] = value;
      } else {
        data["Nav2StandbyFreq"] = value;
      }
    } else {
      # COM frequency
      if (value > fg1000.MAX_COM_FREQ) return;
      if (value < fg1000.MIN_COM_FREQ) return;

      if (me._comselected == 1) {
        data["Comm1StandbyFreq"] = value;
      } else {
        data["Comm2StandbyFreq"] = value;
      }
    }

    me.sendNavComDataNotification(data);
  },

  # Used by other pages to set the current standby NAV frequency by pressing ENT
  setStandbyNavFreq : func(value) {
    var data={};

    if (value > fg1000.MAX_NAV_FREQ) return;
    if (value < fg1000.MIN_NAV_FREQ) return;

    if (me._navselected == 1) {
      data["Nav1StandbyFreq"] = value;
    } else {
      data["Nav2StandbyFreq"] = value;
    }

    me.sendNavComDataNotification(data);
  },
};
