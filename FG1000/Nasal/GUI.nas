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

var GUI =
{
  # List of UI hotspots and their mapping to Emesary bridge notifications
  WHEEL_HOT_SPOTS : [
    { notification: fg1000.FASCIA.NAV_VOL, shift: 0, top_left: [65, 45], bottom_right: [112, 90] },
    { notification: fg1000.FASCIA.NAV_INNER, shift: 0, top_left: [45, 168], bottom_right: [135, 250] },
    { notification: fg1000.FASCIA.NAV_OUTER, shift: 1, top_left: [45, 168], bottom_right: [135, 250] },
    { notification: fg1000.FASCIA.HEADING, shift: 0, top_left: [45, 338], bottom_right: [135, 411] },
    { notification: fg1000.FASCIA.ALT_INNER, shift: 0, top_left: [45, 800], bottom_right: [135, 880] },
    { notification: fg1000.FASCIA.ALT_OUTER, shift: 1, top_left: [45, 800], bottom_right: [135, 880] },


    { notification: fg1000.FASCIA.COM_VOL, shift: 0, top_left: [1290, 45], bottom_right: [1340, 90] },
    { notification: fg1000.FASCIA.COM_INNER, shift: 0, top_left: [1275, 170], bottom_right: [1355, 245] },
    { notification: fg1000.FASCIA.COM_OUTER, shift: 1, top_left: [1275, 170], bottom_right: [1355, 245] },

    { notification: fg1000.FASCIA.CRS, shift: 0, top_left: [1275, 331], bottom_right: [1355, 410] },
    { notification: fg1000.FASCIA.BARO, shift: 1, top_left: [1275, 331], bottom_right: [1355, 410] },

    { notification: fg1000.FASCIA.RANGE, shift: 0, top_left: [1275, 497], bottom_right: [1355, 554] },

    { notification: fg1000.FASCIA.FMS_INNER, shift: 0, top_left: [1275, 800], bottom_right: [1355, 880] },
    { notification: fg1000.FASCIA.FMS_OUTER, shift: 1, top_left: [1275, 800], bottom_right: [1355, 880] },
  ],

  CLICK_HOT_SPOTS : [
    { notification: fg1000.FASCIA.NAV_ID,            shift: 0, value: 1, top_left: [65, 47], bottom_right: [112, 90] },
    { notification: fg1000.FASCIA.NAV_FREQ_TRANSFER, shift: 0, value: 1, top_left: [100, 102], bottom_right: [150, 138] },
    { notification: fg1000.FASCIA.NAV_TOGGLE, shift: 0, value: 1, top_left: [45, 168], bottom_right: [135, 250] },
    { notification: fg1000.FASCIA.HEADING_PRESS, shift: 0, value: 1, top_left: [45, 338], bottom_right: [135, 411] },

    { notification: fg1000.FASCIA.COM_VOL_TOGGLE, shift: 0, value: 1, top_left: [1290, 45], bottom_right: [1340, 90] },
    { notification: fg1000.FASCIA.COM_FREQ_TRANSFER, shift: 0, value: 1, top_left: [1250, 100], bottom_right: [1300, 140] },
    { notification: fg1000.FASCIA.COM_FREQ_TRANSFER_HOLD, shift: 1, value: 1, top_left: [1250, 100], bottom_right: [1300, 140] },
    { notification: fg1000.FASCIA.COM_TOGGLE, shift: 0, value: 1, top_left: [1275, 170], bottom_right: [1355, 245] },

    { notification: fg1000.FASCIA.CRS_CENTER, shift: 0, value: 1, top_left: [1275, 331], bottom_right: [1355, 410] },

    { notification: fg1000.FASCIA.JOYSTICK_PRESS, shift: 0, value: 1, top_left: [1295, 500], bottom_right: [1345, 550] },

    { notification: fg1000.FASCIA.JOYSTICK_HORIZONTAL, shift: 0, value: -1, top_left: [1255, 500], bottom_right: [1285, 550] },
    { notification: fg1000.FASCIA.JOYSTICK_HORIZONTAL, shift: 0, value: 1, top_left: [1345, 500], bottom_right: [1380, 550] },

    { notification: fg1000.FASCIA.JOYSTICK_VERTICAL, shift: 0, value: -1, top_left: [1295, 465], bottom_right: [1345, 500] },
    { notification: fg1000.FASCIA.JOYSTICK_VERTICAL, shift: 0, value: 1, top_left: [1295, 550], bottom_right: [1345, 585] },

    { notification: fg1000.FASCIA.DTO, shift: 0, value: 1, top_left: [1255, 620], bottom_right: [1305, 660] },
    { notification: fg1000.FASCIA.FPL, shift: 0, value: 1, top_left: [1255, 670], bottom_right: [1305, 710] },
    { notification: fg1000.FASCIA.CLR, shift: 0, value: 1, top_left: [1255, 720], bottom_right: [1305, 760] },
    { notification: fg1000.FASCIA.CLR_HOLD, shift: 1, value: 1, top_left: [1255, 720], bottom_right: [1305, 760] },

    { notification: fg1000.FASCIA.MENU, shift: 0, value: 1, top_left: [1325, 620], bottom_right: [1380, 660] },
    { notification: fg1000.FASCIA.PROC, shift: 0, value: 1, top_left: [1325, 670], bottom_right: [1380, 710] },
    { notification: fg1000.FASCIA.ENT, shift: 0, value: 1, top_left: [1325, 720], bottom_right: [1380, 760] },

    { notification: fg1000.FASCIA.FMS_CRSR, shift: 0, value: 1, top_left: [1275, 800], bottom_right: [1355, 880] },
  ],

  SOFTKEY_HOTSPOTS : [
    { Id: 1, top_left: [205, 830], bottom_right: [265, 875] },
    { Id: 2, top_left: [290, 830], bottom_right: [350, 875] },
    { Id: 3, top_left: [375, 830], bottom_right: [435, 875] },
    { Id: 4, top_left: [460, 830], bottom_right: [520, 875] },
    { Id: 5, top_left: [545, 830], bottom_right: [605, 875] },
    { Id: 6, top_left: [630, 830], bottom_right: [690, 875] },
    { Id: 7, top_left: [715, 830], bottom_right: [775, 875] },
    { Id: 8, top_left: [800, 830], bottom_right: [860, 875] },
    { Id: 9, top_left: [885, 830], bottom_right: [945, 875] },
    { Id: 10, top_left: [970, 830], bottom_right: [1030, 875] },
    { Id: 11, top_left: [1055, 830], bottom_right: [1115, 875] },
    { Id: 12, top_left: [1145, 830], bottom_right: [1200, 875] },
  ],

  new : func(mfd, mfd_canvas, device_id, scale = 1.0)
  {
    var obj = {
      parents : [ GUI ],
      mfd : mfd,
      eisPublisher : nil,
      navcomPublisher : nil,
      navcomUpdater : nil,
      navdataInterface : nil,
      width : 1407,
      height : 918,
      scale : scale,
      device_id : device_id,
    };

    obj.window = canvas.Window.new([obj.scale*obj.width,obj.scale*obj.height],"dialog");
    obj.window.set('title',"FG1000 Device " ~ device_id ~ " (" ~ int(scale * 100) ~ "%)");

    obj.window.del = func() {
      # Over-ride the window.del function so we clean up when the user closes the window
      # Use call method to ensure we have the correct closure.
      call(obj.cleanup, [], obj);
    };

    # creating the top-level/root group which will contain all other elements/group
    obj.myCanvas = obj.window.createCanvas();
    obj.myCanvas.set("name", "MFD");
    obj.root = obj.myCanvas.createGroup();

    # Project the canvas onto the dialog
    var mfd_child = obj.root.createChild("image")
      .setFile(mfd_canvas.getPath())
      .set("z-index", 150)
      .setTranslation(obj.scale*186,obj.scale*45)
      .setSize(obj.scale*1024, obj.scale*768);


    # Create the surround fascia, which is just a PNG image;
    var child = obj.root.createChild("image")
        .setFile("Aircraft/Instruments-3d/FG1000/Dialogs/fascia.png")
        .set("z-index", 100)
        .setTranslation(0, 0)
        .setSize(obj.scale*obj.width,obj.scale*obj.height);

    # Add a event listener for the mouse wheel, which is used for turning the
    # knobs.
    obj.myCanvas.addEventListener("wheel", func(e)
    {
      foreach(var hotspot; GUI.WHEEL_HOT_SPOTS) {
        if ((e.localX > obj.scale*hotspot.top_left[0]) and (e.localX < obj.scale*hotspot.bottom_right[0]) and
            (e.localY > obj.scale*hotspot.top_left[1]) and (e.localY < obj.scale*hotspot.bottom_right[1]) and
            (e.shiftKey == hotspot.shift))
        {
          # We've found the hotspot, so send a notification to deal with it
          var args = {'device': obj.device_id,
                      'notification': hotspot.notification,
                      'offset' : e.deltaY};

          fgcommand("FG1000HardKeyPushed", props.Node.new(args));
          break;
        }
      }
    });

    # Add a event listener for the mouse click, which is used for buttons
    obj.myCanvas.addEventListener("click", func(e)
    {
      foreach(var hotspot; GUI.CLICK_HOT_SPOTS) {
        if ((e.localX > obj.scale*hotspot.top_left[0]) and (e.localX < obj.scale*hotspot.bottom_right[0]) and
            (e.localY > obj.scale*hotspot.top_left[1]) and (e.localY < obj.scale*hotspot.bottom_right[1]) and
            (e.shiftKey == hotspot.shift))
        {
          # We've found the hotspot, so send a notification to deal with it
          var args = {'device': obj.device_id,
                      'notification': hotspot.notification,
                      'offset' : hotspot.value};

          fgcommand("FG1000HardKeyPushed", props.Node.new(args));
          break;
        }
      }

      foreach(var hotspot; GUI.SOFTKEY_HOTSPOTS) {
        if ((e.localX > obj.scale*hotspot.top_left[0]) and (e.localX < obj.scale*hotspot.bottom_right[0]) and
            (e.localY > obj.scale*hotspot.top_left[1]) and (e.localY < obj.scale*hotspot.bottom_right[1]))
        {
          # We've found the hotspot, so send a notification to deal with it
          var args = {'device': obj.device_id,
                      'offset' : hotspot.Id};
          fgcommand("FG1000SoftKeyPushed", props.Node.new(args));
          break;
        }
      }
    });

    return obj;
  },

  cleanup : func()
  {
    # Clean up the MFD.  Particularly important to stop if picking up
    # Emesary notifications.
    me.mfd.del();
    # Clean up the window itself
    call(canvas.Window.del, [], me.window);
  },
};
