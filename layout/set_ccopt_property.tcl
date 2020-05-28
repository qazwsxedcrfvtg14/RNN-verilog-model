setOptMode -usefulSkewCCOpt standard


add_ndr -name CTS_2W1S -spacing {METAL1:METAL4 0.1 METAL5:METAL6 0.2 METAL7 0.3} -width {METAL1:METAL4 0.2 METAL5:METAL6 0.4 METAL7 0.6}
add_ndr -name CTS_2W2S -spacing {METAL1:METAL4 0.2 METAL5:METAL6 0.4 METAL7 0.6} -width {METAL1:METAL4 0.2 METAL5:METAL6 0.4 METAL7 0.6}

create_route_type -name leaf_rule -non_default_rule CTS_2W1S -top_preferred_layer METAL5 -bottom_preferred_layer METAL4
create_route_type -name trunk_rule -non_default_rule CTS_2W2S -top_preferred_layer METAL7 -bottom_preferred_layer METAL6 -shield_net VSS
#-bottom_shield_net METAL6
#create_route_type -name top_rule -non_default_rule CTS_2W2S -top_preferred_layer METAL9 -bottom_preferred_layer METAL8 -shield_net VSS
#-bottom_shield_net METAL8
set_ccopt_property -net_type leaf route_type leaf_rule
set_ccopt_property -net_type trunk route_type trunk_rule
#set_ccopt_property -net_type top route_type top_rule
set_ccopt_property routing_top_min_fanout 10000


set_ccopt_property buffer_cells {BUFX12 BUFX8 BUFX6 BUFX4 BUFX2}
set_ccopt_property inverter_cells {INVX12 INVX8 INVX6 INVX4 INVX2}
#set_ccopt_property clock_gating_cells {PREICGX12 PREICGX8 PREICGX6 IPREICGX4 PREICGX2}
set_ccopt_property use_inverters true
set_ccopt_property target_max_trans 100ps
set_ccopt_property target_skew 50ps