--  Demonstration code for the AdaPilot project
--  (http://adapilot.likeabird.eu).
--  Copyright (C) 2016 Simon Wright <simon@pushface.org>

private
package SPI1.Timer_Sleep
with
  Elaborate_Body,
  SPARK_Mode => On
is

   -----------------------------------------------------------------------
   --  NOTE, this package is *NOT* task-safe. Only call from one task.  --
   -----------------------------------------------------------------------

   procedure Sleep (For_Interval : Duration)
   with Pre => For_Interval in 0.0 .. 0.010_000;

end SPI1.Timer_Sleep;
