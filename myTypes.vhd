library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

package myTypes is

-- Control unit input sizes
    constant OP_CODE_SIZE : integer :=  6;                                              -- OPCODE field size
    constant FUNC_SIZE    : integer :=  11;                                             -- FUNC field size

--I-Type instruction -> OPCODE field
   
   constant ITYPE_NOP   : std_logic_vector(OP_CODE_SIZE - 1 downto 0) :=  "010101";  --0x15
    constant ITYPE_ADDI  : std_logic_vector(OP_CODE_SIZE - 1 downto 0) :=  "001000"; --0x08   8
    constant ITYPE_SUBI  : std_logic_vector(OP_CODE_SIZE - 1 downto 0) :=  "001010";  --0x0a  10
    constant ITYPE_ANDI  : std_logic_vector(OP_CODE_SIZE - 1 downto 0) :=  "001100";  --0x0c  12
    constant ITYPE_ORI   : std_logic_vector(OP_CODE_SIZE - 1 downto 0) :=  "001101";  --0x0d  13
    constant ITYPE_XORI  : std_logic_vector(OP_CODE_SIZE - 1 downto 0) :=  "001110";  --0x0e  14
    constant ITYPE_SLTI  : std_logic_vector(OP_CODE_SIZE - 1 downto 0) :=  "011010";  --0x1a  26
    constant ITYPE_SGTI  : std_logic_vector(OP_CODE_SIZE - 1 downto 0) :=  "011011";  --0x1b  27
    constant ITYPE_SLEI  : std_logic_vector(OP_CODE_SIZE - 1 downto 0) :=  "011100";  --0x1C  28
    constant ITYPE_SGEI  : std_logic_vector(OP_CODE_SIZE - 1 downto 0) :=  "011101";  --0x1D  29
    constant ITYPE_SLLI  : std_logic_vector(OP_CODE_SIZE - 1 downto 0) :=  "010100";  --0x14  20 
    constant ITYPE_SRLI  : std_logic_vector(OP_CODE_SIZE - 1 downto 0) :=  "010110";  --0x16  22
    constant ITYPE_SRAI  : std_logic_vector(OP_CODE_SIZE - 1 downto 0) :=  "010111";  --0x17  23
    constant ITYPE_SEQI  : std_logic_vector(OP_CODE_SIZE - 1 downto 0) :=  "011000";  --0x18  24
    constant ITYPE_SNEI  : std_logic_vector(OP_CODE_SIZE - 1 downto 0) :=  "011001";  --0x19  25

    --immediate is unsigned
    constant ITYPE_ADDUI : std_logic_vector(OP_CODE_SIZE - 1 downto 0) :=  "001001";  --0x09  9
    constant ITYPE_SUBUI : std_logic_vector(OP_CODE_SIZE - 1 downto 0) :=  "001011";  --0x0b  11
    constant ITYPE_SGTUI : std_logic_vector(OP_CODE_SIZE - 1 downto 0) :=  "111011";  --0x3b   59 
    constant ITYPE_SLTUI : std_logic_vector(OP_CODE_SIZE - 1 downto 0) :=  "111010";  --0x3a   58
    constant ITYPE_SGEUI : std_logic_vector(OP_CODE_SIZE - 1 downto 0) :=  "111101";  --0x3d   61

    --load and store 
    constant ITYPE_LW    : std_logic_vector(OP_CODE_SIZE - 1 downto 0) :=  "100011";  --0x23  35
    constant ITYPE_LBU   : std_logic_vector(OP_CODE_SIZE - 1 downto 0) :=  "100000";  --0x24  36
    constant ITYPE_LHI   : std_logic_vector(OP_CODE_SIZE - 1 downto 0) :=  "001111"; --0x0f   15
    constant ITYPE_LHU   : std_logic_vector(OP_CODE_SIZE - 1 downto 0) :=  "100101";  --0x25  37
    constant ITYPE_SW    : std_logic_vector(OP_CODE_SIZE - 1 downto 0) :=  "101011";  --0x2b  43
    constant ITYPE_SB    : std_logic_vector(OP_CODE_SIZE - 1 downto 0) :=  "101000";  --0x28  40
 
    

    -- J-Type instruction -> OPCODE field
    constant JTYPE_J    : std_logic_vector(OP_CODE_SIZE - 1 downto 0) :=  "000010";--0x02  2
    constant JTYPE_JAL  : std_logic_vector(OP_CODE_SIZE - 1 downto 0) :=  "000011";--0x03  3
    constant JTYPE_BEQZ : std_logic_vector(OP_CODE_SIZE - 1 downto 0) :=  "000100";--0x04  4
    constant JTYPE_BNEZ : std_logic_vector(OP_CODE_SIZE - 1 downto 0) :=  "000101";--0x05  5
    constant JTYPE_JR   : std_logic_vector(OP_CODE_SIZE - 1 downto 0) :=  "010010";--0x12  18
    constant JTYPE_JALR : std_logic_vector(OP_CODE_SIZE - 1 downto 0) :=  "010011";--0x13  19

    -- R-Type instruction -> OPCODE field

    constant NOP : std_logic_vector(OP_CODE_SIZE - 1 downto 0) :=  "010101";  --0x15  21
    constant RTYPE: std_logic_vector(OP_CODE_SIZE - 1 downto 0) :=  "000000";

    -- R-Type instruction -> FUNC field 
    --constant i_RTYPE_NOP  : std_logic_vector(FUNC_SIZE - 1 downto 0) :=  "00000000000";
    constant RTYPE_ADD  : std_logic_vector(FUNC_SIZE - 1 downto 0) :=  "00000100000";--0x20    32
    constant RTYPE_SUB  : std_logic_vector(FUNC_SIZE - 1 downto 0) :=  "00000100010";--0x22    34
    constant RTYPE_AND  : std_logic_vector(FUNC_SIZE - 1 downto 0) :=  "00000100100";--0x24    36
    constant RTYPE_OR   : std_logic_vector(FUNC_SIZE - 1 downto 0) :=  "00000100101";--0x25    37
    constant RTYPE_XOR  : std_logic_vector(FUNC_SIZE - 1 downto 0) :=  "00000100110";--0x26     38
    constant RTYPE_SGE  : std_logic_vector(FUNC_SIZE - 1 downto 0) :=  "00000101101";--0x2d     45
    constant RTYPE_SLE  : std_logic_vector(FUNC_SIZE - 1 downto 0) :=  "00000101100";--0x2c     46
    constant RTYPE_SLL  : std_logic_vector(FUNC_SIZE - 1 downto 0) :=  "00000000100";--0x04     4
    constant RTYPE_SRL  : std_logic_vector(FUNC_SIZE - 1 downto 0) :=  "00000000110";--0x06     6
    constant RTYPE_SNE  : std_logic_vector(FUNC_SIZE - 1 downto 0) :=  "00000101001";--0x29     41
    constant RTYPE_SEQ  : std_logic_vector(FUNC_SIZE - 1 downto 0) :=  "00000101000";--0x28     40
    constant RTYPE_SGT  : std_logic_vector(FUNC_SIZE - 1 downto 0) :=  "00000101011";--0x2b     43
    constant RTYPE_SLT  : std_logic_vector(FUNC_SIZE - 1 downto 0) :=  "00000101010";--0x2a     42
    constant RTYPE_SRA  : std_logic_vector(FUNC_SIZE - 1 downto 0) :=  "00000000111";--0x07     7
    constant RTYPE_ADDU : std_logic_vector(FUNC_SIZE - 1 downto 0) :=  "00000100001";--0x21     33
    constant RTYPE_SUBU : std_logic_vector(FUNC_SIZE - 1 downto 0) :=  "00000100011";--0x23     35
    constant RTYPE_SGEU : std_logic_vector(FUNC_SIZE - 1 downto 0) :=  "00000111101";--0x3d     61
    constant RTYPE_SGTU : std_logic_vector(FUNC_SIZE - 1 downto 0) :=  "00000111011";--0x3b     59
    constant RTYPE_SLTU : std_logic_vector(FUNC_SIZE - 1 downto 0) :=  "00000111010";--0x3a     58
    constant RTYPE_MULT : std_logic_vector(FUNC_SIZE - 1 downto 0) :=  "00000001110";--0x0e     

  constant MICROCODE_MEM_SIZE  :    integer := 11;
  constant CW_SIZE             :     integer := 12;
  type mem_array is array (integer range 0 to MICROCODE_MEM_SIZE - 1) of std_logic_vector(CW_SIZE - 1 downto 0);
  signal cw_mem : mem_array := ( 
                                 "000000000000", --R_TYPE_NOP             0
                                 "111100000011", --R_type                 1
                                 "111101000011", --I_type                 2
                                 "111101000101", --I_type_LW              3
                                 "111101001100", --I_type_SW              4
                                 "010010000000", --J                      5
                                 "010010000011", --JAL                    6
                                 "011010010000", --BEQZ                   7
                                 "011010110000", --BNEZ                   8
                                 "011010000000", --JR                     9
                                 "011010000011" --JALR                   10
  );



  end myTypes;