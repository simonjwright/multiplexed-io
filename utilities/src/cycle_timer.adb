--  Demonstration code for the AdaPilot project
--  (http://adapilot.likeabird.eu).
--  Copyright (C) 2016 Simon Wright <simon@pushface.org>

with System;

package body Cycle_Timer
with SPARK_Mode => On
is

   DEMCR : Interfaces.Unsigned_32
     with
       Import,
       Convention => Ada,
       Volatile,
       Address => System'To_Address (16#E000_EDFC#);

   DWT_CTRL : Interfaces.Unsigned_32
     with
       Import,
       Convention => Ada,
       Volatile,
       Address => System'To_Address (16#E000_1000#);

   DWT_CYCCNT : Cycles
     with
       Import,
       Convention => Ada,
       Volatile,
       Address => System'To_Address (16#E000_1004#);

   function Clock return Cycles
   is
      pragma SPARK_Mode (Off);
      Result : constant Cycles := DWT_CYCCNT;
   begin
      return Result;
   end Clock;

begin
   pragma SPARK_Mode (Off);

   declare
      --  Bits in DEMCR
      TRCENA : constant := 24;

      --  Bits in DWT_CTRL
      NOCYCCNT  : constant := 25;
      CYCCNTENA : constant := 0;

      use type Interfaces.Unsigned_32;
   begin
      DEMCR := DEMCR or Interfaces.Shift_Left (1, TRCENA);

      --  Check for the presence of CYCCNT
      if (DWT_CTRL and Interfaces.Shift_Left (1, NOCYCCNT)) /= 0 then
         raise Program_Error with "DWT_CYCCNT not supported";
      end if;

      --  Enable CYCCNT
      DWT_CTRL := DWT_CTRL or Interfaces.Shift_Left (1, CYCCNTENA);
   end;
end Cycle_Timer;
