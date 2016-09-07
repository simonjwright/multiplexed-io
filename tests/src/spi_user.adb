--  Demonstration code for the AdaPilot project
--  (http://adapilot.likeabird.eu).
--  Copyright (C) 2016 Simon Wright <simon@pushface.org>

with Ada.Real_Time;
with Ada.Text_IO; use Ada.Text_IO;
with System;

with SPI2.FRAM;

procedure SPI_User with Priority => System.Priority'First is
   package Integer_FRAM is new SPI2.FRAM.IO (Integer);
   Result : Integer;
   use type Ada.Real_Time.Time;
begin
   loop
      for Input in 250 .. 260 loop
         Put (Input'Img & " .. ");
         Integer_FRAM.Write (To => 42, V => Input);
         Integer_FRAM.Read (From => 42, V => Result);
         Put_Line ("=> " & Result'Img);
         delay until Ada.Real_Time.Clock + Ada.Real_Time.Seconds (1);
      end loop;
   end loop;
end SPI_User;
