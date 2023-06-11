library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity id_stage is
    generic(data_width:             integer := 32;
            addr_width:             integer := 32;
            opcode_width:           integer := 6;
            rf_reg_addr_width:      integer := 5;
            func_width:             integer := 6);
    port(id_instruction:            in std_logic_vector(data_width-1 downto 0);
         id_currinstruction_addr:   in std_logic_vector(addr_width-1 downto 0);
         id_clk_i:                  in std_logic;
         id_rf_enable_i:            in std_logic;
         id_jn_sel_i:               in std_logic; -- j-type and normal instruction selection
         id_ri_sel_i:               in std_logic; -- r-type instruction and i-type instruction selection
         id_write_back_data_i:      in std_logic_vector(data_width-1 downto 0); -- data write back from memory
         id_write_back_addr_i:      in std_logic_vector(rf_reg_addr_width-1 downto 0);
         id_rf_rw_control_i:        in std_logic; -- register file read/write
         id_opcode_o:               out std_logic_vector(opcode_width-1 downto 0);
         id_func_code_o:            out std_logic_vector(func_width-1 downto 0);
         id_operand_a_reg_o:        out std_logic_vector(data_width-1 downto 0);
         id_operand_a_o:            out std_logic_vector(data_width-1 downto 0);
         id_operand_b_o:            out std_logic_vector(data_width-1 downto 0);
         id_wb_addr_rd_o:           out std_logic_vector(rf_reg_addr_width-1 downto 0);
         id_rf_state_o:             out std_logic);
end entity;

architecture str of id_stage is

begin


end str;
