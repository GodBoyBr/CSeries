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
# NearestFrequencies
var NearestFrequencies =
{
  new : func (mfd, myCanvas, device, svg)
  {
    var obj = {
      parents : [
        NearestFrequencies,
        MFDPage.new(mfd, myCanvas, device, svg, "NearestFrequencies", "NRST - NEAREST FREQUENCIES")
      ],
    };

    var textElements = ["ARTCCName", "ARTCCBRG", "ARTCCDIS", "FSSName", "FSSBRG", "FSSDIS"];

    obj.addTextElements(textElements);

    obj.artccSelect = PFD.GroupElement.new(
      obj.pageName,
      svg,
      ["ARTCCFreq"],
      3,
      "ARTCCFreq",
      0,
    );

    obj.fssSelect = PFD.GroupElement.new(
      obj.pageName,
      svg,
      ["FSSFreq"],
      3,
      "FSSFreq",
      0,
    );

    obj.wxSelect = PFD.GroupElement.new(
      obj.pageName,
      svg,
      ["WXID", "WXType", "WXFreq"],
      8,
      "WXFreq",
      0,
      "ScrollTrough",
      "ScrollThumb",
      (181 - 116)
    );

    obj.topMenu(device, obj, nil);

    obj.setController(fg1000.NearestFrequenciesController.new(obj, svg));

    return obj;
  },

  # Clear any cursor, highlights.  Used when exiting from CRSR mode
  resetCRSR : func() {
    me.artccSelect.hideCRSR();
    me.fssSelect.hideCRSR();
    me.wxSelect.hideCRSR();
    me.resetMenuColors();
  },


  updateARTCC : func(artcc) {
    if (artcc != nil) {
      me.setTextElement("ARTCCName", artcc.name);
      me.setTextElementBearing("ARTCCBRG", artcc.brg);
      me.setTextElementDistance("ARTCCDIS", artcc.dis);
      me.artccSelect.setValues(artcc.freqs);
    } else {
      me.setTextElement("ARTCCName", "");
      me.setTextElementBearing("ARTCCBRG", nil);
      me.setTextElementDistance("ARTCCDIS", nil);
      me.artccSelect.setValues([]);
    }

  },

  updateFSS : func(fss) {
    if (fss != nil) {
      me.setTextElement("FSSName", fss.name);
      me.setTextElementBearing("FSSBRG", fss.brg);
      me.setTextElementDistance("FSSDIS", fss.dis);
      me.fssSelect.setValues(fss.freqs);
    } else {
      me.setTextElement("FSSName", "");
      me.setTextElementBearing("FSSBRG", nil);
      me.setTextElementDistance("FSSDIS", nil);
      me.fssSelect.setValues([]);
    }
  },

  updateWX : func(freqs) {
    var values = [];

    if (freqs != nil) {
      foreach (var f; freqs) {
        append(values, { WXID: f.id, WXType: f.type, WXFreq: sprintf("%0.03f", f.freq) } );
      }
    }

    me.wxSelect.setValues(values);
  },

  getSelectedARTCC : func() {
    return me.artccSelect.getValue();
  },
  getSelectedFSS : func() {
    return me.fssSelect.getValue();
  },
  getSelectedWX : func() {
    return me.wxSelect.getValue();
  },

  # Function to highlight the ARTCC softkey - used when CRSR is pressed to indicate
  # that we're editing the ARTCC selection.
  selectARTCC : func() {
    me.resetMenuColors();
    var bg_name = sprintf("SoftKey%d-bg",5);
    var tname = sprintf("SoftKey%d",5);
    me.device.svg.getElementById(bg_name).setColorFill(0.5,0.5,0.5);
    me.device.svg.getElementById(tname).setColor(0.0,0.0,0.0);
  },

  offdisplay : func() {
    me._group.setVisible(0);
    # The Nearest... pages use the underlying navigation map.
    me.mfd.NavigationMap.offdisplayPartial();
    me.resetMenuColors();
    me.getController().offdisplay();
  },
  ondisplay : func() {
    me._group.setVisible(1);
    me.mfd.setPageTitle(me.title);

    # The Nearest... pages use the underlying navigation map.
    me.mfd.NavigationMap.ondisplayPartial();

    me.getController().ondisplay();
  },

  # Indicate which group is selected by colour of the softkeys
  display_toggle : func(device, svg, mi, group) {
    var bg_name = sprintf("SoftKey%d-bg",mi.menu_id);
    if (me.getController().getSelectedGroup() == group) {
      device.svg.getElementById(bg_name).setColorFill(0.5,0.5,0.5);
      svg.setColor(0.0,0.0,0.0);
    } else {
      device.svg.getElementById(bg_name).setColorFill(0.0,0.0,0.0);
      svg.setColor(1.0,1.0,1.0);
    }
    svg.setText(mi.title);
    svg.setVisible(1); # display function
  },

  topMenu : func(device, pg, menuitem) {
    pg.clearMenu();
    pg.resetMenuColors();

    pg.addMenuItem(0, "ENGINE", pg, pg.mfd.EIS.engineMenu);
    pg.addMenuItem(2, "MAP", pg, pg.mfd.NavigationMap.mapMenu);
    pg.addMenuItem(5, "ARTCC", pg,
      func(dev, pg, mi) { pg.getController().selectARTCC(); device.updateMenus(); }, # callback
      func(svg, mi) { pg.display_toggle(device, svg, mi, NearestFrequenciesController.UIGROUP.ARTCC); }
    );
    pg.addMenuItem(6, "FSS", pg,
      func(dev, pg, mi) { pg.getController().selectFSS(); device.updateMenus(); }, # callback
      func(svg, mi) { pg.display_toggle(device, svg, mi, NearestFrequenciesController.UIGROUP.FSS); }
    );
    pg.addMenuItem(7, "WX", pg,
      func(dev, pg, mi) { pg.getController().selectWX(); device.updateMenus(); }, # callback
      func(svg, mi) { pg.display_toggle(device, svg, mi, NearestFrequenciesController.UIGROUP.WX); }
    );

    device.updateMenus();
  },


};
