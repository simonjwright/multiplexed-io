--  Demonstration code for the AdaPilot project
--  (http://adapilot.likeabird.eu).
--  Copyright (C) 2016 Simon Wright <simon@pushface.org>

--  THIS FILE, i2c?.ads, IS GENERATED USING GNATPREP FROM
--  ../../i2c/src/i2c.ads.pp.  TO MAKE A PERMANENT CHANGE, EDIT THAT
--  FILE AND REGENERATE, THEN COMMIT THE REGENERATED FILE.

with STM32_SVD;

package $I2C
with
  SPARK_Mode => On,
  Abstract_State => (State with External),
  Elaborate_Body
is

   --  The I2C address of the peripheral being addressed
   subtype Chip_Address is STM32_SVD.Byte;

   function Initialized return Boolean;

   procedure Initialize
   with
     Pre => not Initialized,
     Post => Initialized;

   procedure Read (From : Chip_Address; To : out STM32_SVD.Byte)
   with
     Pre => Initialized,
     Depends => (State => State,
                 To => (State, From));

   procedure Write (To : Chip_Address; Data : STM32_SVD.Byte)
   with
     Pre => Initialized,
     Depends => (State => (State, To, Data));

private

   --  We use a protected type here because we have to protect the bus
   --  from concurrent access.

   protected Implementation
   with Part_Of => State
   is

      procedure Read (From : Chip_Address; To : out STM32_SVD.Byte)
      with
        Pre => Initialized,
        Depends => (Implementation => Implementation,
                    State => State,
                    To => (State, From));

      procedure Write (To : Chip_Address; Data : STM32_SVD.Byte)
      with
        Pre => Initialized,
        Depends => (Implementation => Implementation,
                    State => (State, To, Data));

   end Implementation;

end $I2C;
