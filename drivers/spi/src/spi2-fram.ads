--  Demonstration code for the AdaPilot project
--  (http://adapilot.likeabird.eu).
--  Copyright (C) 2016 Simon Wright <simon@pushface.org>

package SPI2.FRAM
with
  SPARK_Mode => On,
  Elaborate_Body
is

   FRAM_Size : constant := 32768;
   subtype FRAM_Index is Natural range 0 .. FRAM_Size - 1;
   --  The index of the data concerned within the FRAM.
   --  XXX how is this to be managed?

   generic
      type T is private;
   package IO is
      procedure Read (From : FRAM_Index; V : out T)
        with Pre => From + ((T'Size + 7) / 8 - 1) < FRAM_Size;
      procedure Write (To : FRAM_Index; V : T)
        with Pre => To + ((T'Size + 7) / 8 - 1) < FRAM_Size;
   end IO;

end SPI2.FRAM;
