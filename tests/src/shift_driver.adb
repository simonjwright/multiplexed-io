--  Demonstration code for the AdaPilot project
--  (http://adapilot.likeabird.eu).
--  Copyright (C) 2016 Simon Wright <simon@pushface.org>

with Ada.Real_Time;
with SN74HC595;
with STM32F4.GPIO;
with STM32F42xxx;

package body Shift_Driver is

   The_Output : SN74HC595.Chip;

   task T;

   task body T is
      Bits : SN74HC595.Byte;
      use type Ada.Real_Time.Time;
   begin
      loop
         for B in Bits'Range loop
            Bits := (others => 0);
            Bits (B) := 1;
            SN74HC595.Write (The_Output, Bits);
            delay until Ada.Real_Time.Clock
              + Ada.Real_Time.Milliseconds (100);
         end loop;
      end loop;
   end T;

begin
   declare
      use STM32F42xxx;
      use STM32F4.GPIO;
      use SN74HC595;
   begin
      --  The Sparkfun breakout board has
      --
      --    /Reset  => NOT_SCLR
      --    /OE     => NOT_G
      --    Clock   => SCK
      --    L_Clock => RCK
      --    SER_IN  => SER
      --
      --  Configure the input; on the RHS of the STM32F429I-DISCO,
      --  free pins per DocID025175 Rev 1 (STM32F429I-DISCO User
      --  Manual) Table 6 are:
      --
      --  PA5 PC3 PF6 PG2 PG3
      --
      --  On my board, PF6 is u/s, so I've used PF7. Its alternate
      --  functions are related to LCD-TFT, LCD-SPI, and L3GD20
      --  (MEMS), so not much lost for the demo!
      The_Output.Initialize
        ((NOT_SCLR => (GPIO_A'Access, Pin_5),
          NOT_G    => (GPIO_C'Access, Pin_3),
          SCK      => (GPIO_F'Access, Pin_7),
          RCK      => (GPIO_G'Access, Pin_2),
          SER      => (GPIO_G'Access, Pin_3)));
   end;
end Shift_Driver;
