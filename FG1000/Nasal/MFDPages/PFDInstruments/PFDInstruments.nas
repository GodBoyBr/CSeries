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
# PFDInstruments
var PFDInstruments =
{

  COLORS : {
      green : [0, 1, 0],
      white : [1, 1, 1],
      black : [0, 0, 0],
      lightblue : [0, 1, 1],
      darkblue : [0, 0, 1],
      red : [1, 0, 0],
      magenta : [1, 0, 1],
  },

  new : func (mfd, myCanvas, device, svg)
  {
    var obj = {
      parents : [
        PFDInstruments,
        MFDPage.new(mfd, myCanvas, device, svg, "PFDInstruments", "PFD Instruments")
      ],

      _ias_already_exceeded : 0,
      _windDataDisplay : 0,
      _BRG1 : "OFF",
      _BRG2 : "OFF",
      _DME : 0,
      _OMI : "",
      _Multiline : 0,
      _annunciation : 0,
      _fd_enabled : 1,  # Mark the Flight Director as enabled, as it is visible in the SVG.
      _selected_spd : 0,
      _selected_spd_visible : 0,
    };

    # Hide various elements for the moment. TODO - implement
    obj.device.svg.getElementById("PFDInstrumentsFailures").setVisible(0);
    obj.device.svg.getElementById("PFDInstrumentsGSPD").setVisible(0);

    obj.addTextElements([
      "Speed110",
      "VSIText",
      "TAS-text", "GSPD-text",
      "Alt11100",
      "AltBigC",  "AltSmallC",
      "BARO-text", "OAT-text",
      "HDG-text",
      "SelectedHDG-text",
      "SelectedALT-text",
      "SelectedSPD-text",
      "XPDR-DIGIT-3-text", "XPDR-DIGIT-2-text", "XPDR-DIGIT-1-text", "XPDR-DIGIT-0-text",
      "XPDR-MODE-text",
      "TIME-text",
      "GS-type",
      "MarkerText",
    ]);

    # Set clipping for the various tapes
    var clips = {
        PitchScale   : "rect(70,664,370,256)",
        SpeedLint1   : "rect(252,226,318,204)",
        SpeedTape    : "rect(115,239,455,156)",
        LintAlt      : "rect(115,808,455,704)",
        AltLint00011 : "rect(252,804,318,771)",
    };

    foreach(var id; keys(clips)) {
      var clip = clips[id];
      obj.device.svg.getElementById("PFDInstruments" ~ id).set("clip", clip);
    }

    obj._SVGGroup.setInt("z-index", 10);
    obj.insetMap = fg1000.NavMap.new(obj, obj.getElement("PFD-Map-Display"), [119,601], "rect(-109px, 109px, 109px, -109px)", 0, 2);

    # Flight Plan Window group
    obj.flightplanList = PFD.GroupElement.new(
      obj.pageName,
      svg,
      [ "FlightPlanArrow", "FlightPlanID", "FlightPlanType", "FlightPlanDTK", "FlightPlanDIS"],
      5,
      "FlightPlanArrow",
      1,
      "FlightPlanScrollTrough",
      "FlightPlanScrollThumb",
      120
    );

    obj.setController(fg1000.PFDInstrumentsController.new(obj, svg));

    obj.setWindDisplay(0);
    obj.setCDISource("GPS");
    obj.setBRG1("OFF");
    obj.setBRG2("OFF");
    obj.setDME(0);
    obj.setMultiline(0);
    obj.setAnnunciation(0);
    obj.setOMI("");
    obj.setInsetMapVisible(0);
    obj.updateHDG(0);
    obj.updateSelectedALT(0);
    obj.updateCRS(0);
    obj.setFlightPlanVisible(0);

    return obj;
  },

  topMenu : func(device, pg, menuitem) {
    pg.clearMenu();
    pg.resetMenuColors();
    pg.addMenuItem(1, "INSET", pg, pg.mfd.PFDInstruments.insetMenu);
    pg.addMenuItem(3, "PFD", pg, pg.mfd.PFDInstruments.PFDMenu);
    pg.addMenuItem(4, "OBS", pg); # TODO
    pg.addMenuItem(5, "CDI", pg,  func(dev, pg, mi) { pg.getController().incrCDISource(); } );
    #pg.addMenuItem(6, "DME", pg, func(dev, pg, mi) { pg.toggleDME(); } ); # TODO
    pg.addMenuItem(7, "XPDR", pg, pg.mfd.PFDInstruments.transponderMenu);
    pg.addMenuItem(8, "IDENT", pg, pg.mfd.PFDInstruments.setIdent); # TODO
    pg.addMenuItem(9, "TMR/REF", pg); # TODO
    pg.addMenuItem(10, "NRST", pg, pg.mfd.PFDInstruments.toggleNRST, func(svg, mi) { pg.mfd.PFDInstruments.toggleNRSTDisplay(device, pg, svg, mi); }  );
    pg.addMenuItem(11, "ALERTS", pg); # TODO
    device.updateMenus();
  },

  toggleNRST : func (device, pg, mi) {
    pg.mfd.NearestAirports.toggleDisplay();
    device.updateMenus();
  },

  toggleNRSTDisplay : func(device, pg, svg, mi) {
    var bg_name = sprintf("SoftKey%d-bg",mi.menu_id);
    if (pg.mfd.NearestAirports.visible()) {
      device.svg.getElementById(bg_name).setColorFill(0.5,0.5,0.5);
      svg.setColor(0.0,0.0,0.0);
    } else {
      device.svg.getElementById(bg_name).setColorFill(0.0,0.0,0.0);
      svg.setColor(1.0,1.0,1.0);
    }
    svg.setText(mi.title);
    svg.setVisible(1); # display function
  },

  insetMenu : func(device, pg, menuitem) {
    # Switch on the inset Map
    pg.setInsetMapVisible(1);

    pg.clearMenu();
    pg.resetMenuColors();
    pg.addMenuItem(0, "OFF", pg, func(dev, pg, mi) { pg.setInsetMapVisible(0); pg.mfd.PFDInstruments.topMenu(dev, pg, mi); } );
    pg.addMenuItem(1, "DCLTR", pg,
      func(dev, pg, mi) { pg.insetMap.incrDCLTR(dev, mi); device.updateMenus(); },
      func(svg, mi) { pg.displayDCLTR(svg, mi); },
      );
    #pg.addMenuItem(2, "WXLGND", pg); # Optional

    # TODO: Support TRFC-1 to add traffic layer, TRFC-2 to just display a traffic map
    pg.addMenuItem(3, "TRAFFIC", pg,
      func(dev, pg, mi) { pg.insetMap.toggleLayer("TFC"); device.updateMenus(); }, # callback
      func(svg, mi) { pg.display_toggle(device, svg, mi, "TFC"); }
    );

    pg.addMenuItem(4, "TOPO", pg,
      func(dev, pg, mi) { pg.insetMap.toggleLayer("STAMEN"); device.updateMenus(); }, # callback
      func(svg, mi) { pg.display_toggle(device, svg, mi, "STAMEN"); }
    );

    pg.addMenuItem(5, "TERRAIN", pg,
      func(dev, pg, mi) { pg.insetMap.toggleLayer("STAMEN_terrain"); device.updateMenus(); }, # callback
      func(svg, mi) { pg.display_toggle(device, svg, mi, "STAMEN_terrain"); }
    );
    #pg.addMenuItem(6, "STRMSCP", pg); # TODO
    #pg.addMenuItem(7, "NEXRAD", pg); # TODO
    #pg.addMenuItem(8, "XM LTNG", pg); # TODO
    #pg.addMenuItem(9, "METAR", pg); # TODO
    pg.addMenuItem(10, "BACK", pg, pg.mfd.PFDInstruments.topMenu);
    pg.addMenuItem(11, "ALERTS", pg); # TODO
    device.updateMenus();
  },

  displayDCLTR : func(svg, mi) {
    mi.title = me.insetMap.getDCLTRTitle();
    svg.setText(mi.title);
    svg.setVisible(1);
  },

  # Display map toggle softkeys which change color depending
  # on whether a particular layer is enabled or not.
  display_toggle : func(device, svg, mi, layer) {
    var bg_name = sprintf("SoftKey%d-bg",mi.menu_id);
    if (me.insetMap.isEnabled(layer)) {
      device.svg.getElementById(bg_name).setColorFill(0.5,0.5,0.5);
      svg.setColor(0.0,0.0,0.0);
    } else {
      device.svg.getElementById(bg_name).setColorFill(0.0,0.0,0.0);
      svg.setColor(1.0,1.0,1.0);
    }
    svg.setText(mi.title);
    svg.setVisible(1); # display function
  },

  PFDMenu : func(device, pg, menuitem) {
    pg.clearMenu();
    pg.resetMenuColors();
    pg.addMenuItem(0, "SYN VIS", pg);  # TODO
    pg.addMenuItem(1, "DFLTS", pg);
    pg.addMenuItem(2, "WIND", pg, pg.mfd.PFDInstruments.windMenu);
    #pg.addMenuItem(3, "DME", pg); # TODO
    pg.addMenuItem(4, "BRG1", pg, func(dev, pg, mi) { pg.getController().incrBRG1(); });
    pg.addMenuItem(5, "HSI FRMT", pg); # TODO
    pg.addMenuItem(6, "BRG2", pg, func(dev, pg, mi) { pg.getController().incrBRG2(); });
    pg.addMenuItem(8, "ALT UNIT ", pg); # TODO
    pg.addMenuItem(9, "STD BARO", pg, func(dev, pg, mi) { pg.getController().setStdBaro(); } );
    pg.addMenuItem(10, "BACK", pg, pg.mfd.PFDInstruments.topMenu);
    pg.addMenuItem(11, "ALERTS", pg); # TODO
    device.updateMenus();
  },

  windMenu : func(device, pg, menuitem) {
    pg.clearMenu();
    pg.resetMenuColors();
    pg.addMenuItem(2, "OPTN1", pg,
      func(dev, pg, mi) { pg.mfd.PFDInstruments.setWindDisplay(1); device.updateMenus(); }, # Action callback
      func(svg, mi) { pg.mfd.PFDInstruments.toggleWindDisplay(device, svg, mi, 1); } # Display callback
    );
    pg.addMenuItem(3, "OPTN2", pg,
      func(dev, pg, mi) { pg.mfd.PFDInstruments.setWindDisplay(2); device.updateMenus(); }, # Action callback
      func(svg, mi) { pg.mfd.PFDInstruments.toggleWindDisplay(device, svg, mi, 2); } # Display callback
    );
    pg.addMenuItem(4, "OPTN3", pg,
      func(dev, pg, mi) { pg.mfd.PFDInstruments.setWindDisplay(3); device.updateMenus(); }, # Action callback
      func(svg, mi) { pg.mfd.PFDInstruments.toggleWindDisplay(device, svg, mi, 3); } # Display callback
    );
    pg.addMenuItem(5, "OFF", pg,
      func(dev, pg, mi) { pg.mfd.PFDInstruments.setWindDisplay(0); device.updateMenus(); }, # Action callback
      func(svg, mi) { pg.mfd.PFDInstruments.toggleWindDisplay(device, svg, mi, 0); } # Display callback
    );
    pg.addMenuItem(10, "BACK", pg, pg.mfd.PFDInstruments.topMenu);
    pg.addMenuItem(11, "ALERTS", pg); # TODO
    device.updateMenus();
  },

  toggleWindDisplay : func(device, svg, mi, wind_value) {
    var bg_name = sprintf("SoftKey%d-bg",mi.menu_id);
    if (me._windDataDisplay == wind_value) {
      device.svg.getElementById(bg_name).setColorFill(0.5,0.5,0.5);
      svg.setColor(0.0,0.0,0.0);
    } else {
      device.svg.getElementById(bg_name).setColorFill(0.0,0.0,0.0);
      svg.setColor(1.0,1.0,1.0);
    }
    svg.setText(mi.title);
    svg.setVisible(1); # display function
  },

  transponderMenu : func(device, pg, menuitem) {
    pg.clearMenu();
    pg.resetMenuColors();
    pg.addMenuItem(2, "STBY", pg, pg.mfd.PFDInstruments.setTransponderMode);
    pg.addMenuItem(3, "ON", pg, pg.mfd.PFDInstruments.setTransponderMode);
    pg.addMenuItem(4, "ALT", pg, pg.mfd.PFDInstruments.setTransponderMode);
    pg.addMenuItem(5, "GND", pg, pg.mfd.PFDInstruments.setTransponderMode);
    pg.addMenuItem(6, "VFR", pg, pg.mfd.PFDInstruments.setVFR);
    pg.addMenuItem(7, "CODE", pg, pg.mfd.PFDInstruments.codeMenu);
    pg.addMenuItem(8, "IDENT", pg, pg.mfd.PFDInstruments.setIdent);
    pg.addMenuItem(10, "BACK", pg, pg.mfd.PFDInstruments.topMenu);
    pg.addMenuItem(11, "ALERTS", pg); # TODO
    device.updateMenus();
  },

  codeMenu : func(device, pg, menuitem) {
    pg.clearMenu();
    pg.resetMenuColors();
    pg.addMenuItem(0, "0", pg, pg.mfd.PFDInstruments.setTransponderDigit);
    pg.addMenuItem(1, "1", pg, pg.mfd.PFDInstruments.setTransponderDigit);
    pg.addMenuItem(2, "2", pg, pg.mfd.PFDInstruments.setTransponderDigit);
    pg.addMenuItem(3, "3", pg, pg.mfd.PFDInstruments.setTransponderDigit);
    pg.addMenuItem(4, "4", pg, pg.mfd.PFDInstruments.setTransponderDigit);
    pg.addMenuItem(5, "5", pg, pg.mfd.PFDInstruments.setTransponderDigit);
    pg.addMenuItem(6, "6", pg, pg.mfd.PFDInstruments.setTransponderDigit);
    pg.addMenuItem(7, "7  ", pg, pg.mfd.PFDInstruments.setTransponderDigit);
    pg.addMenuItem(8, "IDENT", pg, pg.mfd.PFDInstruments.setIdent);
    pg.addMenuItem(9, "BKSP", pg, pg.mfd.PFDInstruments.setTransponderDigit);
    pg.addMenuItem(10, "BACK", pg, pg.mfd.PFDInstruments.transponderMenu);
    pg.addMenuItem(11, "ALERTS", pg); # TODO
    device.updateMenus();
  },

  setTransponderMode : func(device, pg, menuitem) {
    # Get the transponder mode from the menuitem itself.
    pg.getController().setTransponderMode(menuitem.title);
  },

  setVFR : func(device, pg, menuitem) {
    # Set VFR Mode - 1200
    pg.getController().setTransponderCode(1200);
  },

  setIdent : func(device, pg, menuitem) {
    # Ident the transponder
    pg.getController().setTransponderIdent(1);
  },

  setTransponderDigit: func(device, pg, menuitem) {
    # Set a transponder digit.  Get digit from menu item.
    pg.getController().setTransponderDigit(menuitem.title);
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
    me.getController().ondisplay();
  },

  updateAI: func(pitch, roll, slip) {
    if (pitch > 80)
      pitch = 80;
    elsif (pitch < -80)
      pitch = -80;
    me.getElement("Horizon")
      .setCenter(459, 282.8 - 6.849 * pitch)
      .setRotation(-roll * D2R)
      .setTranslation(0, pitch * 6.849);
    me.getElement("bankPointer")
      .setRotation(-roll * D2R);
    me.getElement("SlipSkid")
      .setTranslation(slip * 10, 0);
  },

  updateFD : func(enabled, pitch, roll, fd_pitch, fd_roll) {
    if (enabled) {
      me.getElement("FlightDirector")
        .setCenter(459,282.8)
        .setRotation(-(roll - fd_roll) * D2R)
        .setTranslation(0, -(fd_pitch - pitch) * 6.849)
        .setVisible(1);
      me._fd_enabled = 1;
    } else if (me._fd_enabled == 1) {
      me.getElement("FlightDirector").setVisible(0);
      me._fd_enabled = 0;
    }

    # Overrides - command bars disappear if pitch exceeeds -20/+30, roll 65
    if ((pitch < -20.0) or (pitch > 30.0) or (roll < -65.0) or (roll > 65.0)) {
      me.getElement("FlightDirector").setVisible(0);
    }
  },

  updateIAS: func (ias, ias_trend) {
    if (ias >= 10) {
      me.setTextElement("Speed110", sprintf("% 2u",num(math.floor(ias/10))));
    } else {
      me.setTextElement("Speed110", "");
    }

    me.getElement("SpeedLint1").setTranslation(0,(math.mod(ias,10) + (ias >= 10)*10) * 36);
    me.getElement("SpeedTape").setTranslation(0,ias * 5.711);

    ias_trend = math.clamp(ias_trend, -30, 30);
    me.getElement("Airspeed-Trend-Indicator")
      .setScale(1,ias_trend)
      .setTranslation(0, -284.5 * (ias_trend - 1));

    var vne = me.mfd.ConfigStore.get("Vne");

    if (ias > vne and ! me._ias_already_exceeded) {
      me._ias_already_exceeded = 1;
      me.getElement("IAS-bg").setColorFill(1,0,0);
    } elsif (ias < vne and me._ias_already_exceeded) {
      me._ias_already_exceeded = 0;
      me.getElement("IAS-bg").setColorFill(0,0,0);
    }

    foreach (var v; ["Vx", "Vy", "Vr", "Vglide"]) {
      var spd = me.mfd.ConfigStore.get(v);
      var visible = me.mfd.ConfigStore.get(v ~ "-visible");
      if (visible and abs(spd - ias) < 30) {
          me.getElement("IAS-" ~ v)
              .setTranslation(0, (ias - spd) * 5.711)
              .show();
      } else {
          me.getElement("IAS-" ~ v).hide();
      }
    }

    if ((me._selected_spd_visible) and ((me._selected_spd - ias) < 30)) {
      me.getElement("SelectedSPD-bug")
          .setTranslation(0, (ias - me._selected_spd) * 5.711)
          .show();
    } else {
      me.getElement("SelectedSPD-bug").hide();
    }
  },

  updateVSI: func (vsi) {
    me.getElement("VSI").setTranslation(0, math.clamp(vsi, -4500, 4500) * -0.03465);
    me.setTextElement("VSIText", num(math.round(vsi, 10)));
  },

  updateTAS: func (tas) {
    me.setTextElement("TAS-text", sprintf("%iKT", tas));
    #me.getElement("GSPD-text").setText(sprintf("%iKT", tas));
  },

  updateGS : func (deflection_norm, type) {
    me.getElement("GS-ILS").setTranslation(0, - deflection_norm * 100);
    me.setTextElement("GS-type", type);
  },

  updateALT: func (alt, alt_trend, selected_alt) {
      if (alt < 0) {
        me.setTextElement("Alt11100", sprintf("-% 3i",abs(math.ceil(alt/100))));
      } elsif (alt < 100) {
        me.setTextElement("Alt11100", "");
      } else {
        me.setTextElement("Alt11100", sprintf("% 3i",math.floor(alt/100)));
      }

      me.getElement("AltLint00011").setTranslation(0,math.fmod(alt,100) * 1.24);

      if (alt> -1000 and alt< 1000000) {
          var Offset10 = 0;
          var Offset100 = 0;
          var Offset1000 = 0;
          var Ne = 0;
          var Alt10       = math.mod(alt,100);
          var Alt100      = int(math.mod(alt/100,10));
          var Alt1000     = int(math.mod(alt/1000,10));
          var Alt10000    = int(math.mod(alt/10000,10));
          var Alt20       = math.mod(Alt10,20)/20;


          if (alt< 0) {
              var Ne = 1;
              var alt= -alt;
          }

          if (Alt10 >= 80) Alt100 += Alt20;
          if (Alt10 >= 80 and Alt100 >= 9) Alt1000 += Alt20;
          if (Alt10 >= 80 and Alt100 >= 9 and Alt1000 >= 9) Alt10000 += Alt20;
          if (alt> 100) Offset10 = 100;
          if (alt> 1000) Offset100 = 10;
          if (alt> 10000) Offset1000 = 10;

          if (Ne) {
            me.getElement("LintAlt").setTranslation(0,(math.mod(alt,100))*-0.57375);
            var altCentral = -(int(alt/100)*100);
          } else {
            me.getElement("LintAlt").setTranslation(0,(math.mod(alt,100))*0.57375);
            var altCentral = (int(alt/100)*100);
          }

          me.setTextElement("AltBigC", "");
          me.setTextElement("AltSmallC", "");
          for (var place = 1; place <= 6; place += 1) {
            var altUP = altCentral + (place*100);
            var altDOWN = altCentral - (place*100);
            var offset = -30.078;
            var prefix = "";

            if (altUP < 0) {
              altUP = -altUP;
              prefix = "-";
              offset += 15.039;
            }
            var AltBigUP = "";
            var AltSmallUP = "0";

            if (altUP == 0) {
              AltBigUP    = "";
              AltSmallUP  = "0";
            } elsif (math.mod(altUP,500) == 0 and altUP != 0) {
              AltBigUP    = sprintf(prefix~"%1d", altUP);
              AltSmallUP  = "";
            } elsif (altUP < 1000 and (math.mod(altUP,500))) {
              AltBigUP    = "";
              AltSmallUP  = sprintf(prefix~"%1d", int(math.mod(altUP,1000)));
              offset = -30.078;
            } elsif ((altUP < 10000) and (altUP >= 1000) and (math.mod(altUP,500))) {
              AltBigUP    = sprintf(prefix~"%1d", int(altUP/1000));
              AltSmallUP  = sprintf("%1d", int(math.mod(altUP,1000)));
              offset += 15.039;
            } else {
              AltBigUP    = sprintf(prefix~"%1d", int(altUP/1000));
              mod = int(math.mod(altUP,1000));
              AltSmallUP  = sprintf("%1d", mod);
              offset += 30.078;
            }

            me.getElement("AltBigU"~place).setText(AltBigUP);
            me.getElement("AltSmallU"~place).setText(AltSmallUP);
            me.getElement("AltSmallU"~place).setTranslation(offset,0);

            offset = -30.078;
            prefix = "";
            if (altDOWN < 0) {
              altDOWN = -altDOWN;
              prefix = "-";
              offset += 15.039;
            }

            if (altDOWN == 0) {
              AltBigDOWN = "";
              AltSmallDOWN = "0";
            } elsif (math.mod(altDOWN,500) == 0 and altDOWN != 0) {
              AltBigDOWN = sprintf(prefix~"%1d", altDOWN);
              AltSmallDOWN = "";
            } elsif (altDOWN < 1000 and (math.mod(altDOWN,500))) {
              AltBigDOWN = "";
              AltSmallDOWN = sprintf(prefix~"%1d", int(math.mod(altDOWN,1000)));
              offset = -30.078;
            } elsif ((altDOWN < 10000) and (altDOWN >= 1000) and (math.mod(altDOWN,500))) {
                AltBigDOWN = sprintf(prefix~"%1d", int(altDOWN/1000));
                AltSmallDOWN = sprintf("%1d", int(math.mod(altDOWN,1000)));
                offset += 15.039;
            } else {
                AltBigDOWN  = sprintf(prefix~"%1d", int(altDOWN/1000));
                AltSmallDOWN = sprintf("%1d", int(math.mod(altDOWN,1000)));
                offset += 30.078;
            }

            me.getElement("AltBigD"~place).setText(AltBigDOWN);
            me.getElement("AltSmallD"~place).setText(AltSmallDOWN);
            me.getElement("AltSmallD"~place).setTranslation(offset,0);
        }
      }

      alt_trend = math.clamp(alt_trend, -15, 15);
      me.getElement("Altitude-Trend-Indicator")
          .setScale(1,alt_trend)
          .setTranslation(0, -284.5 * (alt_trend - 1));

      var delta_alt = alt - selected_alt;
      delta_alt = math.clamp(delta_alt, -300, 300);
      me.getElement("SelectedALT-bug").setTranslation(0, delta_alt * 0.567); # 170/300 = 0.567
  },

  updateBARO : func (baro) {
    # TODO: Support hPa and inhg
    #var fmt = me._baro_unit == "inhg" ? "%.2fin" : "%i%shPa";
    var fmt = "%.2fIN";
    me.setTextElement("BARO-text", sprintf(fmt, baro));
  },

  updateOAT : func (oat) {
    # TODO: Support FAHRENHEIT
    me.setTextElement("OAT-text", sprintf((abs(oat) < 10) ? "%.1f %s" : "%i %s", oat, "°C"));
  },

  updateTime : func (time_sec) {
    var sec = math.mod(time_sec, 60);
    var mins = math.mod((time_sec - sec) / 60, 60);
    var hours = math.mod((time_sec - mins - sec) / 3600, 12);
    me.setTextElement("TIME-text", sprintf("%02d:%02d:%02d", hours, mins, sec));
  },

  updateHSI : func (hdg) {
    me.getElement("Rose").setRotation(-hdg * D2R);
    me.setTextElement("HDG-text", sprintf("%03u°", hdg));
  },

  updateHDG : func (hdg) {
    me.getElement("Heading-bug").setRotation(hdg * D2R);
    me.setTextElement("SelectedHDG-text", sprintf("%03d°%s", hdg, ""));
  },

  # Indicate the selected course, from a given source (OFF, NAV, GPS)
  updateCRS : func (crs) {
    me.getElement("SelectedCRS-text")
      .setText(sprintf("%03d°%s", crs, ""))
      .setColor(me.getController().getCDISource() == "GPS" ? me.COLORS.magenta : me.COLORS.green);
  },

  updateSelectedALT : func (selected_alt) {
    me.setTextElement("SelectedALT-text", sprintf("%i", selected_alt));
  },

  setSelectedSPDVisible : func(visible) {
    me._selected_spd_visible = visible;
    if (visible) {
      me.getElement("SelectedSPD-text").show();
      me.getElement("SelectedSPD-bg").show();
      me.getElement("SelectedSPD-bug").show();
      me.getElement("SelectedSPD-symbol").show();
    } else {
      me.getElement("SelectedSPD-text").hide();
      me.getElement("SelectedSPD-bg").hide();
      me.getElement("SelectedSPD-bug").hide();
      me.getElement("SelectedSPD-symbol").hide();
    }
  },

  updateSelectedSPD : func (selected_spd) {
    me._selected_spd = selected_spd;
    me.setTextElement("SelectedSPD-text", sprintf("%ikt", me._selected_spd));
  },

  setBRG1 : func(option) { me._setBRG("BRG1",option); },
  setBRG2 : func(option) { me._setBRG("BRG2",option); },

  _setBRG : func (brg, option) {
    if (option == "OFF") {
      me.getElement(brg).hide();
      me.getElement(brg ~ "-pointer").hide();
      if ((me.getController().getBRG1() == "OFF") and (me.getController().getBRG2() == "OFF")) {
        # Hide the circle if there are now BRGs selected
        me.getElement("BRG-circle").hide();
      }
    } else {
      me.getElement(brg).show();
      me.getElement(brg ~ "-pointer").show();
      me.getElement("BRG-circle").show();

      me.getElement(brg ~ "-SRC-text").setText(option);
      me.getElement(brg ~ "-WPID-text").setText("----");

      if (option == "ADF") {
        # Special case.  We won't have a distance and the "ID" will be the ADF
        # frequency
        me.getElement(brg ~ "-DST-text").setText("");
      } else {
        me.getElement(brg ~ "-DST-text").setText("--nm");
      }
    }
  },

  # Update BRG information
  updateBRG1 : func(valid, id, dst, current_heading, brg_heading) {
    me._updateBRG("BRG1", me.getController().getBRG1(), valid, id, dst, current_heading, brg_heading);
  },
  updateBRG2 : func(valid, id, dst, current_heading, brg_heading) {
    me._updateBRG("BRG2", me.getController().getBRG2(), valid, id, dst, current_heading, brg_heading);
  },
  _updateBRG : func (brg, source, valid, id, dst, current_heading, brg_heading) {
    if (source == "OFF") return;

    if (valid) {
      me.getElement(brg ~ "-SRC-text").setText(source);
      me.getElement(brg ~ "-WPID-text").setText(id);

      if (source == "ADF") {
        # Special case.  We won't have a distance and the "ID" will be the ADF
        # frequency
        me.getElement(brg ~ "-DST-text").setText("");
      } else {
        me.getElement(brg ~ "-DST-text").setText(sprintf("%.1fNM", dst));
      }

      var rot = (brg_heading - current_heading) * D2R;
      me.getElement(brg ~ "-pointer").setRotation(rot).show();
    } else {
      # Data is not valid - hide the pointer and display NO DATA
      me.getElement(brg ~ "-SRC-text").setText(source);
      me.getElement(brg ~ "-WPID-text").setText("NO DATA");
      me.getElement(brg ~ "-DST-text").setText("");
      me.getElement(brg ~ "-pointer").hide();
    }
  },

  toggleDME : func() {
    me.setDME(! me._DME);
  },

  setDME : func (enabled) {
    me._DME = enabled;
    me.getElement("DME1").setVisible(enabled);
  },

  updateDME : func (mode, freq, dst) {
    if (me._DME == 0) return;
    me.getElement("DME1-SRC-text").setText(mode);
    me.getElement("DME1-FREQ-text").setText(sprintf("%.2f", freq));
    me.getElement("DME1-DST-text").setText(sprintf("%.2fNM", dst));
  },

  setCDISource : func(source) {
    foreach (var s; ["GPS", "NAV1", "NAV2"]) {
      me.getElement(s ~ "-pointer").setVisible(source == s);
      me.getElement(s ~ "-CDI").setVisible(source == s);
      me.getElement(s ~ "-FROM").setVisible(source == s);
      me.getElement(s ~ "-TO").setVisible(source == s);
    }

    me.getElement("CDI-SRC-text")
      .setText(source)
      .setColor(source == "GPS" ? me.COLORS.magenta : me.COLORS.green)
      .setVisible(source != "OFF");
  },

  updateCDI : func (heading, course, waypoint_valid, course_deviation_deg, deflection_dots, xtrk_nm, from, annun, loc) {

    var source = me.getController().getCDISource();
    if (source == "OFF") return;

    # While the user selects between GPS, NAV1, NAV2, we display localizers as LOC1 and LOC2
    if ((source == "NAV1") and (loc == 1)) me.getElement("CDI-SRC-text").setText("LOC1");
    if ((source == "NAV2") and (loc == 1)) me.getElement("CDI-SRC-text").setText("LOC2");

    if (waypoint_valid == 0) {
      me.getElement(source ~ "-CDI").hide();
      me.getElement(source ~ "-FROM").hide();
      me.getElement(source ~ "-TO").hide();
      me.getElement(source ~ "-pointer").hide();
      me.getElement("CDI").setRotation(0);
      me.getElement("GPS-CTI-diamond").hide();
      me.getElement("CDI-GPS-XTK-text").hide();
      me.getElement("CDI-GPS-ANN-text").setText("NO DATA").show();
    } else {
      me.getElement(source ~ "-CDI").show();

      var rot = (course - heading) * D2R;
      me.getElement("CDI").setRotation(rot).show();
      me.getElement("GPS-CTI-diamond").setRotation(course_deviation_deg * D2R).setVisible(source == "GPS");

      if ((source == "GPS") and (abs(deflection_dots) > 2.0)) {
        # Only display the cross-track error if the error exceeds the maximum
        # deflection of two dots.
        me.getElement("CDI-GPS-XTK-text")
          .setText(sprintf("XTK %.2fNM", abs(xtrk_nm)))
          .show();
      } else {
        me.getElement("CDI-GPS-XTK-text").hide();
      }

      if (source == "GPS") {
        me.getElement("CDI-GPS-ANN-text").setText(annun).show();
      } else {
        me.getElement("CDI-GPS-ANN-text").hide();
      }

      var scale = math.clamp(deflection_dots, -2.4, 2.4);
      me.getElement(source ~ "-CDI").setTranslation(80 * scale / 2.4, 0);

      # Display the appropriate TO/FROM indication for the selected source,
      # switching all others off.
      me.getElement(source ~ "-TO").setVisible(from == 0);
      me.getElement(source ~ "-FROM").setVisible(from);
    }
  },

  # Update the wind display.  There are three options:
  # 0 - No wind data displayed
  # 1 - Numeric headwind and crosswind components
  # 2 - Direction arrow and numeric speed
  # 3 - Direction arrow, and numeric True direction and speet
  setWindDisplay : func(option) {
    me.getElement("WindData").setVisible(option != 0);
    me.getElement("WindData-OPTN1").setVisible(option == 1);
    me.getElement("WindData-OPTN2").setVisible(option == 2);
    me.getElement("WindData-OPTN3").setVisible(option == 3);

    me._windDataDisplay = option;
  },

  updateWindData : func (hdg, wind_hdg, wind_spd, no_data) {
    if (no_data and (me._windDataDisplay > 0)) {
      me.getElement("WindData-NODATA").show();
      me.getElement("WindData-NODATA-bg").show();
      return;
    } else {
      me.getElement("WindData-NODATA").hide();
      me.getElement("WindData-NODATA-bg").hide();
    }

    var alpha = (wind_hdg - hdg);

    # Stop the wind arrows oscillating
    if (wind_spd < 1) {
      alpha = 0;
      wind_hdg = 0;
    }

    if (me._windDataDisplay == 0) {
      me.getElement("WindData").hide();
    } elsif (me._windDataDisplay == 1) {
      # Headwind/Crosswind numeric display
      var Vt = wind_spd * math.sin(alpha * D2R);
      var Ve = wind_spd * math.cos(alpha * D2R);
      me.getElement("WindData-OPTN1-crosswind-text").setText(sprintf("%i", abs(Vt)));
      me.getElement("WindData-OPTN1-crosswind").setRotation(Vt > 0.1 ? 180*D2R : 0);
      me.getElement("WindData-OPTN1-headwind-text").setText(sprintf("%i", abs(Ve)));
      me.getElement("WindData-OPTN1-headwind").setRotation(Ve > 0.1 ? 180*D2R : 0);
    } elsif (me._windDataDisplay == 2) {
      # Direction arrow and numeric speed
      me.getElement("WindData-OPTN2-HDG").setRotation((alpha + 180) * D2R);
      me.getElement("WindData-OPTN2-SPD-text").setText(sprintf("%i", wind_spd));
    } elsif (me._windDataDisplay == 3) {
      # Direction arrow with numeric true direction and speed
      me.getElement("WindData-OPTN3-HDG").setRotation((alpha + 180) * D2R);
      me.getElement("WindData-OPTN3-HDG-text").setText(sprintf("%03i°T", wind_hdg));
      me.getElement("WindData-OPTN3-SPD-text").setText(sprintf("%iKT", wind_spd));
    } else {
      print("Unknown wind data option " ~ me._windDataDisplay);
    }
  },

  # Enable/disable the multiline display on the right hand side of the PFD
  setMultiline : func(enabled) {
    me._Multiline = enabled;
    me.getElement("PFD-Multilines").setVisible(enabled);
  },

  # Enable/disable the warning annunication window.
  setAnnunciation : func(enabled) {
    me._annunciation = enabled;
    me.getElement("Annunciation").setVisible(enabled);
  },

  # set the Outer, Middle, Inner indicator
  setOMI : func(omi) {
    if (omi == "") {
      me.getElement("OMI").hide();
    } else {
      me.getElement("OMI").show();
      me.setTextElement("MarkerText", omi);
    }
    me._OMI = omi;
  },

  setInsetMapVisible :func(enabled ) {
    me.getElement("PFD-Map").setVisible(enabled);
    me.getElement("PFD-Map-bg").setVisible(enabled);
    me.insetMap.setVisible(enabled);
  },

  setFlightPlanVisible : func(enabled) {
    me.getElement("FlightPlanGroup").setVisible(enabled);
  },

  # Update the FlightPlan display with an updated flightplan.
  setFlightPlan : func(fp) {
    var elements = [];

    if (fp == nil) return;

    var current_wp = fp.current;

    for (var i = 0; i < fp.getPlanSize(); i = i + 1) {
      var wp = fp.getWP(i);

      var element = {
        FlightPlanArrow : 0,
        FlightPlanID : "",
        FlightPlanType : "",
        FlightPlanDTK : 0,
        FlightPlanDIS : 0,
      };

      if (wp.wp_name != nil) element.FlightPlanID = substr(wp.wp_name, 0, 7);
      if (wp.wp_role != nil) element.FlightPlanType = substr(wp.wp_role, 0, 4);

      if (i < current_wp) {
        # Passed waypoints are blanked out on the display
        element.FlightPlanDIS = "___nm";
        element.FlightPlanDTK = "___°";
      } else {
        if (wp.leg_distance != nil) element.FlightPlanDIS = sprintf("%.1fnm", wp.leg_distance);
        if (wp.leg_bearing != nil) element.FlightPlanDTK = sprintf("%03d°", wp.leg_bearing);
      }
      append(elements, element);
    }

    me.flightplanList.setValues(elements);
    me.flightplanList.setCRSR(current_wp);

    # Determine a suitable name to display, using the flightplan name if there is one,
    # but falling back to the flightplan departure / destination airports, or failing
    # that the IDs of the first and last waypoints.
    if ((fp.id == nil) or (fp.id == "default-flightplan")) {
      var from = "????";
      var dest = "????";

      if ((fp.getWP(0) != nil) and (fp.getWP(0).wp_name != nil)) {
        from = fp.getWP(0).wp_name;
      }

      if ((fp.getWP(fp.getPlanSize() -1) != nil) and (fp.getWP(fp.getPlanSize() -1).wp_name != nil)) {
        dest = fp.getWP(fp.getPlanSize() -1).wp_name;
      }

      if (fp.departure   != nil) from = fp.departure.id;
      if (fp.destination != nil) dest = fp.destination.id;
      me.getElement("FlightPlanName").setText(from ~ " / " ~ dest);
    } else {
      me.getElement("FlightPlanName").setText(fp.id);
    }
  },

  # Update the FlightPlan display to indicate the current waypoint
  updateFlightPlan : func(current_wp) {
    if (current_wp == -1) return;
    me.flightplanList.setCRSR(current_wp);
    me.flightplanList.displayGroup();
  },

  # Update the Transponder display
  updateTransponder : func(mode, code, ident, edit=0) {
    # Data validation on the mode
    if (mode < 0) mode = 0;
    if (mode > 5) mode = 5;

    # Ensure the code is a 4 digit string representation of a number.
    # Normally this means padding with 0's at the left e.g.  42 becomes 0042.
    # In editing mode we enter values from the left, so we want " " padding on the
    # right, so 42 becomes "42  ".  Note also that the code is a string value
    # so we can have "004 "
    if (edit) {
      code = sprintf("%-4s", code);
    } else {
      code = sprintf("%04i", code);
    }

    # Colour of display. White in OFF, STDBY, TEST modes, green in GND, ON, ALT
    var r = 1.0;
    var g = 1.0;
    var b = 1.0;
    if (mode > 2) {
      r = 0.2;
      g = 1.0;
      b = 0.2;
    }

    if (ident) {
      me.getElement("XPDR-MODE-text").setText("IDNT").setColor(r,g,b);
    } else {
      me.getElement("XPDR-MODE-text").setText(TRANSPONDER_MODES[mode]).setColor(r,g,b);
    }

    var codes = split("", code);
    me.getElement("XPDR-DIGIT-3-text").setText(chr(code[0])).setColor(r,g,b);
    me.getElement("XPDR-DIGIT-2-text").setText(chr(code[1])).setColor(r,g,b);
    me.getElement("XPDR-DIGIT-1-text").setText(chr(code[2])).setColor(r,g,b);
    me.getElement("XPDR-DIGIT-0-text").setText(chr(code[3])).setColor(r,g,b);
  },
};
