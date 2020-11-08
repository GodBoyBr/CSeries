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
# NearestUserWPT
var NearestUserWPT =
{
  new : func (mfd, myCanvas, device, svg)
  {
    var obj = {
      parents : [
        NearestUserWPT,
        MFDPage.new(mfd, myCanvas, device, svg, "NearestUserWPT", "NRST - NEAREST USER WPTS")
      ],
    };

    obj.topMenu(device, obj, nil);

    obj.setController(fg1000.NearestUserWPTController.new(obj, svg));

    return obj;
  },
  offdisplay : func() {
    me._group.setVisible(0);

    # Reset the menu colours.  Shouldn't have to do this here, but
    # there's not currently an obvious other location to do so.
    for(var i = 0; i < 12; i +=1) {
      var name = sprintf("SoftKey%d",i);
      me.device.svg.getElementById(name ~ "-bg").setColorFill(0.0,0.0,0.0);
      me.device.svg.getElementById(name).setColor(1.0,1.0,1.0);
    }
    me.getController().offdisplay();
  },
  ondisplay : func() {
    me._group.setVisible(1);
    me.mfd.setPageTitle(me.title);
    me.getController().ondisplay();
  },
  topMenu : func(device, pg, menuitem) {
    pg.clearMenu();
    pg.resetMenuColors();
    device.updateMenus();
  },


};
