--  Demonstration code for the AdaPilot project
--  (http://adapilot.likeabird.eu).
--  Copyright (C) 2016 Simon Wright <simon@pushface.org>

with Ada.Real_Time; use Ada.Real_Time;
with PCF8574A;
with STM32F40x;

procedure IO_Expander is
   Value : STM32F40x.Byte;
   use type STM32F40x.Byte;
begin
   PCF8574A.Initialize;

   loop
      --  bits 0 .. 3 are LEDs, 4 .. 7 are pushbuttons.
      --
      --  ***********************************************************
      --  LEDs are lit by writing 0.
      --  The pull-up required for switches is provided by writing 1.
      --  ***********************************************************

      Value := PCF8574A.Read;
      PCF8574A.Write ((Value / (2 ** 4)) or 16#f0#);

      delay until Ada.Real_Time.Clock + Ada.Real_Time.Milliseconds (500);
   end loop;
end IO_Expander;
