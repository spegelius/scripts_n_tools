__author__ = 'ppiippo'

import os

def parse_conf_key_value(line):
    if line.count("CONFIG_"):
        temp = ""
        if line.count("="):
            key = "CONFIG" + line.split("=")[0].split("CONFIG", 1)[1]
            value = line.split("=")[1].split(" ")[0]
            return key, value
        else:
            for i in line.split(" "):
                temp = i
                if i.count("CONFIG_"):
                    break
                temp = ""
        return temp, ""
    return None, None


def find_key(lines, key):

    for line in lines:
        cur_key, val = parse_conf_key_value(line)
        if cur_key and cur_key == key:
            return line


if __name__ == "__main__":

    print parse_conf_key_value(" # CONFIG_TEST_VALUE=y")