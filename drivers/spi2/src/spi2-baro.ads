--  Demonstration code for the AdaPilot project
--  (http://adapilot.likeabird.eu).
--  Copyright (C) 2016 Simon Wright <simon@pushface.org>

package SPI2.BARO
with
  SPARK_Mode => On,
  Elaborate_Body
is

   --  Pressure in mB * 100
   type Pressure is range 10_00 .. 1200_00;

   Measurement : Pressure := 1000_00;

end SPI2.BARO;
