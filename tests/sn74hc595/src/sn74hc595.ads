--  Demonstration code for the AdaPilot project
--  (http://adapilot.likeabird.eu).
--  Copyright (C) 2016 Simon Wright <simon@pushface.org>

with STM32F4.GPIO;

package SN74HC595 is

   --  This package manages single SN74HC595's; will require
   --  modification if they are chained.

   type Chip is tagged limited private;

   type Pins is (NOT_SCLR, SCK, RCK, NOT_G, SER);
   --  At the expense of possible initial glitch, NOT_SCLR can be tied
   --  to VCC and NOT_G can be tied to GND.

   type Chip_Pins is array (Pins) of STM32F4.GPIO.GPIO_Point;

   procedure Initialize (The_Chip : out Chip; Using : Chip_Pins);

   type Bit is range 0 .. 1
   with Size => 1;

   type Byte is array (0 .. 7) of Bit
   with
     Component_Size => 1,
     Size => 8;

   procedure Write (To : in out Chip; Bits : Byte);

private

   type Chip is tagged limited record
      The_Pins : Chip_Pins;
   end record;

end SN74HC595;
