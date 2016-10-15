--  Demonstration code for the AdaPilot project
--  (http://adapilot.likeabird.eu).
--  Copyright (C) 2016 Simon Wright <simon@pushface.org>

package Monitor
with
  SPARK_Mode => On,
  Elaborate_Body is

   type Device is (Accelerometer, Barometer, Gyro, Magnetometer);
   --  Accelerometer & Gyro are the same device for AdaRacer

   type Status is (Unknown, Ok, Failed);

   procedure Set_Status (For_Device : Device; To : Status)
   with Post => Get_Status (For_Device) = To;

   function Get_Status (For_Device : Device) return Status;

   function Usable (The_Device : Device) return Boolean
     is (Get_Status (The_Device) = Ok);

end Monitor;
