--  Demonstration code for the AdaPilot project
--  (http://adapilot.likeabird.eu).
--  Copyright (C) 2016 Simon Wright <simon@pushface.org>

with STM32_SVD.GPIO;
with STM32_SVD.RCC;
with STM32_SVD.SPI;

package body SPI2.Internal
with
  SPARK_Mode => On
is

   --  We use a protected type here because we have to protect the bus
   --  from concurrent access by FRAM and BARO.
   --
   --  Under Ravenscar restrictions, it doesn't appear possible to
   --  implement a standard Lock scheme since the maximum entry queue
   --  length is 1 (for SPI2, there might not be a problem, since
   --  there are only two devices; but ... we don't know how many
   --  tasks might want to access the FRAM).
   --
   --  In any case, the lockout won't be very long (some timing data
   --  needed here!).
   protected Implementation is

      procedure Read_SPI (The_Device : Device; Bytes : out Byte_Array);

      procedure Write_SPI (The_Device : Device; Bytes : Byte_Array);

      procedure Command_SPI (The_Device :     Device;
                             Command    :     Byte_Array;
                             Result     : out Byte_Array);

   end Implementation;

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
   --  From RM0090 Issue 11 Fig 27, SPI2 uses GPIO AF6.
   --  From RM0090 Issue 11 Table 1, SPI2 is on APB1 (42 MHz with our
   --  settings).
   --
   --  From DA5611-01BA03_011 page 4, the maximum SCLK is 20 MHz.
   --  This means we will need to run the SPI with a divisor of 4
   --  (=> c10.5 MHz).

   use STM32_SVD;

   procedure Select_Device (The_Device : Device) with Inline;
   procedure Deselect_Device (The_Device : Device) with Inline;

   protected body Implementation is

      procedure Read_SPI (The_Device : Device; Bytes : out Byte_Array)
      with SPARK_Mode => Off
      is
         Value_Read : Short;
         use type Short;
      begin
         Select_Device (The_Device);
         for J in Bytes'Range loop
            --  We are in full duplex, so we have to write _something_ to
            --  start the cycle; see "Handling data transmission and
            --  reception", RM0090 rev 11 p 878
            SPI.SPI2_Periph.DR.DR := 0;
            while SPI.SPI2_Periph.SR.RXNE = 0 loop
               null;
            end loop;
            Value_Read := SPI.SPI2_Periph.DR.DR;
            pragma Assert (Value_Read <= Short (Interfaces.Unsigned_8'Last));
            Bytes (J) := Interfaces.Unsigned_8 (Value_Read);
         end loop;
         Deselect_Device (The_Device);
      end Read_SPI;

      procedure Write_SPI (The_Device : Device; Bytes : Byte_Array)
      with SPARK_Mode => Off
      is
      begin
         Select_Device (The_Device);
         for B of Bytes loop
            SPI.SPI2_Periph.DR.DR := Short (B);
            while SPI.SPI2_Periph.SR.TXE /= 0 loop
               null;
            end loop;
            while SPI.SPI2_Periph.SR.BSY /= 0 loop
               null;
            end loop;
         end loop;
         Deselect_Device (The_Device);
      end Write_SPI;

      procedure Command_SPI (The_Device :     Device;
                             Command    :     Byte_Array;
                             Result     : out Byte_Array)
      with SPARK_Mode => Off
      is
         Value_Read : Short;
         use type Short;
      begin
         Select_Device (The_Device);
         for C of Command loop
            SPI.SPI2_Periph.DR.DR := Short (C);
            while SPI.SPI2_Periph.SR.TXE /= 0 loop
               null;
            end loop;
            while SPI.SPI2_Periph.SR.BSY /= 0 loop
               null;
            end loop;
         end loop;
         for J in Result'Range loop
            --  We are in full duplex, so we have to write _something_ to
            --  start the cycle; see "Handling data transmission and
            --  reception", RM0090 rev 11 p 878
            SPI.SPI2_Periph.DR.DR := 0;
            while SPI.SPI2_Periph.SR.RXNE = 0 loop
               null;
            end loop;
            Value_Read := SPI.SPI2_Periph.DR.DR;
            pragma Assert (Value_Read <= Short (Interfaces.Unsigned_8'Last));
            Result (J) := Interfaces.Unsigned_8 (Value_Read);
         end loop;
         while SPI.SPI2_Periph.SR.BSY /= 0 loop
            null;
         end loop;
         Deselect_Device (The_Device);
      end Command_SPI;

   end Implementation;

   procedure Select_Device (The_Device : Device)
   with SPARK_Mode => Off
   is
   begin
      case The_Device is
         when BARO =>
            GPIO.GPIOD_Periph.BSRR.BR.Arr (7)   := 1;     -- reset /BARO CS
         when FRAM =>
            GPIO.GPIOD_Periph.BSRR.BR.Arr (10)   := 1;    -- reset /FRAM CS
      end case;
   end Select_Device;

   procedure Deselect_Device (The_Device : Device)
   with SPARK_Mode => Off
   is
   begin
      case The_Device is
         when BARO =>
            GPIO.GPIOD_Periph.BSRR.BS.Arr (7)   := 1;     -- set /BARO CS
         when FRAM =>
            GPIO.GPIOD_Periph.BSRR.BS.Arr (10)   := 1;    -- set /FRAM CS
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

   --  Enable GPIOB
   RCC.RCC_Periph.AHB1ENR.GPIOBEN := 1;

   --  PB10, SCLK
   GPIO.GPIOB_Periph.MODER.Arr (10)     := 2#10#; -- AF
   GPIO.GPIOB_Periph.OTYPER.OT.Arr (10) := 0;     -- push-pull
   GPIO.GPIOB_Periph.OSPEEDR.Arr (10)   := 2#10#; -- high speed
   GPIO.GPIOB_Periph.PUPDR.Arr (10)     := 2#00#; -- no pullup/down
   GPIO.GPIOB_Periph.AFRH.Arr (10)      := 5;     -- AF5

   --  PB14, MISO
   GPIO.GPIOB_Periph.MODER.Arr (14)     := 2#10#; -- AF
   GPIO.GPIOB_Periph.OTYPER.OT.Arr (14) := 1;     -- open-drain
   GPIO.GPIOB_Periph.OSPEEDR.Arr (14)   := 2#10#; -- high speed
   GPIO.GPIOB_Periph.PUPDR.Arr (14)     := 2#00#; -- no pullup/down
   GPIO.GPIOB_Periph.AFRH.Arr (14)      := 5;     -- AF5

   --  PB15, MOSI
   GPIO.GPIOB_Periph.MODER.Arr (15)     := 2#10#; -- AF
   GPIO.GPIOB_Periph.OTYPER.OT.Arr (15) := 0;     -- push-pull
   GPIO.GPIOB_Periph.OSPEEDR.Arr (15)   := 2#10#; -- high speed
   GPIO.GPIOB_Periph.PUPDR.Arr (15)     := 2#00#; -- no pullup/down
   GPIO.GPIOB_Periph.AFRH.Arr (15)      := 5;     -- AF5

   --  Enable SPI2
   RCC.RCC_Periph.APB1ENR.SPI2EN := 1;

   --  Configure SPI
   SPI.SPI2_Periph.CR1 := (             -- XXX fill in the others!
                           MSTR   => 1,
                           BR     => 1, -- fPCLK / 4
                           SSI    => 1, -- software NSS
                           SSM    => 1, -- software NSS
                           CPOL   => 0, -- mode 0
                           CPHA   => 0,
                           others => <>);
   --  SPI.SPI2_Periph.CR2 := (SSOE   => 1,
   --                          others => <>);

   --  Deconfigure I2S
   SPI.SPI2_Periph.I2SCFGR.I2SMOD := 0;

   --  Enable SPI
   SPI.SPI2_Periph.CR1.SPE := 1;

end SPI2.Internal;