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
# Checklist Controller
var ChecklistController =
{
  UIGROUP : {
    GROUP : 0,
    CHECKLIST: 1,
    ITEMS : 2,
    NEXT : 3,
  },

  new : func (page, svg)
  {
    var obj = {
      parents : [ ChecklistController, MFDPageController.new(page) ],
      _crsrToggle : 0,
      _recipient : nil,
      _page : page,
      _currentGroup : -1,
      _group_selected : nil,
      _list_selected : nil,
      _checklists : nil,
    };

    obj.selectGroup(-1);
    return obj;
  },

  selectGroup : func() {
    me.selectGroup(ChecklistController.UIGROUP.GROUP)
  },
  selectChecklist : func() {
    me.selectGroup(ChecklistController.UIGROUP.CHECKLIST);
  },
  selectItems : func() {
    me.selectGroup(ChecklistController.UIGROUP.ITEMS);
  },
  selectNext : func() {
    me.selectGroup(ChecklistController.UIGROUP.NEXT);
  },


  getSelectedGroup : func() {
    return me._currentGroup;
  },

  selectGroup : func(grp) {
    me._page.hideGroupSelect();
    me._page.hideChecklistSelect();

    me._currentGroup = grp;
    if (grp == ChecklistController.UIGROUP.GROUP) {
      me._page.highlightTextElement("GroupName");
    } else {
      me._page.unhighlightTextElement("GroupName");
    }

    if (grp == ChecklistController.UIGROUP.CHECKLIST) {
      me._page.highlightTextElement("Name");
    } else {
      me._page.unhighlightTextElement("Name");
    }

    if (grp == ChecklistController.UIGROUP.ITEMS) {
      me._page.checklistDisplay.showCRSR();
    } else {
      me._page.checklistDisplay.hideCRSR();
    }

    if (grp == ChecklistController.UIGROUP.NEXT) {
      me._page.highlightTextElement("Next");
    } else {
      me._page.unhighlightTextElement("Next");
    }
  },

  selectEmergencyChecklist : func() {
    if (me._checklist == nil) return;
    # Select the EMERGENCY checklist group, if available.
    var emergency_labels = ["EMERGENCY", "Emergency", "emergency"];
    var group = nil;
    foreach (var l; emergency_labels) {
      if (me._checklists[l] != nil) {
        group = l;
        break;
      }
    }

    if (group != nil) {
      me._group_selected = group;
      me._list_selected = keys(me._checklists[me._group_selected])[0];
      me._page.hideGroupSelect();
      me._page.displayChecklist(me._group_selected, me._list_selected, me._checklists);
      me.selectChecklist();
    }
  },

  # Input Handling
  handleCRSR : func() {
    # If there are no checklists then we don't allow the CRSR to be enabled as
    # there's nothing to do.
    if (me._checklists == nil) return emesary.Transmitter.ReceiptStatus_Finished;
    me._crsrToggle = (! me._crsrToggle);
    if (me._crsrToggle) {
      me.selectGroup(0);
    } else {
      me.selectGroup(-1);
    }
    return emesary.Transmitter.ReceiptStatus_Finished;
  },
  handleFMSInner : func(value) {
    if (me._crsrToggle == 1) {
      # Either display the select group or scroll through whatever is the current list

      if (me._currentGroup == ChecklistController.UIGROUP.GROUP) {
        if (me._page.isGroupSelectVisible()) {
          me._page.checklistGroupSelect.incrSmall(value);
        } else {
          me._page.displayGroupSelect();
          me._page.unhighlightTextElement("GroupName");
        }
      }

      if (me._currentGroup == ChecklistController.UIGROUP.CHECKLIST) {
        if (me._page.isChecklistSelectVisible()) {
          me._page.checklistSelect.incrSmall(value);
        } else {
          me._page.displayChecklistSelect();
          me._page.unhighlightTextElement("Name");
        }
      }

      if (me._currentGroup == ChecklistController.UIGROUP.ITEMS) {
        me._page.checklistDisplay.incrSmall(value);
      }

      return emesary.Transmitter.ReceiptStatus_Finished;
    } else {
      # Pass to the page group controller to display and scroll through the page group menu
      return me._page.mfd.SurroundController.handleFMSInner(value);
    }
  },
  handleFMSOuter : func(value) {
    if (me._crsrToggle == 1) {
      # Manual explicitly documents that _either_ FMS knob may be used to scroll through the checklist.
      # However, that means that there is no way to navigate from the checklist itself other
      # than to disable and then re-enable the CRSR.  Odd.
      if (me._currentGroup == ChecklistController.UIGROUP.ITEMS) return me.handleFMSInner(value);

      var incr_or_decr = (value > 0) ? 1 : -1;
      var idx = me._currentGroup + incr_or_decr;
      if (idx < 0) idx = 0;
      if (idx > (size(ChecklistController.UIGROUP) -1)) idx = size(ChecklistController.UIGROUP) -1;
      me.selectGroup(idx);
      return emesary.Transmitter.ReceiptStatus_Finished;
    } else {
      # Pass to the page group controller to display and scroll through the page group menu
      return me._page.mfd.SurroundController.handleFMSOuter(value);
    }
  },
  handleEnter : func(value) {
    if (me._crsrToggle == 1) {
      if (me._checklists ==nil) return emesary.Transmitter.ReceiptStatus_Finished;
      if (me._currentGroup == ChecklistController.UIGROUP.GROUP) {
        # Load the new group, selecting the first checklist in the group
        me._group_selected = me._page.checklistGroupSelect.getValue();
        me._list_selected = keys(me._checklists[me._group_selected])[0];
        me._page.hideGroupSelect();
        me._page.displayChecklist(me._group_selected, me._list_selected, me._checklists);
        me._page.checklistDisplay.setCRSR(0);
        me.selectChecklist();
        return emesary.Transmitter.ReceiptStatus_Finished;
      }

      if (me._currentGroup == ChecklistController.UIGROUP.CHECKLIST) {
        # Load the selected checking from the group
        me._list_selected = me._page.checklistSelect.getValue();
        me._page.hideChecklistSelect();
        me._page.displayChecklist(me._group_selected, me._list_selected, me._checklists);
        me._page.checklistDisplay.setCRSR(0);
        me.selectItems();
        return emesary.Transmitter.ReceiptStatus_Finished;
      }

      if (me._currentGroup == ChecklistController.UIGROUP.ITEMS) {
        # Check the selected Checklist item
        me.checkCurrentItem();
        var idx = me._page.checklistDisplay.getCRSR();

        if ((idx == (size(me._checklists[me._group_selected][me._list_selected]) -1)) and
            me._page.checklistDisplay.isComplete()) {
          # If we're right at the end of this checklist then move onto the "Next Checklist"
          # button.  Manual isn't clear on whether this is only if the checklist is complete,
          # but we will assume that is the case.
          me.selectNext();
        } else {
          # Automatically go to the next item.
          me.handleFMSInner(1);
        }

        return emesary.Transmitter.ReceiptStatus_Finished;
      }

      if (me._currentGroup == ChecklistController.UIGROUP.NEXT) {
        # Select the next checklist if there's one available
        var lists = keys(me._checklists[me._group_selected]);
        var idx = 0;
        for (i = 0; i < size(lists); i = i +1) {
          if (lists[i] == me._list_selected) idx = i + 1;
        }

        if (idx < size(lists)) {
          me._list_selected = lists[idx];
          me._page.checklistDisplay.setCRSR(0);
          me._page.displayChecklist(me._group_selected, me._list_selected, me._checklists);
          me.selectItems();
        }
        return emesary.Transmitter.ReceiptStatus_Finished;
      }

      return emesary.Transmitter.ReceiptStatus_NotProcessed;
    } else {
      return emesary.Transmitter.ReceiptStatus_NotProcessed;
    }
  },

  handleClear : func() {
    if ((me._crsrToggle == 1) and
        (me._currentGroup == ChecklistController.UIGROUP.ITEMS)) {
      # Uncheck the selected Checklist item
      me.clearCurrentItem();
      return emesary.Transmitter.ReceiptStatus_Finished;
    }

    return emesary.Transmitter.ReceiptStatus_NotProcessed;
  },

  checkCurrentItem : func() {
    me._page.checklistDisplay.enterElement();
    var idx = me._page.checklistDisplay.getCRSR();
    me._checklists[me._group_selected][me._list_selected][idx]["Checked"] = 1;
    me._page.displayChecklist(me._group_selected, me._list_selected, me._checklists);
  },

  clearCurrentItem : func() {
    me._page.checklistDisplay.clearElement();
    var idx = me._page.checklistDisplay.getCRSR();
    me._checklists[me._group_selected][me._list_selected][idx]["Checked"] = 0;
    me._page.displayChecklist(me._group_selected, me._list_selected, me._checklists);
  },

  toggleCurrentItem : func() {
    if (me._page.checklistDisplay.getValue()) {
      me.clearCurrentItem();
    } else {
      me.checkCurrentItem();
    }
  },

  # Retrieve the current set of checklists from the system.
  getChecklists : func() {
    var notification = notifications.PFDEventNotification.new(
      "MFD",
      me.getDeviceID(),
      notifications.PFDEventNotification.NavData,
      {Id: "GetChecklists", Value: nil});

    var response = me._transmitter.NotifyAll(notification);
    if (! me._transmitter.IsFailed(response)) {
      me._checklists = notification.EventParameter.Value;
    }

    me._page.displayChecklist("", "", nil);

    # Find the first checklist of the first group to display;
    if ((me._checklists != nil) and size(keys(me._checklists)) != 0) {
      me._group_selected = keys(me._checklists)[0];
      if (size(keys(me._checklists[me._group_selected])) != 0) {
        me._list_selected = keys(me._checklists[me._group_selected])[0];
        me._page.displayChecklist(me._group_selected, me._list_selected, me._checklists);
      }
    }
  },

  # Reset controller if required when the page is displayed or hidden
  ondisplay : func() {
    me.RegisterWithEmesary();

    # Get the list of checklists if we don't already have it.  This has to
    # be done here rather than in the Constructor because the appropriate
    # Emesary interface may not have been initialized in time.
    if (me._checklists == nil) me.getChecklists();
  },
  offdisplay : func() {
    me.DeRegisterWithEmesary();
  },

};
