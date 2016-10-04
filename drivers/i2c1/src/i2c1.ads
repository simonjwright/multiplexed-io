--  Demonstration code for the AdaPilot project
--  (http://adapilot.likeabird.eu).
--  Copyright (C) 2016 Simon Wright <simon@pushface.org>

with Interfaces;

package I2C1
with
  SPARK_Mode,
  Pure
is

   subtype Byte is Interfaces.Unsigned_8;

   type Byte_Array is array (Natural range <>) of Byte
   with Component_Size => 8;

end I2C1;
