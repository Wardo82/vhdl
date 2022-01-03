library ieee;
use ieee.std_logic_1164.all, ieee.numeric_std.all;

use work.core_buses.all;

entity gumnut_system is
    generic ( 
        IMem_file_name: string := "gasm_text.data";
        DMem_file_name: string := "gasm_data.dat";
        debug: boolean := false 
    );
    port( 
        clk_i: in std_ulogic;
        rst_i: in std_ulogic;
        -- I/O port bus
        io_port_bus_in: in io_port_bus_in_type;
        io_port_bus_out: out io_port_bus_out_type;
        -- Interrupts
        interrupt_bus_in: in interrupt_bus_in_type;
        interrupt_bus_out: out interrupt_bus_out_type
    );
end entity gumnut_system;

architecture struct of gumnut_system is
    
    -- Instruction memory bus
    signal inst_mem_bus_in: inst_mem_bus_in_type;
    signal inst_mem_bus_out: inst_mem_bus_out_type;
    -- Data memory bus
    signal data_mem_bus_in: data_mem_bus_in_type;
    signal data_mem_bus_out: data_mem_bus_out_type;
     
    component gumnut 
    generic( debug: boolean:= false );
    port(
        clk_i : in std_ulogic;
        rst_i : in std_ulogic;
        -- Instuction memory bus
        inst_mem_bus_in: in inst_mem_bus_in_type;
        inst_mem_bus_out: out inst_mem_bus_out_type;
        -- Data memory bus
        data_mem_bus_in: in data_mem_bus_in_type;
        data_mem_bus_out: out data_mem_bus_out_type;
        -- I/O port bus
        io_port_bus_in: in io_port_bus_in_type;
        io_port_bus_out: out io_port_bus_out_type;
        -- Interrupts
        interrupt_bus_in: in interrupt_bus_in_type;
        interrupt_bus_out: out interrupt_bus_out_type
    );
    end component gumnut;

    component inst_mem is
        generic ( IMem_file_name: string );
        port (
            clk_i: in std_ulogic;
            inst_mem_bus_out: out inst_mem_bus_in_type; -- What comes "in" to the core, goes "out" of the inst_mem
            inst_mem_bus_in: in inst_mem_bus_out_type -- What comes "out" of the core, comes "in" to the inst_mem
        );
    end component inst_mem;

    component data_mem is
        generic ( DMem_file_name: string);
        port(
            clk_i: in std_ulogic;
            data_mem_bus_out: out data_mem_bus_in_type; -- What comes "in" to the core, goes "out" of the data_mem
            data_mem_bus_in: in data_mem_bus_out_type -- What comes "out" of the core, comes "in" to the data_mem
        );
    end component data_mem;

begin

    core: component gumnut 
        generic map (debug => debug)
        port map(
            clk_i => clk_i,
            rst_i => rst_i,
            -- Instuction memory bus
            inst_mem_bus_in => inst_mem_bus_in,
            inst_mem_bus_out => inst_mem_bus_out,
            -- Data memory bus
            data_mem_bus_in => data_mem_bus_in,
            data_mem_bus_out => data_mem_bus_out,
            -- I/O port bus
            io_port_bus_in => io_port_bus_in,
            io_port_bus_out => io_port_bus_out,
            -- Interrupts
            interrupt_bus_in => interrupt_bus_in,
            interrupt_bus_out => interrupt_bus_out
        );

    core_inst_mem: component inst_mem
        generic map ( IMem_file_name => IMem_file_name )
        port map (
            clk_i => clk_i,
            inst_mem_bus_out => inst_mem_bus_in, -- What comes "in" to the core, goes "out" of the inst_mem
            inst_mem_bus_in => inst_mem_bus_out -- What comes "out" of the core, comes "in" to the inst_mem
        );

    core_data_mem: component data_mem
        generic map ( DMem_file_name => DMem_file_name)
        port map (
            clk_i => clk_i,
            data_mem_bus_out => data_mem_bus_in, -- What comes "in" to the core, goes "out" of the data_mem
            data_mem_bus_in => data_mem_bus_out -- What comes "out" of the core, comes "in" to the data_mem
        );

end architecture struct;