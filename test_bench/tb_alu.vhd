library ieee;
use ieee.std_logic_1164.all;

entity ALU_Testbench is
end entity ALU_Testbench;

architecture Behavioral of ALU_Testbench is
  constant DATA_WIDTH: positive := 8;
  
  component ALU is
    generic (
      DATA_WIDTH: positive := 8
    );
    port (
      A: in std_logic_vector(DATA_WIDTH - 1 downto 0);
      B: in std_logic_vector(DATA_WIDTH - 1 downto 0);
      Op: in std_logic_vector(4 downto 0);
      Result: out std_logic_vector(DATA_WIDTH - 1 downto 0);
      O: out std_logic
    );
  end component;

  signal A_tb: std_logic_vector(DATA_WIDTH - 1 downto 0):= (others => '0');
  signal B_tb: std_logic_vector(DATA_WIDTH - 1 downto 0):= (others => '0');
  signal Op_tb: std_logic_vector(4 downto 0);
  signal Result_tb: std_logic_vector(DATA_WIDTH - 1 downto 0):= (others => '0');
  signal O_tb: std_logic;

begin
    UUT: entity work.ALU
    generic map (
      DATA_WIDTH => DATA_WIDTH
    )
    port map (
      A => A_tb,
      B => B_tb,
      Op => Op_tb,
      Result => Result_tb,
      O => O_tb
    );
  

  process
  begin
    --wait for 1 ns;
    -- Testcase 1: Logic OR
    A_tb <= "00000001";
    B_tb <= "00000100";
    Op_tb <= "00000";
    wait for 10 ns;

    -- Testcase 1: Logic AND
    A_tb <= "00000011";
    B_tb <= "00000110";
    Op_tb <= "00001";
    wait for 10 ns;
    
    -- Testcase 1: Logic xor
    A_tb <= "00001011";
    B_tb <= "00010110";
    Op_tb <= "00010";
    wait for 10 ns;

    -- Testcase 2: Logic Left Shift
    A_tb <= "11110010";
    B_tb <= "00000010";
    Op_tb <= "00011";
    wait for 10 ns;

    -- Testcase 2: Logic R Shift
    A_tb <= "11110010";
    B_tb <= "00000010";
    Op_tb <= "00100";
    wait for 10 ns;
    
    -- Testcase 3: Add
    A_tb <= "00000111";
    B_tb <= "10000011";
    Op_tb <= "00101";
    wait for 10 ns;
    
    -- Testcase 4: sub
    A_tb <= "00000101";
    B_tb <= "10000001";
    Op_tb <= "00110";
    wait for 10 ns;
    
    -- Testcase 5: sne
    A_tb <= "00000110";
    B_tb <= "00000111";
    Op_tb <= "00111";
    wait for 10 ns;
    
    -- Testcase 5: sne
    A_tb <= "00010010";
    B_tb <= "00000110";
    Op_tb <= "01000";
    wait for 10 ns;

    -- Testcase 5: sge
    A_tb <= "00010000";
    B_tb <= "00000100";
    Op_tb <= "01001";
    wait for 10 ns;

    -- Testcase 6: addu
    A_tb <= "00010000";
    B_tb <= "00000100";
    Op_tb <= "01010";
    wait for 10 ns;

    -- Testcase 6: subu
    A_tb <= "00010000";
    B_tb <= "00000100";
    Op_tb <= "01011";
    wait for 10 ns;

    -- Testcase 7: seq
    A_tb <= "00010101";
    B_tb <= "00010101";
    Op_tb <= "01100";
    wait for 10 ns;

    -- Testcase 8: mul
    A_tb <= "00000101";
    B_tb <= "00001011";
    Op_tb <= "01101";
    wait for 10 ns;

    -- Testcase 8: div
    A_tb <= "00100101";
    B_tb <= "00000011";
    Op_tb <= "01110";
    wait for 10 ns;
    
    -- Additional added here
    
    wait;
  end process;

end architecture Behavioral;
