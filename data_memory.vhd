library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity data_memory is
    generic(data_width:        integer := 32;
            addr_width:        integer := 32);
    port(mem_data_i:           in std_logic_vector(data_width-1 downto 0);
         mem_addr_i:           in std_logic_vector(addr_width-1 downto 0);
         mem_rw_sel_i:         in std_logic;
         mem_en_i:             in std_logic;
         mem_out_sel_i:        in std_logic;
         mem_output_o:         out std_logic_vector(data_width-1 downto 0);
         mem_data_mem_state_o: out std_logic);
end entity;

architecture str of data_memory is

begin
    

end str;
