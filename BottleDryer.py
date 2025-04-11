#!/usr/bin/env python3
# -*- coding: utf-8 -*-
""" Bulk create a set otf bottle dryer STL files """

import os

from itertools import product
from numbers import Number
from subprocess import Popen
from typing import List

variables = {'stand_count': range(1, 10), 'fan_diameter': [40, 80], 'base_type': ['SEPARATE', 'COMMON']}

permutations = []
keys = list(variables.keys())
values = [variables[key] for key in keys]
for value_tuple in product(*values):
    permutations.append(dict(zip(keys, value_tuple)))

calls = []
for params in permutations:
    out_file = f'BottleDryer_{params["stand_count"]}Arms_{params["fan_diameter"]}mmFan_{params["base_type"][0]}{params["base_type"][1:].lower()}Base'
    call = ['openscad', '-o', f'{out_file}.stl', '-o', f'{out_file}.png', '-D', '$fn=200', '--imgsize=1000,1000']
    for key, value in params.items():
        if not isinstance(value, Number):
            value = f'"{value}"'
        call.extend(['-D', f'{key}={value}'])
    call.append('BottleDryer.scad')
    calls.append(call)

cpu_count = 2
processes = set()

for call in calls:
    print(f'Running: {" ".join(call)}')
    processes.add(Popen(call))
    if len(processes) >= cpu_count:
        os.wait()
        processes.difference_update([
            p for p in processes if p.poll() is not None])
for p in processes:
    p.wait()

