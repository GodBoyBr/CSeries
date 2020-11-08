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
# NearestFrequencies Controller
var NearestFrequenciesController =
{
  UIGROUP : {
    NONE   : 0, # No group currently selected,
    ARTCC  : 1,
    FSS    : 2,
    WX     : 3,
  },

  new : func (page, svg)
  {
    var obj = {
      parents : [ NearestFrequenciesController, MFDPageController.new(page) ],
      _crsrToggle : 0,
      _recipient : nil,
      _page : page,
      _atrcc_data: nil,
      _fss_data : nil,
      _wx_data : nil,
    };

    obj._currentGroup = NearestFrequenciesController.UIGROUP.NONE;

    obj._page.updateARTCC(nil,[]);
    obj._page.updateFSS(nil,[]);
    obj._page.updateWX([]);

    return obj;
  },


  selectARTCC : func() {
    me.selectGroup(NearestFrequenciesController.UIGROUP.ARTCC)
  },
  selectFSS : func() {
    me.selectGroup(NearestFrequenciesController.UIGROUP.FSS);
  },
  selectWX : func() {
    me.selectGroup(NearestFrequenciesController.UIGROUP.WX);
  },
  getSelectedGroup : func() {
    return me._currentGroup;
  },
  selectGroup : func(grp) {
    me._currentGroup = grp;
    if (grp == NearestFrequenciesController.UIGROUP.ARTCC)  me._page.artccSelect.showCRSR() else me._page.artccSelect.hideCRSR();
    if (grp == NearestFrequenciesController.UIGROUP.FSS)    me._page.fssSelect.showCRSR()   else me._page.fssSelect.hideCRSR();
    if (grp == NearestFrequenciesController.UIGROUP.WX)     me._page.wxSelect.showCRSR()    else me._page.wxSelect.hideCRSR();
    me._crsrToggle = 1;
  },

  updateFrequencies : func() {
    me._atrcc_data = me.getNavData("GetNearestATRCC");
    me._fss_data = me.getNavData("GetNearestFSS");
    me._wx_data = me.getNavData("GetNearestWX");
    me._page.updateARTCC(me._atrcc_data);
    me._page.updateFSS(me._fss_data);
    me._page.updateWX(me._wx_data);
    
    # Display the DTO line to the airport
    var apt_idx = me._page.wxSelect.getCRSR();
    var freq_data= me._wx_data[apt_idx];
    if (freq_data != nil) {
      me._page.mfd.NavigationMap.getController().setDTOLineTarget(freq_data.lat, freq_data.lon);
    }
  },

  # Input Handling
  handleCRSR : func() {
    me._crsrToggle = (! me._crsrToggle);
    if (me._crsrToggle) {
      me._page.selectARTCC();
      me._page.topMenu(me._page.device, me._page, nil);
      #me.selectAirports();
    } else {
      # Hide the cursor and reset any highlighting
      me._page.resetCRSR();
    }
    return emesary.Transmitter.ReceiptStatus_Finished;
  },

  handleFMSInner : func(value) {
    if (me._crsrToggle == 1) {
      # Scroll through whatever is in the current list
      if (me._currentGroup == NearestFrequenciesController.UIGROUP.ARTCC) me._page.artccSelect.incrSmall(value);
      if (me._currentGroup == NearestFrequenciesController.UIGROUP.FSS) me._page.fssSelect.incrSmall(value);
      if (me._currentGroup == NearestFrequenciesController.UIGROUP.WX) {
        me._page.wxSelect.incrSmall(value);

        # Display the DTO line to the airport
        var apt_idx = me._page.wxSelect.getCRSR();
        var freq_data= me._wx_data[apt_idx];
        if (freq_data != nil) {
          me._page.mfd.NavigationMap.getController().setDTOLineTarget(freq_data.lat, freq_data.lon);
        }
      }

      return emesary.Transmitter.ReceiptStatus_Finished;
    } else {
      return me._page.mfd.SurroundController.handleFMSInner(value);
    }
  },

  handleFMSOuter : func(value) {
    if (me._crsrToggle == 1) {
      # Scroll through whatever is in the current list.  Unclear if this should
      # scroll between windows instead?
      if (me._currentGroup == NearestFrequenciesController.UIGROUP.ARTCC) me._page.artccSelect.incrSmall(value);
      if (me._currentGroup == NearestFrequenciesController.UIGROUP.FSS) me._page.fssSelect.incrSmall(value);
      if (me._currentGroup == NearestFrequenciesController.UIGROUP.WX) me._page.wxSelect.incrSmall(value);

      return emesary.Transmitter.ReceiptStatus_Finished;
    } else {
      return me._page.mfd.SurroundController.handleFMSOuter(value);
    }
  },

  handleEnter : func(value) {
    if (me._crsrToggle == 1) {
      var select = nil;
      if (me._currentGroup == NearestFrequenciesController.UIGROUP.ARTCC) select = me._page.artccSelect;
      if (me._currentGroup == NearestFrequenciesController.UIGROUP.FSS) select = me._page.fssSelect;
      if (me._currentGroup == NearestFrequenciesController.UIGROUP.WX) select = me._page.wxSelect;

      assert(select != nil, "Failed to determine currently selected group.");

      var freq = select.getValue();
      if (freq != nil) {
        me._page.mfd.SurroundController.setStandbyNavComFreq(freq);
      }
      return emesary.Transmitter.ReceiptStatus_Finished;
    } else {
      return emesary.Transmitter.ReceiptStatus_NotProcessed;
    }
  },

  handleRange : func(val)
  {
    # Pass any range entries to the NavMapController
    me._page.mfd.NavigationMap.getController().handleRange(val);
  },

  # Reset controller if required when the page is displayed or hidden
  ondisplay : func() {
    me.RegisterWithEmesary();
    me.updateFrequencies();
    me._page.mfd.NavigationMap.getController().enableDTO(1);
  },
  offdisplay : func() {
    me._page.mfd.NavigationMap.getController().enableDTO(0);
    me.DeRegisterWithEmesary();
  },

};
