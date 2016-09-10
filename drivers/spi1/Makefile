# Demonstration code for the AdaPilot project
# (http://adapilot.likeabird.eu).
# Copyright (C) 2016 Simon Wright <simon@pushface.org>

# The purpose of this Makefile is to run gnatprep on the template spi-device
# source to generate code for SPI2, using src/spi2.def.

# This specifies the package name, the SCLK, MISO and MOSI pins (GPIO
# and pin number), and the specific SPI.

# It is intended that the generated files be maintained within the
# repository.

all::

SOURCES = src/spi1-device.ads src/spi1-device.adb
DEFINITION = src/spi1.def

sources: $(SOURCES)

src/spi1-device.ads: ../spi/src/spi-device.ads.pp $(DEFINITION)
	gnatprep				\
	  -c -r -v				\
	  $<					\
	  $@					\
	  $(DEFINITION)
src/spi1-device.adb: ../spi/src/spi-device.adb.pp $(DEFINITION)
	gnatprep				\
	  -c -r -v				\
	  $<					\
	  $@					\
	  $(DEFINITION)

clean:
	-rm $(SOURCES)

.PHONY: all clean
