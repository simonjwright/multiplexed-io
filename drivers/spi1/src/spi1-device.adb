pragma Source_Reference (1, "../spi/src/spi-device.adb.pp");
--  Demonstration code for the AdaPilot project
--  (http://adapilot.likeabird.eu).
--  Copyright (C) 2016 Simon Wright <simon@pushface.org>

--  THIS FILE, spi?-device.ads, IS GENERATED USING GNATPREP FROM
--  spi/src/spi-device.ads.pp.  TO MAKE A PERMANENT CHANGE, EDIT THAT
--  FILE AND REGENERATE, THEN COMMIT THE REGENERATED FILE.

with Interfaces;
with STM32_SVD.GPIO;
with STM32_SVD.RCC;
with STM32_SVD.SPI;

with System_Clocks;

package body SPI1.Device
with
  SPARK_Mode => On,
  Refined_State => (State => null,
                    Initialization => (Initialize_Done))
is

   Initialize_Done : Boolean := False;

   function Initialized return Boolean is
   begin
      return Initialize_Done;
   end Initialized;

   --  From RM0090 Issue 11 Fig 27, SPI uses GPIO AF5 or AF6.
   --  This is WRONG, see DocID024030 Rev 8 Table 12; it's AF5.
   use STM32_SVD;
   --  for simplicity below; but note potential clash between
   --  STM32_SVD.SPI and our SPI.

   procedure Initialize (Maximum_Frequency : Natural) is
      pragma SPARK_Mode (Off);
   begin
      --  First, enable 3.3V Power Sensors (VDD_SENS_EN on PE3)

      --  Enable PE3, VDD_SENS_EN
      RCC.RCC_Periph.AHB1ENR.GPIOEEN      := 1;
      GPIO.GPIOE_Periph.MODER.Arr (3)     := 2#01#; -- general-purpose output
      GPIO.GPIOE_Periph.OTYPER.OT.Arr (3) := 0;     -- push-pull
      GPIO.GPIOE_Periph.OSPEEDR.Arr (3)   := 2#10#; -- high speed
      GPIO.GPIOE_Periph.PUPDR.Arr (3)     := 2#00#; -- no pullup/down
      GPIO.GPIOE_Periph.BSRR.BS.Arr (3)   := 1;     -- set bit

      --  Set up GPIO for SCLK pin
      RCC.RCC_Periph.AHB1ENR.GPIOAEN  := 1;
      GPIO.GPIOA_Periph.MODER.Arr (5)     := 2#10#; -- AF
      GPIO.GPIOA_Periph.OTYPER.OT.Arr (5) := 0;     -- push-pull
      GPIO.GPIOA_Periph.OSPEEDR.Arr (5)   := 2#10#; -- high speed
      GPIO.GPIOA_Periph.PUPDR.Arr (5)     := 2#00#; -- no pullup/down
--!       #if SCLK_Pin < 8 then
      GPIO.GPIOA_Periph.AFRL.Arr (5)      := 5;     -- AF5
--!       #else
--!       $SCLK_GPIO.AFRH.Arr ($SCLK_Pin)      := 5;     -- AF5
--!       #end if;

      --  Set up GPIO for MISO pin
      RCC.RCC_Periph.AHB1ENR.GPIOAEN  := 1;
      GPIO.GPIOA_Periph.MODER.Arr (6)     := 2#10#; -- AF
      GPIO.GPIOA_Periph.OTYPER.OT.Arr (6) := 1;     -- open-drain
      GPIO.GPIOA_Periph.OSPEEDR.Arr (6)   := 2#10#; -- high speed
      GPIO.GPIOA_Periph.PUPDR.Arr (6)     := 2#00#; -- no pullup/down
--!       #if MISO_Pin < 8 then
      GPIO.GPIOA_Periph.AFRL.Arr (6)      := 5;     -- AF5
--!       #else
--!       $MISO_GPIO.AFRH.Arr ($MISO_Pin)      := 5;     -- AF5
--!       #end if;

      --  Set up GPIO for MOSI pin
      RCC.RCC_Periph.AHB1ENR.GPIOAEN  := 1;
      GPIO.GPIOA_Periph.MODER.Arr (7)     := 2#10#; -- AF
      GPIO.GPIOA_Periph.OTYPER.OT.Arr (7) := 0;     -- push-pull
      GPIO.GPIOA_Periph.OSPEEDR.Arr (7)   := 2#10#; -- high speed
      GPIO.GPIOA_Periph.PUPDR.Arr (7)     := 2#00#; -- no pullup/down
--!       #if MOSI_Pin < 8 then
      GPIO.GPIOA_Periph.AFRL.Arr (7)      := 5;     -- AF5
--!       #else
--!       $MOSI_GPIO.AFRH.Arr ($MOSI_Pin)      := 5;     -- AF5
--!       #end if;

      --  Enable $SPI
      RCC.RCC_Periph.APB2ENR.SPI1EN := 1;

      --  Configure SPI
      declare
         Bus_Clock : constant Natural
           := Natural (System_Clocks.PCLK2);
         SPI_Clock : Natural := Bus_Clock / 2;
         BR_Setting : UInt3 := 0;
      begin
         loop
            --  Probably a good plan for the clock to be strictly less
            --  than the device requirement
            exit when SPI_Clock < Maximum_Frequency;

            BR_Setting := BR_Setting + 1;  -- CE here if unachievable
            SPI_Clock := SPI_Clock / 2;
         end loop;

         STM32_SVD.SPI.SPI1_Periph.CR1 :=
           (             -- XXX fill in the others!
            MSTR   => 1,
            BR     => BR_Setting,
            SSI    => 1, -- software NSS
            SSM    => 1, -- software NSS
            CPOL   => 0, -- mode 0
            CPHA   => 0,
            others => <>);
      end;

      --  Deconfigure I2S
      STM32_SVD.SPI.SPI1_Periph.I2SCFGR.I2SMOD := 0;

      --  Enable SPI
      STM32_SVD.SPI.SPI1_Periph.CR1.SPE := 1;

      Initialize_Done := True;
   end Initialize;

   procedure Read_SPI (Bytes : out SPI.Byte_Array)
   with SPARK_Mode => Off
   is
      Value_Read : Short;
      use type Short;
   begin
      for J in Bytes'Range loop
         --  We are in full duplex, so we have to write _something_ to
         --  start the cycle; see "Handling data transmission and
         --  reception", RM0090 rev 11 p 878
         STM32_SVD.SPI.SPI1_Periph.DR.DR := 0;
         while STM32_SVD.SPI.SPI1_Periph.SR.RXNE = 0 loop
            null;
         end loop;
         Value_Read := STM32_SVD.SPI.SPI1_Periph.DR.DR;
         pragma Assert (Value_Read <= Short (Interfaces.Unsigned_8'Last));
         Bytes (J) := Interfaces.Unsigned_8 (Value_Read);
      end loop;
   end Read_SPI;

   procedure Write_SPI (Bytes : SPI.Byte_Array)
   with SPARK_Mode => Off
   is
   begin
      for B of Bytes loop
         STM32_SVD.SPI.SPI1_Periph.DR.DR := Short (B);
         while STM32_SVD.SPI.SPI1_Periph.SR.TXE /= 0 loop
            null;
         end loop;
         while STM32_SVD.SPI.SPI1_Periph.SR.BSY /= 0 loop
            null;
         end loop;
      end loop;
   end Write_SPI;

   procedure Command_SPI (Command    :     SPI.Byte_Array;
                          Result     : out SPI.Byte_Array)
   with SPARK_Mode => Off
   is
      Value_Read : Short;
      use type Short;
   begin
      for C of Command loop
         STM32_SVD.SPI.SPI1_Periph.DR.DR := Short (C);
         while STM32_SVD.SPI.SPI1_Periph.SR.TXE /= 0 loop
            null;
         end loop;
         while STM32_SVD.SPI.SPI1_Periph.SR.BSY /= 0 loop
            null;
         end loop;
      end loop;
      for J in Result'Range loop
         --  We are in full duplex, so we have to write _something_ to
         --  start the cycle; see "Handling data transmission and
         --  reception", RM0090 rev 11 p 878
         STM32_SVD.SPI.SPI1_Periph.DR.DR := 0;
         while STM32_SVD.SPI.SPI1_Periph.SR.RXNE = 0 loop
            null;
         end loop;
         Value_Read := STM32_SVD.SPI.SPI1_Periph.DR.DR;
         pragma Assert (Value_Read <= Short (Interfaces.Unsigned_8'Last));
         Result (J) := Interfaces.Unsigned_8 (Value_Read);
      end loop;
      while STM32_SVD.SPI.SPI1_Periph.SR.BSY /= 0 loop
         null;
      end loop;
   end Command_SPI;

end SPI1.Device;
