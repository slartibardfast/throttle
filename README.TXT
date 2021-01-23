throttle source code
jeff leyda
jeff@silent.net

released 3-24-04 to the public domain

welcome, oh brave soul, to the source code for throttle.

Here's the file breakdown:
CMDLINE  ASM         command line parsing routines
CONSTANT INC         stuff that never changes
EQUATES  INC         vendor IDs and handy things
MACROS   INC         macros for quick text printing
MAKEFILE             build instructions for masm
MISC     ASM         converters, printers, whatever
PCI      ASM         PCI reader/writers/scanners
README   TXT         right here baby!
SBSTRUC  ASM         structures for all the known southbridges
SOUTHB   ASM         helper routines for manipulating southbridges
THROTTLE ASM         main executable
THPIIX4E ASM         main executable modified for PIIX4E
SBPIIX4E ASM         structures for all the known southbridges modified for PIIX4E


The concept behind throttle is quite simple.  Just tweak the ACPI processor
control register to change the throttle value, and then enable it.
It's literally 4 bits of a single I/O register that need to be changed.

The problem and bulk of throttle's code is locating WHERE that darn ACPI
base address is.  Since throttle works under windows, it's impossible for
it to scan through upper memory to locate the ACPI FAC tables to get the
base address that way, so I went the route of IDing the southbridge that
actually contains the base address registers and fetching them out of PCI.

Throttle is quickly dying of old age.  As CPU speeds reach 2 and 3GHz and
higher, even maximum throttling can barely make a dent.

Back in the days when 800MHz was screaming, it was possible to get a machine
to perform as slowly as a 286 using throttle.  Now a high end machine still
acts like a high end machine, even at maximum throttling.
Oh well, we had a good run.  Until hardware changes to give us more options,
there's not much more that can be done.


I'm still willing to support throttle on newer chipsets, just email me and
ask.  Otherwise, take this code and tweak it yourself.  Please send me the
changes, and if they're good, I'll officially add them to the core and update
the site.

have fun,

-jeff!
