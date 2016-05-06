--  Demonstration code for the AdaPilot project
--  (http://adapilot.likeabird.eu).
--  Copyright (C) 2016 Simon Wright <simon@pushface.org>

with STM32F40x.RCC;

with System;

package body STM32F40x.GPIO.Clock with SPARK_Mode => Off is

   --  function Enabled (Periph : GPIO_Peripheral) return Boolean is
   --     Periph_Address : constant System.Address := Periph'Address;
   --     use type System.Address;
   --  begin
   --     if Periph_Address = GPIOA_Periph'Address then
   --        return STM32F40x.RCC.RCC_Periph.AHB1ENR.GPIOAEN = 1;
   --     elsif Periph_Address = GPIOB_Periph'Address then
   --        return STM32F40x.RCC.RCC_Periph.AHB1ENR.GPIOBEN = 1;
   --     elsif Periph_Address = GPIOC_Periph'Address then
   --        return STM32F40x.RCC.RCC_Periph.AHB1ENR.GPIOCEN = 1;
   --     elsif Periph_Address = GPIOD_Periph'Address then
   --        return STM32F40x.RCC.RCC_Periph.AHB1ENR.GPIODEN = 1;
   --     elsif Periph_Address = GPIOE_Periph'Address then
   --        return STM32F40x.RCC.RCC_Periph.AHB1ENR.GPIOEEN = 1;
   --     elsif Periph_Address = GPIOF_Periph'Address then
   --        return STM32F40x.RCC.RCC_Periph.AHB1ENR.GPIOFEN = 1;
   --     elsif Periph_Address = GPIOG_Periph'Address then
   --        return STM32F40x.RCC.RCC_Periph.AHB1ENR.GPIOGEN = 1;
   --     elsif Periph_Address = GPIOH_Periph'Address then
   --        return STM32F40x.RCC.RCC_Periph.AHB1ENR.GPIOHEN = 1;
   --     elsif Periph_Address = GPIOI_Periph'Address then
   --        return STM32F40x.RCC.RCC_Periph.AHB1ENR.GPIOIEN = 1;
   --     else
   --        raise Constraint_Error with "invalid GPIO_Peripheral";
   --     end if;
   --  end Enabled;

   procedure Enable (Periph : GPIO_Peripheral) is
      Periph_Address : constant System.Address := Periph'Address;
      use type System.Address;
   begin
      if Periph_Address = GPIOA_Periph'Address then
         STM32F40x.RCC.RCC_Periph.AHB1ENR.GPIOAEN := 1;
      elsif Periph_Address = GPIOB_Periph'Address then
         STM32F40x.RCC.RCC_Periph.AHB1ENR.GPIOBEN := 1;
      elsif Periph_Address = GPIOC_Periph'Address then
         STM32F40x.RCC.RCC_Periph.AHB1ENR.GPIOCEN := 1;
      elsif Periph_Address = GPIOD_Periph'Address then
         STM32F40x.RCC.RCC_Periph.AHB1ENR.GPIODEN := 1;
      elsif Periph_Address = GPIOE_Periph'Address then
         STM32F40x.RCC.RCC_Periph.AHB1ENR.GPIOEEN := 1;
      elsif Periph_Address = GPIOF_Periph'Address then
         STM32F40x.RCC.RCC_Periph.AHB1ENR.GPIOFEN := 1;
      elsif Periph_Address = GPIOG_Periph'Address then
         STM32F40x.RCC.RCC_Periph.AHB1ENR.GPIOGEN := 1;
      elsif Periph_Address = GPIOH_Periph'Address then
         STM32F40x.RCC.RCC_Periph.AHB1ENR.GPIOHEN := 1;
      elsif Periph_Address = GPIOI_Periph'Address then
         STM32F40x.RCC.RCC_Periph.AHB1ENR.GPIOIEN := 1;
      else
         raise Constraint_Error with "invalid GPIO_Peripheral";
      end if;
   end Enable;

   --  Disable needed?

end STM32F40x.GPIO.Clock;
