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
         id_rst_i:                  in std_logic;
         id_rf_enable_i:            in std_logic;
         id_jn_sel_i:               in std_logic; -- j-type and normal instruction selection
         id_ri_sel_i:               in std_logic; -- r-type instruction and i-type instruction selection
         id_su_sel_i:               in std_logic; -- 0=signed imm, 1=unsigned imm
         id_write_back_data_i:      in std_logic_vector(data_width-1 downto 0); -- data write back from memory
         id_write_back_addr_i:      in std_logic_vector(rf_reg_addr_width-1 downto 0);
         id_rf_rw_control_i:        in std_logic; -- register file read/write
         id_opcode_o:               out std_logic_vector(opcode_width-1 downto 0);
         id_func_code_o:            out std_logic_vector(func_width-1 downto 0);
         id_operand_a_reg_o:        out std_logic_vector(data_width-1 downto 0); -- goes to branch
         id_operand_a_o:            out std_logic_vector(data_width-1 downto 0);
         id_operand_b_o:            out std_logic_vector(data_width-1 downto 0);
         id_wb_addr_rd_o:           out std_logic_vector(rf_reg_addr_width-1 downto 0);
         id_rf_state_o:             out std_logic);
end entity;

architecture str of id_stage is

component comb is
    generic (
        F : integer := 8; --number of windows
        N : integer := 8; --number of registers in each IN,OUT,LOCAL (fixed) window
        M : integer := 8; --number of global registers 

        NBIT_ADD : integer := 5; --number of bits in address
        NBIT_DATA : integer := 64   --number of bits in registers
    );
    port(
        --register file signals with virtual addresses
        CLK     : in  std_logic;
        RESET   : in  std_logic;
        ENABLE  : in  std_logic; -- 1=rf enable
        RD1     : in  std_logic; -- 1=rd1 output enable 0=disable
        RD2     : in  std_logic; -- 1=rd2 output enable 0=disable
        WR      : in  std_logic; -- 1=data input enable 0=disable
        ADD_WR  : in  std_logic_vector(NBIT_ADD-1 downto 0);
        ADD_RD1 : in  std_logic_vector(NBIT_ADD-1 downto 0);
        ADD_RD2 : in  std_logic_vector(NBIT_ADD-1 downto 0);
        DATAIN  : in  std_logic_vector(NBIT_DATA-1 downto 0);
        OUT1    : out std_logic_vector(NBIT_DATA-1 downto 0);
        OUT2    : out std_logic_vector(NBIT_DATA-1 downto 0);

        --additional signals for windowing
        CALL    : in  std_logic; --for subroutine call
        RTRN    : in  std_logic --for subroutine return
    );
end component;

-- signal list
signal imm26: std_logic_vector(25 downto 0);
signal imm16: std_logic_vector(15 downto 0);
signal imm_ext: std_logic_vector(31 downto 0);
signal rs1: std_logic_vector(4 downto 0);
signal rs2: std_logic_vector(4 downto 0);
signal rd: std_logic_vector(4 downto 0);
signal rs1_enable: std_logic;
signal rs2_enable: std_logic;
signal op_a: std_logic_vector(data_width-1 downto 0);
signal op_b: std_logic_vector(data_width-1 downto 0);

begin
    -- decoder
    id_opcode_o<=id_instruction(data_width-1 downto data_width-1-opcode_width);
    imm26<=id_instruction(25 downto 0);
    imm16<=id_instruction(15 downto 0);
    rs1<=id_instruction(25 downto 21);
    rs2<=id_instruction(20 downto 16);
    id_func_code_o<=id_instruction(func_width-1 downto 0);
    
    process(id_jn_sel_i, id_ri_sel_i, id_su_sel_i)
    begin
        if (id_jn_sel_i='0' and id_ri_sel_i='1') then -- j-type bias extend imm26
            imm_ext(data_width-1 downto 26)<=(others=>imm26(25));
            imm_ext(25 downto 0)<=imm26;
        elsif (id_jn_sel_i='1' and id_ri_sel_i='1') then-- i-type extend imm16
            if id_su_sel_i='0' then -- signed
                imm_ext(data_width-1 downto 16)<=(others=>imm16(15));
                imm_ext(15 downto 0)<=imm16;
            else -- unsigned
                imm_ext(data_width-1 downto 16)<=(others=>'0');
                imm_ext(15 downto 0)<=imm16;
            end if;
        end if;
    end process;      
    
    rf: comb port map(CLK=>id_clk_i,     
                    RESET=>id_rst_i,  
                    ENABLE=>id_rf_enable_i,   
                    RD1=>'1',       
                    RD2=>'1',       
                    WR=>id_rf_rw_control_i,        
                    ADD_WR=>id_write_back_addr_i,    
                    ADD_RD1=>rs1,   
                    ADD_RD2=>rs2,   
                    DATAIN=>id_write_back_data_i,    
                    OUT1=>op_a,      
                    OUT2=>op_b,                
                    CALL=>'0',    -- in  std_logic; --for subroutine call --TODO: call and return operations need PC stack and pop
                    RTRN=>'0'    -- in  std_logic; --for subroutine return
                    );
    id_operand_a_reg_o<=op_a;
    id_operand_a_o<=op_a when id_jn_sel_i='0' else
                    id_currinstruction_addr;
    id_operand_b_o<=op_b when id_ri_sel_i='0' else
                    imm_ext;
    
end str;
