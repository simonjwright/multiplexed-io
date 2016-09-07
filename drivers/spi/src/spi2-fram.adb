--  Demonstration code for the AdaPilot project
--  (http://adapilot.likeabird.eu).
--  Copyright (C) 2016 Simon Wright <simon@pushface.org>

with Ada.Unchecked_Conversion;
with Interfaces;

with SPI2.Internal;

package body SPI2.FRAM
with SPARK_Mode => On
is

   type FRAM_Opcode is
     (
      Write_Status_Register,  -- 'Enum_Rep order
      Write_Memory_Data,
      Read_Memory_Data,
      Reset_Write_Enable_Latch,
      Read_Status_Register,
      Set_Write_Enable_Latch,
      Fast_Read_Memory_Data,
      Read_Device_ID,
      Enter_Sleep_Mode
     ) with Size => 8;
   for FRAM_Opcode use
     (
      Set_Write_Enable_Latch   => 2#0000_0110#,  -- documentation order
      Reset_Write_Enable_Latch => 2#0000_0100#,
      Read_Status_Register     => 2#0000_0101#,
      Write_Status_Register    => 2#0000_0001#,
      Read_Memory_Data         => 2#0000_0011#,
      Fast_Read_Memory_Data    => 2#0000_1011#,
      Write_Memory_Data        => 2#0000_0010#,
      Enter_Sleep_Mode         => 2#1011_1001#,
      Read_Device_ID           => 2#1001_1111#
     );

   package body IO is

      subtype T_FRAM_Data
        is Internal.Byte_Array (0 .. (T'Size + 7) / 8 - 1);

      function To_T
        is new Ada.Unchecked_Conversion (T_FRAM_Data, T);
      function To_T_FRAM_Data
        is new Ada.Unchecked_Conversion (T, T_FRAM_Data);

      procedure Read
        (From : FRAM_Index;
         V : out T)
      is
         Demand : constant Internal.Byte_Array :=
           (Read_Memory_Data'Enum_Rep,
            Interfaces.Unsigned_8 (From / 256),
            Interfaces.Unsigned_8 (From mod 256));
         Result : T_FRAM_Data;
      begin
         Internal.Command_SPI (Internal.FRAM, Demand, Result);
         V := To_T (Result);
      end Read;

      procedure Write
        (To : FRAM_Index;
         V : T)
      is
         Demand : constant Internal.Byte_Array :=
           (Write_Memory_Data'Enum_Rep,
            Interfaces.Unsigned_8 (To / 256),
            Interfaces.Unsigned_8 (To mod 256));
         use type Internal.Byte_Array;
      begin
         Internal.Write_SPI (Internal.FRAM,
                             (0 => Set_Write_Enable_Latch'Enum_Rep));
         Internal.Write_SPI (Internal.FRAM,
                             Demand & To_T_FRAM_Data (V));
      end Write;

   end IO;

end SPI2.FRAM;
