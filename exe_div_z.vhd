library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity Restoring_Division is
    generic (
        DATA_WIDTH: positive := 32
    );
    port (
        dividend: in std_logic_vector(DATA_WIDTH - 1 downto 0);
        divisor: in std_logic_vector(DATA_WIDTH - 1 downto 0);
        quotient: out std_logic_vector(DATA_WIDTH - 1 downto 0);
        remainder: out std_logic_vector(DATA_WIDTH - 1 downto 0)
    );
end entity Restoring_Division;

architecture Behavioral of Restoring_Division is
begin
    process (dividend, divisor)
        variable dividend_reg: std_logic_vector(DATA_WIDTH - 1 downto 0):= (others => '0');
        variable divisor_reg: std_logic_vector(DATA_WIDTH - 1 downto 0):= (others => '0');
        variable quotient_reg: std_logic_vector(DATA_WIDTH - 1 downto 0):= (others => '0');
        variable remainder_reg: std_logic_vector(DATA_WIDTH - 1 downto 0):= (others => '0');
        variable restore_reg: std_logic_vector(DATA_WIDTH - 1 downto 0):= (others => '0');
        variable shift_count: natural := DATA_WIDTH;
    begin
        
            dividend_reg := dividend;
            divisor_reg := divisor;
            quotient_reg := (others => '0');
            remainder_reg := dividend_reg;

            divisor_reg (DATA_WIDTH - 1) := divisor_reg(DATA_WIDTH - 1);
            divisor_reg(DATA_WIDTH - 2 downto DATA_WIDTH/2) := divisor_reg((DATA_WIDTH/2-2) downto 0);
            divisor_reg(DATA_WIDTH/2-1 downto 0) := (others => '0');

            for i in  DATA_WIDTH/2 downto 0 loop
                if remainder_reg(DATA_WIDTH - 1) = '0' then
                    remainder_reg (DATA_WIDTH - 1) := remainder_reg(DATA_WIDTH - 1);
                    remainder_reg (DATA_WIDTH - 2 downto 1) := remainder_reg(DATA_WIDTH - 3 downto 0);
                    remainder_reg (0) := '0';
                    restore_reg(DATA_WIDTH - 1 downto 0) := remainder_reg(DATA_WIDTH - 1 downto 0);
                    remainder_reg := std_logic_vector(signed(remainder_reg) - signed(divisor_reg));
                    quotient_reg(i) := '1';
                else
                    remainder_reg(DATA_WIDTH - 1 downto 0) := restore_reg(DATA_WIDTH - 1 downto 0);
                    remainder_reg (DATA_WIDTH - 1) := remainder_reg(DATA_WIDTH - 1);
                    remainder_reg (DATA_WIDTH - 2 downto 1) := remainder_reg(DATA_WIDTH - 3 downto 0);
                    remainder_reg (0) := '0';
                    restore_reg(DATA_WIDTH - 1 downto 0) := remainder_reg(DATA_WIDTH - 1 downto 0);
                    remainder_reg := std_logic_vector(signed(remainder_reg) - signed(divisor_reg));
                    quotient_reg(i) := '0';
                end if;
            end loop;

            quotient_reg(DATA_WIDTH/2) := '0';

        quotient <= quotient_reg;
        remainder(DATA_WIDTH/2 - 2 downto 0) <= restore_reg(DATA_WIDTH - 1 downto DATA_WIDTH/2 + 1);
        remainder(DATA_WIDTH-1 downto DATA_WIDTH/2 - 2) <= (others => '0');
    end process;
end architecture Behavioral;
