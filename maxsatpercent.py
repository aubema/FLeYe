#!/usr/bin/python3
import os
import sys
import numpy as np

user = "sand"
path = "/home/" + user
file = path + "/saturation.tmp"
with open(file, "r") as f:
    words = [word for line in f for word in line.split()]
R = float(words[2])
G = float(words[5])
B = float(words[8])
colors = [R, G, B]
max = round(np.amax(colors) * 100)
print(max)
