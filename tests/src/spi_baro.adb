--  Demonstration code for the AdaPilot project
--  (http://adapilot.likeabird.eu).
--  Copyright (C) 2016 Simon Wright <simon@pushface.org>

with STM32_SVD.GPIO;
with STM32_SVD.RCC;
with STM32_SVD.SPI;

with Ada.Real_Time;
with Ada.Text_IO; use Ada.Text_IO;
with Ada.Unchecked_Conversion;
with Interfaces;

procedure SPI_BARO
is

   --  From schematics_38180-2_adaracer_1.1, SPI2 uses pins
   --
   --  PB10 - SCLK
   --  PB14 - MISO
   --  PB15 - MOSI
   --
   --  /BARO CS - PD7
   --  /FRAM CS - PD10
   --
   --  From RM0090 Issue 11 Fig 27, SPI2 uses GPIO AF5.
   --  From RM0090 Issue 11 Table 1, SPI2 is on APB1 (42 MHz with our
   --  settings).
   --
   --  From DA5611-01BA03_011 page 4, the maximum SCLK is 20 MHz.
   --  This means we will need to run the SPI with a divisor of 4
   --  (=> c10.5 MHz).

   use STM32_SVD;

   type Byte_Array is array (Natural range <>) of Byte;

   type BARO_Command is (ADC_Read,
                         Reset,
                         Convert_Pressure_256,
                         Convert_Pressure_512,
                         Convert_Pressure_1024,
                         Convert_Pressure_2048,
                         Convert_Pressure_4096,
                         Convert_Temperature_256,
                         Convert_Temperature_512,
                         Convert_Temperature_1024,
                         Convert_Temperature_2048,
                         Convert_Temperature_4096,
                         Prom_Read_0,
                         Prom_Read_1,
                         Prom_Read_2,
                         Prom_Read_3,
                         Prom_Read_4,
                         Prom_Read_5,
                         Prom_Read_6,
                         Prom_Read_7)
   with Size => 8;
   for BARO_Command use (ADC_Read                 => 16#00#,
                         Reset                    => 16#1e#,
                         Convert_Pressure_256     => 16#40#,
                         Convert_Pressure_512     => 16#42#,
                         Convert_Pressure_1024    => 16#44#,
                         Convert_Pressure_2048    => 16#46#,
                         Convert_Pressure_4096    => 16#48#,
                         Convert_Temperature_256  => 16#50#,
                         Convert_Temperature_512  => 16#52#,
                         Convert_Temperature_1024 => 16#54#,
                         Convert_Temperature_2048 => 16#56#,
                         Convert_Temperature_4096 => 16#58#,
                         Prom_Read_0              => 16#a0#,
                         Prom_Read_1              => 16#a2#,
                         Prom_Read_2              => 16#a4#,
                         Prom_Read_3              => 16#a6#,
                         Prom_Read_4              => 16#a8#,
                         Prom_Read_5              => 16#aa#,
                         Prom_Read_6              => 16#ac#,
                         Prom_Read_7              => 16#ae#);

   type BARO_Coefficient_Index is (SENS_T1, OFF_T1, TCS, TCO, T_REF, TEMPSENS);
   subtype BARO_Coefficient is Integer range 0 .. 2 ** 16 - 1;
   BARO_Coefficients : array (BARO_Coefficient_Index) of BARO_Coefficient;

   procedure Select_BARO with Inline;
   procedure Deselect_BARO with Inline;
   procedure Read_SPI (Bytes : out Byte_Array);
   procedure Write_SPI (Bytes : Byte_Array);
   procedure Command_SPI (Command : Byte_Array; Result : out Byte_Array);

   procedure Select_BARO
   is
   begin
      GPIO.GPIOD_Periph.BSRR.BR.Arr (7)   := 1;     -- reset /BARO CS
   end Select_BARO;

   procedure Deselect_BARO
   is
   begin
      GPIO.GPIOD_Periph.BSRR.BS.Arr (7)   := 1;     -- set /BARO CS
   end Deselect_BARO;

   procedure Read_SPI (Bytes : out Byte_Array)
   is
      Value_Read : Short;
      use type Short;
   begin
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
   end Read_SPI;

   procedure Write_SPI (Bytes : Byte_Array)
   is
   begin
      for B of Bytes loop
         SPI.SPI2_Periph.DR.DR := Short (B);
         while SPI.SPI2_Periph.SR.TXE /= 0 loop
            null;
         end loop;
         while SPI.SPI2_Periph.SR.BSY /= 0 loop
            null;
         end loop;
      end loop;
   end Write_SPI;

   procedure Command_SPI (Command : Byte_Array; Result : out Byte_Array)
   is
      Value_Read : Short;
      use type Short;
   begin
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
   end Command_SPI;

   use type Ada.Real_Time.Time;

begin
   --  First, deselect BARO.

   --  Enable GPIOD
   RCC.RCC_Periph.AHB1ENR.GPIODEN := 1;

   --  PD7, /BARO CS
   GPIO.GPIOD_Periph.MODER.Arr (7)     := 2#01#; -- general-purpose output
   GPIO.GPIOD_Periph.OTYPER.OT.Arr (7) := 0;     -- push-pull
   GPIO.GPIOD_Periph.OSPEEDR.Arr (7)   := 2#10#; -- high speed
   GPIO.GPIOD_Periph.PUPDR.Arr (7)     := 2#00#; -- no pullup/down
   GPIO.GPIOD_Periph.BSRR.BS.Arr (7)   := 1;     -- set bit

   --  Enable 3.3V Power Sensors (VDD_SENS_EN on PE3)

   --  enable GPIOE
   RCC.RCC_Periph.AHB1ENR.GPIOEEN := 1;

   --  PE3, VDD_SENS_EN
   GPIO.GPIOE_Periph.MODER.Arr (3)     := 2#01#; -- general-purpose output
   GPIO.GPIOE_Periph.OTYPER.OT.Arr (3) := 0;     -- push-pull
   GPIO.GPIOE_Periph.OSPEEDR.Arr (3)   := 2#10#; -- high speed
   GPIO.GPIOE_Periph.PUPDR.Arr (3)     := 2#00#; -- no pullup/down
   GPIO.GPIOE_Periph.BSRR.BS.Arr (3)   := 1;     -- set bit

   --  Enable GPIOB for FRAM SPI pins
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
                           BR     => 3, -- fPCLK / 16
                           SSI    => 1, -- software NSS
                           SSM    => 1, -- software NSS
                           CPOL   => 0, -- mode 0
                           CPHA   => 0,
                           others => <>);

   --  Deconfigure I2S
   SPI.SPI2_Periph.I2SCFGR.I2SMOD := 0;

   --  Enable SPI
   SPI.SPI2_Periph.CR1.SPE := 1;

   declare -- check BARO status
      Raw : Byte_Array (0 .. 1);
      use type Byte;
   begin
      Put_Line ("BARO");
      Select_BARO;
      Write_SPI ((0 => Reset'Enum_Rep));
      Deselect_BARO;
      --  MS5611 needs 2.8 ms
      delay until Ada.Real_Time.Clock + Ada.Real_Time.Milliseconds (5);
         for J in 0 .. 7 loop
            Select_BARO;
            Command_SPI ((0 => Prom_Read_0'Enum_Rep + 2 * Byte (J)),
                         Raw);
            Deselect_BARO;
            Put ("BARO prom" & J'Img & " ");
            for R of Raw loop
               Put (R'Img);
            end loop;
            if J in 1 .. 6 then
               BARO_Coefficients (BARO_Coefficient_Index'Val (J - 1)) :=
                 Integer (Raw (0)) * 256 + Integer (Raw (1));
               Put
                 (BARO_Coefficients (BARO_Coefficient_Index'Val (J - 1))'Img);
            end if;
            New_Line;
            delay until Ada.Real_Time.Clock + Ada.Real_Time.Milliseconds (100);
         end loop;
      New_Line;
   end;

   declare
      Raw : Byte_Array (0 .. 2);
      subtype Digital_Pressure is Integer range 0 .. 2 ** 24 - 1;
      subtype Digital_Temperature is Integer range 0 .. 2 ** 24 - 1;
      subtype Temperature_Difference is Integer range -16776960 .. 16777216;
      subtype Actual_Temperature is Integer range -4000 .. 8500;
      D2 : Digital_Temperature;
      DT : Temperature_Difference;
      TEMP : Actual_Temperature;
   begin
      loop
         Select_BARO;
         Write_SPI ((0 => Convert_Temperature_256'Enum_Rep));
         Deselect_BARO;
         delay until Ada.Real_Time.Clock + Ada.Real_Time.Milliseconds (10);
         Select_BARO;
         Command_SPI ((0 => ADC_Read'Enum_Rep),
                      Raw (0 .. 2));
         Deselect_BARO;
         Put ("BARO temperature ");
         for R of Raw (0 .. 2) loop
            Put (R'Img);
         end loop;
         Put (" => ");
         D2 := (Integer (Raw (0)) * 256
                  + Integer (Raw (1))) * 256
           + Integer (Raw (2));
         Put (" D2" & D2'Img);
         DT := D2 - (BARO_Coefficients (T_REF) * 2 ** 8);
         Put (" DT" & DT'Img);
         declare
            Intermediate_Temp : Float
              := (Float (DT)
                    * Float (BARO_Coefficients (TEMPSENS)))
                / 2.0 ** 23;
         begin
            TEMP := 2000 + Actual_Temperature (Intermediate_Temp);
         end;
         --  TEMP := 2000 + Actual_Temperature
         --    (Long_Integer (DT)
         --       * Long_Integer (BARO_Coefficients (TEMPSENS))
         --       / 2 ** 23);
         Put (TEMP'Img);
         Select_BARO;
         Write_SPI ((0 => Convert_Pressure_256'Enum_Rep));
         Deselect_BARO;
         delay until Ada.Real_Time.Clock + Ada.Real_Time.Milliseconds (10);
         Select_BARO;
         Command_SPI ((0 => ADC_Read'Enum_Rep),
                      Raw (0 .. 2));
         Deselect_BARO;
         Put (" pressure ");
         for R of Raw (0 .. 2) loop
            Put (R'Img);
         end loop;
         New_Line;
         delay until Ada.Real_Time.Clock + Ada.Real_Time.Seconds (1);
      end loop;
   end;

end SPI_BARO;
