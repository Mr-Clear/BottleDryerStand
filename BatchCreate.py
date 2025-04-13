#!/usr/bin/env python3
# -*- coding: utf-8 -*-
""" Bulk create a set of bottle dryer STL files """

import os

from itertools import product
from numbers import Number
from subprocess import Popen
from typing import List

quality = 20
image_size = (100, 100)
variables = {'stand_count': range(1, 11, 1),
             'fan_diameter': [40, 50, 60, 70, 80, 92, 120, 140, 200, 220], 
             'base_type': ['SEPARATE', 'COMMON']}
cpu_count = 8

permutations = []
keys = list(variables.keys())
values = [variables[key] for key in keys]
for value_tuple in product(*values):
    permutations.append(dict(zip(keys, value_tuple)))

calls = []
for params in permutations:
    out_file = f'BottleDryer_{params["stand_count"]}Arms_{params["fan_diameter"]}mmFan_{params["base_type"][0]}{params["base_type"][1:].lower()}Base'
    call = ['openscad', '-o', f'{out_file}.stl', '-o', f'{out_file}.png', '-D', '$fn={quality}', '--imgsize={image_size[0]},{image_size[1]}', '-D', f'$quality={quality}', '-D', f'$imgsize={image_size[0]},{image_size[1]}']

    for key, value in params.items():
        if not isinstance(value, Number):
            value = f'"{value}"'
        call.extend(['-D', f'{key}={value}'])
    call.append('BottleDryer.scad')
    calls.append(call)

processes = set()

for call in calls:
    print(f'Running: {" ".join(call)}')
    processes.add(Popen(call, stdout=None))
    if len(processes) >= cpu_count:
        os.wait()
        processes.difference_update([
            p for p in processes if p.poll() is not None])
for p in processes:
    p.wait()

