#!/bin/bash
W=$(aerospace list-workspaces --focused)
if [ "$W" = "6" ]; then
  aerospace move-node-to-workspace 7
  aerospace workspace 7
elif [ "$W" = "7" ]; then
  aerospace move-node-to-workspace 6
  aerospace workspace 6
fi
