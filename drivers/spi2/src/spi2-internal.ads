--  Demonstration code for the AdaPilot project
--  (http://adapilot.likeabird.eu).
--  Copyright (C) 2016 Simon Wright <simon@pushface.org>

with SPI;

private
package SPI2.Internal
with
  SPARK_Mode => On,
  Elaborate_Body
is

   function Initialized return Boolean
   with
     Inline;

   procedure Initialize
   with
     Pre => not Initialized,
     Post => Initialized;

   type Device is (BARO, FRAM);

   subtype Byte_Array is SPI.Byte_Array;

   procedure Read_SPI (The_Device : Device; Bytes : out Byte_Array)
   with
     Pre => Initialized;

   procedure Write_SPI (The_Device : Device; Bytes : Byte_Array)
   with
     Pre => Initialized;

   procedure Command_SPI (The_Device :     Device;
                          Command    :     Byte_Array;
                          Result     : out Byte_Array)
   with
     Pre => Initialized;

private

   --  We use a protected type here because we have to protect the bus
   --  from concurrent access by FRAM and BARO.
   --
   --  Under Ravenscar restrictions, it doesn't appear possible to
   --  implement a standard Lock scheme since the maximum entry queue
   --  length is 1 (for SPI2, there might not be a problem, since
   --  there are only two devices; but ... we don't know how many
   --  tasks might want to access the FRAM).
   --
   --  In any case, the lockout won't be very long (some timing data
   --  needed here!).
   protected Implementation
   is

      procedure Read_SPI (The_Device : Device; Bytes : out Byte_Array)
      with
        Pre => Initialized;

      procedure Write_SPI (The_Device : Device; Bytes : Byte_Array)
      with
        Pre => Initialized;

      procedure Command_SPI (The_Device :     Device;
                             Command    :     Byte_Array;
                             Result     : out Byte_Array)
      with
        Pre => Initialized;

   end Implementation;

end SPI2.Internal;
