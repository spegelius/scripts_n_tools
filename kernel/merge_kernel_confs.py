#!/usr/bin/env python

import os
import sys
import common

conf1 = None
conf2 = None



def parse_confs(conf1, conf2):

    result = []
    
    processed_lines = []
    
    clines1 = conf1.split('\n')
    clines2 = conf2.split('\n')
    
    for line in clines1:
        key, val = common.parse_conf_key_value(line)
        if not key:
            result.append(line)
        else:
            line2 = common.find_key(clines2, key)
            if line2:
                result.append(line2)
                processed_lines.append(line2)
                clines2.remove(line2)

    for line in clines2:
        if line not in processed_lines:
            result.append(line)

    return result

with open(sys.argv[1], 'r') as fy:
    conf1 = fy.read()
    
with open(sys.argv[2], 'r') as fy:
    conf2 = fy.read()


result = parse_confs(conf1, conf2)

with open("resultconf", 'w') as rc:
    rc.write("\n".join(result))