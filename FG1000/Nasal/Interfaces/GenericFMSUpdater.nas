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
# FMS Interface using Emesary to update FMS properties from Emesary messages.

var GenericFMSUpdater =
{
  new : func () {
    var obj = {
      parents : [
        GenericFMSUpdater,
        PropertyUpdater.new(
          notifications.PFDEventNotification.DefaultType,
          notifications.PFDEventNotification.FMSData,
        )
      ],
    };

    obj.addPropMap("FMSHeadingBug", "/autopilot/settings/heading-bug-deg");
    obj.addPropMap("FMSSelectedAlt", "/autopilot/settings/target-alt-ft");
    obj.addPropMap("FMSPressureSettingInHG", "/instrumentation/altimeter/setting-inhg");
    return obj;
  },
};
