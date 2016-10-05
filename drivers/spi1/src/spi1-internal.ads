--  Demonstration code for the AdaPilot project
--  (http://adapilot.likeabird.eu).
--  Copyright (C) 2016 Simon Wright <simon@pushface.org>

private
package SPI1.Internal
with
  SPARK_Mode,
  Elaborate_Body
is

   --  This package assumes that - while there may be multiple devices
   --  on the SPI1 bus - they will all be accessed by the same task, so
   --  there is no need for mutual exclusion.

   type Device is (MPU9250);

   procedure Read_SPI (The_Device : Device; Bytes : out Byte_Array);

   procedure Write_SPI (The_Device : Device; Bytes : Byte_Array);

   procedure Command_SPI (The_Device :     Device;
                          Command    :     Byte_Array;
                          Result     : out Byte_Array);

end SPI1.Internal;
