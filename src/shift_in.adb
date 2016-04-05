with Ada.Real_Time;
with Reporter;

procedure Shift_In is
   use type Ada.Real_Time.Time;
begin
   loop
      delay until Ada.Real_Time.Clock + Ada.Real_Time.Seconds (1);
   end loop;
end Shift_In;
