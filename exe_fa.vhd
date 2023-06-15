library ieee;
use ieee.std_logic_1164.all;


entity FA is

  port (
    A   : in  std_logic;
    B   : in  std_logic;
    Cin : in  std_logic;
    Sum : out std_logic;
    Cout: out std_logic
  );
end entity FA;

architecture Behavioral of FA is
begin

  Sum <= A xor B xor Cin;
  Cout <= (A and B) or (B and Cin) or (A and Cin);

end architecture Behavioral;

--configuration cfg_fa of FA is
 -- for Behavioral
--  end for;
--end cfg_fa;

