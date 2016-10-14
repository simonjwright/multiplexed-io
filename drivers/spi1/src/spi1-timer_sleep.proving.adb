--  Demonstration code for the AdaPilot project
--  (http://adapilot.likeabird.eu).
--  Copyright (C) 2016 Simon Wright <simon@pushface.org>

--  This version is for use with gnatprove (the real code uses an
--  interrupt which is unknown to the normal RTS that gnatprove uses -
--  unless you tell it the actual location of your RTS - one could
--  maybe include the RTS inside gnatprove's library?).

package body SPI1.Timer_Sleep
is

   procedure Sleep (For_Interval : Duration)
   is
   begin
      null;
   end Sleep;

end SPI1.Timer_Sleep;
