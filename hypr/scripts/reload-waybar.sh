#!/bin/bash

killall kanshi
kanshi > /dev/null 2>&1 &
killall waybar
waybar > /dev/null 2>&1 &
