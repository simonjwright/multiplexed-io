--  Demonstration code for the AdaPilot project
--  (http://adapilot.likeabird.eu).
--  Copyright (C) 2016 Simon Wright <simon@pushface.org>

pragma Warnings (Off, "*internal GNAT unit");
with System.STM32;
pragma Warnings (On, "*internal GNAT unit");

package body System_Clocks
with SPARK_Mode => On
is

   function PCLK1 return Frequency
   is (Frequency (System.STM32.System_Clocks.PCLK1));

   function PCLK2 return Frequency
   is (Frequency (System.STM32.System_Clocks.PCLK2));

end System_Clocks;
