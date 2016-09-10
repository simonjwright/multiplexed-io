--  Demonstration code for the AdaPilot project
--  (http://adapilot.likeabird.eu).
--  Copyright (C) 2016 Simon Wright <simon@pushface.org>

with Ada.Real_Time;
with Interfaces;

with Ada.Text_IO;

with SPI;
with SPI1.Internal;
pragma Elaborate_All (SPI1.Internal);

package body SPI1.MPU9250
with SPARK_Mode => On
is

   task MPU9250_Reader;

   task body MPU9250_Reader is
      Start_Time : Ada.Real_Time.Time;
      use type Ada.Real_Time.Time;
   begin
      Ada.Text_IO.Put_Line ("mpu9250 task starting.");

      --  Some time needed for MPU9250 to warm up
      Start_Time := Ada.Real_Time.Clock;
      delay until Start_Time + Ada.Real_Time.Milliseconds (5);

      loop
         declare
            Data : SPI.Byte_Array (0 .. 0);
            use type Interfaces.Unsigned_8;
         begin
            Internal.Command_SPI (The_Device => Internal.MPU9250,
                                  Command    => (0 => 16#80# or 16#75#),
                                  Result     => Data);
            Ada.Text_IO.Put_Line
              ("mpu9250 whoami: " & Interfaces.Unsigned_8'Image (Data (0)));
         end;
         Start_Time := Ada.Real_Time.Clock;
         delay until Start_Time + Ada.Real_Time.Seconds (1);
      end loop;
   end MPU9250_Reader;

end SPI1.MPU9250;
