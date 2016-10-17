--  Demonstration code for the AdaPilot project
--  (http://adapilot.likeabird.eu).
--  Copyright (C) 2016 Simon Wright <simon@pushface.org>

with Ada.Real_Time;
with Monitor;
with STM32_SVD.RCC;
with STM32_SVD.GPIO;
with System;

package body LEDs is

   --  The LEDs are as below (1 => off)
   --
   --  FMU_LED_RED   PB11
   --  FMU_LED_GREEN PB1
   --  FMU_LED_BLUE  PB3

   type LED is (Red, Green, Blue);

   use STM32_SVD;

   procedure On (L : LED);
   procedure Off (L : LED);

   type Morse_Symbol is (Dot, Dash);
   type Morse_Letter is array (Natural range <>) of Morse_Symbol;

   function Letter_For_Device (D : Monitor.Device) return Morse_Letter;
   procedure Output_Letter (Using : LED; Letter : Morse_Letter);

   Dot_Period : Ada.Real_Time.Time_Span :=
     Ada.Real_Time.Milliseconds (100);

   task Show with Priority => System.Priority'First + 1;
   task body Show is
      type Monitored_Devices is array (Natural range <>) of Monitor.Device;
      Monitored : constant Monitored_Devices :=
        (Monitor.Accelerometer,
         Monitor.Barometer,
         Monitor.Gyro,
         Monitor.Magnetometer);
      use Monitor;
      use Ada.Real_Time;
   begin
      loop
         if (for all D of Monitored => Get_Status (D) = Unknown) then
            for L in LED'Range loop
               Off (L);
            end loop;
         elsif (for all D of Monitored => Get_Status (D) = Ok) then
            Off (Red);
            Off (Blue);
            On (Green);
         elsif (for some D of Monitored => Get_Status (D) = Failed) then
            for D of Monitored loop
               if Get_Status (D) = Failed then
                  Output_Letter (Red, Letter_For_Device (D));
               end if;
               --  Add the word separator (3 dots already output)
               delay until Ada.Real_Time.Clock + Dot_Period * 4;
            end loop;
         end if;
         delay until Ada.Real_Time.Clock + Ada.Real_Time.Seconds (1);
      end loop;
   end Show;

   Pin_Number : constant array (LED) of Natural :=
     (Red => 11, Green => 1, Blue => 3);

   procedure On (L : LED)
   is
   begin
      GPIO.GPIOB_Periph.BSRR.BR.Arr (Pin_Number (L)) := 1;
   end On;

   procedure Off (L : LED)
   is
   begin
      GPIO.GPIOB_Periph.BSRR.BS.Arr (Pin_Number (L)) := 1;
   end Off;

   function Letter_For_Device (D : Monitor.Device) return Morse_Letter
   is
   begin
      return (case D is
                 when Monitor.Accelerometer => (Dot, Dash),
                 when Monitor.Barometer     => (Dash, Dot, Dot, Dot),
                 when Monitor.Gyro          => (Dash, Dash, Dot),
                 when Monitor.Magnetometer  => (Dash, Dash));
   end Letter_For_Device;

   procedure Output_Letter (Using : LED; Letter : Morse_Letter)
   is
      Next : Ada.Real_Time.Time := Ada.Real_Time.Clock;
      use Ada.Real_Time;
   begin
      for Code of Letter loop
         On (Using);
         Next := Next + (case Code is
                            when Dot  => Dot_Period,
                            when Dash => Dot_Period * 3);
         delay until Next;
         Off (Using);
         Next := Next + Dot_Period;
         delay until Next;
      end loop;
      --  The inter-letter separation is 3 dots, and we've already
      --  output one.
      Next := Next + Dot_Period * 2;
      delay until Next;
   end Output_Letter;

begin
   RCC.RCC_Periph.AHB1ENR.GPIOBEN := 1;

   --  PB11, red
   GPIO.GPIOB_Periph.MODER.Arr (11)     := 2#01#; -- general-purpose output
   GPIO.GPIOB_Periph.OTYPER.OT.Arr (11) := 0;     -- push-pull
   GPIO.GPIOB_Periph.OSPEEDR.Arr (11)   := 2#10#; -- high speed
   GPIO.GPIOB_Periph.PUPDR.Arr (11)     := 2#00#; -- no pullup/down
   GPIO.GPIOB_Periph.BSRR.BS.Arr (11)   := 1;     -- set bit

   --  PB1, green
   GPIO.GPIOB_Periph.MODER.Arr (1)     := 2#01#; -- general-purpose output
   GPIO.GPIOB_Periph.OTYPER.OT.Arr (1) := 0;     -- push-pull
   GPIO.GPIOB_Periph.OSPEEDR.Arr (1)   := 2#10#; -- high speed
   GPIO.GPIOB_Periph.PUPDR.Arr (1)     := 2#00#; -- no pullup/down
   GPIO.GPIOB_Periph.BSRR.BS.Arr (1)   := 1;     -- set bit

   --  PB3, blue
   GPIO.GPIOB_Periph.MODER.Arr (3)     := 2#01#; -- general-purpose output
   GPIO.GPIOB_Periph.OTYPER.OT.Arr (3) := 0;     -- push-pull
   GPIO.GPIOB_Periph.OSPEEDR.Arr (3)   := 2#10#; -- high speed
   GPIO.GPIOB_Periph.PUPDR.Arr (3)     := 2#00#; -- no pullup/down
   GPIO.GPIOB_Periph.BSRR.BS.Arr (3)   := 1;     -- set bit

end LEDs;
