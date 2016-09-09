# use port 4242 to talk to st-util
target remote :4242

# load the image
load

# works with jlink
monitor reset

# works with st-util
monitor jtag_reset

# the version that comes with ravenscar-sfp-adaracer resets the board,
# which makes it a little hard to find out what's wrong
break __gnat_last_chance_handler
