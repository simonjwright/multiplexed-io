--  Demonstration code for the AdaPilot project
--  (http://adapilot.likeabird.eu).
--  Copyright (C) 2016 Simon Wright <simon@pushface.org>

with Interfaces;

--  private
package I2C1.Internal
with
  SPARK_Mode,
  Elaborate_Body
is

   --  This package assumes that - while there may be multiple devices
   --  on the I2C1 bus - they will all be accessed by the same task, so
   --  there is no need for mutual exclusion.

   type Device is (MPU9250, AK8963);

   procedure Read_I2C (The_Device : Device; Data : out Interfaces.Unsigned_8);

   procedure Write_I2C (The_Device : Device; Data : Interfaces.Unsigned_8);

   procedure Read_I2C (The_Device : Device; Bytes : out Byte_Array)
     with Pre => Bytes'Length > 0;

   procedure Write_I2C (The_Device : Device; Bytes : Byte_Array)
     with Pre => Bytes'Length > 0;

end I2C1.Internal;
