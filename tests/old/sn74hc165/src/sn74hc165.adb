--  Demonstration code for the AdaPilot project
--  (http://adapilot.likeabird.eu).
--  Copyright (C) 2016 Simon Wright <simon@pushface.org>

with Interfaces;
with Nanosleep;
with STM32F42xxx;

package body SN74HC165 is

   procedure Initialize (The_Chip : out Chip; Using : Chip_Pins)
   is
      use STM32F4.GPIO;
   begin
      The_Chip.The_Pins := Using;
      for Point of Using loop
         STM32F42xxx.Enable_Clock (Point.Port.all);
      end loop;
      Configure_IO (Using (SER_OUT),
                    (Mode => Mode_In,
                     Output_Type => Open_Drain,
                     Speed => Speed_25MHz,
                     Resistors => Floating));
      Configure_IO (Using (SH_LD),
                    (Mode => Mode_Out,
                     Output_Type => Push_Pull,
                     Speed => Speed_25MHz,
                     Resistors => Floating));
      Configure_IO (Using (CLK),
                    (Mode => Mode_Out,
                     Output_Type => Push_Pull,
                     Speed => Speed_25MHz,
                     Resistors => Floating));
      Configure_IO (Using (CE),
                    (Mode => Mode_Out,
                     Output_Type => Push_Pull,
                     Speed => Speed_25MHz,
                     Resistors => Floating));
      STM32F4.GPIO.Clear (The_Chip.The_Pins (CLK));
      STM32F4.GPIO.Clear (The_Chip.The_Pins (CE));
      STM32F4.GPIO.Set (The_Chip.The_Pins (SH_LD));
   end Initialize;

   Short_Sleep : constant Nanosleep.Interval :=
     Nanosleep.To_Interval (0.000_000_024);
   --  This is the datasheet value for 4.5V VCC, a bit short for the
   --  3V of the STM32F42xx but works for me!

   function Read (From : in out Chip) return Byte
   is
      --  See http://playground.arduino.cc/Code/ShiftRegSN74HC165N.
      --
      --  Note, since we only drive CLK when we want to retrieve data,
      --  we don't need to manipulate CE (Clock Enable, not-CLK_INH)
      --  at all.
      The_Port : STM32F4.GPIO.GPIO_Port
        renames From.The_Pins (SER_OUT).Port.all;
      The_Pin : constant Integer :=
        STM32F4.GPIO.GPIO_Pin'Pos (From.The_Pins (SER_OUT).Pin);
      Result : Byte := (others => 0);
      use STM32F4.GPIO;
      use type Interfaces.Unsigned_16;
   begin
      Clear (From.The_Pins (SH_LD));
      Nanosleep.Sleep (Short_Sleep);
      Set (From.The_Pins (SH_LD));
      for B in reverse Result'Range loop
         --  Read the current bit.
         declare
            Raw_Input : constant STM32F4.Half_Word := Current_Input (The_Port);
            Input : constant Interfaces.Unsigned_16 :=
              Interfaces.Unsigned_16 (Raw_Input);
         begin
            Result (B) :=
              Bit (Interfaces.Shift_Right (Input, The_Pin) and 1);
         end;
         exit when B = Byte'First;
         --  Clock in the next bit.
         Set (From.The_Pins (CLK));
         Nanosleep.Sleep (Short_Sleep);
         Clear (From.The_Pins (CLK));
         Nanosleep.Sleep (Short_Sleep);
      end loop;
      return Result;
   end Read;

end SN74HC165;
