with Ada.Text_IO;
with SPI2.BARO;
pragma Unreferenced (SPI2.BARO);

with Ada.Real_Time;
procedure SPI2_BARO is
   use type Ada.Real_Time.Time;
begin
   Ada.Text_IO.Put_Line ("spi2_baro starting.");
   loop
      Ada.Text_IO.Put_Line ("spi2_baro running.");
      delay until Ada.Real_Time.Clock + Ada.Real_Time.Seconds (10);
   end loop;
end SPI2_BARO;
