--  Demonstration code for the AdaPilot project
--  (http://adapilot.likeabird.eu).
--  Copyright (C) 2016 Simon Wright <simon@pushface.org>

with Ada.Interrupts.Names;
with System;

with STM32_SVD.RCC;
with STM32_SVD.TIM;

package body SPI1.Timer_Sleep
is

   protected Timer_Handler
   with Interrupt_Priority => System.Interrupt_Priority'Last - 1
   is
      entry Wait;
      procedure Start_Waiting (For_Interval : Duration)
      with Pre => For_Interval in 0.0 .. 0.010_000;
   private
      procedure Handler
      with
        Attach_Handler => Ada.Interrupts.Names.TIM8_TRG_COM_TIM14_Interrupt,
        Unreferenced;  -- not really!
      Triggered : Boolean := False;
   end Timer_Handler;

   procedure Sleep (For_Interval : Duration)
   is
   begin
      Timer_Handler.Start_Waiting (For_Interval);
      Timer_Handler.Wait;
   end Sleep;

   use STM32_SVD;

   protected body Timer_Handler is
      entry Wait when Triggered is
      begin
         Triggered := False;
      end Wait;

      procedure Start_Waiting (For_Interval : Duration)
      is
      begin
         TIM.TIM14_Periph.ARR := (ARR => Short (For_Interval * 1_000_000),
                                  others => 0);
         TIM.TIM14_Periph.EGR.UG := 1;  -- update registers, reset CNT
         TIM.TIM14_Periph.CR1.CEN := 1; -- enable the counter
      end Start_Waiting;

      procedure Handler is
      begin
         pragma Assert (TIM.TIM14_Periph.SR.UIF /= 0, "interrupt but no UIF");
         TIM.TIM14_Periph.CR1.CEN := 0; -- disable the counter
         TIM.TIM14_Periph.SR.UIF := 0;  -- clear the interrupt
         Triggered := True;
      end Handler;
   end Timer_Handler;

begin

   --  TIM14 is on APB1, frequency 42 MHz (peripherals), 84 MHz (timers).

   RCC.RCC_Periph.APB1ENR.TIM14EN := 1;

   --  Update interrupt on counter overflow only
   TIM.TIM14_Periph.CR1 := (URS => 1, others => <>);
   --  Enable Update interrupt
   TIM.TIM14_Periph.DIER := (UIE => 1, others => <>);
   --  The divisor is 84 for 1 us/count, so PSC is 1 less
   TIM.TIM14_Periph.PSC := (PSC => 83, others => <>);

end SPI1.Timer_Sleep;
