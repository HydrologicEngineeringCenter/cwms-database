#!/bin/python

parms = open("base_parameters.sql").read().split(";")

for p in parms:
    print(repr(p))