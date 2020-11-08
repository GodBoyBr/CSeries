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
# Traffic Map Options
var TrafficMapOptions =
{
  new : func() {
    var obj = { parents : [TrafficMapOptions] };
    obj.Options= {};
    obj.loadOptions();
    return obj;
  },

  getOption : func(type) {
    return me.Options[type];
  },

  setOption : func(type, name, value) {
    me.Options[type][name] = value;
  },

  loadOptions : func() {
    me.clearOptions();
    me.Options.APS = {};

    me.Options.TFC = {
      ceiling_ft : 2700,  # Display targets up to this height above the aircraft
      floor_ft : 2700,    # Display target from this height below the aircraft
      display_id: 0,
    };
  },

  clearOptions : func() {
    me.Options = {};
  },

};
