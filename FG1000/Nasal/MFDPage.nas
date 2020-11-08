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
# FG1000 MFD Page base class

# Load the PFD UI Elements
var mfd_dir = getprop("/sim/fg-root") ~ "/Nasal/canvas/PFD/";
var loadPFDFile = func(file) io.load_nasal(mfd_dir ~ file, "PFD");

loadPFDFile("DefaultStyle.nas");
loadPFDFile("UIElement.nas");
loadPFDFile("HighlightTimer.nas");
loadPFDFile("TextElement.nas");
loadPFDFile("HighlightElement.nas");
loadPFDFile("GroupElement.nas");
loadPFDFile("ScrollElement.nas");
loadPFDFile("DataEntryElement.nas");
loadPFDFile("PointerElement.nas");
loadPFDFile("RotatingElement.nas");

var MFDPage =
{

new : func (mfd, myCanvas, device, SVGGroup, pageName, title)
{
  var obj = {
    pageName : pageName,
    _group : myCanvas.createGroup(pageName ~ "Layer"),
    _SVGGroup : SVGGroup,
    parents : [ MFDPage, device.addPage(title, pageName ~ "Group") ],
    _textElements : {},
    _controller : nil,
    _elements : {},
  };

  obj.device = device;
  obj.mfd = mfd;

  # Pick up Style, Options and Controller
  var code = "obj.Styles  = fg1000." ~ pageName ~ "Styles.new(); " ~
             "obj.Options = fg1000." ~ pageName ~ "Options.new();";
  var createStylesAndOptions = compile(code);
  createStylesAndOptions();

  # Need to display this underneath the softkeys, EIS, header.
  obj._group.setInt("z-index", -10.0);
  obj._group.setVisible(0);

  return obj;
},

addElement : func(e) {
  if (me._elements[e] == nil) {
    var element = me._SVGGroup.getElementById(me.pageName ~ e);
    if (element != nil) {
      me._elements[e] = element;
    } else {
      die("Unable to find element " ~ me.pageName ~ e);
    }
  } else {
    die("Element already exists: "~ me.pageName ~ e);
  }
},

elementExists : func(e) {
  var element = me._SVGGroup.getElementById(me.pageName ~ e);
  return (element != nil);
},

addElements : func(elements) {
  foreach (var e; elements) {
    me.addElement(e);
  }
},

getElement : func(e) {
  if (me._elements[e] == nil) me.addElement(e);
  return me._elements[e];
},

addTextElements : func(symbols, style=nil) {
  foreach (var s; symbols) {
    me._textElements[s] = PFD.TextElement.new(me.pageName, me._SVGGroup, s, "", style);
  }
},

addTextElement : func(e, style=nil) {
  if (me._textElements[e] == nil) {
    me._textElements[e] = PFD.TextElement.new(me.pageName, me._SVGGroup, e, "", style);
  } else {
    die("addTextElement element already exists: "~ me.pageName ~ e);
  }
},

getTextElement : func(symbolName) {
  return me._textElements[symbolName];
},

highlightTextElement : func(symbolName, highlightime=-1) {
  me._textElements[symbolName].highlightElement(highlightime);
},

unhighlightTextElement : func(symbolName) {
  me._textElements[symbolName].unhighlightElement();
},

getTextValue : func(symbolName) {
  var sym = me._textElements[symbolName];
  assert(sym != nil, "Unknown text element " ~ symbolName ~ " (check your addTextElements call?)");
  return sym.getValue();
},

setTextElement : func(symbolName, value) {
  var sym = me._textElements[symbolName];
  assert(sym != nil, "Unknown text element " ~ symbolName ~ " (check your addTextElements call?)");
  if (value == nil ) value = "";
  sym.setValue(value);
},

setTextElements : func(symbols, value) {
  foreach (var s; symbols) {
    me.setTextElement(s, value);
  }
},

setTextElementLat : func(symbolName, value) {
  if ((value == nil) or (int(value) == nil)) {
    me.setTextElement(symbolName, "_ __°__.__'");
  } else {
    var degrees_part = int(value);
    var minutes_part = 100.0 * (value - degrees_part);
    if (value < 0.0) {
      me.setTextElement(symbolName, sprintf("S %2d°%.2f'", -degrees_part, -minutes_part));
    } else {
      me.setTextElement(symbolName, sprintf("N %2d°%.2f'", degrees_part, minutes_part));
    }
  }
},

setTextElementLon : func(symbolName, value) {
  if ((value == nil) or (int(value) == nil)) {
    me.setTextElement(symbolName, "____°__.__'");
  } else {
    var degrees_part = int(value);
    var minutes_part = 100.0 * (value - degrees_part);
    if (value < 0.0) {
      me.setTextElement(symbolName, sprintf("W%3d°%.2f'", -degrees_part, -minutes_part));
    } else {
      me.setTextElement(symbolName, sprintf("E%3d°%.2f'", degrees_part, minutes_part));
    }
  }
},

setTextElementBearing : func(symbolName, brg) {
  if ((brg == nil) or (brg == "")) {
    me.setTextElement(symbolName, "___°");
  } else {
    me.setTextElement(symbolName, sprintf("%i°", brg));
  }
},

setTextElementMagVar : func(symbolName, brg) {
  if ((brg == nil) or (brg == "")) {
    me.setTextElement(symbolName, "___°");
  } else {
    if (brg < 0.0) {
      me.setTextElement(symbolName, sprintf("%i°W", -brg));
    } else {
      me.setTextElement(symbolName, sprintf("%i°E", brg));
    }
  }
},


setTextElementDistance : func(symbolName, dst) {
  if ((dst == nil) or (dst == "")) {
    me.setTextElement(symbolName, "___nm");
  } else {
    me.setTextElement(symbolName, sprintf("%.1fnm", dst));
  }
},

setTextElementNavFreq : func(symbolName, freq) {
  if ((freq == nil) or (freq == "")) {
    me.setTextElement(symbolName, "___.__");
  } else {
    me.setTextElement(symbolName, sprintf("%0.02f", freq));
  }
},

setTextElementComFreq : func(symbolName, freq) {
  if ((freq == nil) or (freq == "")) {
    me.setTextElement(symbolName, "___.___");
  } else {
    # 8.33Hz spacing
    me.setTextElement(symbolName, sprintf("%0.03f", freq));
  }
},

# Function to undo any colors set by display_toggle when loading a new menu
resetMenuColors : func() {
  for(var i = 0; i < 12; i +=1) {
    var name = sprintf("SoftKey%d",i);
    me.device.svg.getElementById(name ~ "-bg").setColorFill(0.0,0.0,0.0);
    me.device.svg.getElementById(name).setColor(1.0,1.0,1.0);
  }
},

getController : func() {
  return me._controller;
},
setController : func (controller) {
  me._controller = controller;
},

getDevice : func() {
  return me.device;
},
getMFD : func() {
  return me.mfd;
},
getPageName : func () {
  return me.pageName;
},
getSVG : func() {
  return me._SVGGroup;
},
getGroup : func() {
  return me._group;
},

};
