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
# Checklist
var Checklist =
{
  new : func (mfd, myCanvas, device, svg)
  {
    var obj = {
      parents : [
        Checklist,
        MFDPage.new(mfd, myCanvas, device, svg, "Checklist", "LST - CHECKLIST")
      ],
      _groupSelectVisible : 0,
      _checklistSelectVisible : 0,
      _checklistDisplayVisible : 0,
    };

    obj.topMenu(device, obj, nil);

    obj.checklistGroupSelect = PFD.GroupElement.new(
      obj.pageName,
      svg,
      ["GroupItem"],
      7,
      "GroupItem",
      0,
      "GroupSelectScrollTrough",
      "GroupSelectScrollThumb",
      (165 - 120)
    );

    obj.checklistSelect = PFD.GroupElement.new(
      obj.pageName,
      svg,
      ["ChecklistItem"],
      7,
      "ChecklistItem",
      0,
      "SelectScrollTrough",
      "SelectScrollThumb",
      (165 - 120)
    );

    obj.checklistDisplay = ChecklistGroupElement.new(
      obj,
      svg,
      16,
      "ScrollTrough",
      "ScrollThumb",
      (525 - 180)
    );

    # Other dynamic text elements
    obj.addTextElements(["GroupName", "Name", "Next", "Finished", "NotFinished"]);

    # The "Next" element isn't technically dynamic, though we want it to be
    # highlighted as a text element.  We need to set a value for it explicitly,
    # as it'll be set to an empty string otherwise.
    obj.setTextElement("Next", "GO TO NEXT CHECKLIST?");
    obj.setTextElement("Finished", "* Checklist Finished *");
    obj.setTextElement("NotFinished", "* CHECKLIST NOT FINISHED *");

    # Hide the various groups
    obj.hideChecklistSelect();
    obj.hideGroupSelect();

    obj.setController(fg1000.ChecklistController.new(obj, svg));

    return obj;
  },

  displayChecklist : func(group, name, checklist_data) {
    me.setTextElement("GroupName", group);
    me.setTextElement("Name", name);

    if (checklist_data == nil) {
      me.checklistGroupSelect.setValues([]);
      me.checklistGroupSelect.setValues([]);
      me.checklistDisplay.setValues([]);
      return;
    }

    # Populate the list of groups
    var grouplist = [];
    foreach (var grp; keys(checklist_data)) {
      append(grouplist, { GroupItem : substr(grp, 0, 20) } );
    }

    me.checklistGroupSelect.setValues(grouplist);

    # Populate the list of checklists for this group
    var checklist_group = checklist_data[group];
    var checklistlist = [];
    foreach (var checklist; keys(checklist_group)) {
      append(checklistlist, { ChecklistItem : checklist } );
    }

    me.checklistSelect.setValues(checklistlist);

    # Finally, populate the checklist itself!
    var checklist = checklist_group[name];
    var checklistitems = [];
    foreach (var item; checklist) {
      append(checklistitems, {
        "ItemName" : item.Name,
        "ItemValue" : item.Value,
        "ItemBox"  : 1,
        "ItemDots" : 1,
        "ItemTick" : item.Checked,
        "ItemSelect" : size(checklistitems),
      });
    }

    me.checklistDisplay.setValues(checklistitems);
  },

  displayChecklistSelect : func () {
    me.getElement("Select").setVisible(1);
    me.checklistSelect.displayGroup();
    me.checklistSelect.showCRSR();
  },

  hideChecklistSelect : func () { me.getElement("Select").setVisible(0); },
  isChecklistSelectVisible : func() { return me.getElement("Select").getVisible(); },

  displayGroupSelect : func () {
    me.getElement("GroupSelect").setVisible(1);
    me.checklistGroupSelect.displayGroup();
    me.checklistGroupSelect.showCRSR();
  },

  hideGroupSelect    : func () { me.getElement("GroupSelect").setVisible(0); },
  isGroupSelectVisible : func() { return me.getElement("GroupSelect").getVisible(); },

  displayItemSelect : func () {
    me.checklistDisplay.displayGroup();
    me.checklistDisplay.showCRSR();
  },

  hideItemSelect    : func () {
    me.checklistDisplay.hideCRSR();
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
    pg.addMenuItem(0, "ENGINE", pg, pg.mfd.EIS.engineMenu);
    pg.addMenuItem(2, "MAP", pg, pg.mfd.NavigationMap.mapMenu);
    pg.addMenuItem(5, "CHECK", pg,
      func(dev, pg, mi) { pg.getController().toggleCurrentItem(); dev.updateMenus(); }, # callback
      func(svg, mi) { pg.displayCheckUncheck(svg); }  # Display function
    );
    pg.addMenuItem(10, "EXIT", pg,
      # This should return to the previous page...
      func(dev, pg, mi) { dev.selectPage(pg.getMFD().getPage("NavigationMap")); },
    );

    pg.addMenuItem(11, "EMERGENCY", pg,
      func(dev, pg, mi) { pg.getController().selectEmergencyChecklist(); }, # callback
    );

    device.updateMenus();
  },

  # Display function for the CHECK/UNCHECK softkey
  displayCheckUncheck : func (svg) {
    if (me.checklistDisplay.getValue()) {
      svg.setText("UNCHECK");
    } else {
      svg.setText("CHECK");
    }
    svg.setVisible(1);
  },
};


# A modified GroupElement for specific use by the checklist function.
#
# Key differences:
#  - Current selected item is shown in white.
#  - Checked items are shown in green
#  - Unchecked items are shown in blue.
var ChecklistGroupElement =
{

new : func (page, svg, displaysize, scrollTroughElement=nil, scrollThumbElement=nil, scrollHeight=0, style=nil)
{
  var obj = {
    parents : [ ChecklistGroupElement ],
    _page : page,
    _pageName : page.pageName,
    _svg : svg,
    _style : style,
    _scrollTroughElement : nil,
    _scrollThumbElement : nil,
    _scrollBaseTransform : nil,

    # A hash mapping keys to the element name prefix of an SVG element
    _textElementNames : ["ItemName", "ItemValue"],
    _highlightElementNames : ["ItemBox", "ItemTick", "ItemDots", "ItemSelect"],

    # The size of the group.  For each of the ._textElementNames hash values there
    # must be an SVG Element [pageName][elementName]{0...pageSize}
    _size : displaysize,

    # Length of the scroll bar.
    _scrollHeight : scrollHeight,

    # List of values to display
    _values : [],

    # List of SVG elements to display the values
    _elements : [],

    # Cursor index into the _values array
    _crsrIndex : 0,

    # Whether the CRSR is enabled
    _crsrEnabled : 0,

    # Page index - which _values index element[0] refers to.  The currently
    # selected _element has index (_crsrIndex - _pageIndex)
    _pageIndex : 0,
  };

  # Optional scroll bar elements, consisting of the Thumb and the Trough *,
  # which will be used to display the scroll position.
  # * Yes, these are the terms of art for the elements.
  assert(((scrollTroughElement == nil) and (scrollThumbElement == nil)) or
         ((scrollTroughElement != nil) and (scrollThumbElement != nil)),
         "Both the scroll trough element and the scroll thumb element must be defined, or neither");

  if (scrollTroughElement != nil) {
    obj._scrollTroughElement = svg.getElementById(obj._pageName ~ scrollTroughElement);
    assert(obj._scrollTroughElement != nil, "Unable to find scroll element " ~ obj._pageName ~ scrollTroughElement);
  }
  if (scrollThumbElement != nil) {
    obj._scrollThumbElement = svg.getElementById(obj._pageName ~ scrollThumbElement);
    assert(obj._scrollThumbElement != nil, "Unable to find scroll element " ~ obj._pageName ~ scrollThumbElement);
    obj._scrollBaseTransform = obj._scrollThumbElement.getTranslation();
  }

  if (style == nil) obj._style = PFD.DefaultStyle;

  for (var i = 0; i < displaysize; i = i + 1) {
    append(obj._elements, PFD.HighlightElement.new(obj._pageName, svg, "ItemSelect" ~ i, i, obj._style));
  }

  return obj;
},

# Set the values of the group. values_array is an array of hashes, each of which
# has keys that match those of ._textElementNames
setValues : func (values_array) {
  me._values = values_array;
  #me._pageIndex = 0;
  #me._crsrIndex = 0;

  if (size(me._values) > me._size) {
    # Number of elements exceeds our ability to display them, so enable
    # the scroll bar.
    if (me._scrollThumbElement  != nil) me._scrollThumbElement.setVisible(1);
    if (me._scrollTroughElement != nil) me._scrollTroughElement.setVisible(1);
  } else {
    # There is no scrolling to do, so hide the scrollbar.
    if (me._scrollThumbElement  != nil) me._scrollThumbElement.setVisible(0);
    if (me._scrollTroughElement != nil) me._scrollTroughElement.setVisible(0);
  }

  me.displayGroup();
},

displayGroup : func () {

  # The _crsrIndex element should be displayed as close to the middle of the
  # group as possible. So as the user scrolls the list appears to move around
  # a static cursor position.
  #
  # The exceptions to this is as the _crsrIndex approaches the ends of the list.
  # In these cases, we let the cursor move to the top or bottom of the list.

  # Check the CRSR index is valid
  if (me._crsrIndex > (size(me._values) -1)) me._crsrIndex = 0;

  # Determine the middle element
  var middle_element_index = math.ceil(me._size / 2);
  me._pageIndex = me._crsrIndex - middle_element_index;

  if ((size(me._values) <= me._size) or (me._crsrIndex < middle_element_index)) {
    # Start of list or the list is too short to require scrolling
    me._pageIndex = 0;
  } else if (me._crsrIndex > (size(me._values) - middle_element_index - 1)) {
    # End of list
    me._pageIndex = size(me._values) - me._size;
  }

  for (var i = 0; i < me._size; i = i + 1) {
    if (me._pageIndex + i < size(me._values)) {

      var value = me._values[me._pageIndex + i];
      var checked = 0;
      var crsr = 0;

      if (value["ItemTick"] == 1) checked = 1;
      if (me._crsrEnabled and (i + me._pageIndex  == me._crsrIndex)) crsr = 1;

      foreach (var k; keys(value)) {

        var name = me._pageName ~ k ~ i;
        var element  = me._svg.getElementById(name);
        assert(element != nil, "Unable to find element " ~ name);

        if (k == "ItemSelect") {
          # Display if this is the cursor element
          element.setVisible(crsr);
        } else if (k == "ItemTick") {
          # Check the box if appropriate
          element.setVisible(checked);
        } else if (k == "ItemBox") {
          # Always display the box, but don't colour it.
          element.setVisible(1);
        } else if (k == "ItemDots") {
          # Always display the dots
          element.setVisible(1);

          if (crsr) {
            # White - current cursor
            element.setColor("#FFFFFF");
          } else if (checked) {
            # Green - checked
            element.setColor("#00FF00");
          } else {
            # Cyan - unchecked
            element.setColor("#00FFFF");
          }
        } else if ((k == "ItemName") or (k == "ItemValue")) {
          element.setVisible(1);
          # We need to fill the bounding box with black so that we don't
          # see the underlying dots.
          element.setText(value[k])
                 .setDrawMode(canvas.Text.TEXT + canvas.Text.FILLEDBOUNDINGBOX)
                 .setPadding(2)
                 .setColorFill("#000000");

          if (crsr) {
            # White - current cursor
            element.setColor("#FFFFFF");
          } else if (checked) {
            # Green - checked
            element.setColor("#00FF00");
          } else {
            # Cyan - unchecked
            element.setColor("#00FFFF");
          }
        } else {
          print("Unknown value " ~ k);
        }
      }
    } else {
      # We've gone off the end of the values list, so hide any further values.
      foreach (var k; me._textElementNames) {
        var name = me._pageName ~ k ~ i;
        var element  = me._svg.getElementById(name);
        assert(element != nil, "Unable to find element " ~ name);
        element.setVisible(0);
      }
      foreach (var k; me._highlightElementNames) {
        var name = me._pageName ~ k ~ i;
        var element  = me._svg.getElementById(name);
        assert(element != nil, "Unable to find element " ~ name);
        element.setVisible(0);
      }
    }
  }

  if ((me._scrollThumbElement != nil) and (me._size < size(me._values))) {
    # Shift the scrollbar if it's relevant
    me._scrollThumbElement.setTranslation([
      me._scrollBaseTransform[0],
      me._scrollBaseTransform[1] + me._scrollHeight * (me._crsrIndex / (size(me._values) -1))
    ]);
  }

  # Indicate whether we're finished with this checklist or not
  var finished = me.isComplete();
  me._page.getTextElement("Finished").setVisible(finished);
  me._page.getTextElement("NotFinished").setVisible(! finished);

  # Update the softkeys, which will in particular change the CHECK/UNCHECK softkeys
  # appropriately.
  me._page.device.updateMenus();
},

isComplete : func() {
  var finished = 1;
  foreach (var entry; me._values) {
    if (entry["ItemTick"] == 0) {
      finished = 0;
      break;
    }
  }

  return finished;
},

# Methods to add dynamic elements to the group.  Must be called in the
# scroll order, as they are simply appended to the end of the list of elements!
addHighlightElement : func(name, value) {
  append(me._elements, HighlightElement.new(me._pageName, me._svg, name, value));
},
addTextElement : func(name, value) {
  append(me._elements, TextElement.new(me._pageName, me._svg, name, value));
},

showCRSR : func() {
  if (size(me._values) == 0) return;
  me._crsrEnabled = 1;
  me.displayGroup();
},
hideCRSR : func() {
  if (me._crsrEnabled == 0) return;
  me._crsrEnabled = 0;
  me.displayGroup();
},
setCRSR : func(index) {
  me._crsrIndex = math.min(index, size(me._values) -1);
  me._crsrIndex = math.max(0, me._crsrIndex);
},
getCRSR : func() {
  return me._crsrIndex;
},
getCursorElementName : func() {
  if (me._crsrEnabled == -1) return nil;
  return me._elements[me._crsrIndex - me._pageIndex].name;
},
isCursorOnDataEntryElement : func() {
  if (me._crsrEnabled == -1) return 0;
  return isa(me._elements[me._crsrIndex - me._pageIndex], DataEntryElement);
},
enterElement : func() {
  if (me._crsrEnabled == 0) return;

  # ENT on an element of the checklist checks the box,
  # indicated by whether the check mark is visible or not.
  var name = me._pageName ~ "ItemTick" ~ (me._crsrIndex - me._pageIndex);
  var element  = me._svg.getElementById(name);
  element.setVisible(1);
  return element.getVisible();
},
getValue : func() {
  if (me._crsrEnabled == -1) return nil;

  # In this case, all we care about is whether this particular value is
  # checked or not.
  var name = me._pageName ~ "ItemTick" ~ (me._crsrIndex - me._pageIndex);
  var element  = me._svg.getElementById(name);
  return element.getVisible();
},
setValue : func(idx, key, value) {
  me._values[idx][key] = value;
},
clearElement : func() {
  if (me._crsrEnabled == 0) return;

  # CLR on an element of the checklist unchecks the box,
  # indicated by whether the check mark is visible or not.
  var name = me._pageName ~ "ItemTick" ~ (me._crsrIndex - me._pageIndex);
  var element  = me._svg.getElementById(name);
  element.setVisible(0);
  return element.getVisible();
},
incrSmall : func(value) {
  if (me._crsrEnabled == 0) return;

  var incr_or_decr = (value > 0) ? 1 : -1;
  if (me._elements[me._crsrIndex - me._pageIndex].isInEdit()) {
    # We're editing, so pass to the element.
    me._elements[me._crsrIndex - me._pageIndex].incrSmall(val);
  } else {
    # Move to next selection element
    me._crsrIndex = me._crsrIndex + incr_or_decr;
    if (me._crsrIndex <  0               ) me._crsrIndex = 0;
    if (me._crsrIndex == size(me._values)) me._crsrIndex = size(me._values) -1;
    me.displayGroup();
  }
},
incrLarge : func(val) {
  if (me._crsrEnabled == 0) return;
  var incr_or_decr = (val > 0) ? 1 : -1;
  if (me._elements[me._crsrIndex - me._pageIndex].isInEdit()) {
    # We're editing, so pass to the element.
    me._elements[me._crsrIndex - me._pageIndex].incrLarge(val);
  } else {
    # Move to next selection element
    me._crsrIndex = me._crsrIndex + incr_or_decr;
    if (me._crsrIndex <  0               ) me._crsrIndex = 0;
    if (me._crsrIndex == size(me._values)) me._crsrIndex = size(me._values) -1;
    me.displayGroup();
  }
},
};
