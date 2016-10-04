--  Demonstration code for the AdaPilot project
--  (http://adapilot.likeabird.eu).
--  Copyright (C) 2016 Simon Wright <simon@pushface.org>

--  THIS FILE, i2c?-device.adb, IS GENERATED USING GNATPREP FROM
--  ../../i2c/src/i2c-device.adb.pp.  TO MAKE A PERMANENT CHANGE, EDIT
--  THAT FILE AND REGENERATE, THEN COMMIT THE REGENERATED FILE.

with Interfaces;
with System_Clocks;

with STM32_SVD.GPIO;
with STM32_SVD.I2C;
with STM32_SVD.RCC;

package body $I2C.Device
with
  SPARK_Mode    => Off  -- or generation of Global contracts takes forever
is

   Initialize_Done : Boolean := False;

   use STM32_SVD;

   --  Local subprogram specs  --

   function ADDR_Set return Boolean
     with Inline;

   procedure Generate_Start (To               : Chip_Address;
                             For_Transmission : Boolean)
   with
     Inline,
     Pre => Initialized;

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
   begin
      return $I2C_Periph.SR1.ADDR = 1;
   end ADDR_Set;

   procedure Clear_ADDR is
      pragma SPARK_Mode (Off);
      --  Read SR2 to clear ADDR.
      Dummy : I2C.SR2_Register;
   begin
      Dummy := $I2C_Periph.SR2;
   end Clear_ADDR;

   function Initialized return Boolean is
      pragma SPARK_Mode (Off);
   begin
      return Initialize_Done;
   end Initialized;

   procedure Generate_Start (To               : Chip_Address;
                             For_Transmission : Boolean) is
      pragma SPARK_Mode (Off);
      --  Bit 0 is clear for transmission, set for reception.
      use type Byte;
      Address : constant Byte :=
        Interfaces.Shift_Left (To, 1) or (if For_Transmission then 0 else 1);
   begin
      $I2C_Periph.CR1.START := 1;
      loop
         exit when $I2C_Periph.SR1.SB = 1; -- start condition generated
      end loop;

      $I2C_Periph.CR1.ACK := 1;            -- enable

      $I2C_Periph.DR := (DR => Address,    --  bit 0 clear => transmit
                        others => <>);
      loop
         exit when $I2C_Periph.SR1.ADDR = 1;
         pragma Assert ($I2C_Periph.SR1.AF = 0, "I2C Address Failure");
      end loop;
   end Generate_Start;

   procedure Initialize (Frequency : Maximum_Frequency) is
      pragma SPARK_Mode (Off);
   begin
      --  First, enable 3.3V Power Sensors (VDD_SENS_EN on PE3) for
      --  AdaRacer

      --  Enable PE3, VDD_SENS_EN
      RCC.RCC_Periph.AHB1ENR.GPIOEEN      := 1;
      GPIO.GPIOE_Periph.MODER.Arr (3)     := 2#01#; -- general-purpose output
      GPIO.GPIOE_Periph.OTYPER.OT.Arr (3) := 0;     -- push-pull
      GPIO.GPIOE_Periph.OSPEEDR.Arr (3)   := 2#10#; -- high speed
      GPIO.GPIOE_Periph.PUPDR.Arr (3)     := 2#00#; -- no pullup/down
      GPIO.GPIOE_Periph.BSRR.BS.Arr (3)   := 1;     -- set bit

      --  We have to
      --  - enable the GPIO
      --  - set the alternate function
      --  - enable the pin as output open-drain, no pullup/down,
      --    medium speed.

      --  SCL
      RCC.RCC_Periph.AHB1ENR.$SCL_Enable := 1;
      $SCL_GPIO.MODER.Arr ($SCL_Pin)     := 2#10#; -- alternate function
      $SCL_GPIO.OTYPER.OT.Arr ($SCL_Pin) := 1;     -- open drain
      $SCL_GPIO.OSPEEDR.Arr ($SCL_Pin)   := 2#10#; -- high speed
      $SCL_GPIO.PUPDR.Arr ($SCL_Pin)     := 2#00#; -- nopullup, no pulldown
      #if SCL_Pin < 8 then
      $SCL_GPIO.AFRL.Arr ($SCL_Pin)      := 4;     -- AF4
      #else
      $SCL_GPIO.AFRH.Arr ($SCL_Pin)      := 4;     -- AF4
      #end if;

      --  SDA
      RCC.RCC_Periph.AHB1ENR.$SDA_Enable := 1;
      $SDA_GPIO.MODER.Arr ($SDA_Pin)     := 2#10#; -- alternate function
      $SDA_GPIO.OTYPER.OT.Arr ($SDA_Pin) := 1;     -- open drain
      $SDA_GPIO.OSPEEDR.Arr ($SDA_Pin)   := 2#10#; -- high speed
      $SDA_GPIO.PUPDR.Arr ($SDA_Pin)     := 2#00#; -- nopullup, no pulldown
      #if SDA_Pin < 8 then
      $SDA_GPIO.AFRL.Arr ($SDA_Pin)      := 4;     -- AF4
      #else
      $SDA_GPIO.AFRH.Arr ($SDA_Pin)      := 4;     -- AF4
      #end if;

      --  I2C
      RCC.RCC_Periph.APB1ENR := ($I2C_Enable => 1, others => <>);

      declare
         Fast_Mode : constant Boolean := Frequency > 100_000;
         I2C_Clock_Speed : constant System_Clocks.Frequency :=
           System_Clocks.Frequency (Frequency);

         --  APB1 clock
         PCLK1 : constant System_Clocks.Frequency
           := System_Clocks.PCLK1;
         use type System_Clocks.Frequency;

         FREQ : constant UInt6 :=  UInt6 (PCLK1 / 1_000_000);
         CCR : UInt12;
      begin
         $I2C_Periph.CR2 := (FREQ   => FREQ,
                             others => <>);
         $I2C_Periph.CR1 := (others => <>);
         --  incl. clearing PE

         CCR := UInt12 (PCLK1 /
                          (I2C_Clock_Speed *
                             (if Fast_Mode then 25 else 3)));
         CCR := UInt12'Max (CCR, 4);
         $I2C_Periph.CCR := (CCR    => CCR,
                             DUTY   => (if Fast_Mode then 1 else 0),
                             F_S    => (if Fast_Mode then 1 else 0),
                             others => <>);

         $I2C_Periph.TRISE :=
           (TRISE  => (if Fast_Mode
                       then UInt6 ((Integer (FREQ) * 3) / 10)
                       else FREQ) + 1,
            others => <>);

         $I2C_Periph.CR1 := (PE     => 1,
                             SMBUS  => 0,
                             others => <>);

         $I2C_Periph.OAR1 := (ADDMODE        => 0,        -- 7-bit
                              Reserved_10_14 => 2#10000#, -- see RM
                              others         => <>);

         pragma Assert ($I2C_Periph.CR1.PE = 1,
                          $NAME & " peripheral not enabled");
      end;

      Initialize_Done := True;
   end Initialize;

   procedure Read (From : Chip_Address; To : out Byte)
   is
      pragma SPARK_Mode (Off);
   begin
      Generate_Start (To => From, For_Transmission => False);

      --  See RM 27.3.3: for single-byte master receiver transfers,
      --
      --  3. In case a single byte has to be received, the Acknowledge
      --  disable is made during EV6 (before ADDR flag is cleared) and
      --  the STOP condition generation is made after EV6.

      $I2C_Periph.CR1.ACK := 0;
      Clear_ADDR;
      $I2C_Periph.CR1.STOP := 1;

      loop
         exit when $I2C_Periph.SR1.RxNE = 1;  -- data reg not empty (rx)
      end loop;

      To := $I2C_Periph.DR.DR;
   end Read;

   procedure Read (From : Chip_Address; To : out Byte_Array)
   is
      pragma SPARK_Mode (Off);
   begin
      if To'Length = 1 then
         --  STOP condition handled specially
         Read (From, To (To'First));
      else
         Generate_Start (To => From, For_Transmission => False);

         --  See RM 27.3.3: for multi-byte master receiver transfers,
         --
         --  1. To generate the nonacknowledge pulse after the last
         --  received data byte, the ACK bit must be cleared just
         --  after reading the second last data byte (after second
         --  last RxNE event).
         --
         --  2. In order to generate the Stop/Restart condition,
         --  software must set the STOP/START bit after reading the
         --  second last data byte (after the second last RxNE event).

         Clear_ADDR;

         for J in To'First .. To'Last - 2 loop
            --  may be null range
            loop
               exit when $I2C_Periph.SR1.RxNE = 1;
               --  data reg not empty (rx)
            end loop;
            To (J) := $I2C_Periph.DR.DR;
         end loop;

         --  Second last transfer
         loop
            exit when $I2C_Periph.SR1.RxNE = 1;
         end loop;
         To (To'Last - 1) := $I2C_Periph.DR.DR;
         $I2C_Periph.CR1.ACK := 0;
         $I2C_Periph.CR1.STOP := 1;

         --  Last transfer
         loop
            exit when $I2C_Periph.SR1.RxNE = 1;
         end loop;
         To (To'Last) := $I2C_Periph.DR.DR;
      end if;
   end Read;

   procedure Write (To : Chip_Address; Data : Byte) is
      pragma SPARK_Mode (Off);
   begin
      Generate_Start (To => To, For_Transmission => True);
      Clear_ADDR;

      loop
         exit when $I2C_Periph.SR1.TxE = 1;  -- data reg empty (tx)
      end loop;
      $I2C_Periph.DR := (DR => Data, others => <>);
      loop
         declare
            SR1 : constant I2C.SR1_Register
              := $I2C_Periph.SR1;
         begin
            exit when SR1.TxE = 1 and SR1.BTF = 1;
         end;
      end loop;

      $I2C_Periph.CR1.STOP := 1;
   end Write;

   procedure Write (To : Chip_Address; Data : Byte_Array)
   is
      pragma SPARK_Mode (Off);
   begin
      Generate_Start (To => To, For_Transmission => True);
      Clear_ADDR;

      for J in Data'Range loop
         loop
            exit when $I2C_Periph.SR1.TxE = 1;
         end loop;
         $I2C_Periph.DR := (DR => Data (J), others => <>);
      end loop;

      loop
         exit when $I2C_Periph.SR1.TxE = 1
           and then $I2C_Periph.SR1.BTF = 1;
      end loop;

      $I2C_Periph.CR1.STOP := 1;
   end Write;

end $I2C.Device;
