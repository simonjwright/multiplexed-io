--  Demonstration code for the AdaPilot project
--  (http://adapilot.likeabird.eu).
--  Copyright (C) 2016 Simon Wright <simon@pushface.org>

with PCF8574A_G;
with STM32F40x.GPIO;
with STM32F40x.I2C;

package PCF8574A_Demo is new PCF8574A_G
  (Chip_Address => 16#70#,
   SCL_GPIO     => STM32F40x.GPIO.GPIOA_Periph,
   SCL_Pin      => 8,
   SDA_GPIO     => STM32F40x.GPIO.GPIOC_Periph,
   SDA_Pin      => 9,
   I2C_Periph   => STM32F40x.I2C.I2C3_Periph);
