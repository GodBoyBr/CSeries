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
# Navigation Map
var NavigationMap =
{
  new : func (mfd, myCanvas, device, svg)
  {
    var obj = {
      parents : [
        NavigationMap,
        MFDPage.new(mfd, myCanvas, device, svg, "NavigationMap", "MAP - NAVIGATION MAP")
      ],
    };

    obj.MFDMap = fg1000.NavMap.new(
      obj,
      obj.getElement("NavMap"),
      [fg1000.MAP_FULL.CENTER.X, fg1000.MAP_FULL.CENTER.Y],
      "",
      zindex=-10);
    obj.setController(fg1000.NavigationMapController.new(obj, svg));

    return obj;
  },

  offdisplay : func(controller=1) {
    me._group.setVisible(0);
    me.getElement("NavMap").setVisible(0);
    me.getElement("NavMap-bg").setVisible(0);
    me.MFDMap.setVisible(0);

    # Reset the menu colours.  Shouldn't have to do this here, but
    # there's not currently an obvious other location to do so.
    for(var i = 0; i < 12; i +=1) {
      var name = sprintf("SoftKey%d",i);
      me.device.svg.getElementById(name ~ "-bg").setColorFill(0.0,0.0,0.0);
      me.device.svg.getElementById(name).setColor(1.0,1.0,1.0);
    }
    if (controller == 1) me.getController().offdisplay();
  },
  ondisplay : func(controller=1) {
    me._group.setVisible(1);
    me.getElement("Group").setVisible(1);
    me.getElement("NavMap").setVisible(1);
    me.getElement("NavMap-bg").setVisible(1);
    me.getElement("Legend").setVisible(1);
    me.MFDMap.setVisible(1);

    # Center the map's origin, modified to take into account the surround.
    me.getElement("NavMap").setTranslation(
      fg1000.MAP_FULL.CENTER.X,
      fg1000.MAP_FULL.CENTER.Y
    );

    me.getElement("Legend").setTranslation(0,0);

    me.mfd.setPageTitle(me.title);
    if (controller == 1) me.getController().ondisplay();
  },

  # Display functions when we're displaying the NavigationMap as part of another
  # page - e.g. NearestAirports.
  ondisplayPartial : func() {
    me._group.setVisible(1);
    me.getElement("Group").setVisible(1);
    me.getElement("NavMap").setVisible(1);
    me.getElement("NavMap-bg").setVisible(1);
    me.getElement("Legend").setVisible(1);
    me.MFDMap.setVisible(1);

    # Center the map's origin, modified to take into account the surround.
    me.getElement("NavMap").setTranslation(
      fg1000.MAP_PARTIAL.CENTER.X,
      fg1000.MAP_PARTIAL.CENTER.Y
    );

    me.getElement("Legend").setTranslation(-300,0);
  },
  offdisplayPartial : func() {
    me._group.setVisible(0);
    me.getElement("Group").setVisible(0);
    me.getElement("NavMap").setVisible(0);
    me.getElement("NavMap-bg").setVisible(0);
    me.getElement("Legend").setVisible(0);
    me.MFDMap.setVisible(0);
    #me.getController().offdisplayPartial();
  },

  # Softkey assigments.  For some pages (notably the NEAREST pages)
  # the MAP softkey is available as key 2:
  # pg.addMenuItem(2, "MAP", pg, pg.mfd.NavigationMap.mapMenu);


  topMenu : func(device, pg, menuitem) {
    pg.clearMenu();
    pg.resetMenuColors();
    pg.addMenuItem(0, "ENGINE", pg, pg.mfd.EIS.engineMenu);
    pg.addMenuItem(2, "MAP", pg, pg.mfd.NavigationMap.mapMenu);
    pg.addMenuItem(8, "DCLTR", pg, func(dev, pg, mi) { pg.mfd.NavigationMap.MFDMap.incrDCLTR(dev, mi); } );
    #pg.addMenuItem(9, "SHW CHRT", pg);  # Optional
    #pg.addMenuItem(10, "CHKLIST", pg);  # Optional
    device.updateMenus();
  },

  mapMenu : func(device, pg, menuitem) {
    pg.clearMenu();
    pg.resetMenuColors();
    pg.addMenuItem(0, "TRAFFIC", pg,
      func(dev, pg, mi) { pg.mfd.NavigationMap.MFDMap.toggleLayer("TFC"); device.updateMenus(); }, # callback
      func(svg, mi) { pg.mfd.NavigationMap.display_toggle(device, svg, mi, "TFC"); }
    );

    pg.addMenuItem(1, "PROFILE", pg);
    pg.addMenuItem(2, "TOPO", pg,
      func(dev, pg, mi) { pg.mfd.NavigationMap.MFDMap.toggleLayer("STAMEN"); device.updateMenus(); }, # callback
      func(svg, mi) { pg.mfd.NavigationMap.display_toggle(device, svg, mi, "STAMEN"); }
    );

    pg.addMenuItem(3, "TERRAIN", pg,
      func(dev, pg, mi) { pg.mfd.NavigationMap.MFDMap.toggleLayer("STAMEN_terrain"); device.updateMenus(); }, # callback
      func(svg, mi) { pg.mfd.NavigationMap.display_toggle(device, svg, mi, "STAMEN_terrain"); }
    );

    pg.addMenuItem(4, "AIRWAYS", pg, func(dev, pg, mi) { pg.mfd.NavigationMap.MFDMap.incrAIRWAYS(dev, mi); } );
    #pg.addMenuItem(5, "STRMSCP", pg); Optional
    #pg.addMenuItem(6, "PRECIP", pg); Optional, or NEXRAD
    #pg.addMenuItem(7, "XM LTNG", pg); Optional, or DL LTNG
    #pg.addMenuItem(8, "METAR", pg);
    #pg.addMenuItem(9, "LEGEND", pg); Optional - only available with NEXRAD/XM LTNG/METAR/PROFILE selected
    pg.addMenuItem(10, "BACK", pg, pg.topMenu);  # Or should this just be the next button?
    device.updateMenus();
  },

  # Display map toggle softkeys which change color depending
  # on whether a particular layer is enabled or not.
  display_toggle : func(device, svg, mi, layer) {
    var bg_name = sprintf("SoftKey%d-bg",mi.menu_id);
    if (me.MFDMap.isEnabled(layer)) {
      device.svg.getElementById(bg_name).setColorFill(0.5,0.5,0.5);
      svg.setColor(0.0,0.0,0.0);
    } else {
      device.svg.getElementById(bg_name).setColorFill(0.0,0.0,0.0);
      svg.setColor(1.0,1.0,1.0);
    }
    svg.setText(mi.title);
    svg.setVisible(1); # display function
  },

};
