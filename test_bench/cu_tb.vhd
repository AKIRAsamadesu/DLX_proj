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
            rf_enable_i:              out std_logic;-- '0'=disable '1'= enable
            rf_r_enable_i:            out std_logic;-- '0' = diable;'1' read data
            rf_w_enable_i:            out std_logic;-- '0' = diable;'1' write data
            --exe stage
            jn_sel_i:                 out std_logic;--  '0' = mormal '1'= branch
            ri_sel_i:                 out std_logic;-- '0'=r-type, '1'=i-type
            b_condition_sel_i:        out std_logic;-- '0'="=", '1'="!="
            jb_sel_i:                 out std_logic;-- '0'=jump, '1'=branch
            --mem stage
            memory_rw_control_i:      out std_logic;
            memory_enable_i:          out std_logic;
            --writeback stage
            output_sel_i:             out std_logic
            );
    end component;

    signal Clock    : std_logic := '0';
    constant PERIOD : TIME := 1 NS;
    signal Reset    : std_logic := '1';

    signal cu_opcode_i  : std_logic_vector(OP_CODE_SIZE - 1 downto 0) := (others => '0');
    signal cu_func_i        : std_logic_vector(FUNC_SIZE - 1 downto 0) := "00000100000";
    signal rf_enable, rf_r_enable, rf_w_enable, jn_sel, ri_sel, b_condition_sel, jb_sel, memory_rw_control, memory_enable, output_sel: std_logic := '0';
begin
    --instance 
    dut : control_unit
    generic map(11, 6)
    port map(
        -- output
            rf_enable_i     => rf_enable,
            rf_r_enable_i   => rf_r_enable,
            rf_w_enable_i   => rf_w_enable,
            jn_sel_i        => jn_sel,
            ri_sel_i        => ri_sel,
            b_condition_sel_i => b_condition_sel,
            jb_sel_i           => jb_sel,
            memory_rw_control_i => memory_rw_control,
            memory_enable_i     => memory_enable,
            output_sel_i        => output_sel,

            --inputs
            opcode_i     =>cu_opcode_i ,
            func_i       =>cu_func_i ,
            clk_i        => Clock,
            rst_i        => Reset
        );
    Clock <= not Clock after 0.5 ns; --generate periodic clock

    CONTROL: process --apply inputs
    begin
        Reset <= '0';
        wait for 10*PERIOD;  --check active low reset working, change all inputs 0.1 ns before rising edge
        Reset <='1';
        
        -- iterate over all RTYPE function and ITYPE opcode 
        -- change input every 4 clock cycles
        cu_opcode_i <= ITYPE_SUBI;      cu_func_i <= (others => '0');   wait for 4 * PERIOD;
        cu_opcode_i <= RTYPE;           cu_func_i <= RTYPE_SUB;         wait for 4 * PERIOD;
        cu_opcode_i <= ITYPE_LW;        cu_func_i <= (others => '0');   wait for 4 * PERIOD;
        cu_opcode_i <= ITYPE_SW;        cu_func_i <= (others => '0');   wait for 4 * PERIOD;
        cu_opcode_i <= JTYPE_J;         cu_func_i <= (others => '0');   wait for 4 * PERIOD;
        cu_opcode_i <= JTYPE_BEQZ;      cu_func_i <= (others => '0');   wait for 4 * PERIOD;

        wait;
    end process;

end TEST;