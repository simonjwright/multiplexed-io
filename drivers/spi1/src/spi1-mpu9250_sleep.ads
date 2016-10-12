--  Demonstration code for the AdaPilot project
--  (http://adapilot.likeabird.eu).
--  Copyright (C) 2016 Simon Wright <simon@pushface.org>

private
package SPI1.MPU9250_Sleep
with
  Elaborate_Body,
  SPARK_Mode => On
is

   procedure Sleep (For_Interval : Duration)
   with Pre => For_Interval in 0.0 .. 0.010_000;

end SPI1.MPU9250_Sleep;
