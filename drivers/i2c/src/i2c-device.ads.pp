--  Demonstration code for the AdaPilot project
--  (http://adapilot.likeabird.eu).
--  Copyright (C) 2016 Simon Wright <simon@pushface.org>

--  THIS FILE, i2c?-device.ads, IS GENERATED USING GNATPREP FROM
--  ../../i2c/src/i2c-device.ads.pp.  TO MAKE A PERMANENT CHANGE, EDIT
--  THAT FILE AND REGENERATE, THEN COMMIT THE REGENERATED FILE.

with STM32_SVD;

package $I2C.Device
with
  SPARK_Mode => On,
  Elaborate_Body
is

   --  The I2C address of the peripheral being addressed
   subtype Chip_Address is STM32_SVD.Byte;

   function Initialized return Boolean
   with
     Inline;

   procedure Initialize
   with
     Pre => not Initialized,
     Post => Initialized;

   procedure Read (From : Chip_Address; To : out STM32_SVD.Byte)
   with
     Pre => Initialized;

   procedure Write (To : Chip_Address; Data : STM32_SVD.Byte)
   with
     Pre => Initialized;

end $I2C.Device;
