--  Demonstration code for the AdaPilot project
--  (http://adapilot.likeabird.eu).
--  Copyright (C) 2016 Simon Wright <simon@pushface.org>

with Interfaces;

package body SPI2.BARO
with
  SPARK_Mode => On,
  Refined_State => (State => (BARO_Reader,
                              Coefficients),
                    Initialization => (Initialization_Status,
                                       Measurement))
is

   Initialization_Status : Device_Status := Uninitialized;

   Measurement : Pressure := 1000_00;

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

   function Enum_Rep (Command : BARO_Command) return Interfaces.Unsigned_8;

   type Coefficient_Index is (SENS_T1, OFF_T1, TCS, TCO, T_REF, TEMPSENS);
   subtype Coefficient is Float range 0.0 .. 2.0 ** 16 - 1.0;
   Coefficients : array (Coefficient_Index) of Coefficient := (others => 0.0);

   function CRC4 (Bytes : Internal.Byte_Array) return Interfaces.Unsigned_8;

   task BARO_Reader;
   --  pragma Annotate
   --    (Gnatprove,
   --       Intentional,
   --       """Coefficients"" might not be initialized before start of tasks",
   --       "initialized at start of task");

   function Status return Device_Status is (Initialization_Status);

   function Current_Pressure return Pressure is (Measurement);

   function Enum_Rep (Command : BARO_Command) return Interfaces.Unsigned_8
     is (Command'Enum_Rep)
   with SPARK_Mode => Off;

   function CRC4 (Bytes : Internal.Byte_Array) return Interfaces.Unsigned_8 is
      CRC : Interfaces.Unsigned_16;
      use type Interfaces.Unsigned_16;
   begin
      CRC := 0;
      for J in Bytes'Range loop
         if J < Bytes'Last then
            CRC := CRC xor Interfaces.Unsigned_16 (Bytes (J));
         end if;
         for K in 1 .. 8 loop
            if (CRC and 16#8000#) /= 0 then
               CRC := Interfaces.Shift_Left (CRC, 1) xor 16#3000#;
            else
               CRC := Interfaces.Shift_Left (CRC, 1);
            end if;
         end loop;
      end loop;
      CRC := Interfaces.Shift_Right (CRC, 12) and 16#000f#;
      return Interfaces.Unsigned_8 (CRC);
   end CRC4;

   procedure Initialize is
      Raw_Coefficients : Internal.Byte_Array (0 .. 15);
      Start_Time : Ada.Real_Time.Time;
      use type Ada.Real_Time.Time;
      use type Interfaces.Unsigned_8;
   begin
      if not Internal.Initialized then
         Internal.Initialize;
      end if;

      --  Reset the MS5611
      Internal.Write_SPI (Internal.BARO, (0 => Enum_Rep (Reset)));
      --  MS5611 needs 2.8 ms
      pragma Warnings (Off, "unused assignment");
      pragma Warnings (Off, "statement has no effect");
      Start_Time := Ada.Real_Time.Clock;
      delay until Start_Time + Ada.Real_Time.Milliseconds (5);
      pragma Warnings (On, "statement has no effect");
      pragma Warnings (On, "unused assignment");

      --  Read the coefficients
      for J in 0 .. 7 loop
         Internal.Command_SPI
           (Internal.BARO,
            (0 => Enum_Rep (Prom_Read_0) + 2 * Interfaces.Unsigned_8 (J)),
            Raw_Coefficients (J * 2 .. J * 2 + 1));
      end loop;

      --  Check the CRC
      if ((CRC4 (Raw_Coefficients)
             xor Raw_Coefficients (Raw_Coefficients'Last))
            and 16#0f#) /= 0
      then
         pragma Annotate
           (Gnatprove,
              False_Positive,
              """Raw_Coefficients"" might not be initialized",
              "all are covered in loop");
         Initialization_Status := Invalid_CRC;
         return;
      end if;

      for J in 1 .. 6 loop
         Coefficients (Coefficient_Index'Val (J - 1)) :=
           Float (Integer (Raw_Coefficients (J * 2)) * 256
                    + Integer (Raw_Coefficients (J * 2 + 1)));
      end loop;

      Initialization_Status := OK;
   end Initialize;

   task body BARO_Reader is
      Raw : Internal.Byte_Array (0 .. 2);

      subtype Digital_Temperature is Float range 0.0 .. 2.0 ** 24 - 1.0;
      subtype Temperature_Difference is Float range -16776960.0 .. 16777216.0;
      subtype Actual_Temperature is Float range -4000.0 .. 8500.0;

      D2   : Digital_Temperature;
      DT   : Temperature_Difference;
      TEMP : Actual_Temperature;
      pragma Unreferenced (TEMP); -- only needed for 2nd-order corrections

      subtype Digital_Pressure is Float range 0.0 .. 2.0 ** 24 - 1.0;
      subtype Offset is Float range -8589672450.0 .. 12884705280.0;
      subtype Sensitivity is Float range -4294836225.0 .. 6442352640.0;
      subtype Actual_Pressure is Float range 1000.0 .. 120000.0;

      D1   : Digital_Pressure;
      OFF  : Offset;
      SENS : Sensitivity;
      P    : Actual_Pressure;

      Start_Time : Ada.Real_Time.Time;
      use type Ada.Real_Time.Time;
   begin
      --  wait for initialization complete
      while Status /= OK loop
         Start_Time := Ada.Real_Time.Clock;
         delay until Start_Time + Ada.Real_Time.Milliseconds (250);
      end loop;
      pragma Assume (Internal.Initialized, "as part of Initialize");

      loop
         --  process temperature

         --  start the conversion
         Internal.Write_SPI (Internal.BARO,
                             (0 => Enum_Rep (Convert_Temperature_4096)));

         --  max conversion time is 9.04 ms w/ precision 4096
         Start_Time := Ada.Real_Time.Clock;
         delay until Start_Time + Ada.Real_Time.Milliseconds (10);

         --  retrieve the result
         Internal.Command_SPI (Internal.BARO, (0 => Enum_Rep (ADC_Read)), Raw);

         D2 := Float ((Integer (Raw (0)) * 256
                         + Integer (Raw (1))) * 256
                        + Integer (Raw (2)));
         DT := D2 - (Coefficients (T_REF) * 2.0 ** 8);
         TEMP :=
           Float'Max
             (Float'Min (2000.0 + DT * Coefficients (TEMPSENS) / 2.0 ** 23,
                         Actual_Temperature'Last),
              Actual_Temperature'First);

         --  process pressure
         --  start the conversion
         Internal.Write_SPI (Internal.BARO,
                             (0 => Enum_Rep (Convert_Pressure_4096)));

         --  max conversion time is 9.04 ms w/ precision 4096
         Start_Time := Ada.Real_Time.Clock;
         delay until Start_Time + Ada.Real_Time.Milliseconds (10);

         --  retrieve the result
         Internal.Command_SPI (Internal.BARO, (0 => Enum_Rep (ADC_Read)), Raw);

         D1 := Float ((Integer (Raw (0)) * 256
                         + Integer (Raw (1))) * 256
                        + Integer (Raw (2)));
         OFF := Coefficients (OFF_T1) * 2.0 ** 16
           + Coefficients (TCO) * DT / 2.0 ** 7;
         SENS := Coefficients (SENS_T1) * 2.0 ** 15
           + Coefficients (TCS) * DT / 2.0 ** 8;
         P := Float'Max
           (Float'Min ((D1 * SENS / 2.0 ** 21 - OFF) / 2.0 ** 15,
                       Actual_Pressure'Last),
            Actual_Pressure'First);

         Measurement := Pressure (P);

         Start_Time := Ada.Real_Time.Clock;
         delay until Start_Time + Ada.Real_Time.Milliseconds (100);
      end loop;
   end BARO_Reader;

end SPI2.BARO;
