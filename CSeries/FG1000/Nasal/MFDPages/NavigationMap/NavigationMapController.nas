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
# Navigation Map Controller
var NavigationMapController =
{
  new : func (page, svg)
  {
    var obj = { parents : [ NavigationMapController, MFDPageController.new(page) ] };
    obj.page = page;
    return obj;
  },

  # Set the DTO line target
  setDTOLineTarget : func(lat, lon) {
    me.page.MFDMap.setDTOLineTarget(lat, lon);
  },
  enableDTO : func(enable) {
    me.page.MFDMap.enableDTO(enable)
  },

  handleRange : func(val)
  {
    me.page.MFDMap.handleRange(val);
  },

  # Reset controller if required when the page is displayed or hidden
  ondisplay : func() {
    me.RegisterWithEmesary();
  },
  offdisplay : func() {
    me.DeRegisterWithEmesary();
  },
};
