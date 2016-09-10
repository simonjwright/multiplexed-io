with Ada.Text_IO;
with SPI1.MPU9250;
pragma Unreferenced (SPI1.MPU9250);

with Ada.Real_Time;
procedure SPI1_MPU9250 is
   use type Ada.Real_Time.Time;
begin
   Ada.Text_IO.Put_Line ("spi1_mpu9250 starting.");
   loop
      Ada.Text_IO.Put_Line ("spi1_mpu9250 running.");
      delay until Ada.Real_Time.Clock + Ada.Real_Time.Seconds (10);
   end loop;
end SPI1_MPU9250;
