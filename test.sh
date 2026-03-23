#!/bin/bash

sed -i "s/^_G\.llm = \".*\"/_G.llm = \"$llm\"/" "$HOME"/.config/nvim/init.lua
