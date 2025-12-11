# GCC-RV

## RISC-V GCC toolchain setup for RIVER MCU

### Files

#### rv.sh

The main toolchain script, can be used to build single-file programs written in either assembly or C language. It allows multi-file projects to be compiled and outputed in rivctl- or memdump-ready format in a single invokation.

##### Tips

To make the script easier to use, you can define an alias in your `.bashrc`/`.profile`:

```sh
alias rv="$HOME/gcc-rv/rv.sh"
```

To see the script usage, run:

```sh
rv -h
```

##### Limitations

- linking is not possible when entry file is an assembly file
- reloc option is currently a noop

#### src/boot.s

The boot file takes care of bootstraping the MCU, initializing the stack pointer register to `0x2000` and running `main` function. It is only used when compiling C programs and contains the entry point `_start`.

#### src/sysdev.h

This header file contains all the necessary definitions of hardware devices and some useful macros; all devices are represented as structures.

##### GPIO A output

```c
gpioa->out = 0b00001010;
/* or */
gpioa->out = PIN(3) | PIN(1);
```

##### Terminal 0 print characters

```c
term0->out = 'R';
term0->out = 'V';
/* or */
PUTCHAR('R');
PUTCHAR('V');
```
