--  Demonstration code for the AdaPilot project
--  (http://adapilot.likeabird.eu).
--  Copyright (C) 2016 Simon Wright <simon@pushface.org>

with Ada.Text_IO;
with SPI2.BARO;

with Ada.Real_Time;
procedure SPI2_BARO is
   use type Ada.Real_Time.Time;
begin
   Ada.Text_IO.Put_Line ("spi2_baro starting.");
   loop
      Ada.Text_IO.Put_Line
        ("pressure:"
           & SPI2.BARO.Pressure'Image (SPI2.BARO.Measurement));
      delay until Ada.Real_Time.Clock + Ada.Real_Time.Seconds (1);
   end loop;
end SPI2_BARO;
