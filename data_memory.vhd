library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

entity data_memory is
    generic(data_width:        integer := 32;
            addr_width:        integer := 32);
    port(mem_data_i:           in std_logic_vector(data_width-1 downto 0);
         mem_addr_i:           in std_logic_vector(addr_width-1 downto 0);
         mem_rw_sel_i:         in std_logic;
         mem_clk_i:            in std_logic;
         mem_en_i:             in std_logic;
         mem_out_sel_i:        in std_logic;
         mem_output_o:         out std_logic_vector(data_width-1 downto 0);
         mem_data_mem_state_o: out std_logic);
end entity;

architecture str of data_memory is
type memory_array is array (addr_width-1 downto 0) of std_logic_vector(data_width-1 downto 0);
signal memory: memory_array;
signal data_from_mem: std_logic_vector(data_width-1 downto 0);

begin
    process(mem_clk_i, mem_en_i)
    begin
        if (mem_en_i='1' and mem_clk_i='1' and mem_clk_i'event) then
            if (mem_rw_sel_i='1') then -- 写
                memory(to_integer(unsigned(mem_addr_i)))<=mem_data_i;
            else -- 读
                data_from_mem<=memory(to_integer(unsigned(mem_addr_i)));
            end if;
        end if;
    end process;
    mem_output_o<= data_from_mem when mem_out_sel_i='1' else
                   mem_data_i when mem_out_sel_i='0';
end str;
