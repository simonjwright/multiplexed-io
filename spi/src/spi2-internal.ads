--  Demonstration code for the AdaPilot project
--  (http://adapilot.likeabird.eu).
--  Copyright (C) 2016 Simon Wright <simon@pushface.org>

with Interfaces;

private
package SPI2.Internal
with
  SPARK_Mode,
  Elaborate_Body
is

   type Device is (BARO, FRAM);

   type Byte_Array is array (Natural range <>) of Interfaces.Unsigned_8;

   procedure Read_SPI (The_Device : Device; Bytes : out Byte_Array);

   procedure Write_SPI (The_Device : Device; Bytes : Byte_Array);

   procedure Command_SPI (The_Device :     Device;
                          Command    :     Byte_Array;
                          Result     : out Byte_Array);

end SPI2.Internal;
