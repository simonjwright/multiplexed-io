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
with Ada.Text_IO; use Ada.Text_IO;

package body SPI1.MPU9250
with
  SPARK_Mode => On
is

   task MPU9250_Reader;

   function Read_9250 (From_Register : MPU9250_Registers.MPU9250_Register)
                      return Interfaces.Unsigned_8;

   procedure Read_9250 (From_Register : MPU9250_Registers.MPU9250_Register;
                        Bytes : out SPI.Byte_Array);

   procedure Write_9250 (To_Register : MPU9250_Registers.MPU9250_Register;
                         Byte        : Interfaces.Unsigned_8);

   function Read_AK8963 (From_Register : MPU9250_Registers.AK8963_Register)
                        return Interfaces.Unsigned_8;

   procedure Write_AK8963 (To_Register : MPU9250_Registers.AK8963_Register;
                           Byte :  Interfaces.Unsigned_8);

   function To_Integer
     (Hi, Lo : Interfaces.Unsigned_8) return Integer;

   task body MPU9250_Reader is
      Start_Time : Ada.Real_Time.Time;
      use type Ada.Real_Time.Time;
      use type Interfaces.Unsigned_8;
      use MPU9250_Registers;
   begin
      --  Some time needed for MPU9250 to warm up
      Start_Time := Ada.Real_Time.Clock;
      delay until Start_Time + Ada.Real_Time.Milliseconds (100);

      pragma Assert (Read_9250 (WHOAMI) = 16#71#, "huh?");

      --  Reset the device
      Write_9250 (PWR_MGMT_1,
                  Convert (Power_Management_1'(H_RESET => 1, others => <>)));

      Start_Time := Ada.Real_Time.Clock;
      delay until Start_Time + Ada.Real_Time.Milliseconds (100);

      --  Select best available clock source
      Write_9250 (PWR_MGMT_1,
                  Convert (Power_Management_1'(CLKSEL => 1, others => <>)));

      --  Enable accelerator and gyro (i.e. don't disable them)
      Write_9250 (PWR_MGMT_2,
                  Convert (Power_Management_2'(others => <>)));

      --  Not going to use DLPF yet
      Write_9250 (CONFIG,
                  Convert (Configuration'(DLPF_CFG => 0, others => <>)));

      --  Not going to use DLPF yet, 2000 dpi
      Write_9250 (GYRO_CONFIG,
                  Convert (Gyro_Configuration'(F_CHOICE_B => 3,
                                               GYRO_FS_SEL => 3,
                                               others => <>)));

      --  +/- 4g
      Write_9250 (ACCEL_CONFIG,
                  Convert (Accel_Configuration'(ACCEL_FS_SEL => 2,
                                                others => <>)));

      --  Not going to use DLPF yet
      Write_9250 (ACCEL_CONFIG_2,
                  Convert (Accel_Configuration_2'(ACCEL_FCHOICE_B => 1,
                                                  others => <>)));

      --  I2C (AK8963) setup

      --  Enable I2C master, disable I2C slave (we must be in SPI mode)
      --  XXX should turn off I2C slave nearer the start?
      Write_9250 (USER_CTRL,
                  Convert (User_Control'(I2C_MST_EN => 1,
                                         I2C_IF_DIS => 1,
                                         others => <>)));

      --  I2C clock to 400 kHz (13), 381 kHz (14), 258 kHz (8)
      Write_9250 (I2C_MST_CTRL,
                  Convert (I2C_Master_Control'(I2C_MST_CLK => K_308,
                                               others => <>)));

      --  wait a bit
      Start_Time := Ada.Real_Time.Clock;
      delay until Start_Time + Ada.Real_Time.Milliseconds (100);

      --  Reading from the AK8963 ..
      --  .. check the ID
      --  pragma Assert (Read_AK8963 (WIA) = 16#48#,
      --                   "wrong ID for AK8963");
      Put_Line ("AK8963 ID should be 72, is " & Read_AK8963 (WIA)'Img);

      --  More AK8963 stuff here

      --  Reset ..
      Write_AK8963 (CNTL2,
                    Convert (Control_2'(SRST => 1, others => <>)));

      --  wait a bit
      Start_Time := Ada.Real_Time.Clock;
      delay until Start_Time + Ada.Real_Time.Milliseconds (100);

      --  Clear reset (XXX needed?)
      Write_AK8963 (CNTL2,
                    Convert (Control_2'(SRST => 0, others => <>)));

      --  wait a bit
      Start_Time := Ada.Real_Time.Clock;
      delay until Start_Time + Ada.Real_Time.Milliseconds (100);

      --  Set for continuous measurement (16-bits, at 100 Hz)
      Write_AK8963 (CNTL1,
                    Convert (Control_1'(BITS => 1,
                                        MODE => Continuous_Measurement_2,
                                        others => <>)));

      --  wait a bit
      Start_Time := Ada.Real_Time.Clock;
      delay until Start_Time + Ada.Real_Time.Milliseconds (100);

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

         --  Read WIA from the AK8963
         AK8963_Device_Identified := Read_AK8963 (WIA) = 16#48#;

         --  Read measurements from the AK8963; we must read ST2 to
         --  ready for next cycle.
         declare
            XYZ : SPI.Byte_Array (HXL .. ST2);
            Start, Finish : Cycle_Timer.Cycles;
            use type Cycle_Timer.Cycles;
         begin
            Start := Cycle_Timer.Clock;
            for J in XYZ'Range loop
               XYZ (J) := Read_AK8963 (Interfaces.Unsigned_8 (J));
            end loop;
            Finish := Cycle_Timer.Clock;
            Put_Line ("reading mag: " & Integer (Finish - Start)'Img);
            Put (" mx: "
                   & To_Integer (Lo => XYZ (HXL),
                                 Hi => XYZ (HXH))'Img);
            Put (" my: "
                        & To_Integer (Lo => XYZ (HYL),
                                      Hi => XYZ (HYH))'Img);
            Put (" mz: "
                        & To_Integer (Lo => XYZ (HZL),
                                      Hi => XYZ (HZH))'Img);
            New_Line;
         end;

         Start_Time := Start_Time + Ada.Real_Time.Milliseconds (1000);
         delay until Start_Time;
      end loop;
   end MPU9250_Reader;

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
      use MPU9250_Registers;
   begin
      Write_9250 (I2C_SLV4_ADDR,
                  Convert (I2C_Slave_Address'(I2C_SLV_RNW => 1,
                                              I2C_ID => AK8963_ID)));
      Write_9250 (I2C_SLV4_REG, From_Register);
      Write_9250 (I2C_SLV4_CTRL,
                  Convert (I2C_Slave4_Control'(I2C_SLV4_EN => 1,
                                               others => <>)));
      declare
         Status : Interfaces.Unsigned_8;
         --  declared outside the loop so we can debug in case we get stuck
         Count : Interfaces.Unsigned_64 := 0;
         use type Interfaces.Unsigned_64;
      begin
         loop
            Status := Read_9250 (I2C_MST_STATUS);
            exit when Convert (Status).I2C_SLV4_DONE /= 0;
            Count := Count + 1;
         end loop;
      end;
      return Read_9250 (I2C_SLV4_DI);
   end Read_AK8963;

   procedure Write_AK8963 (To_Register : MPU9250_Registers.AK8963_Register;
                           Byte :  Interfaces.Unsigned_8)
   is
      use MPU9250_Registers;
   begin
      Write_9250 (I2C_SLV4_ADDR,
                  Convert (I2C_Slave_Address'(I2C_SLV_RNW => 0,
                                              I2C_ID => AK8963_ID)));
      Write_9250 (I2C_SLV4_REG, To_Register);
      Write_9250 (I2C_SLV4_DO, Byte);
      Write_9250 (I2C_SLV4_CTRL,
                  Convert (I2C_Slave4_Control'(I2C_SLV4_EN => 1,
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

end SPI1.MPU9250;
