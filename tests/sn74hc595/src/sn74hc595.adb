--  Demonstration code for the AdaPilot project
--  (http://adapilot.likeabird.eu).
--  Copyright (C) 2016 Simon Wright <simon@pushface.org>

with Nanosleep;
with STM32F42xxx;

package body SN74HC595 is

   Short_Sleep : constant Nanosleep.Interval :=
     Nanosleep.To_Interval (0.000_000_024);
   --  This is the datasheet value for 4.5V VCC, a bit short for the
   --  3V of the STM32F42xx but works for me!

   procedure Initialize (The_Chip : out Chip; Using : Chip_Pins)
   is
      use STM32F4.GPIO;
   begin
      The_Chip.The_Pins := Using;
      for Point of Using loop
         STM32F42xxx.Enable_Clock (Point.Port.all);
      end loop;
      Configure_IO (Using (NOT_SCLR),
                    (Mode => Mode_Out,
                     Output_Type => Push_Pull,
                     Speed => Speed_25MHz,
                     Resistors => Floating));
      Configure_IO (Using (NOT_G),
                    (Mode => Mode_Out,
                     Output_Type => Push_Pull,
                     Speed => Speed_25MHz,
                     Resistors => Floating));
      Configure_IO (Using (SCK),
                    (Mode => Mode_Out,
                     Output_Type => Push_Pull,
                     Speed => Speed_25MHz,
                     Resistors => Floating));
      Configure_IO (Using (RCK),
                    (Mode => Mode_Out,
                     Output_Type => Push_Pull,
                     Speed => Speed_25MHz,
                     Resistors => Floating));
      Configure_IO (Using (SER),
                    (Mode => Mode_Out,
                     Output_Type => Push_Pull,
                     Speed => Speed_25MHz,
                     Resistors => Floating));
      STM32F4.GPIO.Clear (The_Chip.The_Pins (SCK));
      STM32F4.GPIO.Clear (The_Chip.The_Pins (RCK));
      STM32F4.GPIO.Set (The_Chip.The_Pins (NOT_G));
      Nanosleep.Sleep (Short_Sleep);
      STM32F4.GPIO.Clear (The_Chip.The_Pins (NOT_SCLR));
      STM32F4.GPIO.Clear (The_Chip.The_Pins (NOT_G));
      Nanosleep.Sleep (Short_Sleep);
      STM32F4.GPIO.Set (The_Chip.The_Pins (NOT_SCLR));
   end Initialize;

   procedure Write (To : in out Chip; Bits : Byte)
   is
   begin
      for B in reverse Bits'Range loop
         if Bits (B) = 0 then
            STM32F4.GPIO.Clear (To.The_Pins (SER));
         else
            STM32F4.GPIO.Set (To.The_Pins (SER));
         end if;
         Nanosleep.Sleep (Short_Sleep);
         STM32F4.GPIO.Set (To.The_Pins (SCK));
         Nanosleep.Sleep (Short_Sleep);
         STM32F4.GPIO.Clear (To.The_Pins (SCK));
      end loop;
      STM32F4.GPIO.Set (To.The_Pins (RCK));
      Nanosleep.Sleep (Short_Sleep);
      STM32F4.GPIO.Clear (To.The_Pins (RCK));
   end Write;

end SN74HC595;
