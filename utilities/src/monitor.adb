--  Demonstration code for the AdaPilot project
--  (http://adapilot.likeabird.eu).
--  Copyright (C) 2016 Simon Wright <simon@pushface.org>

package body Monitor is

   Current_Status : array (Device) of Status := (others => Unknown);

   procedure Set_Status (For_Device : Device; To : Status)
   is
   begin
      Current_Status (For_Device) := To;
   end Set_Status;

   function Get_Status (For_Device : Device) return Status
     is (Current_Status (For_Device));

end Monitor;
