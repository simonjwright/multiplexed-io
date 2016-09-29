--  Demonstration code for the AdaPilot project
--  (http://adapilot.likeabird.eu).
--  Copyright (C) 2016 Simon Wright <simon@pushface.org>

with Interfaces;

package I2C
with
  SPARK_Mode => On,
  Pure
is

   type Byte_Array is array (Natural range <>) of Interfaces.Unsigned_8
   with Component_Size => 8;

end I2C;
