--  Demonstration code for the AdaPilot project
--  (http://adapilot.likeabird.eu).
--  Copyright (C) 2016 Simon Wright <simon@pushface.org>

with SPI1.MPU9250;
with SPI2.BARO;
with SPI2.FRAM;

with Ada.Real_Time;
with Ada.Text_IO; use Ada.Text_IO;
with System;

procedure AdaRacer_Test
with
  Priority => System.Priority'First -- or we may block e.g.BARO
is
   use type Ada.Real_Time.Time;
begin
   New_Line;
   Put_Line ("               AdaRacer Test");
   Put_Line ("               =============");
   New_Line;
   loop
      Put_Line ("Menu");
      New_Line;
      Put_Line ("b - BARO");
      Put_Line ("f - FRAM");
      Put_Line ("m - MPU9250");
      New_Line;
      Put ("enter your choice: ");
      declare
         C : Character;
      begin
         Get (C);
         Put (C);
         New_Line;

         case C is

            when 'b' | 'B' =>
               Put_Line ("BARO demo: reporting pressure in mB * 100");
               for J in 1 .. 10 loop
                  Put_Line
                    ("pressure:"
                       & SPI2.BARO.Pressure'Image (SPI2.BARO.Measurement));
                  delay until Ada.Real_Time.Clock + Ada.Real_Time.Seconds (1);
               end loop;

            when 'f' | 'F' =>
               Put_Line ("FRAM demo: writing & reading the same location");
               declare
                  package Integer_FRAM is new SPI2.FRAM.IO (Integer);
                  Result : Integer;
               begin
                  for Input in 250 .. 259 loop
                     Put ("writing" & Input'Img & " .. ");
                     Integer_FRAM.Write (To => 42, V => Input);
                     Integer_FRAM.Read (From => 42, V => Result);
                     Put_Line ("read" & Result'Img);
                     delay until
                       Ada.Real_Time.Clock + Ada.Real_Time.Seconds (1);
                  end loop;
               end;

            when 'm' | 'M' =>
               Put_Line ("MPU9250 demo: incomplete");
               for J in 1 .. 10 loop
                  Put_Line
                    ("identified: "
                       & Boolean'Image (SPI1.MPU9250.Device_Identified));
                  delay until Ada.Real_Time.Clock + Ada.Real_Time.Seconds (1);
               end loop;

            when others =>
               Put_Line ("invalid choice " & C);

         end case;
      end;
      New_Line;
   end loop;
end AdaRacer_Test;
