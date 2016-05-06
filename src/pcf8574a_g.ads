--  Demonstration code for the AdaPilot project
--  (http://adapilot.likeabird.eu).
--  Copyright (C) 2016 Simon Wright <simon@pushface.org>

with STM32F40x.GPIO;
with STM32F40x.I2C;

generic
   Chip_Address : STM32F40x.Byte;
   SCL_GPIO     : in out STM32F40x.GPIO.GPIO_Peripheral;
   SCL_Pin      : Natural; -- actually need subtype 0 .. 15
   SDA_GPIO     : in out STM32F40x.GPIO.GPIO_Peripheral;
   SDA_Pin      : Natural; -- actually need subtype 0 .. 16
   I2C_Periph   : in out STM32F40x.I2C.I2C_Peripheral;
package PCF8574A_G with SPARK_Mode is

   pragma Assert (SCL_Pin < 16);
   pragma Assert (SDA_Pin < 16);

   function Enabled return Boolean;
   --  Hmm, this is a check on the hardware's state!

   procedure Initialize
   with Post => Enabled;

   function Read return STM32F40x.Byte
   with
     Pre => Enabled;

   procedure Write (B : STM32F40x.Byte)
   with Pre => Enabled;

end PCF8574A_G;
