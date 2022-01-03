library ieee;
use ieee.std_logic_1164.all, ieee.numeric_std.all;

use work.core_buses.data_mem_bus_in_type, work.core_buses.data_mem_bus_out_type;

entity data_mem is
    generic ( DMem_file_name: string := "gasm_data.dat");
    port(
        clk_i: in std_ulogic;
        data_mem_bus_out: out data_mem_bus_in_type; -- What comes "in" to the core, goes "out" of the data_mem
        data_mem_bus_in: in data_mem_bus_out_type -- What comes "out" of the core, comes "in" to the data_mem
    );
end entity data_mem;