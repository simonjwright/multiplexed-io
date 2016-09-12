--  Demonstration code for the AdaPilot project
--  (http://adapilot.likeabird.eu).
--  Copyright (C) 2016 Simon Wright <simon@pushface.org>

with Ada.Real_Time;
with SPI2.Internal;

package SPI2.BARO
with
  SPARK_Mode => On,
  Abstract_State => ((State with External),
                     Initialization),
  Initializes => Initialization,
  Elaborate_Body
is

   type Device_Status is (Uninitialized, Invalid_CRC, OK);
   --  Uninitialized is the initial condition

   function Status return Device_Status
   with
     Global => (Input => Initialization),
     Inline;

   procedure Initialize
   with
     Pre => Status = Uninitialized,
     Post => Internal.Initialized and then Status /= Uninitialized,
     Global => (Input => Ada.Real_Time.Clock_Time,
                In_Out => (Initialization,
                           State,
                           Internal.Initialization,
                           Internal.State)),
     Depends => (State => (State,
                           Internal.Initialization,
                           Internal.State),
                 Initialization => (Initialization,
                                    Internal.Initialization,
                                    Internal.State,
                                    Ada.Real_Time.Clock_Time),
                 Internal.Initialization => Internal.Initialization,
                 Internal.State => (Internal.Initialization,
                                    Internal.State));

   --  Pressure in mB * 100
   type Pressure is range 10_00 .. 1200_00;

   function Current_Pressure return Pressure
   with
     Pre => Status = OK;

end SPI2.BARO;
