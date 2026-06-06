#!/bin/bash

# AIO cooler (Corsair H115i Platinum)
liquidctl initialize
liquidctl set led color off

# RAM (G.Skill TridentZ) + GPU (NVIDIA 3070) via OpenRGB
openrgb --noGui --alldevices --color 000000
