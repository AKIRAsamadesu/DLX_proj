library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ff is
  generic (
    NBIT_DATA : integer := 64
  );
  port (
    clk    : in  std_logic;
    reset  : in  std_logic;
    enable : in  std_logic;
    d      : in  std_logic_vector(NBIT_DATA-1 downto 0);
    q      : out std_logic_vector(NBIT_DATA-1 downto 0)
  );
end entity ff;

architecture behavioral of ff is
begin
  process(clk, reset)
  begin
    if reset = '1' then
      q <= (others => '0');
    elsif rising_edge(clk) and enable = '1' then
      q <= d;
    end if;
  end process;
end architecture behavioral;

configuration cfg_ff of ff is
  for behavioral
  end for;
end cfg_ff;
