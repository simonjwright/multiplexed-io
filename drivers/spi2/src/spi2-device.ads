pragma Source_Reference (1, "../spi/src/spi-device.ads.pp");
--  Demonstration code for the AdaPilot project
--  (http://adapilot.likeabird.eu).
--  Copyright (C) 2016 Simon Wright <simon@pushface.org>

--  THIS FILE, spi?-device.ads, IS GENERATED USING GNATPREP FROM
--  spi/src/spi-device.ads.pp.  TO MAKE A PERMANENT CHANGE, EDIT THAT
--  FILE AND REGENERATE, THEN COMMIT THE REGENERATED FILE.

with SPI;

--  private -- (can't say this with Abstract_State)
package SPI2.Device
with
  SPARK_Mode,
  Abstract_State => ((State with External),
                     Initialization),
  Initializes => Initialization,
  Elaborate_Body
is

   function Initialized return Boolean
   with
     Global => (Input => Initialization);

   procedure Initialize (Maximum_Frequency : Natural)
   with
     Pre => not Initialized,
     Post => Initialized,
     Global => (Output => (State, Initialization)),
     Depends => (State => (Maximum_Frequency),
                 Initialization => null);
   --  The maximum achievable frequency is the bus clock / 2, with
   --  values reducing by powers of 2 down to bus clock / 256.

   --  The operations below expect the target device to have been
   --  selected before the call, and to be deselected afterwards.
   --
   --  If more than one target device is using this SPI, the
   --  selection, the call, and the deselection must be called within
   --  the envelope of a protected operation.

   procedure Read_SPI (Bytes : out SPI.Byte_Array)
   with
     Pre => Initialized,
     Global => (In_Out => State),
     Depends => (State => State,
                 Bytes => State);

   procedure Write_SPI (Bytes : SPI.Byte_Array)
   with
     Pre => Initialized,
     Global => (In_Out => State),
     Depends => (State => (State, Bytes));

   procedure Command_SPI (Command    :     SPI.Byte_Array;
                          Result     : out SPI.Byte_Array)
   with
     Pre => Initialized,
     Global => (In_Out => State),
     Depends => (State => (State, Command),
                 Result => (State, Command));

end SPI2.Device;
