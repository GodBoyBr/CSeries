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
# FG1000 MFD

var MFDPages = [
  "NavigationMap",
  "TrafficMap",
  "Stormscope",
  "WeatherDataLink",
  "TAWSB",
  "AirportInfo",
  "AirportDirectory",
  "AirportDeparture",
  "AirportArrival",
  "AirportApproach",
  "AirportWeather",
  "IntersectionInfo",
  "NDBInfo",
  "VORInfo",
  "UserWPTInfo",
  "TripPlanning",
  "Utility",
  "GPSStatus",
  "XMRadio",
  "XMInfo",
  "SystemStatus",
  "ActiveFlightPlanNarrow",
  "ActiveFlightPlanWide",
  "FlightPlanCatalog",
  "StoredFlightPlan",
  "Checklist",
  "NearestAirports",
  "NearestIntersections",
  "NearestNDB",
  "NearestVOR",
  "NearestUserWPT",
  "NearestFrequencies",
  "NearestAirspaces",
  "WaypointEntry",
  "DirectTo",
  "Surround",
];

var nasal_dir = getprop("/sim/fg-root") ~ "/Aircraft/Instruments-3d/FG1000/Nasal/";

foreach (var page; MFDPages) {
  io.load_nasal(nasal_dir ~ "MFDPages/" ~ page ~ '/' ~ page ~ '.nas', "fg1000");
  io.load_nasal(nasal_dir ~ "MFDPages/" ~ page ~ '/' ~ page ~ 'Styles.nas', "fg1000");
  io.load_nasal(nasal_dir ~ "MFDPages/" ~ page ~ '/' ~ page ~ 'Options.nas', "fg1000");
  io.load_nasal(nasal_dir ~ "MFDPages/" ~ page ~ '/' ~ page ~ 'Controller.nas', "fg1000");
}

var MFDDisplay =
{
  new : func (fg1000instance, EIS_Class, EIS_SVG, myCanvas, device_id=1)
  {
    var obj = {
      parents : [ MFDDisplay ],
      EIS : nil,
      NavigationMap: nil,
      Surround : nil,
      _pageList : {},
      _fg1000 : fg1000instance,
      _canvas : myCanvas,
    };

    obj.ConfigStore = obj._fg1000.getConfigStore();

    obj._svg = myCanvas.createGroup("softkeys");
    obj._svg.set("clip-frame", canvas.Element.LOCAL);
    obj._svg.set("clip", "rect(0px, 1024px, 768px, 0px)");

    var fontmapper = func (family, weight) {
      #if( family == "Liberation Sans" and weight == "narrow" ) {
        return "LiberationFonts/LiberationSansNarrow-Regular.ttf";
      #}
      # If we don't return anything the default font is used
    };


    foreach (var page; MFDPages) {
      var svg_file ='/Aircraft/Instruments-3d/FG1000/MFDPages/' ~ page ~ '.svg';
      if (resolvepath(svg_file) != "") {
        # Load an SVG file if available.
        canvas.parsesvg(obj._svg,
                        svg_file,
                        {'font-mapper': fontmapper});
      }
    }

    canvas.parsesvg(obj._svg,
                    EIS_SVG,
                    {'font-mapper': fontmapper});

    obj._MFDDevice = canvas.PFD_Device.new(obj._svg, 12, "SoftKey", myCanvas, "MFD");
    obj._MFDDevice.device_id = device_id;

    # DirectTo "Page" loaded first so that it receives any Emesary notifications
    # _before_ the actual page.
    obj._DTO = fg1000.DirectTo.new(obj, myCanvas, obj._MFDDevice, obj._svg);
    obj._DTO.getController().RegisterWithEmesary();

    # Next, the WaypointEntry "Page" so that it too receives any Emesary notifications
    # _before_ the actual page.
    obj._WaypointEntry = fg1000.WaypointEntry.new(obj, myCanvas, obj._MFDDevice, obj._svg);
    obj._WaypointEntry.getController().RegisterWithEmesary();

    obj._MFDDevice.RegisterWithEmesary();

    # Surround dynamic elements
    obj._pageTitle = obj._svg.getElementById("PageTitle");

    # Controller for the header and display on the bottom left which allows selection
    # of page groups and individual pages using the FMS controller.
    obj.Surround = fg1000.Surround.new(obj, myCanvas, obj._MFDDevice, obj._svg);
    obj.SurroundController = obj.Surround.getController();

    # Engine Information System.  A special case as it's always displayed on the MFD.
    # Note that it is passed in on the constructor
    obj.EIS = EIS_Class.new(obj, myCanvas, obj._MFDDevice, obj._svg);
    obj.addPage("EIS", obj.EIS);

    # The NavigationMap page is a special case, as it is displayed with the Nearest... pages as an overlay
    obj.NavigationMap = fg1000.NavigationMap.new(obj, myCanvas, obj._MFDDevice, obj._svg);
    obj.addPage("NavigationMap", obj.NavigationMap);
    obj.NavigationMap.topMenu(obj._MFDDevice, obj.NavigationMap, nil);

    # Now load the other pages normally;
    foreach (var page; MFDPages) {
      if ((page != "NavigationMap") and (page != "EIS") and (page != "DirectTo") and (page != "WaypointEntry")) {
        #var code = "obj.Surround.addPage(\"" ~ page ~ "\", fg1000." ~ page ~ ".new(obj, myCanvas, obj._MFDDevice, obj._svg));";
        var code = "obj.addPage(\"" ~ page ~ "\", fg1000." ~ page ~ ".new(obj, myCanvas, obj._MFDDevice, obj._svg));";
        var addPageFn = compile(code);
        addPageFn();
      }
    }

    # Display the Surround, EIS and NavMap and the appropriate top level on startup.
    obj.Surround.setVisible(1);
    obj.EIS.setVisible(1);
    obj.EIS.ondisplay();
    obj._MFDDevice.selectPage(obj.NavigationMap);

    return obj;
  },
  getDevice : func () {
    return me._MFDDevice;
  },
  del: func()
  {
    me._MFDDevice.current_page.offdisplay();
    me._MFDDevice.DeRegisterWithEmesary();
    me.SurroundController.del();

  },
  setPageTitle: func(title)
  {
    me._pageTitle.setText(title);
  },
  addPage : func(name, page)
  {
    me._pageList[name] = page;
  },

  getPage : func(name)
  {
    return me._pageList[name];
  },

  getDeviceID : func() {
    return me._MFDDevice.device_id;
  },

  getCanvas : func() {
    return me._canvas;
  }
};
