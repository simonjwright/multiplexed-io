# multiplexed-io

This contains explorations, for
[AdaPilot](http://adapilot.likeabird.eu), of implementing drivers for
the AdaRacer MCU, using the Ravenscar profile of Ada 2012 from
[AdaCore](http://libre.adacore.com) and device bindings generated
using [SVD2Ada](https://github.com/AdaCore/svd2ada).

The structure corresponds to that proposed for the main AdaPilot repository.

## Proof

Of particular interest is how "near the metal" we can get code that
can be processed by
[SPARK GPL](http://libre.adacore.com/tools/spark-gpl-edition/) (2016).

The [Ada Drivers Library](https://github.com/AdaCore/Ada_Drivers_Library) imposes quite a lot of code between applications and the hardware, and that code is not in SPARK ([nor is a move in this direction planned](https://github.com/AdaCore/Ada_Drivers_Library/issues/13)).

The code here provides minimal layers between applications and hardware.

### Volatility

A major problem is dealing with _volatile_ objects.

The device bindings declare registers as `Volatile_Full_Access`, which allows you to write code like

       bitfield_of_component := value;

which looks great, but under the hood GNAT implements this as

       local_variable := register;
       bitfield_of_local_variable := value;
       register := local_variable;

and suffers the usual concurrency-related problems. The only apparent solution is to mark the subprograms that have to modify device registers as being out of SPARK (`pragma SPARK_Mode (Off);`), and supply alternative reasoning to justify the code (I haven't done this :-).

## Concurrent access

We have two devices using SPI2, the BARO (MS5611) and the FRAM (FM25V02). It is absolutely vital that they don't interfere with each other.

One approach would be to arrange a schedule so that each device is given its own time slot(s). That would be fine for the MS5611 on its own - bearing in mind that it requres two accesses to perform a measurement, the first to start the process and the second to fetch the result, which must occur after an interval depending on the measurement precision (9 ms for the highest precision). However the purpose of the FRAM is to store application parameters and checkpoint data, which might be quite hard to schedule with the MS5611.

Here, I've used an Ada protected object. To write a command and its parameter, and retrieve the associated data, is performed within one protected action, so that other Ada tasks that try to access the same SPI will be blocked. One might want to arrange that these activities take place at a lower priority than others (RMA scheduling, perhaps). Timing remains to be done.

## GNAT Project Files

Each component directory has three [GNAT Project](http://docs.adacore.com/gprbuild-docs/html/gprbuild_ug.html) (`.gpr`) files (actually, the `test` directory breaks this to some extent):

  * <tt><i>component</i>_build.gpr</tt> calls <tt><i>component</i>.gpr</tt> to build this component for the selected RTS (and MCU),
  * <tt><i>component</i>.gpr</tt> builds the component, calling in the GPRs of other components as required,
  * <tt><i>component</i>_gnatprove.gpr</tt> is for use with *gnatprove*.

The RTS/MCU selection supports building either

  * for the AdaRacer platform (with the scenario variable `RTS` set to, or left at, its default (`adaracer`)), using the `ravenscar-sfp-adaracer` runtime,
  * for the [STM32F4Discovery](http://www.st.com/content/ccc/resource/technical/document/data_brief/09/71/8c/4e/e4/da/4b/fa/DM00037955.pdf/files/DM00037955.pdf/jcr:content/translations/en.DM00037955.pdf) kit (with the scenario variable `RTS` set to `stm32f4`), using the `ravenscar-sfp-stm32f4` runtime.

The reason for a separate <tt><i>component</i>_gnatprove.gpr</tt> is that *gnatprove* doesn't understand runtime or target settings within a GPR; proof is essentially platform-independent, so it's OK to use the host runtime.

## Device variants

AdaRacer uses two of the six SPI peripherals on STM32F42[79] MCUs, which means that there is considerable commonality between the code for SPI1 and SPI2. Trying to address this using a generic resulted in a lot of problems at the proof stage, so instead this work uses template processing with <i>[gnatprep](https://gcc.gnu.org/onlinedocs/gnat_ugn/Preprocessing-with-gnatprep.html#17)</i>.

Preprocessing is triggered by `make sources`, and the results have been checked into the repository; see `drivers/spi/`, `drivers/spi1`, and `drivers/spi2`.

GNAT has a facility to [integrate preprocessing](https://gcc.gnu.org/onlinedocs/gnat_ugn/Integrated-Preprocessing.html#18), but it seems unlikely that this will work well with *gnatprove*.
