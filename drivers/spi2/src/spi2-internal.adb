--  Demonstration code for the AdaPilot project
--  (http://adapilot.likeabird.eu).
--  Copyright (C) 2016 Simon Wright <simon@pushface.org>

with SPI2.Device;

with STM32_SVD.GPIO;
with STM32_SVD.RCC;

package body SPI2.Internal
with
  SPARK_Mode => Off,  -- or loops in "generation of Global contracts"
  Refined_State => (State => (Implementation))
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

   --  From schematics_38180-2_adaracer_1.1, SPI2 uses pins
   --
   --  PB10 - SCLK
   --  PB14 - MISO
   --  PB15 - MOSI
   --
   --  /BARO CS - PD7
   --  /FRAM CS - PD10
   --
   --  From RM0090 Issue 11 Fig 27, SPI2 uses GPIO AF5 or AF6.
   --  This is WRONG, see DocID024030 Rev 8 Table 12; it's AF5.
   --  From RM0090 Issue 11 Table 1, SPI2 is on APB1 (42 MHz with our
   --  settings).
   --
   --  From DA5611-01BA03_011 page 4, the maximum SCLK is 20 MHz.
   --  This means we will need to run the SPI with a divisor of 4
   --  (=> 10.5 MHz).

   use STM32_SVD;

   procedure Select_Device (The_Device : Device) with Inline;
   procedure Deselect_Device (The_Device : Device) with Inline;

   protected body Implementation is

      procedure Read_SPI (The_Device : Device; Bytes : out Byte_Array)
      with SPARK_Mode => Off
      is
      begin
         Select_Device (The_Device);
         SPI2.Device.Read_SPI (Bytes);
         Deselect_Device (The_Device);
      end Read_SPI;

      procedure Write_SPI (The_Device : Device; Bytes : Byte_Array)
      with SPARK_Mode => Off
      is
      begin
         Select_Device (The_Device);
         SPI2.Device.Write_SPI (Bytes);
         Deselect_Device (The_Device);
      end Write_SPI;

      procedure Command_SPI (The_Device :     Device;
                             Command    :     Byte_Array;
                             Result     : out Byte_Array)
      with SPARK_Mode => Off
      is
      begin
         Select_Device (The_Device);
         SPI2.Device.Command_SPI (Command, Result);
         Deselect_Device (The_Device);
      end Command_SPI;

   end Implementation;

   procedure Select_Device (The_Device : Device)
   is
   begin
      case The_Device is
         when BARO =>
            --  Reset /BARO CS
            GPIO.GPIOD_Periph.BSRR.BR.Arr := (7 => 1, others => 0);
         when FRAM =>
            --  Reset /FRAM CS
            GPIO.GPIOD_Periph.BSRR.BR.Arr := (10 => 1, others => 0);
      end case;
   end Select_Device;

   procedure Deselect_Device (The_Device : Device)
   is
   begin
      case The_Device is
         when BARO =>
            --  Set /BARO CS
            GPIO.GPIOD_Periph.BSRR.BS.Arr := (7 => 1, others => 0);
         when FRAM =>
            --  Set /FRAM CS
            GPIO.GPIOD_Periph.BSRR.BS.Arr := (10 => 1, others => 0);
      end case;
   end Deselect_Device;

begin
   pragma SPARK_Mode (Off);

   --  First, deselect FRAM, BARO.

   --  Enable GPIOD
   RCC.RCC_Periph.AHB1ENR.GPIODEN := 1;

   --  PD10, /FRAM CS
   GPIO.GPIOD_Periph.MODER.Arr (10)     := 2#01#; -- general-purpose output
   GPIO.GPIOD_Periph.OTYPER.OT.Arr (10) := 0;     -- push-pull
   GPIO.GPIOD_Periph.OSPEEDR.Arr (10)   := 2#10#; -- high speed
   GPIO.GPIOD_Periph.PUPDR.Arr (10)     := 2#00#; -- no pullup/down
   GPIO.GPIOD_Periph.BSRR.BS.Arr (10)   := 1;     -- set bit

   --  PD7, /BARO CS
   GPIO.GPIOD_Periph.MODER.Arr (7)     := 2#01#; -- general-purpose output
   GPIO.GPIOD_Periph.OTYPER.OT.Arr (7) := 0;     -- push-pull
   GPIO.GPIOD_Periph.OSPEEDR.Arr (7)   := 2#10#; -- high speed
   GPIO.GPIOD_Periph.PUPDR.Arr (7)     := 2#00#; -- no pullup/down
   GPIO.GPIOD_Periph.BSRR.BS.Arr (7)   := 1;     -- set bit

   SPI2.Device.Initialize (Maximum_Frequency => 20_000_000);
   --  This is the limit for MS5611, DA5611-01BA03_011, Oct 26, 2012, p4

end SPI2.Internal;
