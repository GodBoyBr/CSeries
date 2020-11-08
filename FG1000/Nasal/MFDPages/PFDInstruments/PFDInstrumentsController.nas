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
# PFDInstruments Controller
var PFDInstrumentsController =
{
  CDI_SOURCE : [ "GPS", "NAV1", "NAV2" ],
  BRG_SOURCE : ["OFF", "NAV1", "NAV2", "GPS", "ADF"],

  new : func (page, svg)
  {
    var obj = {
      parents : [ PFDInstrumentsController, MFDPageController.new(page) ],
      _crsrToggle : 0,
      _pfdrecipient : nil,
      page : page,

      _CDISource : 0,
      _BRG1Source : 0,
      _BRG2Source : 0,

      _last_ias_kt : 0,
      _last_alt_ft : 0,
      _last_trend : systime(),
      _selected_alt_ft : 0,
      _heading_magnetic_deg : 0,
      _mag_var : 0,
      _time_sec : 0,

      _fd_pitch : 0,
      _fd_roll : 0,
      _fd_enabled : 0,
      _ap_enabled : 0,

      _fp_active : 0,
      _fp_current_wp : 0,
      _current_flightplan : nil,
      _fp_visible : 0,

      _leg_from :0,
      _leg_id : "",
      _leg_bearing  : 0,
      _leg_distance_nm : 0,
      _leg_deviation_deg : 0,
      _deflection_dots : 0.0,
      _leg_xtrk_nm : 0,
      _leg_valid : 0,

      _navSelected : 1,

      _nav1_id : "",
      _nav1_freq : 0.0,
      _nav1_radial_deg : 0,
      _nav1_heading_deg :0.0,
      _nav1_in_range : 0,
      _nav1_distance_m :0,
      _nav1_radial_deg : 0,
      _nav1_in_range : 0,
      _nav1_distance_m : 0,
      _nav1_deviation_deg : 0,
      _nav1_loc : 0,
      _nav1_deflection : 0,
      _nav1_gs_deflection : 0,
      _nav1_gs_in_range : 0,

      _nav2_id : "",
      _nav2_freq : 0.0,
      _nav2_radial_deg :0,
      _nav2_heading_deg : 0.0,
      _nav2_in_range : 0,
      _nav2_distance_m :0,
      _nav2_radial_deg : 0,
      _nav2_in_range : 0,
      _nav2_distance_m : 0,
      _nav2_deviation_deg : 0,
      _nav2_loc : 0,
      _nav2_deflection : 0,
      _nav2_gs_deflection : 0,
      _nav2_gs_in_range : 0,

      _adf_freq : 0.0,
      _adf_in_range : 0,
      _adf_heading_deg : 0.0,

      _transponder_mode : 0,
      _transponder_code : "1200",  # Current code
      _transponder_ident : 0,
      _transponder_edit : 0,      # If we're currently editing the transponder code
      _transponder_edit_code : 0, # Current value being edited as transponder code

      _marker_beacon_outer : 0,
      _marker_beacon_middle : 0,
      _marker_beacon_inner : 0,
    };

    obj._current_flightplan = obj.getNavData("Flightplan");
    if (obj._current_flightplan != nil) {
      obj._fp_current_wp = obj._current_flightplan.current;
      obj.page.setFlightPlan(obj._current_flightplan);
    }

    # Timer used to reset a transponder IDENT
    obj.transponderIdentResetTimer = maketimer(18, obj, func() { me.sendNavComDataNotification({"TransponderIdent" : 0}); });
    obj.transponderIdentResetTimer.simulatedTime = 1;
    obj.transponderIdentResetTimer.singleShot = 1;

    # Timer used to reset a transponder edit, if pilot hasn't completed entering a new code in 45s.
    obj.transponderEditResetTimer = maketimer(45, obj, obj.transponderEditCancel);
    obj.transponderEditResetTimer.simulatedTime = 1;
    obj.transponderEditResetTimer.singleShot = 1;

    return obj;
  },

  # Input Handling
  handleRange : func(val)
  {
    if (val >0) {
      me.page.insetMap.zoomOut();
    } else {
      me.page.insetMap.zoomIn();
    }
    return emesary.Transmitter.ReceiptStatus_Finished;
  },

  handleFPL : func (value) {
    # Display/hide the FPL display
    me._fp_visible = (! me._fp_visible);
    me.page.setFlightPlanVisible(me._fp_active and me._fp_visible);
    return emesary.Transmitter.ReceiptStatus_Finished;
  },

  # Set the STD BARO to 29.92 in Hg
  setStdBaro : func() {
    var data = {};
    data["FMSPressureSettingInHG"] = 29.92;

    var notification = notifications.PFDEventNotification.new(
      "MFD",
      me._page.mfd.getDeviceID(),
      notifications.PFDEventNotification.FMSData,
      data);

    me.transmitter.NotifyAll(notification);
  },

  incrCDISource : func() {
    me._CDISource = math.mod(me._CDISource + 1, size(PFDInstrumentsController.CDI_SOURCE));
    var src = PFDInstrumentsController.CDI_SOURCE[me._CDISource];

    # Indicate the change for CDI source to the autopilot
    var data = {};
    data["AutopilotNAVSource"] = src;
    var notification = notifications.PFDEventNotification.new(
      "MFD",
      me._page.mfd.getDeviceID(),
      notifications.PFDEventNotification.FMSData,
      data);

    me.transmitter.NotifyAll(notification);

    # If we're changing to NAV1 or NAV2, we also change the selected NAV.
    if ((src == "NAV1") or (src == "NAV2")) {
      var data = {};
      data["NavSelected"] = (src == "NAV1") ? 1 : 2;
      var notification = notifications.PFDEventNotification.new(
        "MFD",
        me._page.mfd.getDeviceID(),
        notifications.PFDEventNotification.NavComData,
        data);

      me.transmitter.NotifyAll(notification);
    }

    me.page.setCDISource(src);
  },

  getCDISource : func() {
    return PFDInstrumentsController.CDI_SOURCE[me._CDISource];
  },

  incrBRG1 : func() {
    me._BRG1Source = math.mod(me._BRG1Source + 1, size(PFDInstrumentsController.BRG_SOURCE));
    me.page.setBRG1(PFDInstrumentsController.BRG_SOURCE[me._BRG1Source]);
  },

  incrBRG2 : func() {
    me._BRG2Source = math.mod(me._BRG2Source + 1, size(PFDInstrumentsController.BRG_SOURCE));
    me.page.setBRG2(PFDInstrumentsController.BRG_SOURCE[me._BRG2Source]);
  },

  getBRG1 : func() { return PFDInstrumentsController.BRG_SOURCE[me._BRG1Source]; },
  getBRG2 : func() { return PFDInstrumentsController.BRG_SOURCE[me._BRG2Source]; },

  # Handle update of the airdata information.
  # ADC data is produced periodically as an entire set
  handleADCData : func(data) {
    var ias = data["ADCIndicatedAirspeed"];
    var alt = data["ADCAltitudeFT"];
    # estimated speed and altitude in 6s
    var now = systime();
    var lookahead_ias_6sec = 6 * (ias - me._last_ias_kt) / (now - me._last_trend);
    var lookahead_alt_6sec = .3 * (alt - me._last_alt_ft) / (now - me._last_trend); # scale = 1/20ft
    me.page.updateIAS(ias, lookahead_ias_6sec);
    me.page.updateALT(alt, lookahead_alt_6sec, me._selected_alt_ft);
    me._last_ias_kt = ias;
    me._last_alt_ft = alt;
    me._last_trend = now;

    var pitch = data["ADCPitchDeg"];
    var roll = data["ADCRollDeg"];
    var slip = data["ADCSlipSkid"];
    me.page.updateAI(pitch, roll, slip);
    me.page.updateFD((me._fd_enabled or me._ap_enabled), pitch, roll, me._fd_pitch, me._fd_roll);

    me.page.updateVSI(data["ADCVerticalSpeedFPM"]);
    me.page.updateTAS(data["ADCTrueAirspeed"]);
    me.page.updateBARO(data["ADCPressureSettingInHG"]);

    me.page.updateOAT(data["ADCOutsideAirTemperatureC"]);
    me.page.updateHSI(data["ADCHeadingMagneticDeg"]);
    me._heading_magnetic_deg = data["ADCHeadingMagneticDeg"];
    me._mag_var = data["ADCMagneticVariationDeg"];

    # If we're "flying" at < 10kts, then we won't have sufficient delta between
    # airspeed and groundspeed to determine wind
    me.page.updateWindData(
      hdg : data["ADCHeadingMagneticDeg"],
      wind_hdg : data["ADCWindHeadingDeg"],
      wind_spd : data ["ADCWindSpeedKt"],
      no_data: (data["ADCIndicatedAirspeed"] < 1.0)
    );

    if ((data["ADCTimeLocalSec"] != nil) and (me._time_sec != data["ADCTimeLocalSec"])) {
      me._time_sec = data["ADCTimeLocalSec"];
      me.page.updateTime(me._time_sec);
    }

    return emesary.Transmitter.ReceiptStatus_OK;
  },

  # Handle update to the FMS information.  Note that there is no guarantee
  # that the entire set of FMS data will be available.
  handleFMSData : func(data) {

    if (data["FMSHeadingBug"] != nil) me.page.updateHDG(data["FMSHeadingBug"]);
    if (data["FMSSelectedAlt"] != nil) {
      me.page.updateSelectedALT(data["FMSSelectedAlt"]);
      me._selected_alt_ft = data["FMSSelectedAlt"];
    }

    if (data["FMSLegValid"] != nil) me._leg_valid = data["FMSLegValid"];

    if (me._navSelected == 1) {
      if (data["FMSNav1From"] != nil) me._leg_from = data["FMSNav1From"];
    } else {
      if (data["FMSNav2From"] != nil) me._leg_from = data["FMSNav2From"];
    }

    if (data["FMSLegID"] != nil) me._leg_id = data["FMSLegID"];
    if (data["FMSLegBearingMagDeg"] != nil) me._leg_bearing = data["FMSLegBearingMagDeg"];
    if (data["FMSLegDistanceNM"] != nil) me._leg_distance_nm = data["FMSLegDistanceNM"];
    if (data["FMSLegTrackErrorAngle"] != nil) me._leg_deviation_deg = data["FMSLegTrackErrorAngle"];

    # TODO:  Proper cross-track error based on source and flight phase.
    if (data["FMSLegCourseError"] != nil) me._deflection_dots = data["FMSLegCourseError"] /2.0;
    if (data["FMSLegCourseError"] != nil) me._leg_xtrk_nm = data["FMSLegCourseError"];

    if (data["AutopilotFDEnabled"] != nil) me._fd_enabled = data["AutopilotFDEnabled"];
    if (data["AutopilotEnabled"] != nil) me._ap_enabled = data["AutopilotEnabled"];

    if (data["AutopilotTargetPitch"] != nil) me._fd_pitch   = data["AutopilotTargetPitch"];
    if (data["AutopilotTargetRoll"] != nil)  me._fd_roll    = data["AutopilotTargetRoll"];

    if (data["AutopilotTargetSpeed"] != nil) {
      me._fd_spd = data["AutopilotTargetSpeed"];
      me.page.updateSelectedSPD(me._fd_spd);
    }

    if (data["AutopilotAltitudeMode"] != nil) me.page.setSelectedSPDVisible(data["AutopilotAltitudeMode"] == "FLC");

    var update_fp = 0;

    if (data["FMSFlightPlanEdited"] != nil) {
      # The flightplan has changed in some way, so reload it.
      me._current_flightplan = me.getNavData("Flightplan");
      if (me._current_flightplan != nil) {
        me._fp_current_wp = me._current_flightplan.current;
        me.page.setFlightPlan(me._current_flightplan);
        update_fp = 1;
      }
    }

    if ((data["FMSFlightPlanActive"] != nil) and (data["FMSFlightPlanActive"] != me._fp_active)) {
      me._fp_active = data["FMSFlightPlanActive"];
      me.page.setFlightPlanVisible(me._fp_active and me._fp_visible);
      update_fp = 1;
    }

    if ((data["FMSFlightPlanCurrentWP"] != nil) and (data["FMSFlightPlanCurrentWP"] !=  me._fp_current_wp)) {
      me._fp_current_wp = data["FMSFlightPlanCurrentWP"];
      update_fp = 1;
    }

    if (me._fp_visible and update_fp and me._fp_active) {
      me.page.updateFlightPlan(me._fp_current_wp);
    }

    if (me.getCDISource() == "GPS") {
      if (me._leg_valid == 0) {
        # No valid leg data, likely because there's no GPS course set
        me.page.updateCRS(0);
        me.page.updateCDI(
          heading: me._heading_magnetic_deg,
          course: 0,
          waypoint_valid: 0,
          course_deviation_deg : 0,
          deflection_dots : 0.0,
          xtrk_nm : 0,
          from: 0,
          annun: "NO DATA",
          loc : 0,
        );
      } else {
        me.page.updateCRS(me._leg_bearing);

        me.page.updateCDI(
          heading: me._heading_magnetic_deg,
          course: me._leg_bearing,
          waypoint_valid: me._leg_valid,
          course_deviation_deg : me._leg_deviation_deg,
          deflection_dots : me._deflection_dots,
          xtrk_nm : me._leg_xtrk_nm,
          from: me._leg_from,
          annun: "ENR",
          loc: 0,
        );
      }
    }

    # Update the bearing indicators with GPS data if that's what we're displaying.
    if (me.getBRG1() == "GPS") me.page.updateBRG1(me._leg_valid, me._leg_id, me._leg_distance_nm, me._heading_magnetic_deg, me._leg_bearing);
    if (me.getBRG2() == "GPS") me.page.updateBRG2(me._leg_valid, me._leg_id, me._leg_distance_nm, me._heading_magnetic_deg, me._leg_bearing);

    return emesary.Transmitter.ReceiptStatus_OK;
  },

  # Handle update of the NavCom data.
  # Note that this updated on a property by property basis, so we need to check
  # that the data we want exists in this notification, unlike the periodic
  # publishers
  handleNavComData : func(data) {
    if (data["NavSelected"] != nil) me._navSelected = data["NavSelected"];
    if (data["Nav1SelectedFreq"] != nil) me._nav1_freq = data["Nav1SelectedFreq"];
    if (data["Nav1ID"] != nil) me._nav1_id = data["Nav1ID"];
    if (data["Nav1HeadingDeg"] != nil) me._nav1_heading_deg = data["Nav1HeadingDeg"];
    if (data["Nav1RadialDeg"] != nil) me._nav1_radial_deg = data["Nav1RadialDeg"];
    if (data["Nav1InRange"] != nil) me._nav1_in_range = data["Nav1InRange"];
    if (data["Nav1DistanceMeters"] != nil) me._nav1_distance_m = data["Nav1DistanceMeters"];
    if (data["Nav1CourseDeviationDeg"] != nil) me._nav1_deviation_deg = data["Nav1CourseDeviationDeg"];

    # Deflection range is [-1,1], while deflection_dots is [-2.4, 2.4];
    if (data["Nav1Deflection"] != nil) me._nav1_deflection = data["Nav1Deflection"] * 2.4;
    if (data["Nav1GSDeflection"] != nil) me._nav1_gs_deflection = data["Nav1GSDeflection"];
    if (data["Nav1GSInRange"] != nil) me._nav1_gs_in_range = data["Nav1GSInRange"];
    if (data["Nav1CrosstrackErrorM"] != nil) me._nav1_crosstrack_m = data["Nav1CrosstrackErrorM"];
    if (data["Nav1From"] != nil) me._nav1_from = data["Nav1From"];
    if (data["Nav1Localizer"] != nil) me._nav1_loc = data["Nav1Localizer"];

    if (data["Nav2SelectedFreq"] != nil) me._nav2_freq = data["Nav2SelectedFreq"];
    if (data["Nav2ID"] != nil) me._nav2_id = data["Nav2ID"];
    if (data["Nav2HeadingDeg"] != nil) me._nav2_heading_deg = data["Nav2HeadingDeg"];
    if (data["Nav2RadialDeg"] != nil) me._nav2_radial_deg = data["Nav2RadialDeg"];
    if (data["Nav2InRange"] != nil) me._nav2_in_range = data["Nav2InRange"];
    if (data["Nav2DistanceMeters"] != nil) me._nav2_distance_m = data["Nav2DistanceMeters"];
    if (data["Nav2CourseDeviationDeg"] != nil) me._nav2_deviation_deg = data["Nav1CourseDeviationDeg"];

    # Deflection range is [-1,1], while deflection_dots is [-2.4, 2.4];
    if (data["Nav2Deflection"] != nil) me._nav2_deflection = data["Nav2Deflection"] * 2.4;
    if (data["Nav2GSDeflection"] != nil) me._nav2_gs_deflection = data["Nav2GSDeflection"];
    if (data["Nav2GSInRange"] != nil) me._nav2_gs_in_range = data["Nav2GSInRange"];
    if (data["Nav2CrosstrackErrorM"] != nil) me._nav2_crosstrack_m = data["Nav2CrosstrackErrorM"];
    if (data["Nav2From"] != nil) me._nav2_from = data["Nav2From"];
    if (data["Nav2Localizer"] != nil) me._nav2_loc = data["Nav2Localizer"];

    if (data["ADFSelectedFreq"] != nil) me._adf_freq = data["ADFSelectedFreq"];
    if (data["ADFInRange"] != nil) me._adf_in_range = data["ADFInRange"];
    if (data["ADFHeadingDeg"] !=nil) me._adf_heading_deg = data["ADFInRange"];

    if (data["TransponderMode"] != nil) me._transponder_mode = data["TransponderMode"];
    if (data["TransponderCode"] != nil) me._transponder_code = data["TransponderCode"];
    if (data["TransponderIdent"] != nil) me._transponder_ident = data["TransponderIdent"];

    if (data["MarkerBeaconInner"] != nil) me._marker_beacon_inner = data["MarkerBeaconInner"];
    if (data["MarkerBeaconMiddle"] != nil) me._marker_beacon_middle = data["MarkerBeaconMiddle"];
    if (data["MarkerBeaconOuter"] != nil) me._marker_beacon_outer = data["MarkerBeaconOuter"];

    if (me.getBRG1() == "NAV1") me.page.updateBRG1(me._nav1_in_range, me._nav1_id, me._nav1_distance_m * M2NM, me._heading_magnetic_deg, me._nav1_heading_deg);
    if (me.getBRG1() == "NAV2") me.page.updateBRG1(me._nav2_in_range, me._nav2_id, me._nav2_distance_m * M2NM, me._heading_magnetic_deg, me._nav2_heading_deg);
    if (me.getBRG1() == "ADF")  me.page.updateBRG1(me._adf_in_range, sprintf("%.1f", me._adf_freq), 0, me._heading_magnetic_deg, me._adf_heading_deg);

    if (me.getBRG2() == "NAV1") me.page.updateBRG2(me._nav1_in_range, me._nav1_id, me._nav1_distance_m * M2NM, me._heading_magnetic_deg, me._nav1_heading_deg);
    if (me.getBRG2() == "NAV2") me.page.updateBRG2(me._nav2_in_range, me._nav2_id, me._nav2_distance_m * M2NM, me._heading_magnetic_deg, me._nav2_heading_deg);
    if (me.getBRG2() == "ADF")  me.page.updateBRG2(me._adf_in_range, sprintf("%.1f", me._adf_freq), 0, me._heading_magnetic_deg, me._adf_heading_deg);

    if (me.getCDISource() == "NAV1") {
      me.page.updateCRS(me._nav1_radial_deg);
      me.page.updateCDI(
        heading: me._heading_magnetic_deg,
        course: me._nav1_radial_deg,
        waypoint_valid: me._nav1_in_range,
        course_deviation_deg : me._nav1_deviation_deg,
        deflection_dots : me._nav1_deflection,
        xtrk_nm : me._nav1_crosstrack_m * M2NM,
        from: me._nav1_from,
        annun: "",
        loc : me._nav1_loc,
      );

      if (me._nav1_gs_in_range) {
        me.page.updateGS(me._nav1_gs_deflection, "G");
      } else {
        me.page.updateGS(0, "");
      }
    }

    if (me.getCDISource() == "NAV2") {
      me.page.updateCRS(me._nav2_radial_deg);
      me.page.updateCDI(
        heading: me._heading_magnetic_deg,
        course: me._nav2_radial_deg,
        waypoint_valid: me._nav2_in_range,
        course_deviation_deg : me._nav2_deviation_deg,
        deflection_dots : me._nav2_deflection,
        xtrk_nm : me._nav2_crosstrack_m * M2NM,
        from: me._nav2_from,
        annun: "",
        loc : me._nav2_loc,
      );

      if (me._nav2_gs_in_range) {
        me.page.updateGS(me._nav2_gs_deflection, "G");
      } else {
        me.page.updateGS(0, "");
      }
    }

    # Special case - if the GPS is being used as the CDI source, then it'll be slaved to Nav1
    # and we should used the Nav1 Glideslope to show GPS-controlled glideslope.
    if (me.getCDISource() == "GPS") {
      if (me._nav1_gs_in_range) {
        me.page.updateGS(me._nav1_gs_deflection, "G");
      } else {
        me.page.updateGS(0, "");
      }
    }

    if ((me._transponder_edit == 0) and
        ((data["TransponderMode"] != nil) or (data["TransponderCode"] != nil) or (data["TransponderIdent"] != nil))) {
      # Transponder settings only change irregularly, so only redisplay on a change, and only if we are not currently
      # editing the transponder code itself.
      me.page.updateTransponder(me._transponder_mode, me._transponder_code, me._transponder_ident);
    }

    if (me._marker_beacon_outer == 1) {
      me.page.setOMI("O");
    } else if (me._marker_beacon_middle == 1) {
      me.page.setOMI("M");
    } else if (me._marker_beacon_inner == 1) {
      me.page.setOMI("I");
    } else {
      me.page.setOMI("");
    }

    return emesary.Transmitter.ReceiptStatus_OK;
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

  PFDRegisterWithEmesary : func(transmitter = nil){
    if (transmitter == nil)
      transmitter = emesary.GlobalTransmitter;

    if (me._pfdrecipient == nil){
      me._pfdrecipient = emesary.Recipient.new("PFDInstrumentsController_" ~ me._page.device.designation);
      var pfd_obj = me._page.device;
      var controller = me;
      me._pfdrecipient.Receive = func(notification)
      {
        if (notification.NotificationType == notifications.PFDEventNotification.DefaultType and
            notification.Event_Id == notifications.PFDEventNotification.ADCData and
            notification.EventParameter != nil)
        {
          return controller.handleADCData(notification.EventParameter);
        }

        if (notification.NotificationType == notifications.PFDEventNotification.DefaultType and
            notification.Event_Id == notifications.PFDEventNotification.FMSData and
            notification.EventParameter != nil)
        {
          return controller.handleFMSData(notification.EventParameter);
        }

        if (notification.NotificationType == notifications.PFDEventNotification.DefaultType and
            notification.Event_Id == notifications.PFDEventNotification.NavComData and
            notification.EventParameter != nil)
        {
          return controller.handleNavComData(notification.EventParameter);
        }

        return emesary.Transmitter.ReceiptStatus_NotProcessed;
      };
    }
    transmitter.Register(me._pfdrecipient);
    me.transmitter = transmitter;
  },
  PFDDeRegisterWithEmesary : func(transmitter = nil){
      # remove registration from transmitter; but keep the recipient once it is created.
      if (me.transmitter != nil)
        me.transmitter.DeRegister(me._pfdrecipient);
      me.transmitter = nil;
  },

  setTransponderMode : func(mode) {
    var idx = -1;

    # Find the matching index for the transponder mode string
    for(var i = 0; i < size(TRANSPONDER_MODES); i +=1) {
      if (mode == TRANSPONDER_MODES[i]) {
        idx = i;
        break;
      }
    }

    if (idx == -1) {
      print("Unable to find transponder mode " ~ mode);
    } else {
      me.sendNavComDataNotification({"TransponderMode" : idx});
    }
  },

  setTransponderCode : func(code) {
    me.sendNavComDataNotification({"TransponderCode" : code});
  },

  setTransponderIdent : func(ident) {
    # IDNT is active for 18 seconds, so we set a timer to reset it.
    me.sendNavComDataNotification({"TransponderIdent" : ident});

    # Reset any edit of the transponder code.  Note that this also returns
    # to the top level menu.  This is correct behaviour.
    me.transponderEditCancel();

    if (ident == 1) {
      me.transponderIdentResetTimer.restart(18);
    }
  },

  setTransponderDigit : func(digit) {
    if (me._transponder_edit == 0) {
      # If this is the first time we've pressed a digit button, then go to editing
      # mode, and set the first digit of the display
      me._transponder_edit = 1;

      # Start the transponder edit timer so we will exit out of edit mode
      me.transponderEditResetTimer.restart(45);


      if (digit == "BKSP") {
        me._transponder_edit_code = "";
      } else {
        me._transponder_edit_code = digit;
      }

      me.page.updateTransponder(me._transponder_mode, me._transponder_edit_code, me._transponder_ident, 1);
    } else {
      # Already in edit mode, so we need to append the newly entered number.
      if (digit == "BKSP") {
        # Trim off the last digit
        me._transponder_edit_code = substr(me._transponder_edit_code, 0, size(me._transponder_edit_code) -1);
      } else {
        # append the new digit
        me._transponder_edit_code = me._transponder_edit_code ~ digit;
      }

      if (size(me._transponder_edit_code) == 4) {
        # We've now got 4 digits, so set it both centrally and locally
        me.sendNavComDataNotification({"TransponderCode" : me._transponder_edit_code});
        me._transponder_code = me._transponder_edit_code;
        me.transponderEditCancel();
      } else {
        # Display the code so far entered.
        me.page.updateTransponder(me._transponder_mode, me._transponder_edit_code, me._transponder_ident, 1);
      }
    }
  },

  transponderEditCancel : func() {
    me._transponder_edit = 0;
    me.transponderEditResetTimer.stop();
    me.page.updateTransponder(me._transponder_mode, me._transponder_code, me._transponder_ident);
    me.page.topMenu(me.page.device, me.page, nil);
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

  # Reset controller if required when the page is displayed or hidden
  ondisplay : func() {
    me.RegisterWithEmesary();
    me.PFDRegisterWithEmesary();
  },
  offdisplay : func() {
    me.DeRegisterWithEmesary();
    me.PFDDeRegisterWithEmesary();
  },
};
