library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity n_bit_reg is
    generic(data_width: integer :=32;
            addr_width: integer :=32);
    port ( data_i: in     std_logic_vector(data_width-1 downto 0);
           clk:    in     std_logic;
           en:     in     std_logic;
           data_o: out    std_logic_vector(data_width-1 downto 0));
end n_bit_reg;

architecture behavioral of n_bit_reg is

begin
    process(clk, en)
    begin
        if (en='1' and clk='1' and clk'event) then
            data_o<=data_i;
        elsif (en='0') then
            data_o<=(others=>'0');
        end if;
    end process;
end behavioral;
