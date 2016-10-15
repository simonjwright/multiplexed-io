# tests

This contains tests for the AdaRacer hardware.

## Building

The main test program is `adaracer_test`. It's built (provided you've
installed the Ada runtime `ravenscar-sfp-adaracer`) using the command
line

    gprbuild -p -P adaracer_test_build

(the `-p` is needed the first time to create any needed directories).

The generated executable is (normally, but see below)
`adaracer_test-adaracer`. This is compiled with debug and no
optimisation, and is ready to be loaded to the target board under the
debugger. If you want to flash it directly, create a binary image by

    arm-eabi-objcopy -O binary adaracer_test-adaracer adaracer_test-adaracer.bin

## Running

On running, the program will turn off all the LEDs. If all is well,
the green LED will light solidly after a couple of seconds. If not,
the most likely result is that the red LED will flash in one or more
of the following sequences, which cognoscenti will recognise as the
Morse code for the initial letter of the device:

  * dot dash : the accelerometer has failed
  * dash dot dot dot : the barometer has failed
  * dash dash dot : the gyro has failed
  * dash dash : the magnetometer has failed

In most cases, "failed" means the device has failed to initialize
properly.

Once the program is running properly (you will probably get some
results even if not), a terminal attached to the CLI port will show
the following menu:

                   AdaRacer Test
                   =============

    Menu

    b - BARO
    f - FRAM
    m - MPU9250

    enter your choice:

and typing the indicated letter will result in output like the following:

### Barometer

    BARO demo: reporting pressure in mB*100
    pressure: 99642
    pressure: 99643
    pressure: 99641
    pressure: 99643
    pressure: 99643
    pressure: 99642
    pressure: 99641
    pressure: 99642
    pressure: 99641
    pressure: 99641

### FRAM

    FRAM demo: writing & reading the same location
    writing 250 .. read 250
    writing 251 .. read 251
    writing 252 .. read 252
    writing 253 .. read 253
    writing 254 .. read 254
    writing 255 .. read 255
    writing 256 .. read 256
    writing 257 .. read 257
    writing 258 .. read 258
    writing 259 .. read 259

### MPU9250

    MPU9250 identified, OK, AK8963 identified, OK
    a in g*1000, g in deg/sec*100, m in milligauss (nT/100)
     a:  7  35 -1006 g: -61  67 -24 m: -651  566 -579
     a:  14  35 -995 g: -61  67 -6 m: -629  557 -579
     a:  13  33 -1001 g: -55  43 -37 m: -644  552 -586
     a:  11  33 -995 g: -55  61 -24 m: -629  552 -569
     a:  13  31 -992 g: -79  43 -24 m: -649  536 -577
     a:  11  36 -994 g: -49  49 -24 m: -646  559 -572
     a:  11  30 -991 g: -79  49 -43 m: -653  550 -553
     a:  15  33 -1000 g: -55  73 -37 m: -646  554 -560
     a:  13  34 -994 g: -61  61 -37 m: -638  561 -563
     a:  6  33 -997 g: -92  55 -24 m: -646  568 -581

Note that the magnetometer, in particular, has had no bias correction,
and that no attempt has been made to bring the results to a common
axis set.

## GNAT Project structure

The GPRs are more complex than most of us will need, so that the code
can be built for an STM32F407 Disco board (with similar devices on
breakouts). There are **three** GPRs associated with `adaracer_test`:

  * `adaracer_test_build.gpr` is the one you should use. It uses
    `../environment.gpr` to decide which Ada runtime to use,
    `adaracer` or `stm32f4`, depending on the environment (scenario)
    variable `RTS`. The default is `adaracer`.
  * `adaracer_test.gpr` is used by `adaracer_test_build.gpr`, which
    has set up the correct paths for the SVD2Ada-generated MCU support
    files.
  * `adaracer_gnatprove.gpr` is used for `gnatprove`.

A similar structure applies through the `../drivers` tree.

The `gnatprove`-related GPRs are there because (for reasons, I expect)
`gnatprove` includes its own Ada runtime structure and doesn't
understand how to find the `arm-eabi` runtimes by name alone; you'd
have to specify a full path (or, perhaps, install the `arm-eabi`
runtimes in the place where `gnatprove` does expect them?)
