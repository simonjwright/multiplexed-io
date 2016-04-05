--  Demonstration code for the AdaPilot project
--  (http://adapilot.likeabird.eu).
--  Copyright (C) Simon Wright <simon@pushface.org> 2016

with Ada.Real_Time;
with SN74HC165;
with STM32F4.GPIO;
with STM32F42xxx;

package body Reporter is

   The_Input : SN74HC165.Chip;

   Input_Read : SN74HC165.Byte
     with Volatile, Unreferenced;  -- for GDB access in initial testing

   task T;

   task body T is
      use type Ada.Real_Time.Time;
   begin
      loop
         declare
            Input : constant SN74HC165.Byte := SN74HC165.Read (The_Input);
         begin
            Input_Read := Input;
         end;
         delay until Ada.Real_Time.Clock + Ada.Real_Time.Milliseconds (1000);
      end loop;
   end T;

begin
   declare
      use STM32F42xxx;
      use STM32F4.GPIO;
      use SN74HC165;
   begin
      --  Configure the input
      The_Input.Initialize
        ((SER_OUT => (GPIO_C'Access, Pin_8),
          SH_LD   => (GPIO_C'Access, Pin_12),
          CLK     => (GPIO_C'Access, Pin_11),
          CE      => (GPIO_D'Access, Pin_2)));
   end;
end Reporter;