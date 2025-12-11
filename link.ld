SECTIONS
{
  . = 0x0;
  .text :
  {
    KEEP(*(.text.boot))
    *(.text*)
  }
  .rodata : { *(.rodata*) }
  .data : { *(.data*) }
  .bss  : { *(.bss*) }
}