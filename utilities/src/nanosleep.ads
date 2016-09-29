--  Demonstration code for the AdaPilot project
--  (http://adapilot.likeabird.eu).
--  Copyright (C) 2016 Simon Wright <simon@pushface.org>

--  This package implements a busy-wait loop for periods as required
--  up to 1 ms.

with Interfaces;

package Nanosleep with SPARK_Mode is

   subtype Sleepable is Duration range 0.0 .. 0.001;
   --  This is to avoid busy-waiting for ridiculously long periods;
   --  even a millisecond seems rather long!

   procedure Sleep (Period : Sleepable) with Inline_Always;

   type Interval is private;

   function To_Interval (Period : Sleepable) return Interval
   with Inline_Always;

   --  Loop for the given number of processor cycles.
   procedure Sleep (Period : Interval) with Inline_Always;

private

   type Interval is new Interfaces.Unsigned_32;
   --  Counts processor cycles.

end Nanosleep;
