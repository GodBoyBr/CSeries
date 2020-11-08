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
# Emesary interface to publish autopilot configuration.
#

var GFC700Publisher = {

new : func ()
{
  var obj = { parents : [
    GFC700Publisher,
    TriggeredPropertyPublisher.new(notifications.PFDEventNotification.FMSData) ] };

  obj.addPropMap("AutopilotEnabled", "/autopilot/annunciator/autopilot-enabled");
  obj.addPropMap("AutopilotFDEnabled", "/autopilot/annunciator/flight-director-enabled");
  obj.addPropMap("AutopilotHeadingMode", "/autopilot/annunciator/lateral-mode");
  obj.addPropMap("AutopilotHeadingModeArmed", "/autopilot/annunciator/lateral-mode-armed");
  obj.addPropMap("AutopilotAltitudeMode", "/autopilot/annunciator/vertical-mode");
  obj.addPropMap("AutopilotAltitudeModeArmed", "/autopilot/annunciator/vertical-mode-armed");
  obj.addPropMap("AutopilotTargetPitch", "/autopilot/settings/target-pitch-deg");
  obj.addPropMap("AutopilotTargetRoll", "/autopilot/settings/target-roll-deg");
  obj.addPropMap("AutopilotTargetSpeed", "/autopilot/settings/target-speed-kt");
  obj.addPropMap("AutopilotTargetVertical", "/autopilot/annunciator/vertical-mode-target");

  return obj;
},

};
