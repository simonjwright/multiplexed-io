--  Demonstration code for the AdaPilot project
--  (http://adapilot.likeabird.eu).
--  Copyright (C) 2016 Simon Wright <simon@pushface.org>

with STM32F40x;

package PCF8574A with SPARK_Mode is

   function Enabled return Boolean;
   --  Hmm, this is a check on the hardware's state!

   procedure Initialize
   with Post => Enabled;

   function Read return STM32F40x.Byte
   with Pre => Enabled;

   procedure Write (B : STM32F40x.Byte)
   with Pre => Enabled;

end PCF8574A;
