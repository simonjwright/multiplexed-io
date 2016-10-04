--  Demonstration code for the AdaPilot project
--  (http://adapilot.likeabird.eu).
--  Copyright (C) 2016 Simon Wright <simon@pushface.org>

--  THIS FILE, i2c?-device.ads, IS GENERATED USING GNATPREP FROM
--  ../../i2c/src/i2c-device.ads.pp.  TO MAKE A PERMANENT CHANGE, EDIT
--  THAT FILE AND REGENERATE, THEN COMMIT THE REGENERATED FILE.

--  $I2C translates to I2C1, I2C2 etc; the package I2Cn is expected to
--  contain declarations
--
--  subtype Byte is Interfaces.Unsigned_8;
--  type Byte_Array is array (Natural range <>) of Byte
--  with Component_Size => 8;

package I2C1.Device
with
  SPARK_Mode => On,
  Elaborate_Body
is

   --  The I2C address of the peripheral being addressed (will be
   --  shifted left by one place to allow Read/Write to be indicated
   --  in the LSB).
   subtype Chip_Address is Byte range 16#00# .. 16#7f#;

   function Initialized return Boolean
   with
     Inline;

   subtype Maximum_Frequency is Natural range 0 .. 400_000;

   procedure Initialize (Frequency : Maximum_Frequency)
   with
     Pre => not Initialized,
     Post => Initialized;

   procedure Read (From : Chip_Address; To : out Byte)
   with
     Pre => Initialized;

   procedure Read (From : Chip_Address; To : out Byte_Array)
   with
     Pre => Initialized and To'Length > 0;

   procedure Write (To : Chip_Address; Data : Byte)
   with
     Pre => Initialized;

   procedure Write (To : Chip_Address; Data : Byte_Array)
   with
     Pre => Initialized and Data'Length > 0;

end I2C1.Device;
