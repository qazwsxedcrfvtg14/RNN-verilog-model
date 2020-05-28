# You can only modify clock period 


set cycle 100

set t_in [expr $cycle/2]
set t_out  0.5 

# Constraint setting 
# Clock constraints 
#create_clock -name clk -period $cycle [get_ports clk] 
create_clock            -period $cycle [get_ports clk] 
set_fix_hold                          [get_clocks clk]                                     ;# remove while P&R 
set_dont_touch_network                [get_clocks clk]                                     ;# remove while P&R 
set_ideal_network                     [get_ports clk]                                      ;# remove while P&R 
set_clock_uncertainty            0.1  [get_clocks clk] 
set_clock_latency                0.5  [get_clocks clk] 

#Other Constraints 
#set_max_fanout 6 [all_inputs] 


#Don't touch the basic env setting as below
set_operating_conditions -max_library slow -max slow
set_drive        1     [all_inputs]                                                        ;# DC w IOpad 
set_load         1     [all_outputs]                                                       ;# DC w IOpad 
set_input_delay   $t_in  -clock clk [remove_from_collection [all_inputs] [get_ports clk]] 
set_output_delay  $t_out -clock clk [all_outputs] 
#set_wire_load_model -name tsmc13_wl10 -library slow                                        ;# remove while P&R 
  


# additional (may cause problem)
#set_input_transition   0.5     [all_inputs]
#set_clock_transition   0.1     [all_clocks]












                     

