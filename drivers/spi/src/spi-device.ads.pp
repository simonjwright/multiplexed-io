--  Demonstration code for the AdaPilot project
--  (http://adapilot.likeabird.eu).
--  Copyright (C) 2016 Simon Wright <simon@pushface.org>

--  THIS FILE, spi?-device.ads, IS GENERATED USING GNATPREP FROM
--  spi/src/spi-device.ads.pp.  TO MAKE A PERMANENT CHANGE, EDIT THAT
--  FILE AND REGENERATE, THEN COMMIT THE REGENERATED FILE.

with SPI;

private
package $SPI.Device
with
  SPARK_Mode,
  Elaborate_Body
is

   function Initialized return Boolean
   with
     Inline;

   procedure Initialize (Maximum_Frequency : Natural)
   with
     Pre => not Initialized,
     Post => Initialized;
   --  The maximum achievable frequency is the bus clock / 2, with
   --  values reducing by powers of 2 down to bus clock / 256.

   --  The operations below expect the target device to have been
   --  selected before the call, and to be deselected afterwards.
   --
   --  If more than one target device is using this SPI, the
   --  selection, the call, and the deselection must be called within
   --  the envelope of a protected operation.

   procedure Read_SPI (Bytes : out SPI.Byte_Array)
   with
     Pre => Initialized;

   procedure Write_SPI (Bytes : SPI.Byte_Array)
   with
     Pre => Initialized;

   procedure Command_SPI (Command    :     SPI.Byte_Array;
                          Result     : out SPI.Byte_Array)
   with
     Pre => Initialized;

end $SPI.Device;
