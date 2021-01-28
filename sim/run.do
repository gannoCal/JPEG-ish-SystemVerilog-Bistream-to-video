
# set up paths, top-level module, ...
do setenv.do

# compile the source files
do compile.do

# specify library for simulation
vsim -t 100ps -L altera_mf_ver -lib my_work $top

# Clear previous simulation
restart -f

# add signals to waveform
do waves.do

# run simulation
run -all

do save.do

# print simulation statistics
# simstats

