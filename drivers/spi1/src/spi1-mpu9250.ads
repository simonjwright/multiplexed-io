--  Demonstration code for the AdaPilot project
--  (http://adapilot.likeabird.eu).
--  Copyright (C) 2016 Simon Wright <simon@pushface.org>

package SPI1.MPU9250
with
  SPARK_Mode => On,
  Elaborate_Body
is

   --  Has the MPU9250 identified itself correctly?
   Device_Identified : Boolean := False;

end SPI1.MPU9250;
