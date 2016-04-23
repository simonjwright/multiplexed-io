--  Demonstration code for the AdaPilot project
--  (http://adapilot.likeabird.eu).
--  Copyright (C) 2016 Simon Wright <simon@pushface.org>

with STM32F40x.GPIO; use STM32F40x.GPIO;
with STM32F40x.I2C; use STM32F40x.I2C;
with STM32F40x.RCC; use STM32F40x.RCC;

use STM32F40x;

package body PCF8574A with SPARK_Mode is

   --  bits 0 .. 3 are LEDs, 4 .. 7 are pushbuttons.

   Chip_Address : constant := 16#70#;
   --  This is the write address (bit 0 clear) for A2.. A0 set to LLL,
   --  see datasheet section 8.3.3.

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
   --  called), because we loop until it is: STOPF is a slave-mode
   --  indication: so just read SR2 ..

   --  Implementations  --

   function ADDR_Set return Boolean is
      pragma SPARK_Mode (Off);
      ADDR : constant SR1_ADDR_Field := I2C3_Periph.SR1.ADDR;
   begin
      return ADDR = 1;
   end ADDR_Set;

   procedure Clear_ADDR is
      pragma SPARK_Mode (Off);
      SR2 : SR2_Register with Unreferenced;
   begin
      SR2 := I2C3_Periph.SR2;
   end Clear_ADDR;

   function Enabled return Boolean is
      pragma SPARK_Mode (Off);
   begin
      return I2C3_Periph.CR1.PE /= 0;
   end Enabled;

   procedure Generate_Start (For_Transmission : Boolean) is
      pragma SPARK_Mode (Off);
      --  Bit 0 is clear for transmission, set for reception.
      use type Byte;
      Address : constant Byte :=
        (Chip_Address and 16#fe#) or (if For_Transmission then 0 else 1);
   begin
      I2C3_Periph.CR1.START := 1;
      loop
         exit when I2C3_Periph.SR1.SB = 1; -- start condition generated
      end loop;

      I2C3_Periph.CR1.ACK := 1;            -- enable

      I2C3_Periph.DR := (DR => Address,    --  bit 0 clear => transmit
                         others => <>);
      loop
         exit when I2C3_Periph.SR1.ADDR = 1;
         pragma Assert (I2C3_Periph.SR1.AF = 0, "I2C Address Failure");
      end loop;
   end Generate_Start;

   procedure Initialize is
      pragma SPARK_Mode (Off);
   begin
      --  The nominated alternate function pins for ACP/RF, which I
      --  _think_ is I2C, are (on STM32F429 Discovery)
      --
      --  SCL => PA8
      --  SDA => PC9
      --
      --  I've looked at https://github.com/MaJerle/stm32f429, and it
      --  seems we have to
      --
      --  enable the GPIO
      --  set the alternate function
      --  enable the pin as output open-drain, no pullup/down (I've put
      --    pullup resistors on the board), medium speed.
      --
      --  MaJerle seems to indicate that the pins chosen are default
      --  for the I2C3 device? (actually, they are the only available
      --  pins on the STM32F429 Discovery board). However, on the
      --  STM32F407VG DISC1 board, PA8 & PA9 are available and right
      --  next to each other!

      --  PA8
      RCC_Periph.AHB1ENR.GPIOAEN     := 1;
      GPIOA_Periph.AFRH.Arr (8)      := 4; -- DocID022152 Rev 6 Table 9
      GPIOA_Periph.MODER.Arr (8)     := 2; -- alternate function
      GPIOA_Periph.OTYPER.OT.Arr (8) := 1; -- open drain
      GPIOA_Periph.OSPEEDR.Arr (8)   := 1; -- medium speed
      GPIOA_Periph.PUPDR.Arr (8)     := 0; -- nopullup, no pulldown

      --  PC9
      RCC_Periph.AHB1ENR.GPIOCEN     := 1;
      GPIOC_Periph.AFRH.Arr (9)      := 4; -- DocID022152 Rev 6 Table 9
      GPIOC_Periph.MODER.Arr (9)     := 2; -- alternate function
      GPIOC_Periph.OTYPER.OT.Arr (9) := 1; -- open drain
      GPIOC_Periph.OSPEEDR.Arr (9)   := 1; -- medium speed
      GPIOC_Periph.PUPDR.Arr (9)     := 0; -- nopullup, no pulldown

      --  I2C3
      RCC_Periph.APB1ENR.I2C3EN := 1;

      declare
         I2C_Clock_Speed : constant := 100_000;

         --  APB1 clock, for SYSCLK = 168_000_000;
         PCLK1 : constant := 42_000_000;

         FREQ : constant UInt6 :=  UInt6 (PCLK1 / 1_000_000);
         CCR : UInt12;
      begin
         I2C3_Periph.CR2   := (FREQ           => FREQ,
                               others         => <>);
         I2C3_Periph.CR1   := (others         => <>);      -- incl. clearing PE
         CCR               := UInt12 (PCLK1 / (I2C_Clock_Speed * 2));
         CCR               := UInt12'Max (CCR, 4);
         I2C3_Periph.CCR   := (CCR            => CCR,
                               DUTY           => 0,        -- 50%
                               F_S            => 1,        -- standard mode
                               others         => <>);
         I2C3_Periph.TRISE := (TRISE          => FREQ,
                               others         => <>);
         I2C3_Periph.CR1   := (PE             => 1,
                               SMBUS          => 0,
                               others         => <>);
         I2C3_Periph.OAR1  := (ADDMODE        => 0,        -- 7-bit
                               Reserved_10_14 => 2#10000#, -- see RM
                               others         => <>);
         pragma Assert (I2C3_Periph.CR1.PE = 1,
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

      I2C3_Periph.CR1.ACK := 0;
      Clear_ADDR;
      I2C3_Periph.CR1.STOP := 1;

      loop
         exit when I2C3_Periph.SR1.RxNE = 1;  -- data reg not empty (rx)
      end loop;
      return I2C3_Periph.DR.DR;
   end Read;

   procedure Write (B : STM32F40x.Byte) is
      pragma SPARK_Mode (Off);
   begin
      Generate_Start (For_Transmission => True);
      Clear_ADDR;

      loop
         exit when I2C3_Periph.SR1.TxE = 1;  -- data reg empty (tx)
      end loop;
      I2C3_Periph.DR := (DR => B,
                         others => <>);
      loop
         declare
            SR1 : constant SR1_Register := I2C3_Periph.SR1;
         begin
            exit when SR1.TxE = 1 and SR1.BTF = 1;
         end;
      end loop;

      I2C3_Periph.CR1.STOP := 1;
   end Write;

end PCF8574A;
