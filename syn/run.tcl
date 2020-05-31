read_verilog ../RNN.v
source RNN.sdc
compile_ultra

write_sdf -version 2.1 ./RNN_syn.sdf
write -hierarchy -format verilog -output ../RNN_syn.v
write -hierarchy -format ddc -output ./RNN_syn.ddc
report_area -nosplit -hierarchy > ./RNN_syn.area.rpt
report_timing > ./RNN_syn.timing.rpt
exit
