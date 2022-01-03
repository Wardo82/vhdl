library ieee;
use ieee.std_logic_1164.all, ieee.numeric_std.all;

use work.gumnut_defs.all;
use std.textio.all;

entity test is
end test;

architecture gumnut of test is
    signal syscon_clk_o : std_ulogic;
    signal syscon_rst_o : std_ulogic;
    -- I/O port bus
    signal gumnut_port_io_bus_in : io_port_bus_in_type;
    signal gumnut_port_io_bus_out :io_port_bus_out_type;
    -- Interrupts
    signal gumnut_port_interrupt_bus_in : interrupt_bus_in_type;
    signal gumnut_port_interrupt_bus_out : interrupt_bus_out_type

    component gumnut_system is
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
    end component gumnut_system;

begin
    reset_gen : syscon_rst_o <= '0',
                                '1' after 5 ns,
                                '0' after 25 ns;
    clk_gen : process
    begin 
        syscon_clk_o <= '0';
        wait for 10 ns;
        loop
            syscon_clk_o <= '1', '0' after 5 ns;
        end loop;
    end process clk_gen;

    int_gen : process
    begin
        gumnut_port_interrupt_bus_in.req <= '0';
        for int_count in 1 to 10 loop
            for cycle_count in 1 to 25 loop
                wait until falling_edge(syscon_clk_o);
            end loop;
            gumnut_port_interrupt_bus_in.req <= '1';
            wait until falling_edge(syscon_clk_o)
                        and gumnut_port_interrupt_out.ack = '1';
            gumnut_port_interrupt_bus_in.req <= '0';
        end loop
        wait;
    end process int_gen;

    io_control : process
        -- Hard-wired input stream
        constant input_data : unsigned_byte_array
            := ( X"00", X"01", X"02", X"03", X"04", X"05", X"06", X"07",
            X"08", X"09", X"0A", X"0B", X"0C", X"0D", X"0E", X"0F",
            X"10", X"11", X"12", X"13", X"14", X"15", X"16", X"17",
            X"18", X"19", X"1A", X"1B", X"1C", X"1D", X"1E", X"1F" );
        variable next_input : integer := 0;
        variable debug_line : line;
        constant show_actions : boolean := true;
    begin
        gumnut_port_io_bus_in.ack <= '0';
        loop 
            wait until falling_edge(syscon_clk_o);
            if gumnut_port_io_bus_out.cyc and gumnut_port_io_bus_out.stb then
                if to_X01(gumnut_port_io_bus_out.we) = '0' then
                    if show_actions then
                        swrite(debug_line, "IO: port read; address = ");
                        hwrite(debug_line, gumnut_port_io_bus_out.adr);
                        swrite(debug_line, ", data = ");
                        hwrite(debug_line, input_data(next_input));
                        writeline(output, debug_line);
                    end if;
                    gumnut_port_io_bus_in.data <= std_ulogic_vector(input_data(next_input));
                    next_input := (next_input + 1) mod input_data'length;
                    gumnut_port_io_bus_in.ack <= '1';
                else
                    if show_actions then
                        swrite(debug_line, "IO: port write; address = ");
                        hwrite(debug_line, gumnut_port_io_bus_out.adr);
                        swrite(debug_line, ", data = ");
                        hwrite(debug_line, gumnut_port_io_bus_out.data);
                        writeline(output, debug_line);
                    end if;
                    gumnut_port_io_bus_in.ack = '1';
                end if;
                else
                    gumnut_port_io_bus_in.ack = '0';
            end if;
        end loop;
    end process io_control;

    -- Instantiate the processor
    dut : component gumnut_system
    port map ( 
        clk_i => syscon_clk_o,
        rst_i => syscon_rst_o,
        -- I/O port bus
        io_port_bus_in    => gumnut_port_io_bus_in,
        io_port_bus_out:  => gumnut_port_io_bus_out,
        -- Interrupts
        interrupt_bus_in  => gumnut_port_interrupt_bus_in,
        interrupt_bus_out => gumnut_port_interrupt_bus_out
    );
    end component gumnut_system;
end architecture gumnut;