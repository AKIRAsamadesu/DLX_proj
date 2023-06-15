library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity data_path is
    generic(dp_data_width:         integer := 32;
            dp_addr_width:         integer := 32;
            dp_opcode_width:       integer := 6;
            dp_rf_reg_addr_width:  integer := 5;
            dp_func_code_width:    integer := 11 );
    port(main_clk_i:               in std_logic;
         main_rst_i:               in std_logic;
         alu_func_sel_i:           in std_logic_vector(dp_func_code_width-1 downto 0);
         rf_enable_i:              in std_logic;-- '0'=register file enable '1'=register file disable
         jn_sel_i:                 in std_logic;-- '0'=j-type instruction '1'=r-type/i-type instruction
         jb_sel_i:                 in std_logic;-- '0'=jump, '1'=branch
         b_condition_sel_i:        in std_logic;-- '0'="=", '1'="!="
         ri_sel_i:                 in std_logic;-- '0'=r-type, '1'=i-type
         rf_r_enable_i:            in std_logic;-- '0' = diable;'1' read data
         rf_w_enable_i:            in std_logic;-- '0' = diable;'1' write data
         su_sel_i:                 in std_logic;
         memory_rw_control_i:      in std_logic;-- '0'=memory read '1'=memory write
         memory_enable_i:          in std_logic;
         output_sel_i:             in std_logic;-- '0'=memory , '1'=write back
         if_stage_reg_en_i:        in std_logic;
         id_stage_reg_en_i:        in std_logic;
         exe_stage_reg_en_i:       in std_logic;
         mem_stage_reg_en_i:       in std_logic;
         instruction_mem_state_o:  out std_logic;-- '0'=idle, '1'=occupied
         rf_state_o:               out std_logic;
         alu_state_o:              out std_logic;
         mult_state_o:             out std_logic;
         div_state_o:              out std_logic;
         res_state_o:              out std_logic;
         data_mem_state_o:         out std_logic;
         func_code_o:              out std_logic_vector(dp_func_code_width-1 downto 0);
         opcode_o:                 out std_logic_vector(dp_opcode_width-1 downto 0);
         processor_ouput_o:        out std_logic_vector(dp_opcode_width-1 downto 0)

         );
end entity;
architecture str of data_path is
----------------------
--  component list  --
----------------------
component n_bit_reg is
    generic(data_width: integer := 32);
    port(data_i: in     std_logic_vector(data_width-1 downto 0);
         clk:    in     std_logic;
         en:     in     std_logic;
         data_o: out    std_logic_vector(data_width-1 downto 0));
end component;

component if_stage is
    generic(data_width:         integer := 32;
            addr_width:         integer := 32);
    port(if_curr_addr_i:        in std_logic_vector(addr_width-1 downto 0);
         if_clk_i:              in std_logic;
         if_instruction_o:      out std_logic_vector(data_width-1 downto 0);
         if_ins_mem_state:      out std_logic);
end component;

component id_stage is
    generic(data_width:             integer := 32;
            addr_width:             integer := 32;
            opcode_width:           integer := 6;
            rf_reg_addr_width:      integer := 5;
            func_width:             integer := 11);
    port(id_instruction:            in std_logic_vector(data_width-1 downto 0);
         id_currinstruction_addr:   in std_logic_vector(addr_width-1 downto 0);
         id_clk_i:                  in std_logic;
         id_rst_i:                  in std_logic;
         id_rf_enable_i:            in std_logic;
         id_jn_sel_i:               in std_logic; -- j-type and normal instruction selection
         id_ri_sel_i:               in std_logic; -- r-type instruction and i-type instruction selection
         id_su_sel_i:               in std_logic;
         id_write_back_data_i:      in std_logic_vector(data_width-1 downto 0); -- data write back from memory
         id_write_back_addr_i:      in std_logic_vector(rf_reg_addr_width-1 downto 0);
         id_rf_r_enable_i:          in std_logic; -- register file read
         id_rf_w_enable_i:          in std_logic; -- register file write
         id_opcode_o:               out std_logic_vector(opcode_width-1 downto 0);
         id_func_code_o:            out std_logic_vector(func_width-1 downto 0);
         id_operand_a_reg_o:        out std_logic_vector(data_width-1 downto 0);
         id_operand_a_o:            out std_logic_vector(data_width-1 downto 0);
         id_operand_b_o:            out std_logic_vector(data_width-1 downto 0);
         id_wb_addr_rd_o:           out std_logic_vector(rf_reg_addr_width-1 downto 0);
         id_rf_state_o:             out std_logic);
end component;

component exe_stage is
    generic(data_width:         integer := 32;
            addr_width:         integer := 32;
            func_code_width:    integer := 6);
    port(exe_operand_a_i:       in std_logic_vector(data_width-1 downto 0);
         exe_operand_b_i:       in std_logic_vector(data_width-1 downto 0);
         exe_func_code_i:       in std_logic_vector(func_code_width-1 downto 0);
         exe_result_o:          out std_logic_vector(data_width-1 downto 0);
         exe_alu_state_o:       out std_logic;
         exe_mult_state_o:      out std_logic;
         exe_div_state_o:       out std_logic;
         exe_overflow_o:        out std_logic);
end component;

component data_memory is
    generic(data_width:        integer := 32;
            addr_width:        integer := 32);
    port(mem_data_i:           in std_logic_vector(data_width-1 downto 0);
         mem_addr_i:           in std_logic_vector(addr_width-1 downto 0);
         mem_rw_sel_i:         in std_logic;
         mem_en_i:             in std_logic;
         mem_out_sel_i:        in std_logic;
         mem_clk_i:            in std_logic;
         mem_output_o:         out std_logic_vector(data_width-1 downto 0);
         mem_data_mem_state_o: out std_logic);
end component;

-------------------
--  signal list  --
-------------------
-- to if 
signal curr_instruction_addr:               std_logic_vector(dp_addr_width-1 downto 0);
signal next_instruction_addr:               std_logic_vector(dp_addr_width-1 downto 0);
signal normal_next_instruction_addr:        std_logic_vector(dp_addr_width-1 downto 0);

signal curr_instruction:                    std_logic_vector(dp_data_width-1 downto 0);
signal curr_instruction_id:                 std_logic_vector(dp_data_width-1 downto 0);
-- if to id 
signal operand_a_reg:                       std_logic_vector(dp_func_code_width-1 downto 0);
signal operand_a:                           std_logic_vector(dp_data_width-1 downto 0);
signal operand_b:                           std_logic_vector(dp_data_width-1 downto 0);
signal rd:                                  std_logic_vector(dp_rf_reg_addr_width-1 downto 0);
signal operand_a_reg_exe:                   std_logic_vector(dp_func_code_width-1 downto 0);
signal operand_a_exe:                       std_logic_vector(dp_data_width-1 downto 0);
signal operand_b_exe:                       std_logic_vector(dp_data_width-1 downto 0);
signal rd_exe:                              std_logic_vector(dp_rf_reg_addr_width-1 downto 0);
-- id to exe
signal exe_result:                          std_logic_vector(dp_data_width-1 downto 0);
signal load_data_mem:                       std_logic_vector(dp_data_width-1 downto 0);
signal exe_result_mem:                      std_logic_vector(dp_data_width-1 downto 0);
signal rd_mem:                              std_logic_vector(dp_rf_reg_addr_width-1 downto 0);
-- exe to mem
signal jump_next_instruction_addr:          std_logic_vector(dp_addr_width-1 downto 0);
-- mem to wb
signal data_write_back:                     std_logic_vector(dp_data_width-1 downto 0);
 
begin
-----------------
--  main path  --
-----------------

-- if stage
    risc_if: if_stage generic map(data_width=>dp_data_width,
                                  addr_width=>dp_addr_width)
                      port map(if_curr_addr_i=>curr_instruction_addr,
                               if_clk_i=>main_clk_i,
                               if_instruction_o=>curr_instruction,
                               if_ins_mem_state=>instruction_mem_state_o);
                                
    if_id_reg1: n_bit_reg generic map(data_width=>dp_data_width)
                          port map(data_i=>curr_instruction,
                                   clk=>main_clk_i,
                                   en=>if_stage_reg_en_i,
                                   data_o=>curr_instruction_id);
-- id stage 
    risc_id: id_stage generic map(opcode_width=>dp_opcode_width, 
                                  rf_reg_addr_width=>dp_rf_reg_addr_width,
                                  func_width=>dp_func_code_width)
                      port map(id_instruction=>curr_instruction_id,
                               id_currinstruction_addr=>curr_instruction_addr,
                               id_clk_i=>main_clk_i,
                               id_rst_i=>main_rst_i,
                               id_rf_enable_i=>rf_enable_i,
                               id_jn_sel_i=>jn_sel_i,
                               id_ri_sel_i=>ri_sel_i,
                               id_su_sel_i=>su_sel_i,
                               id_write_back_data_i=>data_write_back,
                               id_write_back_addr_i=>rd_mem,
                               id_rf_r_enable_i=>rf_r_enable_i,
                               id_rf_w_enable_i=>rf_w_enable_i,
                               id_opcode_o=>opcode_o,
                               id_func_code_o=>func_code_o,
                               id_operand_a_reg_o=>operand_a_reg,
                               id_operand_a_o=>operand_a,
                               id_operand_b_o=>operand_b,
                               id_wb_addr_rd_o=>rd,
                               id_rf_state_o=>rf_state_o);
                               
    id_exe_reg1: n_bit_reg generic map(data_width=>dp_data_width)
                          port map(data_i=>operand_a,
                                   clk=>main_clk_i,
                                   en=>id_stage_reg_en_i,
                                   data_o=>operand_a_exe);
                                   
    id_exe_reg2: n_bit_reg generic map(data_width=>dp_data_width)
                           port map(data_i=>operand_b,
                                    clk=>main_clk_i,
                                    en=>id_stage_reg_en_i,
                                    data_o=>operand_b_exe);
    
    id_exe_reg4: n_bit_reg generic map(data_width=>dp_rf_reg_addr_width)
                           port map(data_i=>rd,
                                    clk=>main_clk_i,
                                    en=>id_stage_reg_en_i,
                                    data_o=>rd_exe);
-- exe stage
    risc_exe: exe_stage generic map (data_width=>dp_data_width,
                                     addr_width=>dp_addr_width,
                                     func_code_width=>dp_func_code_width)
                        port map(exe_operand_a_i=>operand_a_exe,
                                 exe_operand_b_i=>operand_b_exe,
                                 exe_func_code_i=>alu_func_sel_i,
                                 exe_result_o=>exe_result,
                                 exe_alu_state_o=>alu_state_o,
                                 exe_mult_state_o=>mult_state_o,
                                 exe_div_state_o=>div_state_o,
                                 exe_overflow_o=>res_state_o);
    jump_next_instruction_addr<=exe_result;
    
    exe_mem_reg1: n_bit_reg generic map(data_width=>dp_data_width)
                            port map(data_i=>exe_result,
                                    clk=>main_clk_i,
                                    en=>exe_stage_reg_en_i,
                                    data_o=>exe_result_mem);
    
    exe_mem_reg2: n_bit_reg generic map(data_width=>dp_data_width)
                            port map(data_i=>operand_b_exe,
                                    clk=>main_clk_i,
                                    en=>exe_stage_reg_en_i,
                                    data_o=>load_data_mem);
    
    exe_mem_reg3: n_bit_reg generic map(data_width=>dp_rf_reg_addr_width)
                            port map(data_i=>operand_b_exe,
                                    clk=>main_clk_i,
                                    en=>exe_stage_reg_en_i,
                                    data_o=>rd_mem);
-- mem stage

    risc_mem: data_memory generic map(data_width=>dp_data_width,
                                      addr_width=>dp_addr_width)
                          port map(mem_data_i=>load_data_mem,
                                     mem_addr_i=>exe_result_mem,
                                     mem_rw_sel_i=>memory_rw_control_i,
                                     mem_en_i=>memory_enable_i,
                                     mem_out_sel_i=>output_sel_i,
                                     mem_clk_i=>main_clk_i,
                                     mem_output_o=>data_write_back,
                                     mem_data_mem_state_o=>data_mem_state_o);
    
    mem_out_reg3: n_bit_reg generic map(data_width=>dp_rf_reg_addr_width)
                            port map(data_i=>data_write_back,
                                     clk=>main_clk_i,
                                     en=>mem_stage_reg_en_i,
                                     data_o=>processor_ouput_o);
-------------------
--  branch path  --
-------------------
    load_next_instruction: n_bit_reg generic map(data_width=>dp_addr_width)
                                     port map(data_i=>next_instruction_addr,
                                              clk=>main_clk_i,
                                              en=>'1',
                                              data_o=>curr_instruction_addr);
    
    process(curr_instruction_addr, jn_sel_i, jb_sel_i, b_condition_sel_i, jump_next_instruction_addr) 
    begin
        if (jn_sel_i='0') then
            next_instruction_addr<=std_logic_vector(unsigned(curr_instruction_addr)+4);
        else
            if (jb_sel_i='0') then -- "0"=normal running
                next_instruction_addr<=jump_next_instruction_addr; -- ri_sel_i select from r_type to i_type, this sel also has impact on j_type
            else -- "1"=jump or branch running
                if (b_condition_sel_i='1') then -- equal to 0 
                    if (unsigned(operand_a_reg)=0) then
                        next_instruction_addr<=jump_next_instruction_addr; 
                    else 
                        next_instruction_addr<=std_logic_vector(unsigned(curr_instruction_addr)+4);
                    end if;
                else -- operand_a not equal to 0
                    if (unsigned(operand_a_reg)/=0) then
                        next_instruction_addr<=jump_next_instruction_addr; 
                    else 
                        next_instruction_addr<=std_logic_vector(unsigned(curr_instruction_addr)+4);
                    end if;
                end if;
            end if;
        end if;
    end process;
    
end str;