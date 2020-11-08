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
# Traffic Map
#
# Functionally similar to the Garmin GTS 800 Unit
#
var TrafficMap =
{
  new : func (mfd, myCanvas, device, svg)
  {
    var obj = {
      parents : [ TrafficMap, MFDPage.new(mfd, myCanvas, device, svg, "TrafficMap", "MAP - TRAFFIC MAP") ]
    };

    obj.mapgroup = obj._group.createChild("map");

    # Dynamic text elements
    var textelements = ["OpMode", "AltMode", "OuterRange", "InnerRange"];
    obj.addTextElements(textelements);

    # Initialize the controller:
    var ctrl_ns = canvas.Map.Controller.get("Aircraft position");
    var source = ctrl_ns.SOURCES["current-pos"];
    if (source == nil) {
        # TODO: amend
        var source = ctrl_ns.SOURCES["current-pos"] = {
            getPosition: func subvec(geo.aircraft_position().latlon(), 0, 2),
            getAltitude: func getprop('/position/altitude-ft'),
            getHeading:  func {
                if (me.aircraft_heading)
                    getprop('/orientation/heading-deg')
                else 0
            },
            aircraft_heading: 1,
        };
    }
    setlistener("/sim/gui/dialogs/map-canvas/aircraft-heading-up", func(n) {
        source.aircraft_heading = n.getBoolValue();
    }, 1);
    # Make it move with our aircraft:
    obj.mapgroup.setController("Aircraft position", "current-pos"); # from aircraftpos.controller

    # Center the map's origin, modified to take into account the surround.
    obj.mapgroup.setTranslation(
      fg1000.MAP_FULL.CENTER.X,
      fg1000.MAP_FULL.CENTER.Y
    );

    var r = func(name,vis=1,zindex=nil) return caller(0)[0];
    foreach(var type; [r('TFC',0),r('APS')] ) {
        obj.mapgroup.addLayer(canvas.SymbolLayer,
                               type.name,
                               4,
                               obj.Styles.getStyle(type.name),
                               obj.Options.getOption(type.name),
                               type.vis );
    }

    obj.setController(fg1000.TrafficMapController.new(obj, svg));

    var topMenu = func(device, pg, menuitem) {
      pg.clearMenu();
      resetMenuColors(device);
      pg.addMenuItem(4, "STANDBY", pg,
        func(dev, pg, mi) { pg.getController().setOperate(0); device.updateMenus(); }, # callback
        func(svg, mi) { display_toggle(device, svg, mi, "STANDBY"); }
      );

      pg.addMenuItem(5, "OPERATE", pg,
        func(dev, pg, mi) { pg.getController().setOperate(1); device.updateMenus(); }, # callback
        func(svg, mi) { display_toggle(device, svg, mi, "OPERATE"); }
      );

      pg.addMenuItem(6, "TEST", pg, func(dev, pg, mi) { printf("Traffic Map TEST mode not implemented yet."); }, nil);
      pg.addMenuItem(7, "FLT ID", pg,
        func(dev, pg, mi) { pg.getController().toggleFlightID(); device.updateMenus(); }, # callback
        func(svg, mi) { display_toggle(device, svg, mi, "FLT ID"); }
      );

      pg.addMenuItem(8, "ALT MODE", pg, altMenu);
      device.updateMenus();
    };

    var altMenu = func(device, pg, menuitem) {
      pg.clearMenu();
      resetMenuColors(device);
      pg.addMenuItem(4, "ABOVE", pg,
        func(dev, pg, mi) { pg.getController().setAlt("ABOVE"); device.updateMenus(); }, # callback
        func(svg, mi) { display_toggle(device, svg, mi, "ABOVE"); }
      );
      pg.addMenuItem(5, "NORMAL", pg,
        func(dev, pg, mi) { pg.getController().setAlt("NORMAL"); device.updateMenus(); }, # callback
        func(svg, mi) { display_toggle(device, svg, mi, "NORMAL"); }
      );

      pg.addMenuItem(6, "BELOW", pg,
        func(dev, pg, mi) { pg.getController().setAlt("BELOW"); device.updateMenus(); }, # callback
        func(svg, mi) { display_toggle(device, svg, mi, "BELOW"); }
      );

      pg.addMenuItem(7, "UNREST", pg,
        func(dev, pg, mi) { pg.getController().setAlt("UNREST"); device.updateMenus(); }, # callback
        func(svg, mi) { display_toggle(device, svg, mi, "UNREST"); }
      );

      pg.addMenuItem(8, "BACK", pg, topMenu);

      device.updateMenus();
    };

    # Display map toggle softkeys which change color depending
    # on whether a particular layer is enabled or not.
    var display_toggle = func(device, svg, mi, layer) {
      var bg_name = sprintf("SoftKey%d-bg",mi.menu_id);
      if (obj.getController().isEnabled(layer)) {
        device.svg.getElementById(bg_name).setColorFill(0.5,0.5,0.5);
        svg.setColor(0.0,0.0,0.0);
      } else {
        device.svg.getElementById(bg_name).setColorFill(0.0,0.0,0.0);
        svg.setColor(1.0,1.0,1.0);
      }
      svg.setText(mi.title);
      svg.setVisible(1); # display function
    };

    # Function to undo any colors set by display_toggle when loading a new menu
    var resetMenuColors = func(device) {
      for(var i = 0; i < 12; i +=1) {
        var name = sprintf("SoftKey%d",i);
        device.svg.getElementById(name ~ "-bg").setColorFill(0.0,0.0,0.0);
        device.svg.getElementById(name).setColor(1.0,1.0,1.0);
      }
    }

    topMenu(device, obj, nil);

    return obj;
  },
  setLayerVisible : func(name,n=1) {
      me.mapgroup.getLayer(name).setVisible(n);
  },
  setOperate : func(enabled) {
    if (enabled) {
      me.setTextElement("OpMode", "OPERATING");
    } else {
      me.setTextElement("OpMode", "STANDBY");
    }

    me.mapgroup.getLayer("TFC").setVisible(enabled);
  },
  setRange : func(range, inner_label, outer_label) {
    me.mapgroup.setRange(range);
    me.setTextElement("OuterRange", outer_label);
    me.setTextElement("InnerRange", inner_label);
  },
  setScreenRange : func(range) {
    me.mapgroup.setScreenRange(range);
  },
  setAlt : func(floor_ft, ceiling_ft, label) {
    me.setTextElement("AltMode", label);
    # Update the TFC controller to filter out the correct targets
    me.mapgroup.getLayer("TFC").options.floor_ft =  floor_ft;
    me.mapgroup.getLayer("TFC").options.ceiling_ft = ceiling_ft;
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
};
