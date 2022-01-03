library ieee;
use ieee.std_logic_1164.all, ieee.numeric_std.all;

package gumnut_defs is
    subtype unsigned_byte    is unsigned(7 downto 0);
    type unsigned_byte_array is array (natural range<>) of unsigned_byte;

    subtype signed_byte    is signed(7 downto 0);
    type signed_byte_array is array (natural range<>) of signed_byte;

    -- Instruction memory
    subtype instruction    is unsigned(17 downto 0);
    type instruction_array is array (natural range <>) of instruction;

    constant IMem_addr_width: positive := 12;
    constant IMem_size: positive := 2**IMem_addr_width;
    subtype IMem_addr  is unsigned(IMem_addr_width - 1 downto 0);
    subtype IMem_array is instruction_array(0 to IMem_size - 1);

    -- Data memory
    constant DMem_size: positive := 256;
    subtype DMem_array is unsigned_byte_array(0 to DMem_size - 1);

    -- Others
    subtype reg_addr    is unsigned(2 downto 0);
    subtype immed       is unsigned(7 downto 0);
    subtype offset      is unsigned(7 downto 0);
    subtype disp        is unsigned(7 downto 0);
    subtype shift_count is unsigned(2 downto 0);

    -- Instruction set
    subtype alu_fn_code    is unsigned(2 downto 0);
    subtype shift_fn_code  is unsigned(1 downto 0);
    subtype mem_fn_code    is unsigned(1 downto 0);
    subtype branch_fn_code is unsigned(1 downto 0);
    subtype jump_fn_code   is unsigned(0 downto 0);
    subtype misc_fn_code   is unsigned(2 downto 0);

    constant alu_fn_add : alu_fn_code := "000";
    constant alu_fn_addc: alu_fn_code := "001";
    constant alu_fn_sub : alu_fn_code := "010";
    constant alu_fn_subc: alu_fn_code := "011";
    constant alu_fn_and : alu_fn_code := "100";
    constant alu_fn_or  : alu_fn_code := "101";
    constant alu_fn_xor : alu_fn_code := "110";
    constant alu_fn_mask: alu_fn_code := "111";

    constant shift_fn_shl : shift_fn_code := "00";
    constant shift_fn_shr : shift_fn_code := "01";
    constant shift_fn_rol : shift_fn_code := "10";
    constant shift_fn_ror : shift_fn_code := "11";

    constant mem_fn_ldm : mem_fn_code := "00";
    constant mem_fn_stm : mem_fn_code := "01";
    constant mem_fn_inp : mem_fn_code := "10";
    constant mem_fn_out : mem_fn_code := "11";

    constant branch_fn_bz  : branch_fn_code := "00";
    constant branch_fn_bnz : branch_fn_code := "01";
    constant branch_fn_bc  : branch_fn_code := "10";
    constant branch_fn_bnc : branch_fn_code := "11";

    constant jump_fn_jmp : jump_fn_code := "0";
    constant jump_fn_jsb : jump_fn_code := "1";

    constant misc_fn_ret    : misc_fn_code := "000";
    constant misc_fn_reti   : misc_fn_code := "001";
    constant misc_fn_enai   : misc_fn_code := "010";
    constant misc_fn_disi   : misc_fn_code := "011";
    constant misc_fn_wait   : misc_fn_code := "100";
    constant misc_fn_stby   : misc_fn_code := "101";
    constant misc_fn_undef_6: misc_fn_code := "110";
    constant misc_fn_undef_7: misc_fn_code := "111";

    subtype disassembled_instruction is string(1 to 30);
    
    procedure disassemble(instr : instruction;
                          result: out disassembled_instruction);
    
    function to_string(n: integer) return string;
    function is_x(n: unsigned) return boolean;
end package gumnut_defs;


package body gumnut_defs is
    
    function to_string(n: integer) return string is
    begin
        return integer'image(n);
    end function to_string;

    function is_x(n: unsigned) return boolean is
    begin
        return (n = 'U') or (n = 'X') or (n = 'Z') or (n = 'W') or (n = '-');   
    end function is_x;

    procedure disassemble( instr : instruction;
                           result: out disassembled_instruction) is
        subtype name is string(1 to 4);

        type name_table is array(natural range <>) of name;

        constant alu_name_table   : name_table(0 to 7) :=
            ( 0 => "add ", 1 => "addc", 2 => "sub ", 3 => "subc",
              4 => "and ", 5 => "or  "  , 6 => "xor ", 7 => "msk " );
        constant shift_name_table : name_table(0 to 3) :=
            ( 0 => "shl ", 1 => "shr ", 2 => "rol ", 3 => "ror ");
        constant mem_name_table   : name_table(0 to 3) := 
            ( 0 => "ldm ", 1 => "stm ", 2 => "inp ", 3 => "out ");
        constant branch_name_table: name_table(0 to 3) :=
            ( 0 => "bz  ", 1 => "bnz ", 2 => "bc  ", 3 => "bnc ");
        constant jump_name_table  : name_table(0 to 1) :=
            ( 0 => "jmp ", 1 => "jsb ");
        constant misc_name_table  : name_table(0 to 7) :=
            ( 0 => "ret ", 1 => "reti", 2 => "enai", 3 => "disi",
              4 => "wait", 5 => "stby", 6 => "um_6", 7 => "um_7");
        
        variable instr_01 : instruction := to_01(instr);

        alias instr_alu_ref_fn   : alu_fn_code is instr_01(2 downto 0);
        alias instr_alu_immed_fn : alu_fn_code is instr_01(16 downto 14);
        alias instr_shift_fn     : shift_fn_code is instr_01(1 downto 0);
        alias instr_mem_fn       : mem_fn_code is instr_01(15 downto 14);
        alias instr_branch_fn    : branch_fn_code is instr_01(11 downto 10);
        alias instr_jump_fn      : jump_fn_code is instr_01(12 downto 12);
        alias instr_misc_fn      : misc_fn_code is instr_01(10 downto 8);

        alias instr_rd : reg_addr is instr_01(13 downto 11);
        alias instr_rs : reg_addr is instr_01(10 downto 8);
        alias instr_r2 : reg_addr is instr_01(7 downto 5);
        alias instr_immed : immed is instr_01(7 downto 0);
        alias instr_count : shift_count is instr_01(7 downto 5);
        alias instr_offset: offset is instr_01(7 downto 0);
        alias instr_disp  : disp is instr_01(7 downto 0);
        alias instr_addr  : IMem_addr is instr_01(11 downto 0);

        procedure disassemble_reg(reg  : reg_addr;
                                  index : positive ) is
            constant str : string := to_string(to_integer(reg));
        begin
            result(index) := str(str'left);
        end procedure disassemble_reg;

        procedure disassemble_unsigned( n    : unsigned;
                                        index: positive ) is
            constant str : string := to_string(to_integer(n));
        begin
            result(index to index + str'length - 1) := str;
        end procedure disassemble_unsigned;

        procedure disassemble_signed(n    : signed;
                                     index: positive ) is
            constant str: string := to_string(to_integer(n));
        begin
            result(index to index + str'length - 1) := str;
        end procedure disassemble_signed;

        procedure disassemble_effective_addr(r : reg_addr;
                                             d : offset;
                                             index : positive ) is
            constant signed_str : string := to_string(to_integer(signed(d)));
            constant unsigned_str : string := to_string(to_integer(d));
        begin
            if r = 0 then
                result(index to index + unsigned_str'length - 1) := unsigned_str;
            else
                result(index to index + 3) := "(r );";
                disassemble_reg(r, index + 2);
                result(index + 4 to index + 4 + signed_str'length - 1) := signed_str;
            end if;
        end procedure disassemble_effective_addr;
    begin
        if is_x(instr) then
            report "disassemble: metalogical value in instruction word"
                severity error;
            result := (others => 'X');
            return;
        end if;
        result := (others => ' ');

        if instr_01(17) = '0' then
            -- Arithmetic/Logical Immediate
            result(1 to name'length) := alu_name_table(to_integer(instr_alu_immed_fn));
            result(name'length + 2 to name'length + 8) := "R , R ,";
            disassemble_reg(instr_rd, name'length + 3);
            disassemble_reg(instr_rs, name'length + 7);
            disassemble_unsigned(instr_immed, name'length + 10);
        elsif instr_01(16) = '0' then
            -- Memory I/O
            result(1 to name'length) := mem_name_table(to_integer(instr_mem_fn));
            result(name'length + 2 to name'length + 4) := "R ,";
            disassemble_reg(instr_rd, name'length + 3);
            disassemble_effective_addr(instr_rs,
                                       instr_offset, name'length + 6);
        elsif instr_01(15) = '0' then
            -- Shift
            result(1 to name'length) := shift_name_table(to_integer(instr_shift_fn));
            result(name'length + 2 to name'length + 8) := "R , R ,";
            disassemble_reg(instr_rd, name'length + 3);
            disassemble_reg(instr_rs, name'length + 7);
            disassemble_unsigned(instr_count, name'length + 10);
        elsif instr_01(14) = '0' then
            -- Arithmetic/Logical Register
            result(1 to name'length) := alu_name_table(to_integer(instr_alu_ref_fn));
            result(name'length + 2 to name'length + 10) := "R , R , R";
            disassemble_reg(instr_rd, name'length + 3);
            disassemble_reg(instr_rs, name'length + 7);
            disassemble_reg(instr_r2, name'length + 11);
        elsif instr_01(13) = '0' then
            -- Jump
            result(1 to name'length) := jump_name_table(to_integer(instr_jump_fn));
            disassemble_unsigned(instr_addr, name'length + 2);
        elsif instr_01(12) = '0' then
            -- Branch
            result(1 to name'length) := branch_name_table(to_integer(instr_branch_fn));
            disassemble_signed(signed(instr_disp), name'length +2);
        elsif instr_01(11) = '0'  then
            -- Miscellaneous
            result(1 to name'length) := misc_name_table(to_integer(instr_misc_fn));
        else
            result(1 to 19) := "Illegal Instruction";
        end if;
    end procedure disassemble;

end package body gumnut_defs;