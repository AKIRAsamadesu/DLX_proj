library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use work.myTypes.all;

entity cu_test is
end cu_test;

architecture TEST of cu_test is
    component control_unit is
        generic(func_code_size: integer :=32;
                op_code_size  : integer :=32);
        port(
        -- input signals
            clk_i        : in std_logic;
            rst_i        : in std_logic;
            opcode_i     : in std_logic_vector(op_code_size-1 downto 0);
            func_i       : in std_logic_vector(func_code_size-1 downto 0);

        -- output signals
            --decode stage
            id_reg_enable_i:          out std_logic; --'0'=off '1'= on
            rf_enable_i:              out std_logic;-- '0'=disable '1'= enable
            rf_r_enable_i:            out std_logic;-- '0' = diable;'1' read data
           
            --exe stage
            operand_reg_enable_i:     out std_logic;--'0'=off '1'= on
            jn_sel_i:                 out std_logic;--  '0' = mormal '1'= branch
            ri_sel_i:                 out std_logic;-- '0'=r-type, '1'=i-type
            b_condition_sel_i:        out std_logic;-- '0'="=", '1'="!="
            jb_sel_i:                 out std_logic;-- '0'=jump, '1'=branch
            --mem stage
            memory_rw_control_i:      out std_logic;
            memory_enable_i:          out std_logic;
            --writeback stage
            output_sel_i:              out std_logic;
            rf_w_enable_i:            out std_logic; -- '0' = diable;'1' write data
            cu_func_code_out:        out std_logic_vector(func_code_size-1 downto 0)
            );
    end component;

    signal Clock    : std_logic := '0';
    constant PERIOD : TIME := 1 ns;
    signal Reset    : std_logic ;

    signal cu_opcode_i  : std_logic_vector(OP_CODE_SIZE - 1 downto 0) := (others => '0');
    signal cu_func_i        : std_logic_vector(FUNC_SIZE - 1 downto 0) := "00000100000";
    signal id_reg_enable, rf_enable, rf_r_enable, rf_w_enable, opreand_reg_enable, jn_sel, ri_sel, b_condition_sel, jb_sel, memory_rw_control, memory_enable, output_sel: std_logic := '0';
    signal cu_func_code : std_logic_vector(FUNC_SIZE - 1 downto 0) := (others => '0');
begin
    --instance 
    dut : control_unit
    generic map(11, 6)
    port map(
        -- output
            id_reg_enable_i => id_reg_enable,
            rf_enable_i     => rf_enable,
            rf_r_enable_i   => rf_r_enable,
            rf_w_enable_i   => rf_w_enable,
            operand_reg_enable_i => opreand_reg_enable,
            jn_sel_i        => jn_sel,
            ri_sel_i        => ri_sel,
            b_condition_sel_i => b_condition_sel,
            jb_sel_i           => jb_sel,
            memory_rw_control_i => memory_rw_control,
            memory_enable_i     => memory_enable,
            output_sel_i        => output_sel,
            cu_func_code_out    => cu_func_code,

            --inputs
            opcode_i     =>cu_opcode_i ,
            func_i       =>cu_func_i ,
            clk_i        => Clock,
            rst_i        => Reset
        );
		
--	clock_p: process 
--	begin

		Clock <= not Clock after 0.5 ns; --generate periodic clock
--		wait for PERIOD/2;
--		Clock <= '1';
--		wait for PERIOD/2;
		
--	end process clock_p;

    CONTROL: process --apply inputs
    begin
        Reset <= '1';
        wait for 10*PERIOD;  --check active low reset working, change all inputs 0.1 ns before rising edge
        Reset <='0';
        
        -- iterate over all RTYPE function and ITYPE opcode 
        -- change input every 4 periods
        cu_opcode_i <= ITYPE_SUBI;      cu_func_i <= (others => '0');   wait for 1 * PERIOD;
        cu_opcode_i <= RTYPE;           cu_func_i <= RTYPE_SUB;         wait for 1 * PERIOD;
        cu_opcode_i <= JTYPE_BEQZ;      cu_func_i <= (others => '0');   wait for 1 * PERIOD;
        cu_opcode_i <= ITYPE_LW;        cu_func_i <= (others => '0');   wait for 1 * PERIOD;
        cu_opcode_i <= ITYPE_SW;        cu_func_i <= (others => '0');   wait for 1 * PERIOD;
        cu_opcode_i <= JTYPE_J;         cu_func_i <= (others => '0');   wait for 1 * PERIOD;
        

        wait;
    end process;

end TEST;