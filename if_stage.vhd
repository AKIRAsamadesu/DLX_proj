library ieee;
use ieee.std_logic_1164.all;

entity if_stage is
    generic(data_width:         integer := 32;
            addr_width:         integer := 32);
    port(if_curr_addr_i:        in std_logic_vector(addr_width-1 downto 0);
         if_clk_i:              in std_logic;
         if_instruction_o:      out std_logic_vector(data_width-1 downto 0);
         if_ins_mem_state:      out std_logic);
end entity;

architecture str of if_stage is
begin

end str;