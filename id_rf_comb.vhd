library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity comb is
    generic (
        F : integer := 2; --number of windows
        N : integer := 2; --number of registers in each IN,OUT,LOCAL (fixed) window
        M : integer := 2; --number of global registers 

        NBIT_ADD : integer := 5; --number of bits in address
        NBIT_DATA : integer := 64   --number of bits in registers
    );
    port(
        --register file signals with virtual addresses
        CLK     : in  std_logic;
        RESET   : in  std_logic;
        ENABLE  : in  std_logic;
        RD1     : in  std_logic;
        RD2     : in  std_logic;
        WR      : in  std_logic;
        ADD_WR  : in  std_logic_vector(NBIT_ADD-1 downto 0);
        ADD_RD1 : in  std_logic_vector(NBIT_ADD-1 downto 0);
        ADD_RD2 : in  std_logic_vector(NBIT_ADD-1 downto 0);
        DATAIN  : in  std_logic_vector(NBIT_DATA-1 downto 0);
        OUT1    : out std_logic_vector(NBIT_DATA-1 downto 0);
        OUT2    : out std_logic_vector(NBIT_DATA-1 downto 0);

        --additional signals for windowing
        CALL    : in  std_logic; --for subroutine call
       -- SPILL   : out std_logic; --for spilling, window to MMU
        RTRN    : in  std_logic  --for subroutine return
       -- FILL    : out std_logic; --for filling, MMU to register
       -- D_BUS   : inout  std_logic_vector(NBIT_DATA-1 downto 0) --bidirectional bus for data transfer
    );
end comb;

architecture STRUCTURAL of comb is

    signal spill_o: std_logic;
    signal fill_o: std_logic;
    signal buss : std_logic_vector(NBIT_DATA-1 downto 0) := (others => 'Z');


    constant SIZE : integer := 20; --mem size


    component MEM
    generic (
        DATA_WIDTH : integer := 64;  
        SIZE : integer := 20     
    );
    port (
        CLK      : in  std_logic;
        RESET    : in  std_logic;
        ENABLE   : in  std_logic;
        PUSH     : in  std_logic;        -- spill
        POP      : in  std_logic;        -- fill
        DATA     : inout std_logic_vector(DATA_WIDTH-1 downto 0)  --D_BUS
    );
    end component;


    component WINDOWED_REGISTER_FILE
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
        ENABLE  : in  std_logic;
        RD1     : in  std_logic;
        RD2     : in  std_logic;
        WR      : in  std_logic;
        ADD_WR  : in  std_logic_vector(NBIT_ADD-1 downto 0);
        ADD_RD1 : in  std_logic_vector(NBIT_ADD-1 downto 0);
        ADD_RD2 : in  std_logic_vector(NBIT_ADD-1 downto 0);
        DATAIN  : in  std_logic_vector(NBIT_DATA-1 downto 0);
        OUT1    : out std_logic_vector(NBIT_DATA-1 downto 0);
        OUT2    : out std_logic_vector(NBIT_DATA-1 downto 0);

        --additional signals for windowing
        CALL    : in  std_logic; --for subroutine call
        SPILL   : out std_logic; --for spilling, window to MMU
        RTRN    : in  std_logic; --for subroutine return
        FILL    : out std_logic; --for filling, MMU to register
        D_BUS   : inout  std_logic_vector(NBIT_DATA-1 downto 0) --bidirectional bus for data transfer
    );
    end component;
  
begin
    
    RF : WINDOWED_REGISTER_FILE --instantiate register file and map signals
        generic map(
            F =>  F,
            N =>  N,
            M =>  M,

            NBIT_ADD => NBIT_ADD,
            NBIT_DATA => NBIT_DATA
        )
        port map(
            CLK     =>  CLK    ,
            RESET   =>  RESET  ,
            ENABLE  =>  ENABLE    ,
            RD1     =>  RD1    ,
            RD2     =>  RD2    ,
            WR      =>  WR     ,
            ADD_WR  =>  ADD_WR ,
            ADD_RD1 =>  ADD_RD1,
            ADD_RD2 =>  ADD_RD2,
            DATAIN  =>  DATAIN ,
            OUT1    =>  OUT1   ,
            OUT2    =>  OUT2   ,
            CALL    =>  CALL   ,
            RTRN    =>  RTRN   ,
            FILL    =>  fill_o ,
            SPILL   =>  spill_o,
            D_BUS   =>  buss
        );

    rf_mem : MEM 
        generic map (
            DATA_WIDTH => NBIT_DATA,
            SIZE => SIZE
        )
        port map (
            CLK      => CLK,
            RESET    => RESET,
            ENABLE   => ENABLE,
            PUSH     => spill_o,
            POP      => fill_o,
            DATA     => buss
        );
        
end STRUCTURAL;


configuration cfg_combine of comb is
    for STRUCTURAL
        for all : MEM
            use configuration WORK.cfg_mem;
        end for;
        for all : WINDOWED_REGISTER_FILE
            use configuration WORK.cfg_regfile;
        end for;
    end for;
end cfg_combine;
