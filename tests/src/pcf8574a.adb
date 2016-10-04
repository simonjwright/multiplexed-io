--  Demonstration code for the AdaPilot project
--  (http://adapilot.likeabird.eu).
--  Copyright (C) 2016 Simon Wright <simon@pushface.org>

with Ada.Real_Time; use Ada.Real_Time;
with Interfaces;
with I2C1.Device;

procedure PCF8574A with SPARK_Mode is
   Value : Interfaces.Unsigned_8;
   use type  Interfaces.Unsigned_8;
begin
   I2C1.Device.Initialize (Frequency => 100_000);

   loop
      --  bits 0 .. 3 are LEDs, 4 .. 7 are pushbuttons.
      --
      --  ***********************************************************
      --  LEDs are lit by writing 0.
      --  The pull-up required for switches is provided by writing 1.
      --  ***********************************************************

      I2C1.Device.Read (From => 16#70#, To => Value);
      I2C1.Device.Write (To => 16#70#,
                         Data => Interfaces.Shift_Right (Value, 4) or 16#f0#);

      delay until Ada.Real_Time.Clock + Ada.Real_Time.Milliseconds (500);
   end loop;
end PCF8574A;
