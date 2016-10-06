--  Demonstration code for the AdaPilot project
--  (http://adapilot.likeabird.eu).
--  Copyright (C) 2016 Simon Wright <simon@pushface.org>

with Ada.Real_Time;
with Ada.Unchecked_Conversion;
with Interfaces;
with System;

with SPI1.Internal;
pragma Elaborate_All (SPI1.Internal);
with SPI1.MPU9250_Registers;

with Nanosleep;
--  with Ada.Text_IO; use Ada.Text_IO;

package body SPI1.MPU9250
with
  SPARK_Mode => Off
is

   --  Suppress debug output.
   procedure Put (S : String) is null;
   procedure Put_Line (S : String) is null;
   procedure New_Line is null;

   task MPU9250_Reader
   with Priority => System.Default_Priority - 1;
   --  This is temporary; it means that if we hang (at least, in a
   --  delay) the remainder of the test application can still run.

   type MPU9250_Components is new Coordinates;
   type AK8963_Calibrations is new Coordinates;
   type AK8963_Components is new Coordinates;

   procedure Self_Test_9250 (Ok : out Boolean);
   --  Leaves device configured for self test.

   procedure Calibrate_AK8963 (Calibrations : out AK8963_Calibrations);
   --  Includes magnetometer scaling. Leaves device powered down.

   procedure Self_Test_AK8963 (Calibrations : AK8963_Calibrations;
                               Ok : out Boolean);
   --  Leaves device powered down.

   procedure Read_MPU9250_Components
     (From_Register : MPU9250_Registers.MPU9250_Register;
      Components : out MPU9250_Components);

   procedure Read_AK8963_Components (Calibrations : AK8963_Calibrations;
                                     Components : out AK8963_Components;
                                     Scaled : Boolean := True);

   function Read_9250 (From_Register : MPU9250_Registers.MPU9250_Register)
                      return Interfaces.Unsigned_8;

   procedure Read_9250 (From_Register : MPU9250_Registers.MPU9250_Register;
                        Bytes : out Byte_Array);

   procedure Write_9250 (To_Register : MPU9250_Registers.MPU9250_Register;
                         Byte        : Interfaces.Unsigned_8);

   function Read_AK8963 (From_Register : MPU9250_Registers.AK8963_Register)
                        return Interfaces.Unsigned_8;

   procedure Read_AK8963 (From_Register : MPU9250_Registers.AK8963_Register;
                          Bytes : out Byte_Array);

   procedure Write_AK8963 (To_Register : MPU9250_Registers.AK8963_Register;
                           Byte :  Interfaces.Unsigned_8);

   procedure Delay_For (Milliseconds : Integer);

   function To_Integer
     (Hi, Lo : Interfaces.Unsigned_8) return Integer;

   task body MPU9250_Reader is
      Magnetometer_Calibrations : AK8963_Calibrations;
      use type Interfaces.Unsigned_8;
      use MPU9250_Registers;
   begin
      --  Some time needed for MPU9250 to warm up
      Delay_For (100);

      declare
         ID : constant Interfaces.Unsigned_8 := Read_9250 (WHOAMI);
      begin
         MPU9250_Device_Identified := ID = 16#71# or ID = 16#73#;
         if ID = 16#71# then
            Put_Line ("MPU9250 recognised");
         elsif ID = 16#73# then
            Put_Line ("MPU9255 (?) recognised");
         else
            raise Program_Error
            with "don't recognise MPU9250,"
              & " WHOAMI is neither 16#71# nor 16#73#";
         end if;
      end;

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

      Self_Test_9250 (Ok => MPU9250_Ok);

      --  Configure for running

      --  Sample rate divider 0 means that the data rates selected
      --  below are unchanged.
      Write_9250 (SMPLRT_DIV, 0);

      --  Set DLPF and ranges for gyro/temp/accel
      Write_9250 (CONFIG,
                  Convert (Configuration'(DLPF_CFG => Hz_184, others => <>)));
      Write_9250 (GYRO_CONFIG,
                  Convert (Gyro_Configuration'(F_CHOICE_B => 0,
                                               GYRO_FS_SEL => Dps_2000,
                                               others => <>)));
      Write_9250 (ACCEL_CONFIG,
                  Convert (Accel_Configuration'(ACCEL_FS_SEL => G_8,
                                                others => <>)));
      Write_9250 (ACCEL_CONFIG_2,
                  Convert (Accel_Configuration_2'(ACCEL_FCHOICE_B => 0,
                                                  A_DLPFCFG => Hz_218_B,
                                                  others => <>)));

      --  I2C (AK8963) setup

      --  Enable I2C master, disable I2C slave (we must be in SPI mode)
      --  XXX should turn off I2C slave nearer the start?
      Write_9250 (USER_CTRL,
                  Convert (User_Control'(I2C_MST_EN => 1,
                                         I2C_IF_DIS => 1,
                                         others => <>)));

      --  Set I2C clock. K_348 is the "default" (i.e. the one with
      --  Enum_Rep = 0).
      Write_9250 (I2C_MST_CTRL,
                  Convert (I2C_Master_Control'(I2C_MST_P_NSR => 1,
                                               I2C_MST_CLK => K_348,
                                               others => <>)));

      --  wait a bit
      Delay_For (100);

      declare
         ID : constant Byte := Read_AK8963 (WIA);
      begin
         AK8963_Device_Identified := ID = 16#48#;
         Put_Line (if AK8963_Device_Identified
                   then "AK8963 recognised"
                   else "AK8963 ID should be 72, is " & ID'Img);
      end;
      --  wait a bit
      Delay_For (100);

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
      Self_Test_AK8963 (Magnetometer_Calibrations, AK8963_Ok);

      --  Kick off magnetometer measurements (100 Hz)
      Write_AK8963 (CNTL1,
                    Convert (Control_1'(BITS => 1,
                                        MODE => Continuous_Measurement_2,
                                        others => <>)));
      --  wait a bit
      Delay_For (100);

      loop
         declare
            ATG : Byte_Array (ACCEL_XOUT_H .. GYRO_ZOUT_L);
            Acceleration_Scale : constant Float := 8.0 / 32768.0;
            Gyro_Scale : constant Float := 2000.0 / 32768.0;
         begin
            Read_9250 (ACCEL_XOUT_H, ATG);

            Accelerations (X) :=
              Float (To_Integer (Lo => ATG (ACCEL_XOUT_L),
                                 Hi => ATG (ACCEL_XOUT_H)))
              * Acceleration_Scale;
            Accelerations (Y) :=
              Float (To_Integer (Lo => ATG (ACCEL_YOUT_L),
                                 Hi => ATG (ACCEL_YOUT_H)))
              * Acceleration_Scale;
            Accelerations (Z) :=
              Float (To_Integer (Lo => ATG (ACCEL_ZOUT_L),
                                 Hi => ATG (ACCEL_ZOUT_H)))
              * Acceleration_Scale;

            Gyro_Rates (X) :=
              Float (To_Integer (Lo => ATG (GYRO_XOUT_L),
                                 Hi => ATG (GYRO_XOUT_H)))
              * Gyro_Scale;
            Gyro_Rates (Y) :=
              Float (To_Integer (Lo => ATG (GYRO_YOUT_L),
                                 Hi => ATG (GYRO_YOUT_H)))
              * Gyro_Scale;
            Gyro_Rates (Z) :=
              Float (To_Integer (Lo => ATG (GYRO_ZOUT_L),
                                 Hi => ATG (GYRO_ZOUT_H)))
              * Gyro_Scale;

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

         --  Read measurements from the AK8963
         declare
            Milligauss : AK8963_Components;
         begin
            Read_AK8963_Components (Magnetometer_Calibrations, Milligauss);
            Magnetic_Fields := Coordinates (Milligauss);
         end;

         Delay_For (10);
      end loop;
   end MPU9250_Reader;

   procedure Self_Test_9250 (Ok : out Boolean)
   is
      use MPU9250_Registers;
      Raw_Gyro_Self_Test : array (Coordinate) of Interfaces.Unsigned_8;
      Gyro_Factory : MPU9250_Components;
      Raw_Accel_Self_Test : array (Coordinate) of Interfaces.Unsigned_8;
      Accel_Factory : MPU9250_Components;
      Gyro_Unmodified : MPU9250_Components := (others => 0.0);
      Accel_Unmodified : MPU9250_Components := (others => 0.0);
      Gyro_Self_Test : MPU9250_Components := (others => 0.0);
      Accel_Self_Test : MPU9250_Components := (others => 0.0);
      use type Interfaces.Unsigned_8;

      --  This from Ada Drivers Library
      --  components/src/motion/mpu9250/mpu9250.ads.
      --
      --  It represents 2620 * (1.01 ** n).
      --
      --  They have some wierd check for a zero value ...
      MPU9250_ST_TB : constant array (0 .. 255) of Interfaces.Unsigned_16
        := (
            2620, 2646, 2672, 2699, 2726, 2753, 2781, 2808,
            2837, 2865, 2894, 2923, 2952, 2981, 3011, 3041,
            3072, 3102, 3133, 3165, 3196, 3228, 3261, 3293,
            3326, 3359, 3393, 3427, 3461, 3496, 3531, 3566,
            3602, 3638, 3674, 3711, 3748, 3786, 3823, 3862,
            3900, 3939, 3979, 4019, 4059, 4099, 4140, 4182,
            4224, 4266, 4308, 4352, 4395, 4439, 4483, 4528,
            4574, 4619, 4665, 4712, 4759, 4807, 4855, 4903,
            4953, 5002, 5052, 5103, 5154, 5205, 5257, 5310,
            5363, 5417, 5471, 5525, 5581, 5636, 5693, 5750,
            5807, 5865, 5924, 5983, 6043, 6104, 6165, 6226,
            6289, 6351, 6415, 6479, 6544, 6609, 6675, 6742,
            6810, 6878, 6946, 7016, 7086, 7157, 7229, 7301,
            7374, 7448, 7522, 7597, 7673, 7750, 7828, 7906,
            7985, 8065, 8145, 8227, 8309, 8392, 8476, 8561,
            8647, 8733, 8820, 8909, 8998, 9088, 9178, 9270,
            9363, 9457, 9551, 9647, 9743, 9841, 9939, 10038,
            10139, 10240, 10343, 10446, 10550, 10656, 10763, 10870,
            10979, 11089, 11200, 11312, 11425, 11539, 11654, 11771,
            11889, 12008, 12128, 12249, 12371, 12495, 12620, 12746,
            12874, 13002, 13132, 13264, 13396, 13530, 13666, 13802,
            13940, 14080, 14221, 14363, 14506, 14652, 14798, 14946,
            15096, 15247, 15399, 15553, 15709, 15866, 16024, 16184,
            16346, 16510, 16675, 16842, 17010, 17180, 17352, 17526,
            17701, 17878, 18057, 18237, 18420, 18604, 18790, 18978,
            19167, 19359, 19553, 19748, 19946, 20145, 20347, 20550,
            20756, 20963, 21173, 21385, 21598, 21814, 22033, 22253,
            22475, 22700, 22927, 23156, 23388, 23622, 23858, 24097,
            24338, 24581, 24827, 25075, 25326, 25579, 25835, 26093,
            26354, 26618, 26884, 27153, 27424, 27699, 27976, 28255,
            28538, 28823, 29112, 29403, 29697, 29994, 30294, 30597,
            30903, 31212, 31524, 31839, 32157, 32479, 32804, 33132
           );
   begin
      --  Read factory info.
      Raw_Gyro_Self_Test (X) := Read_9250 (SELF_TEST_X_GYRO);
      Raw_Gyro_Self_Test (Y) := Read_9250 (SELF_TEST_Y_GYRO);
      Raw_Gyro_Self_Test (Z) := Read_9250 (SELF_TEST_Z_GYRO);
      for J in Raw_Gyro_Self_Test'Range loop
         Gyro_Factory (J) :=
           Float (MPU9250_ST_TB (Integer (Raw_Gyro_Self_Test (J))));
      end loop;
      Raw_Accel_Self_Test (X) := Read_9250 (SELF_TEST_X_ACCEL);
      Raw_Accel_Self_Test (Y) := Read_9250 (SELF_TEST_Y_ACCEL);
      Raw_Accel_Self_Test (Z) := Read_9250 (SELF_TEST_Z_ACCEL);
      for J in Coordinate loop
         Accel_Factory (J) :=
           Float (MPU9250_ST_TB (Integer (Raw_Accel_Self_Test (J))));
      end loop;
      New_Line;
      New_Line;
      Put ("gsf: ");
      for J in Coordinate loop
         Put (Integer (Gyro_Factory (J))'Img & " ");
      end loop;
      New_Line;
      Put ("asf: ");
      for J in Coordinate loop
         Put (Integer (Accel_Factory (J))'Img & " ");
      end loop;
      New_Line;
      New_Line;

      --  Get normal readings
      --  Sample rate divider 0 means that the data rates selected
      --  below are unchanged.
      Write_9250 (SMPLRT_DIV, 0);
      --  Set DLPF for gyro/temp
      Write_9250 (CONFIG,
                  Convert (Configuration'(DLPF_CFG => Hz_92, others => <>)));
      Write_9250 (GYRO_CONFIG,
                  Convert (Gyro_Configuration'(F_CHOICE_B => 0,
                                               GYRO_FS_SEL => Dps_250,
                                               others => <>)));
      Write_9250 (ACCEL_CONFIG,
                  Convert (Accel_Configuration'(ACCEL_FS_SEL => G_2,
                                                others => <>)));
      Write_9250 (ACCEL_CONFIG_2,
                  Convert (Accel_Configuration_2'(ACCEL_FCHOICE_B => 0,
                                                  A_DLPFCFG => Hz_99,
                                                  others => <>)));
      Delay_For (25);
      declare
         Tmp : MPU9250_Components;
      begin
         for J in 1 .. 200 loop
            Read_MPU9250_Components (GYRO_XOUT_H, Tmp);
            for J in Coordinate loop
               Gyro_Unmodified (J) := Gyro_Unmodified (J) + Tmp (J);
            end loop;
            Read_MPU9250_Components (ACCEL_XOUT_H, Tmp);
            for J in Coordinate loop
               Accel_Unmodified (J) := Accel_Unmodified (J) + Tmp (J);
            end loop;
            Delay_For (1);
         end loop;
      end;

      --  Get self-test readings
      Write_9250 (GYRO_CONFIG,
                  Convert (Gyro_Configuration'(XGYRO_CTEN => 1,
                                               YGYRO_CTEN => 1,
                                               ZGYRO_CTEN => 1,
                                               others => <>)));
      Write_9250 (ACCEL_CONFIG,
                  Convert (Accel_Configuration'(AX_ST_EN => 1,
                                                AY_ST_EN => 1,
                                                AZ_ST_EN => 1,
                                                others => <>)));
      Delay_For (25);
      declare
         Tmp : MPU9250_Components;
      begin
         for J in 1 .. 200 loop
            Read_MPU9250_Components (GYRO_XOUT_H, Tmp);
            for J in Coordinate loop
               Gyro_Self_Test (J) := Gyro_Self_Test (J) + Tmp (J);
            end loop;
            Read_MPU9250_Components (ACCEL_XOUT_H, Tmp);
            for J in Coordinate loop
               Accel_Self_Test (J) := Accel_Self_Test (J) + Tmp (J);
            end loop;
            Delay_For (1);
         end loop;
      end;

      --  Leave self-test
      Write_9250 (GYRO_CONFIG,
                  Convert (Gyro_Configuration'(others => <>)));
      Write_9250 (ACCEL_CONFIG,
                  Convert (Accel_Configuration'(others => <>)));
      Delay_For (25);

      --  Form averages
      for J in Coordinate loop
         Gyro_Unmodified (J) := Gyro_Unmodified (J) / 200.0;
         Accel_Unmodified (J) := Accel_Unmodified (J) / 200.0;
         Gyro_Self_Test (J) := Gyro_Self_Test (J) / 200.0;
         Accel_Self_Test (J) := Accel_Self_Test (J) / 200.0;
      end loop;

      Put ("guf: ");
      for J in Coordinate loop
         Put (Integer (Gyro_Unmodified (J))'Img & " ");
      end loop;
      New_Line;
      Put ("gmf: ");
      for J in Coordinate loop
         Put (Integer (Gyro_Self_Test (J))'Img & " ");
      end loop;
      New_Line;
      Put ("auf: ");
      for J in Coordinate loop
         Put (Integer (Accel_Unmodified (J))'Img & " ");
      end loop;
      New_Line;
      Put ("amf: ");
      for J in Coordinate loop
         Put (Integer (Accel_Self_Test (J))'Img & " ");
      end loop;
      New_Line;
      New_Line;
      Put ("gmf-guf: ");
      for J in Coordinate loop
         Put (Integer (Gyro_Self_Test (J) - Gyro_Unmodified (J))'Img & " ");
      end loop;
      New_Line;
      Put ("amf-auf: ");
      for J in Coordinate loop
         Put (Integer (Accel_Self_Test (J) - Accel_Unmodified (J))'Img & " ");
      end loop;
      New_Line;
      New_Line;

      Put ("g%: ");
      for J in Coordinate loop
         declare
            Tmp : Float;
         begin
            Tmp := Gyro_Self_Test (J) - Gyro_Unmodified (J);
            Tmp := Tmp / Gyro_Factory (J) - 1.0;
            Put (Integer (Tmp * 100.0)'Img & " ");
         end;
      end loop;
      New_Line;
      Put ("a%: ");
      for J in Coordinate loop
         declare
            Tmp : Float;
         begin
            Tmp := Accel_Self_Test (J) - Accel_Unmodified (J);
            Tmp := Tmp / Accel_Factory (J) - 1.0;
            Put (Integer (Tmp * 100.0)'Img & " ");
         end;
      end loop;
      New_Line;
      New_Line;

      --  evaluate pass/fail
      Ok := True;
      for J in Coordinate loop
         if abs ((Gyro_Self_Test (J)
                    - Gyro_Unmodified (J)
                    - Gyro_Factory (J))
                   / Gyro_Factory (J)) > 0.14
         then
            Ok := False;
         end if;
         if abs ((Accel_Self_Test (J)
                    - Accel_Unmodified (J)
                    - Accel_Factory (J))
                   / Accel_Factory (J)) > 0.14
         then
            Ok := False;
         end if;
      end loop;
   end Self_Test_9250;

   procedure Calibrate_AK8963 (Calibrations : out AK8963_Calibrations)
   is
      Raw : Byte_Array (0 .. 2) := (others => 0);
      use MPU9250_Registers;
   begin
      Write_AK8963 (CNTL1,
                    Convert (Control_1'(MODE => Power_Down,
                                        others => <>)));
      Delay_For (100);
      Write_AK8963 (CNTL1,
                    Convert (Control_1'(BITS => 1,
                                        MODE => Fuse_ROM_Access,
                                        others => <>)));
      Delay_For (100);

      Put ("waiting for calibration data ready ");
      declare
         use type Interfaces.Unsigned_8;
      begin
         loop
            Read_AK8963 (ASAX, Raw);
            exit when Raw (0) /= 0 and Raw (1) /= 0 and Raw (2) /= 0;
            Put (".");
         end loop;
      end;
      New_Line;
      Put ("mrawcal:");
      for R in Raw'Range loop
         Put (Raw (R)'Img & " ");
      end loop;
      New_Line;
      Put ("cal*100:");
      for C in Coordinate'Range loop
         Calibrations (C) :=
           (Float (Raw (Coordinate'Pos (C))) - 128.0) / 256.0 + 1.0;
         Put (Integer (Calibrations (C) * 100.0)'Img);
      end loop;
      New_Line;
      Write_AK8963 (CNTL1,
                    Convert (Control_1'(MODE => Power_Down,
                                        others => <>)));
      Delay_For (100);
   end Calibrate_AK8963;

   procedure Self_Test_AK8963 (Calibrations : AK8963_Calibrations;
                               Ok : out Boolean)
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
      Delay_For (10);
      Write_AK8963 (CNTL1,
                    Convert (Control_1'(MODE => Self_Test,
                                        others => <>)));

      Put ("waiting for mag self-test ready ");
      while Status_1'(Convert (Read_AK8963 (ST1))).DRDY = 0 loop
         Put (".");
         Delay_For (2);
      end loop;
      New_Line;

      Read_AK8963_Components (Calibrations, Components, Scaled => False);

      Ok := Components (X) in -200.0 .. 200.0
        and Components (Y) in -200.0 .. 200.0
        and Components (Z) in -3200.0 .. -800.0;

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

   procedure Read_MPU9250_Components
     (From_Register : MPU9250_Registers.MPU9250_Register;
     Components : out MPU9250_Components)
   is
      Raw : Byte_Array (1 .. 6);
   begin
      Read_9250 (From_Register, Raw);
      Components (X) := Float (To_Integer (Lo => Raw (2), Hi => Raw (1)));
      Components (Y) := Float (To_Integer (Lo => Raw (4), Hi => Raw (3)));
      Components (Z) := Float (To_Integer (Lo => Raw (6), Hi => Raw (5)));
   end Read_MPU9250_Components;

   procedure Read_AK8963_Components (Calibrations : AK8963_Calibrations;
                                     Components : out AK8963_Components;
                                     Scaled : Boolean := True)
   is
      use MPU9250_Registers;
      --  Measurements from the AK8963; we must read ST2 to ready for
      --  next cycle.
      XYZ : Byte_Array (HXL .. ST2) := (others => 0);
      Raw : array (Coordinate) of Integer;
      Magnetometer_Scaling : constant Float := 10.0 * 4912.0 / 32760.0;
      --  for 16-bit resolution, lsb = 0.15 uT, value is abs 32760.0; this
      --  formula generates milligauss (mG).
   begin
      Read_AK8963 (HXL, XYZ);
      if Status_2'(Convert (XYZ (ST2))).HOFL = 0 then
         Put ("raw st:");
         for J in XYZ'Range loop
            Put (XYZ (J)'Img);
         end loop;
         New_Line;
         Raw (X) := To_Integer (Lo => XYZ (HXL),
                                Hi => XYZ (HXH));
         Raw (Y) := To_Integer (Lo => XYZ (HYL),
                                Hi => XYZ (HYH));
         Raw (Z) := To_Integer (Lo => XYZ (HZL),
                                Hi => XYZ (HZH));
         for Axis in Coordinate'Range loop
            Components (Axis) :=
              Float (Raw (Axis))
              * Calibrations (Axis)
              * (if Scaled then Magnetometer_Scaling else 1.0);
         end loop;
      else
         Put_Line ("AK8963 overflow");
         Components := (others => 0.0);
      end if;
   end Read_AK8963_Components;

   function Read_9250 (From_Register : MPU9250_Registers.MPU9250_Register)
                      return Interfaces.Unsigned_8
   is
      Bytes : Byte_Array (1 .. 1);
      use type Interfaces.Unsigned_8;
   begin
      Internal.Command_SPI (Internal.MPU9250,
                            Command => (0 => 16#80# or From_Register),
                            Result => Bytes);
      return Bytes (1);
   end Read_9250;

   procedure Read_9250 (From_Register : MPU9250_Registers.MPU9250_Register;
                        Bytes : out Byte_Array)
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

   --  Allow 25 us per byte transferred over the internal I2C. Note
   --  there is always one control byte sent first.
   I2C_Time_Per_Byte : constant Duration := 0.000_025;
   --  We seem to need a bit more.
   I2C_Additional_Delay : constant Duration := 0.000_400;

   --  Disable the internal I2C after the transfer is (should have
   --  been) complete.

   function Read_AK8963 (From_Register : MPU9250_Registers.AK8963_Register)
                        return Interfaces.Unsigned_8
   is
      Bytes : Byte_Array (1 .. 1);
   begin
      Read_AK8963 (From_Register, Bytes);
      return Bytes (1);
   end Read_AK8963;

   procedure Read_AK8963 (From_Register : MPU9250_Registers.AK8963_Register;
                          Bytes : out Byte_Array)
   is
      use MPU9250_Registers;
   begin
      --  Ensure nothing's going on before changing the registers
      Write_9250 (I2C_SLV0_CTRL,
                  Convert (I2C_Slave_Control'(I2C_SLV_EN => 0,
                                              others => <>)));
      Write_9250 (I2C_SLV0_ADDR,
                  Convert (I2C_Slave_Address'(I2C_SLV_RNW => 1,
                                              I2C_ID => AK8963_ID)));
      Write_9250 (I2C_SLV0_REG, From_Register);
      Write_9250 (I2C_SLV0_CTRL,
                  Convert (I2C_Slave_Control'(I2C_SLV_EN => 1,
                                              I2C_SLV_LENG => Bytes'Length,
                                              others => <>)));
      Nanosleep.Sleep
        (I2C_Time_Per_Byte * (Bytes'Length + 1) + I2C_Additional_Delay);
      Write_9250 (I2C_SLV0_CTRL,
                  Convert (I2C_Slave_Control'(I2C_SLV_EN => 0,
                                              others => <>)));
      Read_9250 (EXT_SENS_DATA, Bytes);
   end Read_AK8963;

   procedure Write_AK8963 (To_Register : MPU9250_Registers.AK8963_Register;
                           Byte :  Interfaces.Unsigned_8)
   is
      use MPU9250_Registers;
   begin
      --  Ensure nothing's going on before changing the registers
      Write_9250 (I2C_SLV0_CTRL,
                  Convert (I2C_Slave_Control'(I2C_SLV_EN => 0,
                                              others => <>)));
      Write_9250 (I2C_SLV0_ADDR,
                  Convert (I2C_Slave_Address'(I2C_SLV_RNW => 0,
                                              I2C_ID => AK8963_ID)));
      Write_9250 (I2C_SLV0_REG, To_Register);
      Write_9250 (I2C_SLV0_DO, Byte);
      Write_9250 (I2C_SLV0_CTRL,
                  Convert (I2C_Slave_Control'(I2C_SLV_EN => 1,
                                              I2C_SLV_LENG => 1,
                                              others => <>)));
      Nanosleep.Sleep (I2C_Time_Per_Byte * 2 + I2C_Additional_Delay);
      Write_9250 (I2C_SLV0_CTRL,
                  Convert (I2C_Slave_Control'(I2C_SLV_EN => 0,
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
