--  Demonstration code for the AdaPilot project
--  (http://adapilot.likeabird.eu).
--  Copyright (C) 2016 Simon Wright <simon@pushface.org>

package STM32F40x.GPIO.Clock with SPARK_Mode is

   --  This version will be supported in FSF GCC 6 and GNAT GPL 2016.
   --  function Enabled (Periph : GPIO_Peripheral) return Boolean
   --  with Volatile_Function;

   --  procedure Enable (Periph : GPIO_Peripheral)
   --  with Post => Enabled (Periph);

   procedure Enable (Periph : GPIO_Peripheral);

end STM32F40x.GPIO.Clock;
