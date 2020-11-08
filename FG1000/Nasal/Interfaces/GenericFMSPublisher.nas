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
# FMS Driver using Emesary to publish data from the inbuilt FMS properties

var GenericFMSPublisher =
{

  new : func (period=0.5) {
    var obj = {
      parents : [
        GenericFMSPublisher,
      ],
      _running : 0,
    };

    # We have two publishers here:
    #
    # 1) a triggered publisher for properties that will change ocassionally, but which
    # we need to update immediately. These are typically settings.
    #
    # 2) a periodic publisher which triggers every 0.5s to update data values.
    obj._triggeredPublisher = TriggeredPropertyPublisher.new(notifications.PFDEventNotification.FMSData);
    obj._periodicPublisher = PeriodicPropertyPublisher.new(notifications.PFDEventNotification.FMSData, period);

    obj._triggeredPublisher.addPropMap("FMSHeadingBug", "/autopilot/settings/heading-bug-deg");
    obj._triggeredPublisher.addPropMap("FMSSelectedAlt", "/autopilot/settings/target-alt-ft");
    obj._triggeredPublisher.addPropMap("FMSFlightPlanActive", "/autopilot/route-manager/active");
    obj._triggeredPublisher.addPropMap("FMSFlightPlanCurrentWP", "/autopilot/route-manager/current-wp");
    obj._triggeredPublisher.addPropMap("FMSFlightPlanSequenced", "/autopilot/route-manager/signals/sequenced");
    obj._triggeredPublisher.addPropMap("FMSFlightPlanFinished", "/autopilot/route-manager/signals/finished");
    obj._triggeredPublisher.addPropMap("FMSFlightPlanEdited", "/autopilot/route-manager/signals/edited");

    obj._triggeredPublisher.addPropMap("FMSMode", "/instrumentation/gps/mode");

    obj._periodicPublisher.addPropMap("FMSLegValid", "/instrumentation/gps/wp/wp[1]/valid");
    obj._periodicPublisher.addPropMap("FMSPreviousLegID", "/instrumentation/gps/wp/wp[0]/ID");
    obj._periodicPublisher.addPropMap("FMSLegID", "/instrumentation/gps/wp/wp[1]/ID");
    obj._periodicPublisher.addPropMap("FMSLegBearingMagDeg", "/instrumentation/gps/wp/wp[1]/bearing-mag-deg");
    obj._periodicPublisher.addPropMap("FMSLegDistanceNM", "/instrumentation/gps/wp/wp[1]/distance-nm");
    obj._periodicPublisher.addPropMap("FMSLegCourseError", "/instrumentation/gps/wp/wp[1]/course-error-nm");
    obj._periodicPublisher.addPropMap("FMSLegDesiredTrack", "/instrumentation/gps/wp/wp[1]/desired-course-deg");
    obj._periodicPublisher.addPropMap("FMSLegTrackErrorAngle", "/instrumentation/gps/wp/wp[1]/course-deviation-deg");
    obj._periodicPublisher.addPropMap("FMSWayPointCourseError", "/instrumentation/gps/wp/wp[1]/course-error-nm");

    obj._periodicPublisher.addPropMap("FMSGroundspeed",  "/instrumentation/gps/indicated-ground-speed-kt");

    obj._periodicPublisher.addPropMap("FMSNav1From", "/instrumentation/nav/from-flag");
    obj._periodicPublisher.addPropMap("FMSNav2From", "/instrumentation/nav[1]/from-flag");

    # Custom publish method as we need to calculate some particular values manually.
    obj._periodicPublisher.publish = func() {
      var gpsdata = {};

      foreach (var propmap; me._propmaps) {
        var name = propmap.getName();
        gpsdata[name] = propmap.getValue();
      }

      # Some GPS properties have odd values to indicate that nothing is set, so
      # remove them from the data set.
      if (gpsdata["FMSLegBearingMagDeg"] == -9999) gpsdata["FMSLegBearingMagDeg"] = nil;
      if (gpsdata["FMSLegDistanceNM"] == -1) gpsdata["FMSLegDistanceNM"] = nil;

      # A couple of calculated values used by the MFD Header display
      var total_fuel = getprop("/consumables/fuel/tank[0]/fg1000-indicated-level-gal_us") or 0.0;
      total_fuel = total_fuel  + (getprop("/consumables/fuel/tank[1]/fg1000-indicated-level-gal_us") or 0.0);
      var fuel_flow = getprop("/engines/engine[0]/fuel-flow-gph") or 1.0;
      gpsdata["FuelOnBoard"] = total_fuel;
      gpsdata["EnduranceHrs"] = total_fuel /  fuel_flow;

      var plan = flightplan();

      var dst = 0.0;
      if (plan.getPlanSize() > 0) {
        # Determine the distance to travel, based on
        # - current distance to the next WP,
        # - length of each subsequent leg.
        dst = getprop("/instrumentation/gps/wp/wp[1]/distance-nm") or 0.0;

        if (plan.indexOfWP(plan.currentWP()) <  (plan.getPlanSize() -1)) {
          for(var i=plan.indexOfWP(plan.currentWP()) + 1; i < plan.getPlanSize(); i = i+1) {
            var leg = plan.getWP(i);
            if (leg != nil ) dst = dst + leg.leg_distance;
          }
        }
      }

      gpsdata["FMSDistance"] = dst;
      var spd = math.max(getprop("/instrumentation/gps/indicated-ground-speed-kt"), 20.0);
      var time_hrs = dst / spd;

      gpsdata["FMSEstimatedTimeEnroute"] = time_hrs;
      gpsdata["FMSFuelOverDestination"] = total_fuel - time_hrs * fuel_flow;

      var notification = notifications.PFDEventNotification.new(
        "MFD",
        1,
        notifications.PFDEventNotification.FMSData,
        gpsdata);

      me._transmitter.NotifyAll(notification);
    };

    return obj;
  },

  start : func() {
    me._triggeredPublisher.start();
    me._periodicPublisher.start();
    me._running = 1;
  },

  stop : func() {
    me._triggeredPublisher.stop();
    me._periodicPublisher.stop();
    me._running = 0;
  },

  isRunning : func() {
    return me._running;
  },

};

# FMS Delegate which will be triggered by the underlying route manager
var FMSDataDelegate = {
  new : func(fp) {
    var obj = {
      parents : [FMSDataDelegate],
      flightplan : fp,
    };
    return obj;
  },
  currentWaypointChanged : func (fp) {
    var notification = notifications.PFDEventNotification.new(
      "MFD",
      1,
      notifications.PFDEventNotification.FMSData,
      {"FMSFlightPlanSequenced" : fp.current});
    emesary.GlobalTransmitter.NotifyAll(notification);
  },
  departureChanged : func (fp) {
    var notification = notifications.PFDEventNotification.new(
      "MFD",
      1,
      notifications.PFDEventNotification.FMSData,
      {"FMSFlightPlanEdited" : 1});
    emesary.GlobalTransmitter.NotifyAll(notification);
  },
  arrivalChanged : func (fp) {
    var notification = notifications.PFDEventNotification.new(
      "MFD",
      1,
      notifications.PFDEventNotification.FMSData,
      {"FMSFlightPlanEdited" : 1});
    emesary.GlobalTransmitter.NotifyAll(notification);
  },
  waypointsChanged : func (fp) {
    var notification = notifications.PFDEventNotification.new(
      "MFD",
      1,
      notifications.PFDEventNotification.FMSData,
      {"FMSFlightPlanEdited" : 1});
    emesary.GlobalTransmitter.NotifyAll(notification);
  },
  activated : func (fp) {
    var notification = notifications.PFDEventNotification.new(
      "MFD",
      1,
      notifications.PFDEventNotification.FMSData,
      {"FMSFlightPlanEdited" : 1});
    emesary.GlobalTransmitter.NotifyAll(notification);
  },
  cleared : func (fp) {
    var notification = notifications.PFDEventNotification.new(
      "MFD",
      1,
      notifications.PFDEventNotification.FMSData,
      {"FMSFlightPlanEdited" : 1});
      emesary.GlobalTransmitter.NotifyAll(notification);
  },
  endOfFlightPlan: func (fp) {
    var notification = notifications.PFDEventNotification.new(
      "MFD",
      1,
      notifications.PFDEventNotification.FMSData,
      {"FMSFlightPlanFinished" : 1});
    emesary.GlobalTransmitter.NotifyAll(notification);
  },
};

var dd = FMSDataDelegate.new(flightplan());

registerFlightPlanDelegate(FMSDataDelegate.new);
