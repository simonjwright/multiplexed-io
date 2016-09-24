--  Demonstration code for the AdaPilot project
--  (http://adapilot.likeabird.eu).
--  Copyright (C) 2016 Simon Wright <simon@pushface.org>

--  This package provided access to the CPU cycle counter.

with Interfaces;

package Cycle_Timer
with SPARK_Mode => On
is

   type Cycles is new Interfaces.Unsigned_32;

   function Clock return Cycles
   with Volatile_Function;

end Cycle_Timer;
