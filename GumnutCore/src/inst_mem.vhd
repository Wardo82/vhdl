library ieee;
use ieee.std_logic_1164.all, ieee.numeric_std.all;

use work.core_buses.inst_mem_bus_in_type, work.core_buses.inst_mem_bus_out_type;

entity inst_mem is
    generic ( IMem_file_name: string := "gasm_text.data" );
    port (
        clk_i: in std_ulogic;
        inst_mem_bus_out: out inst_mem_bus_in_type; -- What comes "in" to the core, goes "out" of the inst_mem
        inst_mem_bus_in: in inst_mem_bus_out_type -- What comes "out" of the core, comes "in" to the inst_mem
    );
end entity inst_mem;