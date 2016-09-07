--  Demonstration code for the AdaPilot project
--  (http://adapilot.likeabird.eu).
--  Copyright (C) 2016 Simon Wright <simon@pushface.org>

with Ada.Real_Time;
with Shift_Driver;

procedure Shift_Out is
   use type Ada.Real_Time.Time;
begin
   loop
      delay until Ada.Real_Time.Clock + Ada.Real_Time.Seconds (1);
   end loop;
end Shift_Out;
