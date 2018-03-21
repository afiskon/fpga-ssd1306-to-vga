# fpga-ssd1306-to-vga

ICE40 FPGA configuration: SSD1306 to VGA converter.

Tested on iCEstick (ICE40HX1K) and Blue Pill development board
(STM32F103C8T6) running `examples/spi/stm32f1` from
[afiskon/stm32-ssd1306](https://github.com/afiskon/stm32-ssd1306) library.

The code is based on [uXeBoy/VGA1306](https://github.com/uXeBoy/VGA1306)
developed by Dan O'Shea ( [@uXeBoy](https://github.com/uXeBoy) ) in 2018.
Original code targeted BlackIce II and didn't work with iCEstick + STM32 setup
until some refactorings were made.
