library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_arith;

entity Restoring_Division is
    generic (
        DATA_WIDTH: positive := 32
    );
    port (
        clk: in std_logic;
        rst: in std_logic;
        dividend: in std_logic_vector(DATA_WIDTH - 1 downto 0);
        divisor: in std_logic_vector(DATA_WIDTH - 1 downto 0);
        quotient: out std_logic_vector(DATA_WIDTH - 1 downto 0);
        remainder: out std_logic_vector(DATA_WIDTH - 1 downto 0);
        done: out std_logic
    );
end entity Restoring_Division;

architecture Behavioral of Restoring_Division is
begin
    process (clk)
        variable dividend_reg: std_logic_vector(DATA_WIDTH - 1 downto 0);
        variable divisor_reg: std_logic_vector(DATA_WIDTH - 1 downto 0);
        variable quotient_reg: std_logic_vector(DATA_WIDTH - 1 downto 0);
        variable remainder_reg: std_logic_vector(DATA_WIDTH - 1 downto 0);
        variable restore_reg: std_logic_vector(DATA_WIDTH - 1 downto 0);
        variable shift_count: natural := DATA_WIDTH;
        variable done_flag: std_logic := '0';
    begin
        if rst = '1' then
            done <= '0';
            quotient <= (others => '0');
            remainder <= (others => '0');
            shift_count := DATA_WIDTH;
            done_flag := '0';
            dividend_reg := (others => '0');
            divisor_reg := (others => '0');
            quotient_reg := (others => '0');
            remainder_reg := (others => '0');
            restore_reg := (others => '0');
        elsif rising_edge(clk) then
            if shift_count = 0 then
                done_flag := '1';
            else
                dividend_reg := dividend;
                divisor_reg := divisor;
                quotient_reg := (others => '0');
                remainder_reg := dividend_reg;

                divisor_reg (DATA_WIDTH - 1):= divisor_reg(DATA_WIDTH - 1);
                --divisor_reg(DATA_WIDTH - 2 downto DATA_WIDTH/2+1) := divisor_reg(DATA_WIDTH/2-2  downto 0); ???
                divisor_reg(30 downto 16) := divisor_reg(14  downto 0);
                divisor_reg(DATA_WIDTH/2-1 downto 0) := (others => '0');

                for i in  DATA_WIDTH/2  downto 0 loop
                    if remainder_reg(DATA_WIDTH - 1) = '0' then
                        remainder_reg (DATA_WIDTH - 1):= remainder_reg(DATA_WIDTH - 1);
                        remainder_reg (DATA_WIDTH - 2 downto 1):= remainder_reg(DATA_WIDTH - 3 downto 0);
                        remainder_reg (0):= '0';
                        restore_reg(DATA_WIDTH - 1 downto 0) := remainder_reg(DATA_WIDTH - 1 downto 0);
                        remainder_reg := std_logic_vector(signed(remainder_reg) - signed(divisor_reg));
                        quotient_reg(i) := '1';
                    else
                        remainder_reg(DATA_WIDTH - 1 downto 0):= restore_reg(DATA_WIDTH - 1 downto 0);
                        remainder_reg (DATA_WIDTH - 1):= remainder_reg(DATA_WIDTH - 1);
                        remainder_reg (DATA_WIDTH - 2 downto 1):= remainder_reg(DATA_WIDTH - 3 downto 0);
                        remainder_reg (0):= '0';
                        restore_reg(DATA_WIDTH - 1 downto 0) := remainder_reg(DATA_WIDTH - 1 downto 0);
                        remainder_reg := std_logic_vector(signed(remainder_reg) - signed(divisor_reg));
                        quotient_reg(i) := '0';
                    end if;
                end loop;
                
                quotient_reg(DATA_WIDTH/2) := '0';
                shift_count := shift_count - 1;
                done_flag := '0';
            end if;
        end if;

        quotient <= quotient_reg;
        remainder(DATA_WIDTH/2 - 2 downto 0) <= restore_reg(DATA_WIDTH - 1 downto DATA_WIDTH/2 + 1);
        done <= done_flag;
    end process;
end architecture Behavioral;
