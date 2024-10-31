clear -all

check_cov -init -type all -model {branch toggle statement} -toggle_ports_only

analyze -sv iter_mult.v iter_mult_tests.sv 

elaborate -top fixed_point_iterative_Multiplier_sva -create_related_covers {precondition witness}

clock clk
reset reset

check_cov -measure -type {coi proof bound}