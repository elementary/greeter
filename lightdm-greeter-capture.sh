#!/bin/bash
sleep 30
DISPLAY=:0 XAUTHORITY=/var/run/lightdm/root/$DISPLAY xwd -root > /tmp/greeter.xwd
convert /tmp/greeter.xwd /home/$(whoami)/Pictures/greeter.png
