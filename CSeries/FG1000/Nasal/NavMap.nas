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
# Common Navigation map functions
var NavMap = {

  # Declutter levels.
  DCLTR : [ "DCLTR", "DCLTR-1", "DCLTR-2", "DCLTR-3"],

  # Airways levels.
  AIRWAYS : [ "AIRWAYS", "AIRWY ON", "AIRWY LO", "AIRWY HI"],

  # Lazy-loading - only create the map element when the page becomes visible,
  # and delete afterwards.
  LAZY_LOADING : 1,

  new : func(page, element, center, clip="", zindex=0, vis_shift=0, static=0 )
  {
    var obj = {
      parents : [ NavMap ],
      _group : page.getGroup(),
      _svg : page.getSVG(),
      _page : page,
      _pageName : page.getPageName(),
      _element : element,
      _center : center,
      _clip : clip,
      _zindex : zindex,
      _vis_shift : vis_shift,
      _static : static,
      _current_zoom : 13,
      _declutter : 0,
      _airways : 0,
      _map : nil,
    };

    element.setTranslation(center[0], center[1]);

    obj.Styles = fg1000.NavigationMapStyles.new();
    obj.Options = fg1000.NavigationMapOptions.new();

    obj._rangeDisplay = obj._svg.getElementById(obj._pageName ~ "RangeDisplay");
    if (obj._rangeDisplay == nil) die("Unable to find element " ~ obj._pageName ~ "RangeDisplay");

    obj._orientationDisplay = obj._svg.getElementById(obj._pageName ~ "OrientationDisplay");
    if (obj._orientationDisplay == nil) die("Unable to find element " ~ obj._pageName ~ "OrientationDisplay");

    if (NavMap.LAZY_LOADING == 0) {
      obj.createMapElement();
      obj._map.setVisible(0);
    }

    return obj;
  },

  # Create the map element itself.  Depending on whether we are doing lazy loading
  # or not, this may be called by the constructor, or when the NavMap is made visible.
  createMapElement : func() {

    if (me._map != nil) return;

    me._map = me._element.createChild("map");
    me._map.setScreenRange(689/2.0);

    # Initialize the controllers:
    if (me._static) {
      me._map.setController("Static position", "main");
    } else {
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
        setlistener("/sim/gui/dialogs/map-canvas/aircraft-heading-up", func(n) {
          source.aircraft_heading = n.getBoolValue();
        }, 1);
      }
      # Make it move with our aircraft:
      me._map.setController("Aircraft position", "current-pos"); # from aircraftpos.controller
    }

    if (me._clip != "") {
      me._map.set("clip-frame", canvas.Element.LOCAL);
      me._map.set("clip", me._clip);
    }

    if (me._zindex != 0) {
      me._element.setInt("z-index", me._zindex);
    }

    var r = func(name,on_static=1, vis=1,zindex=nil) return caller(0)[0];
    # TODO: we'll need some z-indexing here, right now it's just random
    foreach (var layer_name; me._page.mfd.ConfigStore.getLayerNames()) {
      var layer = me._page.mfd.ConfigStore.getLayer(layer_name);

      if ((me._static == 0) or (layer.static == 1)) {
        # Not all layers are displayed for all map types.  Specifically,
        # some layers are not displayed on static maps - e.g. DirectTo
        me._map.addLayer(
          factory: layer.factory,
          type_arg: layer_name,
          priority: layer.priority,
          style: me.Styles.getStyle(layer_name),
          options: me.Options.getOption(layer_name),
          visible: 0);
      }
    }

    me.setZoom(me._current_zoom);
    me.setOrientation(0);
  },

  setController : func(type, controller ) {
    if (NavMap.LAZY_LOADING) me.createMapElement();
    me._map.setController(type, controller);
  },

  getController : func() {
    if (NavMap.LAZY_LOADING) me.createMapElement();
    return me._map.getController();
  },

  toggleLayerVisible : func(name) {
    if (NavMap.LAZY_LOADING) me.createMapElement();
    (var l = me._map.getLayer(name)).setVisible(l.getVisible());
  },

  setLayerVisible : func(name,n=1) {
    if (NavMap.LAZY_LOADING) me.createMapElement();
    me._map.getLayer(name).setVisible(n);
  },

  setOrientation : func(orientation) {
    # TODO - implment this
    me._orientationDisplay.setText(fg1000.ORIENTATIONS[orientation].label);
  },

  setScreenRange : func(range) {
    if (NavMap.LAZY_LOADING) me.createMapElement();
    me._map.setScreenRange(range);
  },

  zoomIn : func() {
    me.setZoom(me._current_zoom -1);
  },

  zoomOut : func() {
    me.setZoom(me._current_zoom +1);
  },

  setZoom : func(zoom) {
    if (NavMap.LAZY_LOADING) me.createMapElement();
    if ((zoom < 0) or (zoom > (size(fg1000.RANGES) - 1))) return;
    me._current_zoom = zoom;
    me._rangeDisplay.setText(fg1000.RANGES[zoom].label);
    me._map.setRange(fg1000.RANGES[zoom].range);
    me.updateVisibility();
  },

  updateVisibility : func() {
    if (NavMap.LAZY_LOADING) me.createMapElement();
    # Determine which layers should be visible.
    foreach (var layer_name; me._page.mfd.ConfigStore.getLayerNames()) {
      var layer = me._page.mfd.ConfigStore.getLayer(layer_name);

      if (me._map.getLayer(layer_name) == nil) continue;

      # Layers are only displayed if:
      # 1) the user has enabled them.
      # 2) The current zoom level is _less_ than the maximum range for the layer
      #    (i.e. as the range gets larger, we remove layers).  Note that for
      #     inset maps, the range that items are removed is lower.
      # 3) They haven't been removed due to the declutter level.
      var effective_zoom = math.clamp(me._current_zoom + me._vis_shift, 0, size(fg1000.RANGES) -1);
      var effective_range = fg1000.RANGES[effective_zoom].range;
      if (layer.enabled and
          (effective_range <= layer.range) and
          (me._declutter <= layer.declutter)    )
      {
        me._map.getLayer(layer_name).setVisible(1);
      } else {
        me._map.getLayer(layer_name).setVisible(0);
      }
    }
  },

  isEnabled : func(layer) {
    return me._page.mfd.ConfigStore.isLayerEnabled(layer);
  },

  toggleLayer : func(layer) {
    me._page.mfd.ConfigStore.toggleLayerEnabled(layer);
    me.updateVisibility();
  },

  # Increment through the de-clutter levels, which impact what layers are
  # displayed.  We also need to update the declutter menu item.
  incrDCLTR : func(device, menuItem) {
    me._declutter = math.mod(me._declutter +1, 4);
    me.updateVisibility();
    return me.DCLTR[me._declutter];
  },

  getDCLTRTitle : func() {
    return me.DCLTR[me._declutter];
  },

  # Increment through the AIRWAYS levels.  At present this doesn't do anything
  # except change the label.  It should enable/disable different airways
  # information.
  incrAIRWAYS : func(device, menuItem) {
    me._airways = math.mod(me._airways +1, 4);
    me.updateVisibility();
    return me.AIRWAYS[me._airways];
  },

  getAIRWAYSTitle : func() {
    return me.AIRWAYS[me._airways];
  },

  # Set the DTO line target
  setDTOLineTarget : func(lat, lon) {
    if (NavMap.LAZY_LOADING) me.createMapElement();
    me._map.getLayer("DTO").controller.setTarget(lat,lon);
  },
  enableDTO : func(enable) {
    me._page.mfd.ConfigStore.setLayerEnabled("DTO", enable);
    me.updateVisibility();
  },

  handleRange : func(val)
  {
    if (val >0) {
      me.zoomOut();
    } else {
      me.zoomIn();
    }
    return emesary.Transmitter.ReceiptStatus_OK;
  },

  getMap : func() {
    if (NavMap.LAZY_LOADING) me.createMapElement();
    return me._map;
  },
  show : func() {
    if (NavMap.LAZY_LOADING) me.createMapElement();
    me._map.show();
  },
  hide : func() {
    if (me._map != nil) me._map.hide();
    if (NavMap.LAZY_LOADING) me._map = nil;
  },
  setVisible : func(visible) {
    if (visible) {
      if (NavMap.LAZY_LOADING) me.createMapElement();
      me._map.setVisible(visible);
    } else {
      if (me._map != nil) me._map.setVisible(visible);
      if (NavMap.LAZY_LOADING) me._map = nil;
    }
  },
};
