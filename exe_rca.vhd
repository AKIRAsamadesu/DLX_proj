library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity RCA is
  generic (
    DATA_WIDTH: positive := 32
  );
  port (
    A: in std_logic_vector(DATA_WIDTH - 1 downto 0);
    B: in std_logic_vector(DATA_WIDTH - 1 downto 0);
    SUBTRACT: in std_logic;
    Ci: in std_logic;
    S: out std_logic_vector(DATA_WIDTH - 1 downto 0);
    Co: out std_logic;
    O: out std_logic
  );
end entity RCA;

architecture Behavioral of RCA is
  signal carry: std_logic_vector(DATA_WIDTH downto 0) := (others => '0');
  signal carry_bit: std_logic := '0';
  signal B_temp: std_logic_vector(DATA_WIDTH - 1 downto 0);
  signal S_temp: std_logic_vector(DATA_WIDTH - 1 downto 0);

  component FA is
    port (
      a: in std_logic;
      b: in std_logic;
      cin: in std_logic;
      sum: out std_logic;
      cout: out std_logic
    );
  end component;

begin
  -- Carry chain generation
  carry(0) <= Ci;
  B_temp <= B xor (DATA_WIDTH-1 downto 0 => SUBTRACT);  -- 

  RCA_bit_inst: for i in 0 to DATA_WIDTH - 1 generate
    genrca: entity work.FA
      port map (
        a => A(i),
        b => B_temp(i),
        cin => carry(i),
        sum => S_temp(i),
        cout => carry(i + 1)
      );
  end generate;

  Co <= carry(DATA_WIDTH);

  process(carry)
  variable carry_comp1: std_logic;
  variable carry_comp2: std_logic;
  begin
    carry_comp1:= carry(DATA_WIDTH);
    carry_comp2:= carry(DATA_WIDTH-1);
    if carry_comp1=carry_comp2 then
      O <= '0';
    else
      O <= '1';
    end if;
  end process;

  process(S_temp, SUBTRACT)
  begin
    if SUBTRACT = '1' then
      S <= std_logic_vector(unsigned(S_temp) + 1);
    else
      S <= S_temp;
    end if;
  end process;

end architecture Behavioral;
