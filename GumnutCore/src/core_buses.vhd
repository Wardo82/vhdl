library ieee;
use ieee.std_logic_1164.all, ieee.numeric_std.all;

package core_buses is 
-- Bus  declaration
    -- Instruction memory bus
    type inst_mem_bus_in_type is record
        ack: std_ulogic;
        data: std_ulogic_vector(17 downto 0);
    end record;
    type inst_mem_bus_out_type is record
        cyc: std_ulogic;
        stb: std_ulogic;
        adr: unsigned(11 downto 0);
    end record;
    -- Data memory bus
    type data_mem_bus_in_type is record
        ack: std_ulogic;
        data: std_ulogic_vector(7 downto 0);
    end record;
    type data_mem_bus_out_type is record
        cyc: std_ulogic;
        stb: std_ulogic;
        we: std_ulogic;
        adr: unsigned(7 downto 0);
        data: std_ulogic_vector(7 downto 0);
    end record;
    -- I/O port bus
    type io_port_bus_in_type is record
        ack: std_ulogic;
        data: std_ulogic_vector(7 downto 0);
    end record;
    type io_port_bus_out_type is record
        cyc: std_ulogic;
        stb: std_ulogic;
        we: std_ulogic;
        adr: unsigned(7 downto 0);
        data: std_ulogic_vector(7 downto 0);
    end record;
    -- Interrupts
    type interrupt_bus_in_type is record
        req: std_ulogic;
    end record;
    type interrupt_bus_out_type is record
        ack: std_ulogic;
    end record;

-- Compoment declaration
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
end package;