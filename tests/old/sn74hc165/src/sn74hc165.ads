--  Demonstration code for the AdaPilot project
--  (http://adapilot.likeabird.eu).
--  Copyright (C) 2016 Simon Wright <simon@pushface.org>

with STM32F4.GPIO;

package SN74HC165 is

   --  This package manages single SN74HC165's; will require
   --  modification if they are chained.

   type Chip is tagged limited private;

   type Pins is (SER_OUT, SH_LD, CLK, CE);

   type Chip_Pins is array (Pins) of STM32F4.GPIO.GPIO_Point;

   procedure Initialize (The_Chip : out Chip; Using : Chip_Pins);

   type Bit is range 0 .. 1
   with Size => 1;

   type Byte is array (0 .. 7) of Bit
   with
     Component_Size => 1,
     Size => 8;

   function Read (From : in out Chip) return Byte;
   --  "in out" because STM32F4.GPIO needs it for read.

private

   type Chip is tagged limited record
      The_Pins : Chip_Pins;
   end record;

end SN74HC165;
