library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Restoring_Division_Testbench is
end entity Restoring_Division_Testbench;

architecture Behavioral of Restoring_Division_Testbench is
    constant DATA_WIDTH: positive := 32;
    
    signal clk: std_logic := '0';
    signal rst: std_logic := '0';
    signal dividend: std_logic_vector(DATA_WIDTH - 1 downto 0) := (others => '0');
    signal divisor: std_logic_vector(DATA_WIDTH - 1 downto 0) := (others => '0');
    signal quotient: std_logic_vector(DATA_WIDTH - 1 downto 0);
    signal remainder: std_logic_vector(DATA_WIDTH - 1 downto 0);
    signal done: std_logic;

    constant CLK_PERIOD: time := 10 ns;
begin
    uut: entity work.Restoring_Division
        generic map (
            DATA_WIDTH => DATA_WIDTH
        )
        port map (
            clk => clk,
            rst => rst,
            dividend => dividend,
            divisor => divisor,
            quotient => quotient,
            remainder => remainder,
            done => done
        );

    clock_process: process
    begin
        while now < 1000 ns loop
            clk <= '0';
            wait for CLK_PERIOD / 2;
            clk <= '1';
            wait for CLK_PERIOD / 2;
        end loop;
        wait;
    end process;

    stimulus_process: process
    begin
        -- Set test inputs
        dividend <= std_logic_vector(to_signed(117, DATA_WIDTH));
        divisor <= std_logic_vector(to_signed(10, DATA_WIDTH));

        -- Reset
        rst <= '1';
        wait for CLK_PERIOD;
        rst <= '0';

        wait until done = '1';

        -- Display the results
        report "Quotient: " & integer'image(to_integer(signed(quotient)));
        report "Remainder: " & integer'image(to_integer(signed(remainder)));

        wait;
    end process;

end architecture Behavioral;

