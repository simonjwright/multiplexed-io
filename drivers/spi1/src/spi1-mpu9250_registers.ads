--  Demonstration code for the AdaPilot project
--  (http://adapilot.likeabird.eu).
--  Copyright (C) 2016 Simon Wright <simon@pushface.org>

with Ada.Unchecked_Conversion;
with SPI;
with Interfaces;

package SPI1.MPU9250_Registers
with
  SPARK_Mode => Off,
  Pure
is

   type Bit is range 0 .. 1
   with Size => 1;

   type Bits is array (Natural range <>) of Bit
   with Component_Size => 1;

   type Bits_2 is range 0 .. 2**2 - 1 with Size => 2;
   type Bits_3 is range 0 .. 2**3 - 1 with Size => 3;
   type Bits_4 is range 0 .. 2**4 - 1 with Size => 4;
   type Bits_6 is range 0 .. 2**6 - 1 with Size => 6;
   type Bits_7 is range 0 .. 2**7 - 1 with Size => 7;

   subtype MPU9250_Register is Interfaces.Unsigned_8 range 0 .. 126;

   -----------------------------------
   --  Gyro, Acceleration (& Temp)  --
   -----------------------------------

   subtype Self_Test_Gyro is Interfaces.Integer_8;
   SELF_TEST_X_GYRO : constant := 0;
   SELF_TEST_Y_GYRO : constant := 1;
   SELF_TEST_Z_GYRO : constant := 2;

   subtype Self_Test_Accel is Interfaces.Integer_8;
   SELF_TEST_X_ACCEL : constant := 13;
   SELF_TEST_Y_ACCEL : constant := 14;
   SELF_TEST_Z_ACCEL : constant := 15;

   subtype G_Offset is Interfaces.Unsigned_8;
   XG_OFFSET_H : constant := 19;
   XG_OFFSET_L : constant := 20;
   YG_OFFSET_H : constant := 21;
   YG_OFFSET_L : constant := 22;
   ZG_OFFSET_H : constant := 23;
   ZG_OFFSET_L : constant := 24;

   subtype Sample_Rate_Divider is Interfaces.Unsigned_8;
   SMPLRT_DIV : constant := 25;

   type Configuration_DLPF_Bandwidth is
     (Hz_250,
      Hz_184,
      Hz_92,
      Hz_41,
      Hz_20,
      Hz_10,
      Hz_5,
      Hz_3600) with Size => 3;
   --  Only meaningful when Gyro_Configuration.F_Choice_B is 3
   type Configuration is record
      Reserved_7_7 : Bit := 0;
      FIFO_MODE : Bit := 0;
      EXT_SYNC_SET : Bits_3 := 0;
      DLPF_CFG : Configuration_DLPF_Bandwidth := Hz_250;
   end record with Size => 8;
   for Configuration use record
      Reserved_7_7 at 0 range 7 .. 7;
      FIFO_MODE at 0 range 6 .. 6;
      EXT_SYNC_SET at 0 range 3 .. 5;
      DLPF_CFG at 0 range 0 .. 2;
   end record;
   function Convert is new Ada.Unchecked_Conversion (Configuration,
                                                     Interfaces.Unsigned_8);
   CONFIG : constant := 26;

   type Gyro_Full_Scale_Select is
     (Dps_250,
      Dps_500,
      Dps_1000,
      Dps_2000) with Size => 2;
   type Gyro_Configuration is record
      XGYRO_CTEN : Bit := 0;
      YGYRO_CTEN : Bit := 0;
      ZGYRO_CTEN : Bit := 0;
      GYRO_FS_SEL : Gyro_Full_Scale_Select := Dps_250;
      Reserved_2_2 : Bit := 0;
      F_CHOICE_B : Bits_2 := 0;
   end record with Size => 8;
   for Gyro_Configuration use record
      XGYRO_CTEN at 0 range 7 .. 7;
      YGYRO_CTEN at 0 range 6 .. 6;
      ZGYRO_CTEN at 0 range 5 .. 5;
      GYRO_FS_SEL at 0 range 3 .. 4;
      Reserved_2_2 at 0 range 2 .. 2;
      F_CHOICE_B at 0 range 0 .. 1;
   end record;
   function Convert is new Ada.Unchecked_Conversion (Gyro_Configuration,
                                                     Interfaces.Unsigned_8);
   GYRO_CONFIG : constant := 27;

   type Accel_Full_Scale_Select is
     (G_2,
      G_4,
      G_8,
      G_16) with Size => 2;
   type Accel_Configuration is record
      AX_ST_EN : Bit := 0;
      AY_ST_EN : Bit := 0;
      AZ_ST_EN : Bit := 0;
      ACCEL_FS_SEL : Accel_Full_Scale_Select := G_2;
      Reserved_0_2 : Bits_3 := 0;
   end record with Size => 8;
   for Accel_Configuration use record
      AX_ST_EN at 0 range 7 .. 7;
      AY_ST_EN at 0 range 6 .. 6;
      AZ_ST_EN at 0 range 5 .. 5;
      ACCEL_FS_SEL at 0 range 3 .. 4;
      Reserved_0_2 at 0 range 0 .. 2;
   end record;
   function Convert is new Ada.Unchecked_Conversion (Accel_Configuration,
                                                     Interfaces.Unsigned_8);
   ACCEL_CONFIG : constant := 28;

   type Accel_Bandwidth is
     (Hz_218_A,
      Hz_218_B,
      Hz_99,
      Hz_44,
      Hz_21,
      Hz_10,
      Hz_5,
      Hz_420) with Size => 3;
   type Accel_Configuration_2 is record
      Reserved_4_7 : Bits_4 := 0;
      ACCEL_FCHOICE_B : Bit := 0;
      A_DLPFCFG : Accel_Bandwidth := Hz_218_A;
   end record with Size => 8;
   for Accel_Configuration_2 use record
      Reserved_4_7 at 0 range 4 .. 7;
      ACCEL_FCHOICE_B at 0 range 3 .. 3;
      A_DLPFCFG at 0 range 0 .. 2;
   end record;
   function Convert is new Ada.Unchecked_Conversion (Accel_Configuration_2,
                                                     Interfaces.Unsigned_8);
   ACCEL_CONFIG_2 : constant := 29;

   type Low_Power_Accel_Output_Data_Rate is record
      Reserved_4_7 : Bits_4 := 0;
      Lposc_Clksel : Bits_4 := 0;
   end record with Size => 8;
   for Low_Power_Accel_Output_Data_Rate use record
      Reserved_4_7 at 0 range 4 .. 7;
      Lposc_Clksel at 0 range 0 .. 3;
   end record;
   function Convert is new Ada.Unchecked_Conversion
     (Low_Power_Accel_Output_Data_Rate, Interfaces.Unsigned_8);
   LP_ACCEL_ODR : constant := 30;

   subtype Wake_On_Motion_Threshold is Interfaces.Unsigned_8;
   WOM_THR : constant := 31;

   type FIFO_Enable is record
      TEMP_FIFO_EN : Bit := 0;
      GYRO_XOUT : Bit := 0;
      GYRO_YOUT : Bit := 0;
      GYRO_ZOUT : Bit := 0;
      ACCEL : Bit := 0;
      SLV2 : Bit := 0;
      SLV1 : Bit := 0;
      SLV0 : Bit := 0;
   end record with Size => 8;
   for FIFO_Enable use record
      TEMP_FIFO_EN at 0 range 7 .. 7;
      GYRO_XOUT at 0 range 6 .. 6;
      GYRO_YOUT at 0 range 5 .. 5;
      GYRO_ZOUT at 0 range 4 .. 4;
      ACCEL at 0 range 3 .. 3;
      SLV2 at 0 range 2 .. 2;
      SLV1 at 0 range 1 .. 1;
      SLV0 at 0 range 0 .. 0;
   end record;
   function Convert is new Ada.Unchecked_Conversion (FIFO_Enable,
                                                     Interfaces.Unsigned_8);
   FIFO_EN : constant := 35;

   type I2C_Master_Clock is
     (K_348,
      K_333,
      K_320,
      K_308,
      K_296,
      K_286,
      K_276,
      K_267,
      K_258,
      K_500,
      K_471,
      K_444,
      K_421,
      K_400,
      K_381,
      K_364) with Size => 4;
   for I2C_Master_Clock use
     (K_348 => 0,
      K_333 => 1,
      K_320 => 2,
      K_308 => 3,
      K_296 => 4,
      K_286 => 5,
      K_276 => 6,
      K_267 => 7,
      K_258 => 8,
      K_500 => 9,
      K_471 => 10,
      K_444 => 11,
      K_421 => 12,
      K_400 => 13,
      K_381 => 14,
      K_364 => 15);

   type I2C_Master_Control is record
      MULT_MST_EN : Bit := 0;
      WAIT_FOR_ES : Bit := 0;
      SLV_3_FIFO_EN : Bit := 0;
      I2C_MST_P_NSR : Bit := 0;
      I2C_MST_CLK : I2C_Master_Clock := K_348;
   end record with Size => 8;
   for I2C_Master_Control use record
      MULT_MST_EN at 0 range 7 .. 7;
      WAIT_FOR_ES at 0 range 6 .. 6;
      SLV_3_FIFO_EN at 0 range 5 .. 5;
      I2C_MST_P_NSR at 0 range 4 .. 4;
      I2C_MST_CLK at 0 range 0 .. 3;
   end record;
   function Convert is new Ada.Unchecked_Conversion (I2C_Master_Control,
                                                     Interfaces.Unsigned_8);
   I2C_MST_CTRL : constant := 36;

   type I2C_Slave_Address is record
      I2C_SLV_RNW : Bit := 0;  -- 1 to read
      I2C_ID : Bits_7 := 0;
   end record with Size => 8;
   for I2C_Slave_Address use record
      I2C_SLV_RNW at 0 range 7 .. 7;
      I2C_ID at 0 range 0 .. 6;
   end record;
   function Convert is new Ada.Unchecked_Conversion (I2C_Slave_Address,
                                                     Interfaces.Unsigned_8);
   I2C_SLV0_ADDR : constant := 37;

   subtype I2C_Slave_Register is Interfaces.Unsigned_8;
      I2C_SLV0_REG : constant := 38;

   type I2C_Slave_Control is record
      I2C_SLV_EN : Bit := 0;
      I2C_SLV_BYTE_SW : Bit := 0;
      I2C_SLV_REG_DIS : Bit := 0;
      I2C_SLV_GRP : Bit := 0;
      I2C_SLV_LENG : Bits_4 := 0;
   end record with Size => 8;
   for I2C_Slave_Control use record
      I2C_SLV_EN at 0 range 7 .. 7;
      I2C_SLV_BYTE_SW at 0 range 6 .. 6;
      I2C_SLV_REG_DIS at 0 range 5 .. 5;
      I2C_SLV_GRP at 0 range 4 .. 4;
      I2C_SLV_LENG at 0 range 0 .. 3;
   end record;
   function Convert is new Ada.Unchecked_Conversion (I2C_Slave_Control,
                                                     Interfaces.Unsigned_8);
   I2C_SLV0_CTRL : constant := 39;

   I2C_SLV1_ADDR : constant := 40;
   I2C_SLV1_REG : constant := 41;
   I2C_SLV1_CTRL : constant := 42;

   I2C_SLV2_ADDR : constant := 43;
   I2C_SLV2_REG : constant := 44;
   I2C_SLV2_CTRL : constant := 45;

   I2C_SLV3_ADDR : constant := 46;
   I2C_SLV3_REG : constant := 47;
   I2C_SLV3_CTRL : constant := 48;

   I2C_SLV4_ADDR : constant := 49;
   I2C_SLV4_REG : constant := 50;

   subtype I2C_Slave4_Data_Out is Interfaces.Unsigned_8;
   I2C_SLV4_DO : constant := 51;

   type I2C_Slave4_Control is record
      I2C_SLV4_EN : Bit := 0;
      SLV4_DONE_INT_EN : Bit := 0;
      I2C_SLV4_REG_DIS : Bit := 0;
      I2C_MST_DLY : Bits_4 := 0;
   end record with Size => 8;
   for I2C_Slave4_Control use record
      I2C_SLV4_EN at 0 range 7 .. 7;
      SLV4_DONE_INT_EN at 0 range 6 .. 6;
      I2C_SLV4_REG_DIS at 0 range 5 .. 5;
      I2C_MST_DLY at 0 range 0 .. 4;
   end record;
   function Convert is new Ada.Unchecked_Conversion (I2C_Slave4_Control,
                                                     Interfaces.Unsigned_8);
   I2C_SLV4_CTRL : constant := 52;

   subtype I2C_Slave4_Data_In is Interfaces.Unsigned_8;
   I2C_SLV4_DI : constant := 53;

   type I2C_Master_Status is record
      PASS_THROUGH : Bit := 0;
      I2C_SLV4_DONE : Bit := 0;
      I2C_LOST_ARB : Bit := 0;
      I2C_SLV4_NACK : Bit := 0;
      I2C_SLV3_NACK : Bit := 0;
      I2C_SLV2_NACK : Bit := 0;
      I2C_SLV1_NACK : Bit := 0;
      I2C_SLV0_NACK : Bit := 0;
   end record with Size => 8;
   for I2C_Master_Status use record
      PASS_THROUGH at 0 range 7 .. 7;
      I2C_SLV4_DONE at 0 range 6 .. 6;
      I2C_LOST_ARB at 0 range 5 .. 5;
      I2C_SLV4_NACK at 0 range 4 .. 4;
      I2C_SLV3_NACK at 0 range 3 .. 3;
      I2C_SLV2_NACK at 0 range 2 .. 2;
      I2C_SLV1_NACK at 0 range 1 .. 1;
      I2C_SLV0_NACK at 0 range 0 .. 0;
   end record;
   function Convert is new Ada.Unchecked_Conversion (Interfaces.Unsigned_8,
                                                     I2C_Master_Status);
   I2C_MST_STATUS : constant := 54;

   type Int_Pin_Bypass_Enable is record
      ACTL : Bit := 0;
      OPEN : Bit := 0;
      LATCH_INT_EN : Bit := 0;
      INT_ANYRD_2CLEAR : Bit := 0;
      ACTL_FSYNC : Bit := 0;
      FSYNC_INT_MODE_EN : Bit := 0;
      BYPASS_EN : Bit := 0;
      Reserved_0_0 : Bit := 0;
   end record with Size => 8;
   for Int_Pin_Bypass_Enable use record
      ACTL at 0 range 7 .. 7;
      OPEN at 0 range 6 .. 6;
      LATCH_INT_EN at 0 range 5 .. 5;
      INT_ANYRD_2CLEAR at 0 range 4 .. 4;
      ACTL_FSYNC at 0 range 3 .. 3;
      FSYNC_INT_MODE_EN at 0 range 2 .. 2;
      BYPASS_EN at 0 range 1 .. 1;
      Reserved_0_0 at 0 range 0 .. 0;
   end record;
   function Convert is new Ada.Unchecked_Conversion (Int_Pin_Bypass_Enable,
                                                     Interfaces.Unsigned_8);
   INT_PIN_CFG : constant := 55;

   INT_ENABLE : constant := 56;
   INT_STATUS : constant := 58;

   subtype Accel_Out is Interfaces.Unsigned_8;
   ACCEL_XOUT_H : constant := 59;
   ACCEL_XOUT_L : constant := 60;
   ACCEL_YOUT_H : constant := 61;
   ACCEL_YOUT_L : constant := 62;
   ACCEL_ZOUT_H : constant := 63;
   ACCEL_ZOUT_L : constant := 64;

   subtype Temp_Out is Interfaces.Unsigned_8;
   TEMP_OUT_H : constant := 65;
   TEMP_OUT_L : constant := 66;

   subtype Gyro_Out is Interfaces.Unsigned_8;
   GYRO_XOUT_H : constant := 67;
   GYRO_XOUT_L : constant := 68;
   GYRO_YOUT_H : constant := 69;
   GYRO_YOUT_L : constant := 70;
   GYRO_ZOUT_H : constant := 71;
   GYRO_ZOUT_L : constant := 72;

   subtype External_Sensor_Data is SPI.Byte_Array (0 .. 23);
   EXT_SENS_DATA : constant := 73;

   subtype I2C_Data_Out is Interfaces.Unsigned_8;
   I2C_SLV0_DO : constant := 99;

   --  XXX GAP

   type User_Control is record
      Reserved_7_7 : Bit := 0;
      FIFO_EN : Bit := 0;
      I2C_MST_EN : Bit := 0;
      I2C_IF_DIS : Bit := 0;
      Reserved_3_3 : Bit := 0;
      FIFO_RST : Bit := 0;
      I2C_MST_RST : Bit := 0;
      SIG_COND_RST : Bit := 0;
   end record with Size => 8;
   for User_Control use record
      Reserved_7_7 at 0 range 7 .. 7;
      FIFO_EN at 0 range 6 .. 6;
      I2C_MST_EN at 0 range 5 .. 5;
      I2C_IF_DIS at 0 range 4 .. 4;
      Reserved_3_3 at 0 range 3 .. 3;
      FIFO_RST at 0 range 2 .. 2;
      I2C_MST_RST at 0 range 1 .. 1;
      SIG_COND_RST at 0 range 0 .. 0;
   end record;
   function Convert is new Ada.Unchecked_Conversion (User_Control,
                                                     Interfaces.Unsigned_8);
   USER_CTRL : constant := 106;

   type Power_Management_1 is record
      H_RESET : Bit := 0;
      SLEEP : Bit := 0;
      CYCLE : Bit := 0;
      GYRO_STANDBY : Bit := 0;
      PD_PTAT : Bit := 0;
      CLKSEL : Bits_3 := 0;
   end record with Size => 8;
   for Power_Management_1 use record
      H_RESET at 0 range 7 .. 7;
      SLEEP at 0 range 6 .. 6;
      CYCLE at 0 range 5 .. 5;
      GYRO_STANDBY at 0 range 4 .. 4;
      PD_PTAT at 0 range 3 .. 3;
      CLKSEL at 0 range 0 .. 2;
   end record;
   function Convert is new Ada.Unchecked_Conversion (Power_Management_1,
                                                     Interfaces.Unsigned_8);
   PWR_MGMT_1 : constant := 107;

   type Power_Management_2 is record
      Reserved_6_7 : Bits_2 := 0;
      DISABLE_XA : Bit := 0;
      DISABLE_YA : Bit := 0;
      DISABLE_ZA : Bit := 0;
      DISABLE_XG : Bit := 0;
      DISABLE_YG : Bit := 0;
      DISABLE_ZG : Bit := 0;
   end record with Size => 8;
   for Power_Management_2 use record
      Reserved_6_7 at 0 range 6 .. 7;
      DISABLE_XA at 0 range 5 .. 5;
      DISABLE_YA at 0 range 4 .. 4;
      DISABLE_ZA at 0 range 3 .. 3;
      DISABLE_XG at 0 range 2 .. 2;
      DISABLE_YG at 0 range 1 .. 1;
      DISABLE_ZG at 0 range 0 .. 0;
   end record;
   function Convert is new Ada.Unchecked_Conversion (Power_Management_2,
                                                     Interfaces.Unsigned_8);
   PWR_MGMT_2 : constant := 108;

   subtype Device_Identity is Interfaces.Unsigned_8;
   WHOAMI : constant := 117;

   subtype Accelerometer_Offset_High is Interfaces.Integer_8;
   type Accelerometer_Lower_Offset is mod 2 ** 7 with Size => 7;
   type Accelerometer_Offset_Low is record
      XA_OFFS : Accelerometer_Lower_Offset := 0;
      Reserved_0_0 : Bit := 0;
   end record with Size => 8;
   for Accelerometer_Offset_Low use record
      XA_OFFS at 0 range 1 .. 7;
      Reserved_0_0 at 0 range 0 .. 0;
   end record;
   function Convert is new Ada.Unchecked_Conversion (Interfaces.Unsigned_8,
                                                     Accelerometer_Offset_Low);
   XA_OFFS_H : constant := 119;
   XA_OFFS_L : constant := 120;
   YA_OFFS_H : constant := 122;
   YA_OFFS_L : constant := 123;
   ZA_OFFS_H : constant := 125;
   ZA_OFFS_L : constant := 126;

   --------------
   --  AK8963  --
   --------------

   AK8963_ID : constant := 16#0c#;

   subtype AK8963_Register is Interfaces.Unsigned_8 range 0 .. 18;

   subtype Raw_Magnetometer_Registers is SPI.Byte_Array (0 .. 18);

   subtype Device_ID is Interfaces.Unsigned_8;

   subtype Information is Interfaces.Unsigned_8;

   type Status_1 is record
      Reserved_2_7 : Bits_6 := 0;
      DOR : Bit := 0;
      DRDY : Bit := 0;
   end record with Size => 8;
   for Status_1 use record
      Reserved_2_7 at 0 range 2 .. 7;
      DOR at 0 range 1 .. 1;
      DRDY at 0 range 0 .. 0;
   end record;
   function Convert is new Ada.Unchecked_Conversion (Interfaces.Unsigned_8,
                                                     Status_1);

   subtype Low_Byte is Interfaces.Unsigned_8;
   subtype High_Byte is Interfaces.Integer_8;

   type Status_2 is record
      Reserved_5_7 : Bits_3 := 0;
      BITM : Bit := 0;
      HOFL : Bit := 0;
      Reserved_0_2 : Bits_3 := 0;
   end record with Size => 8;
   for Status_2 use record
      Reserved_5_7 at 0 range 5 .. 7;
      BITM at 0 range 4 .. 4;
      HOFL at 0 range 3 .. 3;
      Reserved_0_2 at 0 range 0 .. 2;
   end record;
   function Convert is new Ada.Unchecked_Conversion (Interfaces.Unsigned_8,
                                                     Status_2);

   type Operation_Mode_Setting is
     (Power_Down,
      Single_Measurement,
      Continuous_Measurement_1,
      External_Trigger_Measurement,
      Continuous_Measurement_2,
      Self_Test,
      Fuse_ROM_Access) with Size => 4;
   for Operation_Mode_Setting use
     (Power_Down                   => 2#0000#,
      Single_Measurement           => 2#0001#,
      Continuous_Measurement_1     => 2#0010#,
      Continuous_Measurement_2     => 2#0110#,
      External_Trigger_Measurement => 2#0100#,
      Self_Test                    => 2#1000#,
      Fuse_ROM_Access              => 2#1111#);

   type Control_1 is record
      Reserved_5_7 : Bits_3 := 0;
      BITS : Bit := 0;
      MODE : Operation_Mode_Setting := Power_Down;
   end record with Size => 8;
   for Control_1 use record
      Reserved_5_7 at 0 range 5 .. 7;
      BITS at 0 range 4 .. 4;
      MODE at 0 range 0 .. 3;
   end record;
   function Convert is new Ada.Unchecked_Conversion (Control_1,
                                                     Interfaces.Unsigned_8);

   type Control_2 is record
      Reserved_1_7 : Bits_7 := 0;
      SRST : Bit := 0;
   end record with Size => 8;
   for Control_2 use record
      Reserved_1_7 at 0 range 1 .. 7;
      SRST at 0 range 0 .. 0;
   end record;
   function Convert is new Ada.Unchecked_Conversion (Control_2,
                                                     Interfaces.Unsigned_8);

   type Self_Test_Control is record
      Reserved_7_7 : Bit := 0;
      SELF : Bit := 0;
      Reserved_0_5 : Bits_6 := 0;
   end record;
   for Self_Test_Control use record
      Reserved_7_7 at 0 range 7 .. 7;
      SELF at 0 range 6 .. 6;
      Reserved_0_5 at 0 range 0 .. 5;
   end record;
   function Convert is new Ada.Unchecked_Conversion (Self_Test_Control,
                                                     Interfaces.Unsigned_8);

   --  Not going to define Test 1, 2 or I2C Disable.

   subtype Sensitivity_Adjustment is Interfaces.Integer_8;

   --  AK8963 registers

   WIA   : constant := 16#00#;
   INFO  : constant := 16#01#;
   ST1   : constant := 16#02#;
   HXL   : constant := 16#03#;
   HXH   : constant := 16#04#;
   HYL   : constant := 16#05#;
   HYH   : constant := 16#06#;
   HZL   : constant := 16#07#;
   HZH   : constant := 16#08#;
   ST2   : constant := 16#09#;
   CNTL1 : constant := 16#0a#;
   CNTL2 : constant := 16#0b#;
   ASTC  : constant := 16#0c#;
   ASAX  : constant := 16#10#;
   ASAY  : constant := 16#11#;
   ASAZ  : constant := 16#12#;

end SPI1.MPU9250_Registers;
