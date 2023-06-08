library ieee;
use ieee.std_logic_1164.all;

entity exe_stage is
    generic(data_width:         integer := 32;
            addr_width:         integer := 32;
            func_code_width:    integer := 6);
    port(exe_operand_a_i:       in std_logic_vector(data_width-1 downto 0);
         exe_operand_b_i:       in std_logic_vector(data_width-1 downto 0);
         exe_func_code_i:       in std_logic_vector(func_code_width-1 downto 0);
         exe_result_o:          out std_logic_vector(data_width-1 downto 0);
         exe_alu_state_o:       out std_logic;
         exe_mult_state_o:      out std_logic;
         exe_div_state_o:       out std_logic);
end entity;

architecture str of exe_stage is
begin

end str;