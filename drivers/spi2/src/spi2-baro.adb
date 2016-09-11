--  Demonstration code for the AdaPilot project
--  (http://adapilot.likeabird.eu).
--  Copyright (C) 2016 Simon Wright <simon@pushface.org>

with Ada.Real_Time;
with Interfaces;

with SPI2.Internal;
pragma Elaborate_All (SPI2.Internal);

package body SPI2.BARO
with SPARK_Mode => On
is

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
   function Enum_Rep (Command : BARO_Command) return Interfaces.Unsigned_8
     is (Command'Enum_Rep)
   with SPARK_Mode => Off;

   type Coefficient_Index is (SENS_T1, OFF_T1, TCS, TCO, T_REF, TEMPSENS);
   subtype Coefficient is Float range 0.0 .. 2.0 ** 16 - 1.0;
   Coefficients : array (Coefficient_Index) of Coefficient;

   task BARO_Reader;
   pragma Annotate
     (Gnatprove,
        Intentional,
        """Coefficients"" might not be initialized before start of tasks",
        "initialized at start of task");

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
      --  Reset the MS5611
      Internal.Write_SPI (Internal.BARO, (0 => Enum_Rep (Reset)));
      --  MS5611 needs 2.8 ms
      Start_Time := Ada.Real_Time.Clock;
      delay until Start_Time + Ada.Real_Time.Milliseconds (3);

      --  Read the coefficients (I'm not bothering with the device data &
      --  the CRC yet)

      for J in 1 .. 6 loop
         declare
            Raw : Internal.Byte_Array (0 .. 1);
            use type Interfaces.Unsigned_8;
         begin
            Internal.Command_SPI
              (Internal.BARO,
               (0 => Enum_Rep (Prom_Read_0) + 2 * Interfaces.Unsigned_8 (J)),
               Raw);
            Coefficients (Coefficient_Index'Val (J - 1)) :=
              Float (Integer (Raw (0)) * 256 + Integer (Raw (1)));
         end;
      end loop;

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
