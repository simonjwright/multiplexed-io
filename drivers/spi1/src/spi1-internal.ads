--  Demonstration code for the AdaPilot project
--  (http://adapilot.likeabird.eu).
--  Copyright (C) 2016 Simon Wright <simon@pushface.org>

with SPI;

--  private --  (can't say this with Abstract_State)
package SPI1.Internal
with
  SPARK_Mode,
  Abstract_State => (State with External),
  Initializes => State,
  Elaborate_Body
is

   type Device is (MPU9250);

   subtype Byte_Array is SPI.Byte_Array;

   procedure Read_SPI (The_Device : Device; Bytes : out Byte_Array)
   with Depends => (State => State,
                    Bytes => (State, The_Device));

   procedure Write_SPI (The_Device : Device; Bytes : Byte_Array)
   with Depends => (State => (State, The_Device, Bytes));

   procedure Command_SPI (The_Device :     Device;
                          Command    :     Byte_Array;
                          Result     : out Byte_Array)
   with Depends => (State => (State, The_Device, Command),
                    Result => (State, The_Device, Command));

private

   --  We use a protected type here because we might have to protect
   --  the bus from concurrent access by MPU and ???.
   --
   --  Under Ravenscar restrictions, it doesn't appear possible to
   --  implement a standard Lock scheme since the maximum entry queue
   --  length is 1 (for SPI1, there might not be a problem, since
   --  there are only two devices; but ... we don't know how many
   --  tasks might want to access the FRAM).
   --
   --  In any case, the lockout won't be very long (some timing data
   --  needed here!).
   protected Implementation
   with Part_Of => State
   is

      procedure Read_SPI (The_Device : Device; Bytes : out Byte_Array)
      with Depends => (Implementation => Implementation,
                       State => State,
                       Bytes => (State, The_Device));

      procedure Write_SPI (The_Device : Device; Bytes : Byte_Array)
      with Depends => (Implementation => Implementation,
                       State => (State, The_Device, Bytes));

      procedure Command_SPI (The_Device :     Device;
                             Command    :     Byte_Array;
                             Result     : out Byte_Array)
      with Depends => (Implementation => Implementation,
                       State => (State, The_Device, Command),
                       Result => (State, The_Device, Command));

   end Implementation;

end SPI1.Internal;
