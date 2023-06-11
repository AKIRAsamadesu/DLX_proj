library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity divider is
    generic(data_width: integer:=32);
    port(operand_a: in std_logic_vector(data_width-1 downto 0);
         operand_b: in std_logic_vector(data_width-1 downto 0);
         clk_i, rst_i: in std_logic;
         quatient: out std_logic_vector(data_width-1 downto 0);
         reminder: out std_logic_vector(data_width-1 downto 0));
end entity;

--architecture beh of divider is 

--signal dividend_reg: std_logic_vector(31 downto 0);
--signal divisor_reg: std_logic_vector(31 downto 0);

--begin
--    dividend_reg<=operand_a;
--    divisor_reg<=operand_b;

--    process(dividend_reg, divisor_reg)
--    variable temp_a: std_logic_vector(63 downto 0):=(others=>'0');
--    variable temp_b: std_logic_vector(63 downto 0):=(others=>'0');
--    begin
--        temp_a(31 downto 0):=dividend_reg;
--        temp_a(63 downto 32):=(others=>'0');
--        temp_b(63 downto 32):=divisor_reg;

--        for i in 0 to 31 loop
--            temp_a:=std_logic_vector(shift_left(unsigned(temp_a), 1));
--            if (unsigned(temp_a(63 downto 32))>=unsigned(temp_b(63 downto 32))) then
--                temp_a:=std_logic_vector(unsigned(temp_a) - unsigned(temp_b) + 1);
--            else
--                temp_a:=temp_a;
--            end if;
--        end loop;
        
--        quatient<=temp_a(31 downto 0);
--        reminder<=temp_a(63 downto 32);
--    end process;
    
--end beh;

architecture beh of divider is
signal dividend_reg: std_logic_vector(63 downto 0);
signal divisor_reg: std_logic_vector(63 downto 0);

--signal temp_a: std_logic_vector(63 downto 0):=(others=>'0');
--signal temp_b: std_logic_vector(63 downto 0):=(others=>'0');
signal cnt: std_logic_vector(4 downto 0);

type div_state_type is (s0,s1,s_end);
signal curr_div_state: div_state_type;
signal next_div_state: div_state_type;
begin
    
    process(curr_div_state, dividend_reg, divisor_reg)
    begin
        case(curr_div_state) is
        when s0 =>
            dividend_reg<=std_logic_vector(shift_left(unsigned(dividend_reg), 1)); --s0
            next_div_state<=s1;
        when s1 =>
            if (unsigned(dividend_reg(63 downto 32))>=unsigned(divisor_reg(63 downto 32))) then -- s1
                dividend_reg<=std_logic_vector(unsigned(dividend_reg) - unsigned(divisor_reg) + 1);
            else
                dividend_reg<=dividend_reg;
            end if;
            if (unsigned(cnt)<31) then
                next_div_state<=s0;
                cnt<=std_logic_vector(unsigned(cnt)+1);
            else
                next_div_state<=s_end;
                cnt<=(others=>'0');
            end if;
        when s_end =>
            quatient<=dividend_reg(31 downto 0);
            reminder<=dividend_reg(63 downto 32);
        end case;
    end process;
    
    process (clk_i, rst_i)
    begin
        if (rst_i='0') then
            dividend_reg(31 downto 0)<=operand_a;
            dividend_reg(63 downto 32)<=(others=>'0');
            divisor_reg(63 downto 32)<=operand_b;
            cnt<="00000";
            curr_div_state<=s0;
--            next_div_state<=s0;
        else
            if (clk_i='1' and clk_i'event) then
                  curr_div_state<=next_div_state;
            end if;
        end if;
    end process;
end beh;