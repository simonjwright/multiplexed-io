--  Demonstration code for the AdaPilot project
--  (http://adapilot.likeabird.eu).
--  Copyright (C) 2016 Simon Wright <simon@pushface.org>

package SPI1.MPU9250
with
  SPARK_Mode => On,
  Elaborate_Body
is

   MPU9250_Device_Identified : Boolean := False;
   MPU9250_Ok : Boolean := False;

   AK8963_Device_Identified : Boolean := False;
   AK8963_Ok : Boolean := False;

   type Coordinate is (X, Y, Z);

   type Coordinates is array (Coordinate) of Float;

   --  G
   Accelerations : Coordinates := (others => 0.0);

   --  Degrees/sec
   Gyro_Rates : Coordinates := (others => 0.0);

   --  milliGauss
   Magnetic_Fields : Coordinates := (others => 0.0);

end SPI1.MPU9250;
