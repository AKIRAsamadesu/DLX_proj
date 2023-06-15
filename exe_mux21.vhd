library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity mux is
  generic (
    NBIT_DATA : integer := 64
  );
  port (
    sel     : in  std_logic;
    in0     : in  std_logic_vector(NBIT_DATA-1 downto 0);
    in1     : in  std_logic_vector(NBIT_DATA-1 downto 0);
    output  : out std_logic_vector(NBIT_DATA-1 downto 0)
  );
end entity mux;

architecture behavioral of mux is
begin
  process(sel, in0, in1)
  begin
    if sel = '0' then
      output <= in0;
    else
      output <= in1;
    end if;
  end process;
end architecture behavioral;

configuration cfg_mux21 of mux is
  for behavioral
  end for;
end cfg_mux21;