--  Demonstration code for the AdaPilot project
--  (http://adapilot.likeabird.eu).
--  Copyright (C) 2016 Simon Wright <simon@pushface.org>

package System_Clocks
with SPARK_Mode => On
is

   subtype Frequency is Natural;  -- e.g.42_000_000

   function PCLK1 return Frequency
   with
     Inline;

   function PCLK2 return Frequency
   with
     Inline;

end System_Clocks;
