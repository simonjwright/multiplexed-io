with SPI2.BARO;
pragma Unreferenced (SPI2.BARO);

with Ada.Real_Time;
procedure SPI2_BARO is
   use type Ada.Real_Time.Time;
begin
   loop
      delay until Ada.Real_Time.Clock + Ada.Real_Time.Seconds (10);
   end loop;
end SPI2_BARO;
