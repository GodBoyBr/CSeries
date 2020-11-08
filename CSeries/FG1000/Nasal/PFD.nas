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
# FG1000 PFD

var PFDDisplay =
{
  new : func (fg1000instance, EIS_Class, EIS_SVG, myCanvas, device_id=1)
  {
    var obj = {
      parents : [ PFDDisplay ],
      EIS : nil,
      PFDInstruments : nil,
      Surround : nil,
      NearestAirports : nil,
      _pageList : {},
      _fg1000 : fg1000instance,
      _canvas : myCanvas,
    };

    var nasal_dir = getprop("/sim/fg-root") ~ "/Aircraft/Instruments-3d/FG1000/Nasal/";
    io.load_nasal(nasal_dir ~ "MFDPages/PFDInstruments/PFDInstruments.nas", "fg1000");
    io.load_nasal(nasal_dir ~ "MFDPages/PFDInstruments/PFDInstrumentsStyles.nas", "fg1000");
    io.load_nasal(nasal_dir ~ "MFDPages/PFDInstruments/PFDInstrumentsOptions.nas", "fg1000");
    io.load_nasal(nasal_dir ~ "MFDPages/PFDInstruments/PFDInstrumentsController.nas", "fg1000");

    io.load_nasal(nasal_dir ~ "MFDPages/DirectTo/DirectTo.nas", "fg1000");
    io.load_nasal(nasal_dir ~ "MFDPages/DirectTo/DirectToController.nas", "fg1000");

    io.load_nasal(nasal_dir ~ "MFDPages/NearestAirportsPFD/NearestAirportsPFD.nas", "fg1000");
    io.load_nasal(nasal_dir ~ "MFDPages/NearestAirportsPFD/NearestAirportsPFDStyles.nas", "fg1000");
    io.load_nasal(nasal_dir ~ "MFDPages/NearestAirportsPFD/NearestAirportsPFDOptions.nas", "fg1000");
    io.load_nasal(nasal_dir ~ "MFDPages/NearestAirportsPFD/NearestAirportsPFDController.nas", "fg1000");

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

    canvas.parsesvg(obj._svg,
                    EIS_SVG,
                    {'font-mapper': fontmapper});


    canvas.parsesvg(obj._svg,
                    '/Aircraft/Instruments-3d/FG1000/MFDPages/PFDInstruments.svg',
                    {'font-mapper': fontmapper});

    canvas.parsesvg(obj._svg,
                    '/Aircraft/Instruments-3d/FG1000/MFDPages/FlightPlanPFD.svg',
                    {'font-mapper': fontmapper});


    canvas.parsesvg(obj._svg,
                    '/Aircraft/Instruments-3d/FG1000/MFDPages/DirectToPFD.svg',
                    {'font-mapper': fontmapper});

    canvas.parsesvg(obj._svg,
                    '/Aircraft/Instruments-3d/FG1000/MFDPages/NearestAirportsPFD.svg',
                    {'font-mapper': fontmapper});

    canvas.parsesvg(obj._svg,
                    '/Aircraft/Instruments-3d/FG1000/MFDPages/NearestAirportsInfoPFD.svg',
                    {'font-mapper': fontmapper});

    canvas.parsesvg(obj._svg,
                    '/Aircraft/Instruments-3d/FG1000/MFDPages/SurroundPFD.svg',
                    {'font-mapper': fontmapper});


    obj._MFDDevice = canvas.PFD_Device.new(obj._svg, 12, "SoftKey", myCanvas, "PFD");
    obj._MFDDevice.device_id = device_id;

    # DirectTo "Page" loaded first so that it receives any Emesary notifications
    # _before_ the actual page.
    obj._DTO = fg1000.DirectTo.new(obj, myCanvas, obj._MFDDevice, obj._svg);
    obj._DTO.getController().RegisterWithEmesary();

    obj.NearestAirports = fg1000.NearestAirportsPFD.new(obj, myCanvas, obj._MFDDevice, obj._svg);

    obj._MFDDevice.RegisterWithEmesary();

    # Surround dynamic elements
    obj._pageTitle = obj._svg.getElementById("PageTitle");

    # Controller for the header and display on the bottom left which allows selection
    # of page groups and individual pages using the FMS controller.
    obj.Surround = fg1000.Surround.new(obj, myCanvas, obj._MFDDevice, obj._svg, 1);
    obj.SurroundController = obj.Surround.getController();

    obj.PFDInstruments = fg1000.PFDInstruments.new(obj, myCanvas, obj._MFDDevice, obj._svg);
    obj.addPage("PFDInstruments", obj.PFDInstruments);
    obj.PFDInstruments.topMenu(obj._MFDDevice, obj.PFDInstruments, nil);

    # Display the Surround, and PFD Instruments
    obj.Surround.setVisible(1);
    obj._MFDDevice.selectPage(obj.PFDInstruments);

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
