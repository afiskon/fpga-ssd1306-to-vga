#!/bin/sh

set -e

./clean.sh

yosys -p "synth_ice40 -blif main.blif" main.sv
arachne-pnr -d 1k -p main.pcf main.blif -o main.asc
icetime -c 25 main.asc
icepack main.asc main.bin
iceprog main.bin 

