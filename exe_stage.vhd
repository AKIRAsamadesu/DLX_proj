library ieee;
use ieee.std_logic_1164.all;

entity exe_stage is
    generic(
        data_width:         integer := 32;
        addr_width:         integer := 32;
        func_code_width:    integer := 6
    );
    port(
        exe_operand_a_i:       in std_logic_vector(data_width-1 downto 0);
        exe_operand_b_i:       in std_logic_vector(data_width-1 downto 0);
        exe_func_code_i:       in std_logic_vector(func_code_width-1 downto 0);
        exe_result_o:          out std_logic_vector(data_width-1 downto 0);
        exe_add_state_o:       out std_logic;
        exe_mult_state_o:      out std_logic;
        exe_div_state_o:       out std_logic;
        exe_overflow:          out std_logic
    );
end entity;

architecture str of exe_stage is

  component ALU is
    generic (
        DATA_WIDTH: positive := 8;
        func_code_width:    integer := 6
    );
    port (
        A: in std_logic_vector(DATA_WIDTH - 1 downto 0);
        B: in std_logic_vector(DATA_WIDTH - 1 downto 0);
        Op: in std_logic_vector(4 downto 0);
        Result: out std_logic_vector(DATA_WIDTH - 1 downto 0);
        exe_add_state_o: out std_logic;
        exe_mult_state_o: out std_logic;
        exe_div_state_o: out std_logic;
        O: out std_logic
    );
  end component;

begin

  alu_cresp: entity work.ALU
    generic map (
        DATA_WIDTH => data_width,
        func_code_width => func_code_width
    )
    port map (
        A => exe_operand_a_i,
        B => exe_operand_b_i,
        Op => exe_func_code_i,  -- Use SUBTRACT_signal for SUBTRACT input
        Result => exe_result_o,
        exe_add_state_o => exe_add_state_o,
        exe_mult_state_o => exe_mult_state_o,
        exe_div_state_o => exe_div_state_o,
        O => exe_overflow
    );

end str;
