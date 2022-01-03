library ieee;
use ieee.std_logic_1164.all, ieee.numeric_std.all;

use work.core_buses.all;
use work.gumnut_defs.all;
use std.textio.all;

entity gumnut is
    generic(debug: boolean := false);
    port(
        clk_i : in std_ulogic;
        rst_i : in std_ulogic;
        -- IRuction memory bus
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
end entity gumnut;

architecture behavior of gumnut is
begin
    interpreter : process

        -- Gumnut internal registers
        variable PC: IMem_addr; -- Program counter
        variable IR: instruction; -- Intstruction register

        -- Fields of instructions of diferent formats
        -- These aliases allow us to refer easily to the fields of an instruction in
        -- order to interpret it.
        alias IR_alu_reg_fn   : alu_fn_code is IR(2 downto 0);
        alias IR_alu_immed_fn : alu_fn_code is IR(16 downto 14);
        alias IR_shift_fn     : shift_fn_code is IR(1 downto 0);
        alias IR_mem_fn       : mem_fn_code is IR(11 downto 0);
        alias IR_branch_fn    : branch_fn_code is IR(11 downto 0);
        alias IR_jump_fn      : jump_fn_code is IR(12 downto 12);
        alias IR_misc_fn      : misc_fn_code is IR(10 downto 8);

        alias IR_rd : reg_addr is IR(13 downto 11);
        alias IR_rs : reg_addr is IR(10 downto 8);
        alias IR_r2 : reg_addr is IR(7 downto 5);
        alias IR_immed : immed is IR(7 downto 0);
        alias IR_count : shift_count is IR(7 downto 5);
        alias IR_offset: offset is IR(7 downto 0);
        alias IR_disp  : disp is IR(7 downto 0);
        alias IR_addr  : IMem_addr is IR(11 downto 0);

        -- Return address stack used for subroutine linkage
        constant stack_depth : positive := 8;
        subtype stack_index is natural range 0 to stack_depth - 1;
        type stack_array is array (stack_index) of IMem_addr;
        variable stack: stack_array;
        variable SP: stack_index; -- Stack pointer

        -- General Purpose Registers
        subtype reg_index is natural range 0 to 7;
        variable GPR: unsigned_byte_array(reg_index);

        -- Temporary registers used for ALU instructions
        variable ALU_result: unsigned_byte;
        variable cc_Z: std_ulogic;
        variable cc_C: std_ulogic;

        variable interrupt_en: std_ulogic; -- Flag indicating whether interrupts are enabled
        -- Registers used to store the state of the processor during interrupt service.
        variable interrupt_PC: IMem_addr;
        variable interrupt_Z, interrupt_C: std_ulogic;
        
        -- Variables used to create debug messages reported by the model
        variable disassembled_instr: disassembled_instruction;
        variable debug_line: line;

        -- =============================================================
        -- Local procedures
        -- =============================================================
        procedure perform_reset is
        begin
            -- Reset internal state
            PC := (others => '0');
            SP := 0;
            GPR := (others => X"00");
            cc_Z := '0';
            cc_C := '0';
            interrupt_en := '0';
            -- Reset bus signals
            inst_mem_bus_out <= ('0', '0');
            -- inst_mem_bus_out.stb <= '0';
            data_mem_bus_out <= ('0', '0');
            -- data_mem_bus_out.stb <= '0';
            data_mem_bus_out.we  <= '0';
            io_port_bus_out.cyc  <= '0';
            io_port_bus_out.stb  <= '0';
            io_port_bus_out.we   <= '0';
            interrupt_bus_out.ack <= '0';
        end procedure perform_reset;

        procedure perform_interrupt is
            variable PC_num : natural;
        begin
            -- TODO: It would be a good idea to store all processor state variables in a record
            PC_num := to_integer(PC); -- Saves the current program coutner in integer form for debug
            -- Store internal state of the processor
            interrupt_PC := PC;
            interrupt_Z := cc_Z;
            interrupt_C := cc_C;
            interrupt_en := '0';
            PC := to_unsigned(1, PC'length);
            -- Set the ack output of the prcessor core to 1 for a clock cycle, then back to 0,
            -- to indicate to the I/O port that the interrupt request is acknowledge
            interrupt_bus_out.ack <= '1';
            wait until rising_edge(clk_i);
            interrupt_bus_out.ack <= '0';
            if debug then
                write(debug_line, "Interrupt acknowledged at PC = ");
                write(debug_line, PC_num, field => 4, justified => right);
                writeline(output, debug_line);
            end if;
        end procedure perform_interrupt;

        procedure fetch_instruction is
            variable PC_num : natural;
        begin
            PC_num := to_integer(PC);
            data_mem_bus_out <= (cyc => '1', stb => '1', adr => PC);
            loop
                wait until rising_edge(clk_i);
                if rst_i then
                    return;
                end if;
                exit when inst_ack_i;
            end loop;
            IR := unsigned(data_mem_in_bus.data); 
            PC := PC + 1;
            if debug then
                disassemble(IR, disassembled_instr);
                write(debug_line, PC_num, field => 4, justified => right);
                write(debug_line, ": ");
                write(debug_line, disassembled_instr);
                writeline(output, debug_line);
            end if;
        end procedure fetch_instruction;
        
        procedure perform_alu_op (  fn : in alu_fn_code;
                                    a, b: in unsigned_byte;
                                    C_in: in std_ulogic;
                                    result: out unsigned_byte;
                                    Z_out, C_out: out std_ulogic ) is
        begin
            case fn is
                when alu_fn_add =>
                    (C_out, result) := ('0' & a) + ('0' & b);
                when alu_fn_addc =>
                    (C_out, result) := ('0' & a) + ('0' & b) + C_in;
                when alu_fn_sub =>
                    (C_out, result) := ('0' & a) - ('0' & b);
                when alu_fn_subc =>
                    (C_out, result) := ('0' & a) - ('0' & b) - C_in;
                when alu_fn_and =>
                    (C_out, result) := ('0' & a) and ('0' & b);
                when alu_fn_or =>
                    (C_out, result) := ('0' & a) or ('0' & b);
                when alu_fn_xor =>
                    (C_out, result) := ('0' & a) xor ('0' & b);    
                when alu_fn_mask =>
                    (C_out, result) := ('0' & a) and not ('0' & b);
                when others =>
                    report "Program logic error in interpreter"
                        severity failure;
            end case;
            Z_out := result ?= X"00";
        end procedure perform_alu_op;

        procedure perform_shift_op (fn: in shift_fn_code;
                                    a: in unsigned_byte;
                                    count: in shift_count;
                                    result: out unsigned_byte;
                                    Z_out, C_out: out std_ulogic) is
        begin

            case fn is
                when shift_fn_shl =>
                    (C_out, result) := ('0' & a) sll to_integer(count);
                when shift_fn_shr =>
                    (result, C_out) := (a & '0') srl to_integer(count);
                when shift_fn_rol =>
                    result := a rol to_integer(count);
                    C_out := result(unsigned_byte'right);
                when shift_fn_ror =>
                    result := a ror to_integer(count);
                    C_out := result(unsigned_byte'left);
                when others =>
                    report "Program logic error in interpreter"
                        severity failure;
            end case;
            Z_out := result ?= X"00";
        end procedure perform_shift_op;

        procedure perform_mem is
            variable mem_addr: unsigned_byte;
            variable tmp_Z, tmp_C: std_ulogic;
        begin
            perform_alu_op(fn => alu_fn_add,
                           a  => GPR(to_integer(IR_rs)), 
                           b  => IR_offset,
                           C_in => '0',
                           result => mem_addr,
                           Z_out   => tmp_Z, 
                           C_out   => tmp_C);
            case IR_mem_fn is
                when mem_fn_ldm =>
                    data_mem_bus_out <= (cyc => '1',
                                         std => '1',
                                         we  => '0',
                                         adr => mem_addr);
                    ldm_loop: loop
                        wait until rising_edge(clk_i);
                        if rst_i then
                            return;
                        end if;
                        exit ldm_loop when data_mem_bus_in.ack;
                    end loop ldm_loop;
                    if IR_rd /= 0 then
                        GPR(to_integer(IR_rd)) := unsigned(data_mem_bus_in.data);
                    end if;
                    data_mem_bus_out => (cyc => '0', 
                                         stb => '0');

                when mem_fn_stm =>
                    data_mem_bus_out <= (cyc => '1',
                                        stb => '1',
                                        we  => '1',
                                        adr => mem_addr,
                                        data => std_ulogic_vector(GPR(to_integer(IR_rd))));
                    stm_loop: loop
                        wait until rising_edge(clk_i);
                        if rst_i then
                            return;
                        end if;
                        exit stm_loop when data_mem_bus_in.ack;
                    end loop stm_loop;
                    data_mem_bus_out => (cyc => '0', 
                                         stb => '0');
                            
                when mem_fn_inp =>
                    io_port_bus_out <= (cyc => '1',
                                        stb => '1',
                                        we  => '0',
                                        adr => mem_addr);
                    inp_loop: loop
                        wait until rising_edge(clk_i);
                        if rst_i then
                        return;
                        end if;
                        exit inp_loop when io_port_bus_in.ack;
                    end loop inp_loop;
                    if IR_rd /= 0 then
                        GPR(to_integer(IR_rd)) := unsigned(io_port_bus_in.data);
                    end if;
                    io_port_bus_out => (cyc => '0', 
                                        stb => '0');

                when mem_fn_out =>
                    io_port_bus_out <= (cyc => '1',
                                        stb => '1',
                                        we  => '1',
                                        adr => mem_addr,
                                        data => std_ulogic_vector(GPR(to_integer(IR_rd))));
                    out_loop: loop
                        wait until rising_edge(clk_i);
                        if rst_i then
                            return;
                        end if;
                        exit out_loop when io_port_bus_in.ack;
                    end loop out_loop;
                    io_port_bus_out => (cyc => '0', 
                                        stb => '0');

                when others =>
                    report "Program logic error in interpreter"
                        severity failure;
            end case;
        end procedure perform_mem;

        procedure perform_branch is
            variable branch_taken: std_ulogic;
        begin
            case IR_branch_fn is
                when branch_fn_bz =>
                    branch_taken := cc_Z;
                when branch_fn_bnz =>
                    branch_taken := not cc_Z;
                when branch_fn_bc =>
                    branch_taken := cc_C;
                when branch_fn_bnc =>
                    branch_taken := not cc_C;
                when others =>
                    report "Program logic error in interpreter"
                        severity failure;
            end case;
            if branch_taken then
                PC := unsigned(signed(PC) + signed(IR_disp));
            end if;
        end procedure perform_branch;

        procedure perform_jump is
        begin
            case IR_jump_fn is
                when jump_fn_jmp =>
                    PC:= IR_addr;
                when jump_fn_jsb =>
                    stack(SP) := PC;
                    SP := (SP + 1) mod stack_depth;
                    PC := IR_addr;
                when others =>
                    report "Program logic error in interpreter"
                        severity failure;
            end case;
        end procedure perform_jump;

        procedure perform_misc is
        begin
            case IR_misc_fn is
                when misc_fn_ret =>
                    SP := (SP - 1) mod stack_depth;
                    PC := stack(SP);
                when misc_fn_reti =>
                    PC := int_PC;
                    cc_Z := int_Z;
                    cc_C := int_C;
                    int_en := '1';
                when misc_fn_enai =>
                    int_en := '1';
                when misc_fn_disi =>
                    int_en := '0';
                when misc_fn_wait | misc_fn_stdby =>
                    wait_loop : loop
                    wait until rising_edge(clk_i);
                        if rst_i then
                            return;
                        end if;
                        exit wait_loop when int_en and int_req;
                    end loop wait_loop;
                    perform_interrupt;
                when misc_fn_undef_6 | misc_fn_undef_7 =>
                    null;
                when others =>
                    report "Program logic error in interpreter"
                        severity failure;
            end case;
        end procedure perform_misc;
    begin
        perform_reset;
        wait until rising_edge(clk_i) and rst_i = '0';
        -- fetch/decode/execute loop
        fetch_execute_loop : loop
            -- Check for interrupts
            if interrupt_en and inst_mem_bus_in.req then
                perform_interrupt;
                exit fetch_execute_loop when rst_i;
                next fetch_execute_loop;
            end if;

            -- fetch next instruction
            fetch_instruction;
            exit fetch_execute_loop when rst_i;
            next fetch_execute_loop when is_x(IR);

            -- decode and execute the instruction
            if IR(17) = '0' then
                -- Arithmetic/Logical Immediate
                perform_alu_op;
                if IR_rd /= 0 then
                    GPR(to_integer(IR_rd)) := ALU_result;
                end if;
            elsif IR(16) = '0' then
                -- Memory I/O
                perform_mem;
                exit fetch_execute_loop when rst_i;
            elsif IR(15) = '0' then
                -- Shift
                perform_shift_op;
                if IR_rd /= 0 then
                    GPR(to_integer(IR_rd)) := ALU_result;
                end if;
            elsif IR(14) = '0' then
                -- Arithmetic/Logical Register
                perform_alu_op();
                if IR_rd /= 0 then
                    GPR(to_integer(IR_rd)) := ALU_result;
                end if;
            elsif IR(13) = '0' then
                -- Jump
                perform_jump;
            elsif IR(12) = '0' then
                -- Branch
                perform_branch;
            elsif IR(11) = '0'  then
                -- Miscellaneous
                perform_misc;
                exit fetch_execute_loop when rst_i;
            else
                -- Illegal instruction
                null;
            end if;

        end loop fetch_execute_loop;
    end process interpreter;

end architecture behavior;