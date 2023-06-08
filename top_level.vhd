library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity top_level is
    generic(data_width: integer :=32;
            addr_width: integer :=32);
    port(clk_i: in std_logic
        );
end entity;

architecture str of top_level is
----------------------
--  component list  --
----------------------
component data_path is
    generic(dp_data_width:         integer := 32;
            dp_addr_width:         integer := 32;
            dp_opcode_width:       integer := 6;
            dp_rf_reg_addr_width:  integer := 5;
            dp_func_code_width:    integer := 6 );
    port(main_clk_i:               in std_logic;
         rf_enable_i:              in std_logic;-- '0'=失能，'1'=使能
         jn_sel_i:                 in std_logic;-- '0'=正常运行，'1'=分支转跳指令
         jb_sel_i:                 in std_logic;-- '0'=jump, '1'=branch
         b_condition_sel_i:        in std_logic;-- '0'="=", '1'="!="
         ri_sel_i:                 in std_logic;-- '0'=r-type, '1'=i-type
         rf_rw_control_i:          in std_logic;-- '0'=rf读, '1'=rf写
         memory_rw_control_i:      in std_logic;-- '1'=memory读， '1'=memory写
         memory_enable_i:          in std_logic;
         output_sel_i:             in std_logic;-- '0'=从memory中输出, '1'=输出exe的结果
         instruction_mem_state:    out std_logic;-- '0'=空闲, '1'=占用
         rf_state:                 out std_logic;
         alu_state:                out std_logic;
         mult_state:               out std_logic;
         div_state:                out std_logic;
         data_mem_state:           out std_logic;
         opcode:                   out std_logic_vector(dp_opcode_width-1 downto 0);
         processor_ouput:          out std_logic_vector(dp_opcode_width-1 downto 0));
end component;

component control_unit is
    --port();
end component;
-------------------
--  signal list  --
-------------------
risc_data_path: data_path port map(main_clk_i=>,
                                   rf_enable_i=>,
                                   jn_sel_i=>,
                                   jb_sel_i=>,
                                   b_condition_sel_i=>,
                                   ri_sel_i=>,
                                   rf_rw_control_i=>,
                                   memory_rw_control_i=>,
                                   memory_enable_i=>,
                                   output_sel_i=>,
                                   instruction_mem_state=>,
                                   rf_state=>,
                                   alu_state=>,
                                   mult_state=>,
                                   div_state=>,
                                   data_mem_state=>,
                                   opcode=>,
                                   processor_ouput=>);
risc_control_unit: control_unit port map();
 
begin




end str;