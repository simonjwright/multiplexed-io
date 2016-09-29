--  Demonstration code for the AdaPilot project
--  (http://adapilot.likeabird.eu).
--  Copyright (C) 2016 Simon Wright <simon@pushface.org>

with System;

package body Nanosleep with SPARK_Mode is

   Clock_Frequency : constant := 168_000_000;
   --  STM32F42xxx without over-drive.

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

   DWT_CYCCNT : Interval
     with
       Import,
       Convention => Ada,
       Volatile,
       Address => System'To_Address (16#E000_1004#);

   function To_Interval (Period : Sleepable) return Interval
     is (Interval (Period * Clock_Frequency));

   procedure Sleep (Period : Sleepable) is
      Start : constant Interval := DWT_CYCCNT;
      Current : Interval;
      Period_As_Interval : constant Interval := To_Interval (Period);
      --  do this last
   begin
      loop
         Current := DWT_CYCCNT;
         exit when Current - Start > Period_As_Interval;
      end loop;
   end Sleep;

   procedure Sleep (Period : Interval) is
      Start : constant Interval := DWT_CYCCNT;
      Current : Interval;
   begin
      loop
         Current := DWT_CYCCNT;
         exit when Current - Start > Period;
      end loop;
   end Sleep;

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
end Nanosleep;
