__author__ = 'ppiippo'

import os
import pprint
import sys

import common

def parse_confs(conf1, conf2):

    keys = []

    only_first = []
    same = []
    different = []
    only_second = []

    clines1 = conf1.split('\n')
    clines2 = conf2.split('\n')

    for line in clines1:
        key, val = common.parse_conf_key_value(line)
        if key:
            keys.append(key)
            line2 = common.find_key(clines2, key)
            if line2:
                key2, val2 = common.parse_conf_key_value(line2)
                if not key:
                    continue
                if val == val2:
                    same.append((key, val))
                else:
                    different.append((key, val, val2))
            else:
                only_first.append((key, val))

    for line in clines2:
        key, val = common.parse_conf_key_value(line)
        if key and key not in keys:
            only_second.append((key, val))

    print ("*****Keys only in first config:")
    pprint.pprint(only_first)
    print ""
    print ("*****Keys only in second config:")
    pprint.pprint(only_second)
    print ""
    print ("*****Keys with similar values:")
    pprint.pprint(same)
    print ""
    print ("*****Keys with different values:")
    pprint.pprint(different)



with open(sys.argv[1], 'r') as fy:
    conf1 = fy.read()

with open(sys.argv[2], 'r') as fy:
    conf2 = fy.read()


parse_confs(conf1, conf2)
