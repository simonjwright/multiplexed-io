package body System_Clocks
with SPARK_Mode => On
is

   function PCLK1 return Frequency is (42_000_000);

   function PCLK2 return Frequency is (84_000_000);

end System_Clocks;
