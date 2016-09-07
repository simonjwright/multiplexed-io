# Demonstration code for the AdaPilot project
# (http://adapilot.likeabird.eu).
# Copyright (C) 2016 Simon Wright <simon@pushface.org>

# The purpose of this Makefile is to run gnatprep on the template i2c
# source to generate code for I2C1, using src/i2c1.def.

# This specifies the package name, the SCL and SCA pins (GPIO and pin
# number), and the specific I2C.

# It is intended that the generated files be maintained within the
# repository.

all::

SOURCES = src/i2c1.ads src/i2c1.adb
DEFINITION = src/i2c1.def

sources: $(SOURCES)

src/i2c1.ads: ../i2c/src/i2c.ads.pp $(DEFINITION)
	gnatprep				\
	  -c -r -v				\
	  $<					\
	  $@					\
	  $(DEFINITION)
src/i2c1.adb: ../i2c/src/i2c.adb.pp $(DEFINITION)
	gnatprep				\
	  -c -r -v				\
	  $<					\
	  $@					\
	  $(DEFINITION)

clean:
	-rm $(SOURCES)

.PHONY: all clean
