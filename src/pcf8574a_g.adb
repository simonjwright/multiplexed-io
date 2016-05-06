--  Demonstration code for the AdaPilot project
--  (http://adapilot.likeabird.eu).
--  Copyright (C) 2016 Simon Wright <simon@pushface.org>

with STM32F40x.GPIO; use STM32F40x.GPIO;
with STM32F40x.I2C;  use STM32F40x.I2C;
with STM32F40x.RCC;  use STM32F40x.RCC;
with STM32F40x.GPIO.Clock;

use STM32F40x;

package body PCF8574A_G with SPARK_Mode is

   --  Local subprogram specs  --

   function ADDR_Set return Boolean
   with Inline;

   procedure Generate_Start (For_Transmission : Boolean)
   with
     Inline,
     Pre => Enabled;

   procedure Clear_ADDR
   with Pre => ADDR_Set;
   --  This is to be called after reading SR1:
   --
   --  RM 27.6.7: Reading I2C_SR2 after reading I2C_SR1 clears the
   --  ADDR flag, even if the ADDR flag was set after reading
   --  I2C_SR1. Consequently, I2C_SR2 must be read only when ADDR is
   --  found set in I2C_SR1 or when the STOPF bit is cleared.
   --
   --  We know that ADDR is set (even if the precondition isn't
   --  called), because we have looped until it was: STOPF is a
   --  slave-mode indication: so just read SR2 ..

   --  Implementations  --

   function ADDR_Set return Boolean is
      pragma SPARK_Mode (Off);
      ADDR : constant SR1_ADDR_Field := I2C_Periph.SR1.ADDR;
   begin
      return ADDR = 1;
   end ADDR_Set;

   procedure Clear_ADDR is
      pragma SPARK_Mode (Off);
      SR2 : SR2_Register with Unreferenced;
   begin
      SR2 := I2C_Periph.SR2;
   end Clear_ADDR;

   function Enabled return Boolean is
      pragma SPARK_Mode (Off);
   begin
      return I2C_Periph.CR1.PE /= 0;
   end Enabled;

   procedure Generate_Start (For_Transmission : Boolean) is
      pragma SPARK_Mode (Off);
      --  Bit 0 is clear for transmission, set for reception.
      use type Byte;
      Address : constant Byte :=
        (Chip_Address and 16#fe#) or (if For_Transmission then 0 else 1);
   begin
      I2C_Periph.CR1.START := 1;
      loop
         exit when I2C_Periph.SR1.SB = 1; -- start condition generated
      end loop;

      I2C_Periph.CR1.ACK := 1;            -- enable

      I2C_Periph.DR := (DR => Address,    --  bit 0 clear => transmit
                        others => <>);
      loop
         exit when I2C_Periph.SR1.ADDR = 1;
         pragma Assert (I2C_Periph.SR1.AF = 0, "I2C Address Failure");
      end loop;
   end Generate_Start;

   procedure Initialize is
      pragma SPARK_Mode (Off);
   begin
      --  I've looked at https://github.com/MaJerle/stm32f429, and it
      --  seems we have to
      --
      --  enable the GPIO
      --  set the alternate function
      --  enable the pin as output open-drain, no pullup/down (I've put
      --    pullup resistors on the board), medium speed.

      --  SCL
      GPIO.Clock.Enable (SCL_GPIO);
      RCC_Periph.AHB1ENR.GPIOAEN       := 1;
      if SCL_Pin < 8 then
         SCL_GPIO.AFRL.Arr (SCL_Pin)   := 4; -- DocID022152 Rev 6 Table 9
      else
         SCL_GPIO.AFRH.Arr (SCL_Pin)   := 4; -- DocID022152 Rev 6 Table 9
      end if;
      SCL_GPIO.MODER.Arr (SCL_Pin)     := 2; -- alternate function
      SCL_GPIO.OTYPER.OT.Arr (SCL_Pin) := 1; -- open drain
      SCL_GPIO.OSPEEDR.Arr (SCL_Pin)   := 1; -- medium speed
      SCL_GPIO.PUPDR.Arr (SCL_Pin)     := 0; -- nopullup, no pulldown

      --  SDA
      GPIO.Clock.Enable (SDA_GPIO);
      if SDA_Pin < 8 then
         SDA_GPIO.AFRL.Arr (SDA_Pin)   := 4; -- DocID022152 Rev 6 Table 9
      else
         SDA_GPIO.AFRH.Arr (SDA_Pin)   := 4; -- DocID022152 Rev 6 Table 9
      end if;
      SDA_GPIO.AFRH.Arr (SDA_Pin)      := 4; -- DocID022152 Rev 6 Table 9
      SDA_GPIO.MODER.Arr (SDA_Pin)     := 2; -- alternate function
      SDA_GPIO.OTYPER.OT.Arr (SDA_Pin) := 1; -- open drain
      SDA_GPIO.OSPEEDR.Arr (SDA_Pin)   := 1; -- medium speed
      SDA_GPIO.PUPDR.Arr (SDA_Pin)     := 0; -- nopullup, no pulldown

      --  I2C
      RCC_Periph.APB1ENR.I2C3EN := 1;

      declare
         I2C_Clock_Speed : constant := 100_000;

         --  APB1 clock, for SYSCLK = 168_000_000;
         --  We can get this from RTS
         PCLK1 : constant := 42_000_000;

         FREQ : constant UInt6 :=  UInt6 (PCLK1 / 1_000_000);
         CCR : UInt12;
      begin
         I2C_Periph.CR2    := (FREQ           => FREQ,
                               others         => <>);
         I2C_Periph.CR1    := (others         => <>);      -- incl. clearing PE
         CCR               := UInt12 (PCLK1 / (I2C_Clock_Speed * 2));
         CCR               := UInt12'Max (CCR, 4);
         I2C_Periph.CCR    := (CCR            => CCR,
                               DUTY           => 0,        -- 50%
                               F_S            => 1,        -- standard mode
                               others         => <>);
         I2C_Periph.TRISE  := (TRISE          => FREQ,
                               others         => <>);
         I2C_Periph.CR1    := (PE             => 1,
                               SMBUS          => 0,
                               others         => <>);
         I2C_Periph.OAR1   := (ADDMODE        => 0,        -- 7-bit
                               Reserved_10_14 => 2#10000#, -- see RM
                               others         => <>);
         pragma Assert (I2C_Periph.CR1.PE = 1,
                          "I2C3 peripheral not enabled");
      end;
   end Initialize;

   function Read return STM32F40x.Byte is
      pragma SPARK_Mode (Off);
   begin
      Generate_Start (For_Transmission => False);

      --  See RM 27.3.3: for single-byte master receiver transfers,
      --
      --  1. To generate the nonacknowledge pulse after the last
      --  received data byte, the ACK bit must be cleared just after
      --  reading the second last data byte (after second last RxNE
      --  event).

      --  2. In order to generate the Stop/Restart condition, software
      --  must set the STOP/START bit after reading the second last
      --  data byte (after the second last RxNE event).

      --  3. In case a single byte has to be received, the Acknowledge
      --  disable is made during EV6 (before ADDR flag is cleared) and
      --  the STOP condition generation is made after EV6.

      I2C_Periph.CR1.ACK := 0;
      Clear_ADDR;
      I2C_Periph.CR1.STOP := 1;

      loop
         exit when I2C_Periph.SR1.RxNE = 1;  -- data reg not empty (rx)
      end loop;
      return I2C_Periph.DR.DR;
   end Read;

   procedure Write (B : STM32F40x.Byte) is
      pragma SPARK_Mode (Off);
   begin
      Generate_Start (For_Transmission => True);
      Clear_ADDR;

      loop
         exit when I2C_Periph.SR1.TxE = 1;  -- data reg empty (tx)
      end loop;
      I2C_Periph.DR := (DR => B,
                         others => <>);
      loop
         declare
            SR1 : constant SR1_Register := I2C_Periph.SR1;
         begin
            exit when SR1.TxE = 1 and SR1.BTF = 1;
         end;
      end loop;

      I2C_Periph.CR1.STOP := 1;
   end Write;

end PCF8574A_G;
