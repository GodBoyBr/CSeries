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
# FG Commands to support simple bindings
io.include("Constants.nas");

removecommand("FG1000HardKeyPushed");
addcommand("FG1000HardKeyPushed",
  func(node) {
    var device = node.getNode("device", 1).getValue();
    var name = node.getNode("notification",1).getValue();

    # The knob animation stores the value as an offset property
    var value = node.getNode("offset", 1).getValue();

    if (name == nil) {
      print("FG1000HardKeyPushed: No <name> argument passed to fgcommand");
      return;
    }

    if (value == nil) {
      print("FG1000HardKeyPushed: No <offset> argument passed to fgcommand");
      return;
    }

    if (device == nil) {
      print("FG1000HardKeyPushed: No <device> argument passed to fgcommand for " ~ name);
      return;
    }

    # Notification may be provided as a number, or a string.
    if (int(name) == nil) {
      # Name is a string, to map it to the correct INT id.
      if (FASCIA[name] != nil) {
        name = FASCIA[name];
      } else {
        print("Unable to find FASCIA entry for Hard Key " ~ name);
        return;
      }
    }

    var notification = notifications.PFDEventNotification.new(
      "MFD",
      int(device),
      notifications.PFDEventNotification.HardKeyPushed,
      { Id: name, Value: value }
    );
    emesary.GlobalTransmitter.NotifyAll(notification);
  }
);

removecommand("FG1000SoftKeyPushed");
addcommand("FG1000SoftKeyPushed",
  func(node) {
    var device = int(node.getNode("device", 1).getValue());
    var value = node.getNode("offset", 1).getValue();

    if (device == nil) {
      print("FG1000SoftKeyPushed: Unknown device" ~ node.getNode("device").getValue());
      return;
    }

    if (value == nil) {
      print("FG1000SoftKeyPushed: No <offset> value for softkey number");
      return;
    }

    if (int(value) == nil) {
      print("Unable to convert softkey number to integer " ~ node.getNode("value").getValue());
      return;
    }

    value = int(value);

    var notification = notifications.PFDEventNotification.new(
      "MFD",
      device,
      notifications.PFDEventNotification.SoftKeyPushed,
      value
    );
    emesary.GlobalTransmitter.NotifyAll(notification);
  }
);

# This command is a convenience for multi-key/menu support to make it easier to
# navigate to particular pages without having to use the FMS knobs.
removecommand("FG1000SelectPage");
addcommand("FG1000SelectPage",
  func(node) {
    var device = node.getNode("device", 1).getValue();
    var group = node.getNode("group",1).getValue();
    var page = node.getNode("page",1).getValue();

    if (group == nil) {
      print("FG1000SelectPage: No <group> argument passed to fgcommand");
      return;
    }

    if (page == nil) {
      print("FG1000SelectPage: No <page> argument passed to fgcommand");
      return;
    }

    if (device == nil) {
      print("FG1000SelectPage: No <device> argument passed to fgcommand for " ~ name);
      return;
    }

    var notification = notifications.PFDEventNotification.new(
      "MFD",
      int(device),
      notifications.PFDEventNotification.SelectPageById,
      { Group: group, Page: page }
    );
    emesary.GlobalTransmitter.NotifyAll(notification);
  }
);
