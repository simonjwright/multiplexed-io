--  Demonstration code for the AdaPilot project
--  (http://adapilot.likeabird.eu).
--  Copyright (C) 2016 Simon Wright <simon@pushface.org>

with SPI1.Device;

with STM32_SVD.GPIO;
with STM32_SVD.RCC;

package body SPI1.Internal
with
  SPARK_Mode => On
is

   procedure Read_SPI (The_Device : Device; Bytes : out Byte_Array)
   is
   begin
      Implementation.Read_SPI (The_Device, Bytes);
   end Read_SPI;

   procedure Write_SPI (The_Device : Device; Bytes : Byte_Array)
   is
   begin
      Implementation.Write_SPI (The_Device, Bytes);
   end Write_SPI;

   procedure Command_SPI (The_Device :     Device;
                          Command    :     Byte_Array;
                          Result     : out Byte_Array)
   is
   begin
      Implementation.Command_SPI (The_Device, Command, Result);
   end Command_SPI;

   --  From schematics_38180-2_adaracer_1.1, SPI1 uses pins
   --
   --  PA5 - SCLK
   --  PA6 - MISO
   --  PA7 - MOSI
   --
   --  /MPU9250 CS - PC2

   use STM32_SVD;

   procedure Select_Device (The_Device : Device) with Inline;
   procedure Deselect_Device (The_Device : Device) with Inline;

   protected body Implementation
   with SPARK_Mode => Off
   is

      procedure Read_SPI (The_Device : Device; Bytes : out Byte_Array)
      with SPARK_Mode => Off
      is
      begin
         Select_Device (The_Device);
         SPI1.Device.Read_SPI (Bytes);
         Deselect_Device (The_Device);
      end Read_SPI;

      procedure Write_SPI (The_Device : Device; Bytes : Byte_Array)
      with SPARK_Mode => Off
      is
      begin
         Select_Device (The_Device);
         SPI1.Device.Write_SPI (Bytes);
         Deselect_Device (The_Device);
      end Write_SPI;

      procedure Command_SPI (The_Device :     Device;
                             Command    :     Byte_Array;
                             Result     : out Byte_Array)
      with SPARK_Mode => Off
      is
      begin
         Select_Device (The_Device);
         SPI1.Device.Command_SPI (Command, Result);
         Deselect_Device (The_Device);
      end Command_SPI;

   end Implementation;

   procedure Select_Device (The_Device : Device)
   with SPARK_Mode => Off
   is
   begin
      case The_Device is
         when MPU9250 =>
            --  Reset /MPU9250 CS
            GPIO.GPIOC_Periph.BSRR.BR.Arr := (2 => 1, others => 0);
      end case;
   end Select_Device;

   procedure Deselect_Device (The_Device : Device)
   with SPARK_Mode => Off
   is
   begin
      case The_Device is
         when MPU9250 =>
            --  Set /MPU950 CS
            GPIO.GPIOC_Periph.BSRR.BS.Arr := (2 => 1, others => 0);
      end case;
   end Deselect_Device;

begin
   pragma SPARK_Mode (Off);

   --  First, deselect MPU9250.

   --  Enable GPIOC
   RCC.RCC_Periph.AHB1ENR.GPIOCEN := 1;

   --  PC2, /MPU9250 CS
   GPIO.GPIOC_Periph.MODER.Arr (2)     := 2#01#; -- general-purpose output
   GPIO.GPIOC_Periph.OTYPER.OT.Arr (2) := 0;     -- push-pull
   GPIO.GPIOC_Periph.OSPEEDR.Arr (2)   := 2#10#; -- high speed
   GPIO.GPIOC_Periph.PUPDR.Arr (2)     := 2#00#; -- no pullup/down
   GPIO.GPIOC_Periph.BSRR.BS.Arr (2)   := 1;     -- set bit

   SPI1.Device.Initialize (Maximum_Frequency => 1_000_000);
   --  This is the limit for MPU9250, PS-MPU-9250A-01 rev 1.0, Table 7

end SPI1.Internal;
