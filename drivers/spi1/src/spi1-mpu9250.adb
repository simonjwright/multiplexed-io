--  Demonstration code for the AdaPilot project
--  (http://adapilot.likeabird.eu).
--  Copyright (C) 2016 Simon Wright <simon@pushface.org>

with Ada.Real_Time;
with Ada.Unchecked_Conversion;
with Interfaces;

with SPI;
with SPI1.Internal;
pragma Elaborate_All (SPI1.Internal);
with SPI1.MPU9250_Registers;

with Cycle_Timer;
with Nanosleep;
with Ada.Text_IO; use Ada.Text_IO;

package body SPI1.MPU9250
with
  SPARK_Mode => On
is

   task MPU9250_Reader;

   type Coordinate is (X, Y, Z);

   type AK8963_Calibrations is array (Coordinate) of Float;
   type AK8963_Components is array (Coordinate) of Float;

   procedure Calibrate_AK8963 (Calibrations : out AK8963_Calibrations);
   --  Includes magnetometer scaling. Leaves device powered down.

   procedure Self_Test_AK8963 (Calibrations : AK8963_Calibrations;
                               OK : out Boolean);
   --  Leaves device powered down.

   procedure Read_AK8963_Components (Calibrations : AK8963_Calibrations;
                                     Components : out AK8963_Components);

   function Read_9250 (From_Register : MPU9250_Registers.MPU9250_Register)
                      return Interfaces.Unsigned_8;

   procedure Read_9250 (From_Register : MPU9250_Registers.MPU9250_Register;
                        Bytes : out SPI.Byte_Array);

   procedure Write_9250 (To_Register : MPU9250_Registers.MPU9250_Register;
                         Byte        : Interfaces.Unsigned_8);

   function Read_AK8963 (From_Register : MPU9250_Registers.AK8963_Register)
                        return Interfaces.Unsigned_8;

   procedure Read_AK8963 (From_Register : MPU9250_Registers.AK8963_Register;
                          Bytes : out SPI.Byte_Array);

   procedure Write_AK8963 (To_Register : MPU9250_Registers.AK8963_Register;
                           Byte :  Interfaces.Unsigned_8);

   procedure Delay_For (Milliseconds : Integer);

   function To_Integer
     (Hi, Lo : Interfaces.Unsigned_8) return Integer;

   task body MPU9250_Reader is
      Magnetometer_Calibrations : AK8963_Calibrations;
      AK8963_OK : Boolean := False;
      use type Interfaces.Unsigned_8;
      use MPU9250_Registers;
   begin
      --  Some time needed for MPU9250 to warm up
      Delay_For (100);

      pragma Assert (Read_9250 (WHOAMI) = 16#71#, "huh?");

      --  Reset the device
      Write_9250 (PWR_MGMT_1,
                  Convert (Power_Management_1'(H_RESET => 1, others => <>)));

      Delay_For (100);

      --  Select best available clock source
      Write_9250 (PWR_MGMT_1,
                  Convert (Power_Management_1'(CLKSEL => 1, others => <>)));

      --  Enable accelerator and gyro (i.e. don't disable them)
      Write_9250 (PWR_MGMT_2,
                  Convert (Power_Management_2'(others => <>)));

      --  Sample rate divider 0 means that the data rates selected
      --  below are unchanged.
      Write_9250 (SMPLRT_DIV, 0);

      --  Set DLPF for gyro/temp bandwidth 184 Hz (temp bandwidth 188
      --  Hz), data rate 1 kHz
      Write_9250 (CONFIG,
                  Convert (Configuration'(DLPF_CFG => 1, others => <>)));

      --  DLPF as above, 2000 dpi
      Write_9250 (GYRO_CONFIG,
                  Convert (Gyro_Configuration'(F_CHOICE_B => 0,
                                               GYRO_FS_SEL => 3,
                                               others => <>)));

      --  +/- 8g
      Write_9250 (ACCEL_CONFIG,
                  Convert (Accel_Configuration'(ACCEL_FS_SEL => 2,
                                                others => <>)));

      --  Using DLPF, bandwidth 218.1, data rate 1 kHz
      Write_9250 (ACCEL_CONFIG_2,
                  Convert (Accel_Configuration_2'(ACCEL_FCHOICE_B => 0,
                                                  A_DLPFCFG => 0,
                                                  others => <>)));

      --  I2C (AK8963) setup

      --  Enable I2C master, disable I2C slave (we must be in SPI mode)
      --  XXX should turn off I2C slave nearer the start?
      Write_9250 (USER_CTRL,
                  Convert (User_Control'(I2C_MST_EN => 1,
                                         --  I2C_IF_DIS => 1,
                                         others => <>)));

      --  Set I2C clock. K_348 is the "default" (i.e. the one with
      --  Enum_Rep = 0).
      Write_9250 (I2C_MST_CTRL,
                  Convert (I2C_Master_Control'(I2C_MST_CLK => K_348,
                                               others => <>)));
      --  wait a bit
      Delay_For (100);

      --  pragma Assert (Read_AK8963 (WIA) = 16#48#,
      --                   "wrong ID for AK8963");
      Put_Line ("AK8963 ID should be 72, is " & Read_AK8963 (WIA)'Img);

      --  Put the AK8963 into power-down
      Write_AK8963 (CNTL1,
                    Convert (Control_1'(MODE => Power_Down,
                                        others => <>)));
      --  wait a bit
      Delay_For (100);

      --  Reset ..
      Write_AK8963 (CNTL2,
                    Convert (Control_2'(SRST => 1, others => <>)));
      --  wait a bit
      Delay_For (100);

      Calibrate_AK8963 (Magnetometer_Calibrations);
      Self_Test_AK8963 (Calibrations => Magnetometer_Calibrations,
                        OK           => AK8963_OK);

      --  Kick off a magnetometer measurement
      Write_AK8963 (CNTL1,
                    Convert (Control_1'(BITS => 1,
                                        MODE => Single_Measurement,
                                        others => <>)));

      --  wait a bit
      Delay_For (100);

      loop
         MPU9250_Device_Identified := Read_9250 (WHOAMI) = 16#71#;

         declare
            ATG : SPI.Byte_Array (ACCEL_XOUT_H .. GYRO_ZOUT_L);
            Start, Finish : Cycle_Timer.Cycles;
            use type Cycle_Timer.Cycles;
         begin
            Start := Cycle_Timer.Clock;
            Read_9250 (ACCEL_XOUT_H, ATG);
            Finish := Cycle_Timer.Clock;
            Put_Line ("reading atg: " & Integer (Finish - Start)'Img);
            Put ("ax: "
                   & To_Integer (Lo => ATG (ACCEL_XOUT_L),
                                 Hi => ATG (ACCEL_XOUT_H))'Img);
            Put (" ay: "
                   & To_Integer (Lo => ATG (ACCEL_YOUT_L),
                                 Hi => ATG (ACCEL_YOUT_H))'Img);
            Put (" az: "
                   & To_Integer (Lo => ATG (ACCEL_ZOUT_L),
                                 Hi => ATG (ACCEL_ZOUT_H))'Img);
            Put (" t: "
                   & To_Integer (Lo => ATG (TEMP_OUT_L),
                                 Hi => ATG (TEMP_OUT_H))'Img);
            Put (" gx: "
                   & To_Integer (Lo => ATG (GYRO_XOUT_L),
                                 Hi => ATG (GYRO_XOUT_H))'Img);
            Put (" gy: "
                   & To_Integer (Lo => ATG (GYRO_YOUT_L),
                                 Hi => ATG (GYRO_YOUT_H))'Img);
            Put (" gz: "
                   & To_Integer (Lo => ATG (GYRO_ZOUT_L),
                                 Hi => ATG (GYRO_ZOUT_H))'Img);
            New_Line;
         end;

         --  There is an issue with reading WIA: you have to repeat
         --  the call up to 4 times to get the "right" answer.
         declare
            ID : Interfaces.Unsigned_8;
         begin
            Put ("WIA: ");
            for J in 1 .. 10 loop
               ID := Read_AK8963 (WIA);
               Put (ID'Img);
            end loop;
            New_Line;
            AK8963_Device_Identified := ID = 16#48#;
         end;

         --  Read measurements from the AK8963
         declare
            DRDY_Loops : Natural := 0;
            Milligauss : AK8963_Components;
            Start, Finish : Cycle_Timer.Cycles;
            use type Cycle_Timer.Cycles;
         begin
            Start := Cycle_Timer.Clock;
            loop
               DRDY_Loops := DRDY_Loops + 1;
               exit when Status_1'(Convert (Read_AK8963 (ST1))).DRDY /= 0;
            end loop;
            Read_AK8963_Components (Magnetometer_Calibrations, Milligauss);
            Finish := Cycle_Timer.Clock;
            Put_Line ("reading mag: "
                        & Integer (Finish - Start)'Img
                        & ", loops"
                        & DRDY_Loops'Img);
            Put ("mx: " & Integer (Milligauss (X))'Img);
            Put (" my: " & Integer (Milligauss (Y))'Img);
            Put (" mz: " & Integer (Milligauss (Z))'Img);
            New_Line;
         end;

         --  Kick off a magnetometer measurement
         Write_AK8963 (CNTL1,
                       Convert (Control_1'(BITS => 1,
                                           MODE => Single_Measurement,
                                           others => <>)));

         Delay_For (1000);
      end loop;
   end MPU9250_Reader;

   procedure Calibrate_AK8963 (Calibrations : out AK8963_Calibrations)
   is
      Raw : SPI.Byte_Array (0 .. 2) := (others => 0);
      Magnetometer_Scaling : constant Float := 10.0 * 4912.0 / 32760.0;
      --  for 16-bit resolution
      use MPU9250_Registers;
   begin
      Write_AK8963 (CNTL1,
                    Convert (Control_1'(MODE => Power_Down,
                                        others => <>)));
      Delay_For (10);
      Write_AK8963 (CNTL1,
                    Convert (Control_1'(MODE => Fuse_ROM_Access,
                                        others => <>)));
      Read_AK8963 (ASAX, Raw);
      for C in Coordinate'Range loop
         Calibrations (C) :=
           (Float (Raw (Coordinate'Pos (C))) - 128.0) / 256.0 + 1.0;
      end loop;
      for C of Calibrations loop
         C := C * Magnetometer_Scaling;
      end loop;
      Write_AK8963 (CNTL1,
                    Convert (Control_1'(MODE => Power_Down,
                                        others => <>)));
      Delay_For (10);
   end Calibrate_AK8963;

   procedure Self_Test_AK8963 (Calibrations : AK8963_Calibrations;
                               OK : out Boolean)
   is
      Components : AK8963_Components := (others => 0.0);
      use MPU9250_Registers;
   begin
      Write_AK8963 (CNTL1,
                    Convert (Control_1'(MODE => Power_Down,
                                        others => <>)));
      Delay_For (10);
      Write_AK8963 (ASTC,
                    Convert (Self_Test_Control'(SELF => 1,
                                                others => <>)));
      Write_AK8963 (CNTL1,
                    Convert (Control_1'(MODE => Self_Test,
                                        others => <>)));
      loop
         exit when Status_1'(Convert (Read_AK8963 (ST1))).DRDY /= 0;
      end loop;
      Read_AK8963_Components (Calibrations, Components);
      Put ("stmx: " & Integer (Components (X))'Img);
      Put (" stmy: " & Integer (Components (Y))'Img);
      Put (" stmz: " & Integer (Components (Z))'Img);
      New_Line;
      Write_AK8963 (ASTC,
                    Convert (Self_Test_Control'(SELF => 0,
                                                others => <>)));
      Write_AK8963 (CNTL1,
                    Convert (Control_1'(MODE => Power_Down,
                                        others => <>)));
      Delay_For (10);
   end Self_Test_AK8963;

   procedure Read_AK8963_Components (Calibrations : AK8963_Calibrations;
                                     Components : out AK8963_Components)
   is
      use MPU9250_Registers;
      --  Measurements from the AK8963; we must read ST2 to ready for
      --  next cycle.
      XYZ : SPI.Byte_Array (HXL .. ST2) := (others => 0);
      Raw : array (Coordinate) of Integer;
   begin
      Read_AK8963 (HXL, XYZ);
      Raw (X) := To_Integer (Lo => XYZ (HXL),
                             Hi => XYZ (HXH));
      Raw (Y) := To_Integer (Lo => XYZ (HYL),
                             Hi => XYZ (HYH));
      Raw (Z) := To_Integer (Lo => XYZ (HZL),
                             Hi => XYZ (HZH));
      for Axis in Coordinate'Range loop
         Components (Axis) := Float (Raw (Axis)) * Calibrations (Axis);
      end loop;
   end Read_AK8963_Components;

   function Read_9250 (From_Register : MPU9250_Registers.MPU9250_Register)
                      return Interfaces.Unsigned_8
   is
      Bytes : SPI.Byte_Array (1 .. 1);
      use type Interfaces.Unsigned_8;
   begin
      Internal.Command_SPI (Internal.MPU9250,
                            Command => (0 => 16#80# or From_Register),
                            Result => Bytes);
      return Bytes (1);
   end Read_9250;

   procedure Read_9250 (From_Register : MPU9250_Registers.MPU9250_Register;
                        Bytes : out SPI.Byte_Array)
   is
      use type Interfaces.Unsigned_8;
   begin
      Internal.Command_SPI (Internal.MPU9250,
                            Command => (0 => 16#80# or From_Register),
                            Result => Bytes);
   end Read_9250;

   procedure Write_9250 (To_Register : MPU9250_Registers.MPU9250_Register;
                         Byte        : Interfaces.Unsigned_8)
   is
      use type Interfaces.Unsigned_8;
   begin
      Internal.Write_SPI
        (Internal.MPU9250,
         Bytes => (0 => 16#00# or To_Register,
                   1 => Byte));
   end Write_9250;

   function Read_AK8963 (From_Register : MPU9250_Registers.AK8963_Register)
                        return Interfaces.Unsigned_8
   is
      Bytes : SPI.Byte_Array (1 .. 1);
   begin
      Read_AK8963 (From_Register, Bytes);
      return Bytes (1);
   end Read_AK8963;

   procedure Read_AK8963 (From_Register : MPU9250_Registers.AK8963_Register;
                          Bytes : out SPI.Byte_Array)
   is
      use MPU9250_Registers;
   begin
      Write_9250 (I2C_SLV0_ADDR,
                  Convert (I2C_Slave_Address'(I2C_SLV_RNW => 1,
                                              I2C_ID => AK8963_ID)));
      Write_9250 (I2C_SLV0_REG, From_Register);
      Write_9250 (I2C_SLV0_CTRL,
                  Convert (I2C_Slave_Control'(I2C_SLV_EN => 1,
                                              I2C_SLV_LENG => Bytes'Length,
                                              others => <>)));
      --  At least 3 bytes to transfer at ~350 kHz, 70 us
      Nanosleep.Sleep (Nanosleep.To_Interval (0.000_070));
      Read_9250 (EXT_SENS_DATA,
                 Bytes);
   end Read_AK8963;

   procedure Write_AK8963 (To_Register : MPU9250_Registers.AK8963_Register;
                           Byte :  Interfaces.Unsigned_8)
   is
      use MPU9250_Registers;
   begin
      --  Put_Line ("Write_AK8963: To_Register :"
      --              & Integer'Image (Integer (To_Register))
      --              & ", Byte"
      --              & Integer'Image (Integer (Byte)));
      Write_9250 (I2C_SLV0_ADDR,
                  Convert (I2C_Slave_Address'(I2C_SLV_RNW => 0,
                                              I2C_ID => AK8963_ID)));
      Write_9250 (I2C_SLV0_REG, To_Register);
      Write_9250 (I2C_SLV0_DO, Byte);
      Write_9250 (I2C_SLV0_CTRL,
                  Convert (I2C_Slave_Control'(I2C_SLV_EN => 1,
                                              I2C_SLV_LENG => 1,
                                              others => <>)));
   end Write_AK8963;

   function To_Integer
     (Hi, Lo : Interfaces.Unsigned_8) return Integer
   is
      type Bytes is array (0 .. 1) of Interfaces.Unsigned_8;
      function Convert_Bytes
        is new Ada.Unchecked_Conversion (Bytes, Interfaces.Integer_16);
   begin
      return Integer (Convert_Bytes ((0 => Lo, 1 => Hi)));
   end To_Integer;

   procedure Delay_For (Milliseconds : Integer)
   is
      Start_Time : Ada.Real_Time.Time;
      use type Ada.Real_Time.Time;
   begin
      Start_Time := Ada.Real_Time.Clock;
      delay until Start_Time + Ada.Real_Time.Milliseconds (Milliseconds);
   end Delay_For;

end SPI1.MPU9250;
