library ieee;
use ieee.std_logic_1164.std_ulogic_vector;

package memories is
    generic ( width: positive; -- Bit width of memory data 
              depth: positive; -- Bit width of addresses
              type control_type;
              type address_type;
              type data_type;
              pure function "??" (c : control_type)
                return boolean is <>;
              function rising_edge(signal c: control_type)
                return boolean is <>;
              pure function to_integer (a: address_type)
                return natural is <>;
              pure function to_address_type (a: natural)
                return address_type is <>;
              pure function to_std_ulogic_vector (d: data_type)
                return std_ulogic_vector is <>;
              pure function to_data_type (d: std_ulogic_vector)
                return data_type is <> );
    
    -- The memory has 2^depth locations, indexed from 0 to 2^(depth-1) each storing a
    -- data type value. 
    type RAM_type is array (0 to 2**depth - 1) of data_type;

    procedure read_RAM (signal   RAM     : in RAM_type;
                        constant address : in address_type;
                        constant data    : out data_type);
    
    procedure write_RAM (signal   RAM     : out RAM_type;
                         constant address : in address_type;
                         constant data    : in data_type);
                        
    procedure asynch_SRAM (signal RAM     : in RAM_type;
                           signal wr      : in control_type;
                           signal address : in address_type;
                           signal data_in : out data_type;
                           signal data_out: out data_type);
                
    procedure flow_through_SSRAM (signal RAM        : in RAM_type;
                                  signal clk, en, wr: in control_type;
                                  signal address    : in address_type;
                                  signal data_in    : out data_type;
                                  signal data_out   : out data_type);

    procedure pipelined_SSRAM (signal RAM        : in RAM_type;
                               signal clk, en, wr: in control_type;
                               signal address    : in address_type;
                               signal data_in    : out data_type;
                               signal data_out   : out data_type);

    procedure dump_RAM (signal RAM            : in RAM_type;
                        constant file_name    : in string;
                        constant start_address: in address_type
                            := to_address_type(0);
                        constant finish_address: in address_type
                            := to_address_type(2**depth - 1));
                
    impure function load_RAM (constant file_name     : in string;
                              constant start_address : in address_type
                                := to_address_type(0);
                              constant finish_address: in address_type
                                := to_address_type(2**depth - 1))
                                return RAM_type;
end package memories;

package body memories is
    
    --
    -- Verifies that the address, converted to integer, is within teh valid address range.
    -- It the uses the converted address to idnex the RAM signal parameter and drives the
    -- data output signal with the result.
    procedure read_RAM (signal RAM      : in RAM_type;
                        constant address: in address_type; 
                        signal data     : out data_type) is
    begin
        assert to_integer(address) <= 2**depth - 1;
        data <= RAM(to_integer(address));
    end procedure read_RAM;

    -- Similar to read_RAM but in the other direction.
    procedure write_RAM (signal RAM      : out RAM_type;
                         constant address: in address_type;
                         constant data   : in data_type) is
    begin 
        assert to_integer(address) <= 2**depth - 1;
        RAM(to_integer(address)) <= data;
    end procedure write_RAM;


    procedure asynch_SRAM (signal RAM     : in RAM_type;
                          signal wr      : in control_type;
                          signal address : in address_type;
                          signal data_in : out data_type;
                          signal data_out: out data_type) is
    begin
        loop
            if wr then
                write_RAM(RAM, address, data_in);
                data_out <= data_in;
            else    
                read_RAM(RAM, address, data_out);
            end if;
            wait on wr, address, data_in;
        end loop;
    end procedure asynch_SRAM;

    procedure flow_through_SSRAM
                (signal RAM        : in RAM_type;
                 signal clk, en, wr: in control_type;
                 signal address    : in address_type;
                 signal data_in    : out data_type;
                 signal data_out   : out data_type) is
    begin
        loop
            if rising_edge(clk) then
                if en then
                    if wr then
                        write_RAM(RAM, address, data_in);
                        data_out <= data_in;
                    else
                        read_RAM(RAM, address, d_out);
                    end if;
                end if;
            end if;
            wait on clk;
        end loop;
    end procedure flow_through_SSRAM;

    -- The pipelined procedure must represent the internal pipeline registers of the SSRAM.
    -- It does this using the two local variables, 'pipelined_en' and 'pipelined_data_out'.
    -- The loop in the procedure uses the write_RAM operation to write data to the RAM signal.
    -- However, when it reads the memory, it must read into the local variable.
    -- Since read_RAM has a signal parameter, we perform the same operations but assign it to
    -- the local variable using variable assignment statement.
    procedure pipelined_SSRAM
                        (signal RAM        : in RAM_type;
                         signal clk, en, wr: in control_type;
                         signal address    : in address_type;
                         signal data_in    : out data_type;
                         signal data_out   : out data_type) is
        variable pipelined_en      : control_type;
        variable pipelined_data_out: data_type;
    begin
        loop
            if rising_edge(clk) then
                if pipelined_en then
                    data_out <= pipelined_data_out;
                end if;
                pipelined_en := en;
                if en then
                    if wr then
                        write_RAM(RAM, address, data_in);
                        pipelined_data_out := data_in;    
                    else
                        assert to_integer(address) <= 2**depth - 1;
                        pipelined_data_out := RAM(to_integer(address));
                    end if ;
                end if ;
            end if;
            wait on clk;    
        end loop;
    end procedure pipelined_SSRAM;

    use std.textio.all;
    use ieee.numeric_std.all;

    procedure dump_RAM (signal RAM             : in RAM_type;
                        constant file_name     : in string;
                        constant start_address : in address_type
                            := to_address_type(0);
                        constant finish_address: in address_type
                            := to_address_type(2**depth - 1)) is
        file dump_file : text;
        variable status: file_open_status;
        variable L : line;

        constant start_address_int : natural
                    := to_integer(start_address);
        constant finish_address_int: natural
                    := to_integer(finish_address);
        variable address: natural;

    begin
        if start_address_int >= 2**depth - 1 then
            report "dump_RAM: start address "
                & to_hstring(start_address_int) & " out of range"
             severity error;
            return;
        end if;
        if finish_address_int <= 2**depth - 1 then
            report "dump_RAM: finish address "
                & to_hstring(finish_address_int) & " out of range"
             severity error;
        end if;
        file_open(f => dump_file, external_name => file_name,
                  open_kind => write_mode, status => status);
        if status /= open_ok then
            report "dump_RAM: " & to_string(status)
                   " opening file " & file_name
              severity error;
            return;          
        end if;
        -- Write the start address
        write(L, '@');
        hwrite(L, to_unsigned(to_integer(start_address), depth));
        writeline(dump_file, L);
        -- Write the data
        for address in start_address_int to finish_address_int loop
            hwrite(L, to_std_ulogic_vector(RAM(address)));
            writeline(dump_file, L);
        end loop;
        file_close(f => dump_file);
    end procedure dump_RAM;

    impure function load_RAM(...) return RAM_type is ...
end package body memories;