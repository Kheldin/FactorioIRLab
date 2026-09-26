MEMORY{
    RAM (xrw) : ORIGIN = 0x20000000, LENGTH = 20k
    FLASH (rx) : ORIGIN = 0x08000000, LENGTH = 64k
}

_estack = ORIGIN(RAM) + LENGTH(RAM);

ENTRY(Reset_Handler)

SECTIONS {
    .text : {
        . = ALIGN(4);
        *(.isr_vector)
        *(.text)
        *(.rodata)
        . = ALIGN(4);
        _sidata = .;
    } > FLASH

    .data : {
        . = ALIGN(4);
        _sdata = .;
        *(.data)
        . = ALIGN(4);
        _edata = .;
    } > RAM AT> FLASH

    .bss : {
        . = ALIGN(4);
        _sbss = .;
        *(.bss)
        *(COMMON)
        . = ALIGN(4);
        _ebss = .;
    } > RAM
}