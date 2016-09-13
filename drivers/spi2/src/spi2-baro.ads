--  Demonstration code for the AdaPilot project
--  (http://adapilot.likeabird.eu).
--  Copyright (C) 2016 Simon Wright <simon@pushface.org>

package SPI2.BARO
with
  SPARK_Mode => On,
  Elaborate_Body
is

   type Device_Status is (Uninitialized, Invalid_CRC, OK);
   --  Uninitialized is the initial condition

   function Status return Device_Status
   with
     Inline;

   procedure Initialize
   with
     Pre => Status = Uninitialized,
     Post => Status /= Uninitialized;

   --  Pressure in mB * 100
   type Pressure is range 10_00 .. 1200_00;

   function Current_Pressure return Pressure
   with
     Pre => Status = OK;

end SPI2.BARO;
