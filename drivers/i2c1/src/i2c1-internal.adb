--  Demonstration code for the AdaPilot project
--  (http://adapilot.likeabird.eu).
--  Copyright (C) 2016 Simon Wright <simon@pushface.org>

with I2C1.Device;

package body I2C1.Internal
with
  SPARK_Mode => On
is

   Chip_Address : constant array (Device) of I2C1.Device.Chip_Address :=
     (MPU9250 => 16#68#,
      AK8963  => 16#0c#);

   procedure Read_I2C (The_Device : Device; Data : out Interfaces.Unsigned_8)
   with SPARK_Mode => Off
   is
   begin
      I2C1.Device.Read
        (From => Interfaces.Unsigned_8 (Chip_Address (The_Device)),
         To   => Data);
   end Read_I2C;

   procedure Write_I2C (The_Device : Device; Data : Interfaces.Unsigned_8)
   with SPARK_Mode => Off
   is
   begin
      I2C1.Device.Write
        (To   => Interfaces.Unsigned_8 (Chip_Address (The_Device)),
         Data => Data);
   end Write_I2C;

   procedure Read_I2C (The_Device : Device; Bytes : out Byte_Array)
   with SPARK_Mode => Off
   is
   begin
      I2C1.Device.Read
        (From => Interfaces.Unsigned_8 (Chip_Address (The_Device)),
         To   => Bytes);
   end Read_I2C;

   procedure Write_I2C (The_Device : Device; Bytes : Byte_Array)
   with SPARK_Mode => Off
   is
   begin
      I2C1.Device.Write
        (To   => Interfaces.Unsigned_8 (Chip_Address (The_Device)),
         Data => Bytes);
   end Write_I2C;

begin
   pragma SPARK_Mode (Off);

   I2C1.Device.Initialize (Frequency => 400_000);

end I2C1.Internal;
