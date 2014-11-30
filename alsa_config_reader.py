__author__ = 'ppiippo'


import os
import sys

class AlsaConfig(object):

    def __init__(self, cfg_file):

        self.usecases = {}
        self.devices = {}
        self.modifiers = {}
        try:
            with open(cfg_file, 'r') as cfg:
                self._parse_cfg(cfg.read())
        except:
            raise

    def _parse_cfg(self, data):
        usecase = None
        sectionverb = False
        sectiondevice = False
        sectionmodifier = False
        section_name = None
        for line in data.split(os.linesep):
            lline = line.strip()
            if lline.startswith("SectionUseCase"):
                usecase = lline.split(".")[1].split("{")[0].strip()
                self.usecases[usecase] = {}
            elif lline.startswith("SectionVerb"):
                sectionverb = True
            elif lline.startswith("SectionDevice"):
                sectiondevice = True
            elif lline.startswith("SectionModifier"):
                sectionmodifier = True
            elif sectionverb and lline.startswith("Name"):
                section_name = lline.split(" ", 1)[1]
                self.usecases[usecase][section_name] = []
            elif sectiondevice and lline.startswith("Name"):
                section_name = lline.split(" ", 1)[1]
                self.devices[section_name] = []
            elif sectionmodifier and lline.startswith("Name"):
                section_name = lline.split(" ", 1)[1]
                self.modifiers[section_name] = []
            elif lline == "EndSection":
                sectionverb = False
                sectiondevice = False
                sectionmodifier = False
                section_name = None
            elif lline == "}":
                usecase = None
            elif usecase and section_name:
                self.usecases[usecase][section_name].append(lline)
            elif sectiondevice and section_name:
                self.devices[section_name].append(lline)
            elif sectionmodifier and section_name:
                self.modifiers[section_name].append(lline)



def main(*args):

    print args
    if len(args) == 1:
        print("No arguments given, do nothing")
        return

    if len(args) == 2:
        print("File argument given, printing SectionUseCases, SectionDevices and SectionModifiers")
        cfg = AlsaConfig(args[1])
        print "------------------------------"
        for usecase in sorted(cfg.usecases.keys()):
            print (usecase)
        print "------------------------------"
        for dev in sorted(cfg.devices.keys()):
            print (dev)
        print "------------------------------"
        for mod in sorted(cfg.modifiers.keys()):
            print (mod)

    if len(args) == 3:
        print("Two file arguments given, printing differences")
        cfg = AlsaConfig(args[1])
        cfg2 = AlsaConfig(args[2])
        print "- UseCases -----------------------------"
        printed = []
        for usecase in sorted(cfg.usecases.keys()):
            if not usecase in cfg2.usecases:
                print (usecase)
                printed.append(usecase)
        print " - "
        for usecase in sorted(cfg2.usecases.keys()):
            if not usecase in cfg.usecases and usecase not in printed:
                print (usecase)

        print "- Devices -----------------------------"
        printed = []
        for dev in sorted(cfg.devices.keys()):
            if not dev in cfg2.devices:
                print (dev)
                printed.append(dev)
        print " - "
        for dev in sorted(cfg2.devices.keys()):
            if not dev in cfg.devices and dev not in printed:
                print (dev)

        print "- Modifiers -----------------------------"
        printed = []
        for mod in sorted(cfg.modifiers.keys()):
            if not mod in cfg2.modifiers:
                print (mod)
                printed.append(mod)
        print " - "
        for mod in sorted(cfg2.modifiers.keys()):
            if not mod in cfg.modifiers and mod not in printed:
                print (mod)


if __name__ == "__main__":

    main(*sys.argv)