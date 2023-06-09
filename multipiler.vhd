library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity multiplier is --32位无符号booth乘法输出64bit结果，11个周期计算，用2个周期输出（先0-31后32-63），可流水化
--    generic(data_width:     integer:=32);
    port(operand_a_i:       in std_logic_vector(31 downto 0);
         operand_b_i:       in std_logic_vector(31 downto 0);
         clk_i:             in std_logic;
         rst_i:             in std_logic;
         end_signal_o:      out std_logic;
         res_o:             out std_logic_vector(31 downto 0));
end entity;

architecture rtl of multiplier is

signal res1: std_logic_vector(31 downto 0);
signal res2: std_logic_vector(31 downto 0);
type lut is array(7 downto 0) of std_logic_vector(63 downto 0);
signal booth_lut: lut:=(others=>(others=>'0'));
type mult_state is (s0, s1, s2, s3, s4, s5, s6, s7, s8, s9, s10, so_1, so_2);
signal curr_state, next_state: mult_state;
signal product: std_logic_vector(31 downto 0):=(others=>'0');
signal ext_operand_b: std_logic_vector(32 downto 0);
signal window_sel: std_logic_vector(2 downto 0);

begin
    booth_lut(0)<=(others=>'0');
    booth_lut(1)(31 downto 0)<=operand_a_i;
    booth_lut(2)(31 downto 0)<=operand_a_i;
    booth_lut(3)(32 downto 1)<=operand_a_i;
    booth_lut(4)(32 downto 1)<=operand_a_i;
    booth_lut(5)(31 downto 0)<=operand_a_i;
    booth_lut(6)(31 downto 0)<=operand_a_i;
    booth_lut(7)<=(others=>'0');
    
    ext_operand_b<=operand_b_i&'0';
    
    process(curr_state,next_state,operand_a_i,operand_b_i)
    begin
        end_signal_o<='0';
        case (curr_state) is
            when s0 =>
                product<=std_logic_vector(unsigned(product)+unsigned(booth_lut(to_integer(unsigned(ext_operand_b(2 downto 0)))))); -- 如果有adder的话这里还可以用adder
                next_state<=s1;
            when s1 =>
                product<=std_logic_vector(unsigned(product)+unsigned(booth_lut(to_integer(unsigned(ext_operand_b(5 downto 3))))));
                next_state<=s2;
            when s2 =>
                product<=std_logic_vector(unsigned(product)+unsigned(booth_lut(to_integer(unsigned(ext_operand_b(8 downto 6))))));
                next_state<=s3;
            when s3 =>
                product<=std_logic_vector(unsigned(product)+unsigned(booth_lut(to_integer(unsigned(ext_operand_b(11 downto 9))))));
                next_state<=s4;
            when s4 =>
                product<=std_logic_vector(unsigned(product)+unsigned(booth_lut(to_integer(unsigned(ext_operand_b(14 downto 12))))));
                next_state<=s5;
            when s5 =>
                product<=std_logic_vector(unsigned(product)+unsigned(booth_lut(to_integer(unsigned(ext_operand_b(17 downto 15))))));
                next_state<=s6;
            when s6 =>
                product<=std_logic_vector(unsigned(product)+unsigned(booth_lut(to_integer(unsigned(ext_operand_b(20 downto 18))))));
                next_state<=s7;
            when s7 =>
                product<=std_logic_vector(unsigned(product)+unsigned(booth_lut(to_integer(unsigned(ext_operand_b(23 downto 21))))));
                next_state<=s8;
            when s8 =>
                product<=std_logic_vector(unsigned(product)+unsigned(booth_lut(to_integer(unsigned(ext_operand_b(26 downto 24))))));
                next_state<=s9;
            when s9 =>
                product<=std_logic_vector(unsigned(product)+unsigned(booth_lut(to_integer(unsigned(ext_operand_b(29 downto 27))))));
                next_state<=s10;
            when s10 =>
                product<=std_logic_vector(unsigned(product)+unsigned(booth_lut(to_integer(unsigned(ext_operand_b(32 downto 30))))));
                next_state<=so_1;
            when so_1 =>
                res_o<=product(31 downto 0);
                end_signal_o<='1';
                next_state<=so_2;
            when so_2 =>
                res_o<=product(63 downto 32);
                end_signal_o<='1';
                next_state<=so_2;
        end case;
    end process;
    
    process(clk_i, rst_i)
    begin
        if (rst_i='0') then
            next_state<=s0;
        else
            if (clk_i='1' and clk_i'event) then
                curr_state<=next_state;
            end if;
        end if;
    end process;
end rtl;