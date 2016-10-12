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
  Priority => System.Priority'First -- or we may block e.g. BARO
is
   use type Ada.Real_Time.Time;
begin
   SPI2.BARO.Initialize;
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
               Put_Line ("BARO demo: reporting pressure in mB*100");
               for J in 1 .. 10 loop
                  case SPI2.BARO.Status is
                     when SPI2.BARO.OK =>
                        Put_Line
                          ("pressure:"
                             & SPI2.BARO.Pressure'Image
                               (SPI2.BARO.Current_Pressure));
                     when SPI2.BARO.Uninitialized  =>
                        Put_Line ("status is Uninitialized");
                     when SPI2.BARO.Invalid_CRC  =>
                        Put_Line ("status is Invalid_CRC");
                  end case;
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
               if SPI1.MPU9250.MPU9250_Device_Identified then
                  Put ("MPU9250 identified, ");
               else
                  Put ("MPU9250 not identified, ");
               end if;
               if SPI1.MPU9250.MPU9250_Ok then
                  Put ("OK, ");
               else
                  Put ("not OK, ");
               end if;
               if SPI1.MPU9250.AK8963_Device_Identified then
                  Put ("AK8963 identified, ");
               else
                  Put ("AK8963 not identified, ");
               end if;
               if SPI1.MPU9250.AK8963_Ok then
                  Put ("OK");
               else
                  Put ("not OK");
               end if;
               New_Line;
               Put_Line
                 ("a in g*1000, g in deg/sec*100, m in milligauss (nT/100)");
               for J in 1 .. 10 loop
                  Put ("a:");
                  for A of SPI1.MPU9250.Accelerations loop
                     Put (" " & Integer'Image (Integer (A * 1000.0)));
                  end loop;
                  Put (" g:");
                  for G of SPI1.MPU9250.Gyro_Rates loop
                     Put (" " & Integer'Image (Integer (G * 100.0)));
                  end loop;
                  Put (" m:");
                  for M of SPI1.MPU9250.Magnetic_Fields loop
                     Put (" " & Integer'Image (Integer (M)));
                  end loop;
                  New_Line;
                  delay until Ada.Real_Time.Clock + Ada.Real_Time.Seconds (1);
               end loop;

            when others =>
               Put_Line ("invalid choice " & C);

         end case;
      end;
      New_Line;
   end loop;
end AdaRacer_Test;
