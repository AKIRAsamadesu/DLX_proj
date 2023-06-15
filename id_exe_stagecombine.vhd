library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity combine_part2 is
    generic (
        F : integer := 8; --number of windows
        N : integer := 8; --number of registers in each IN,OUT,LOCAL (fixed) window
        M : integer := 8; --number of global registers 

        NBIT_ADD : integer := 5; --number of bits in address
        NBIT_DATA : integer := 64   --number of bits in registers
    );  
	Port (	
            --register file signals with virtual addresses
        CLK     : in  std_logic;
        RESET   : in  std_logic;
        EN1     : in  std_logic;
        RD1     : in  std_logic;
        RD2     : in  std_logic;
        WF1     : in  std_logic;
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
        D_BUS   : inout  std_logic_vector(NBIT_DATA-1 downto 0); --bidirectional bus for data transfer

        --
        S1      : in  std_logic;
        S2      : in  std_logic;
        ALU1    : in  std_logic;
        ALU2    : in  std_logic;
        EN2     : in  std_logic;

        --
        INP1    : in  std_logic_vector(NBIT_ADD-1 downto 0);
        INP2    : in  std_logic_vector(NBIT_ADD-1 downto 0)

        );
end combine_part2;

architecture STRUCTURAL of combine_part2 is

    signal RF_OUT1: std_logic_vector(NBIT_ADD-1 downto 0);
    signal RF_OUT2: std_logic_vector(NBIT_ADD-1 downto 0);
    signal in1_out: std_logic_vector(NBIT_ADD-1 downto 0);
    signal A_out: std_logic_vector(NBIT_ADD-1 downto 0);
    signal B_out: std_logic_vector(NBIT_ADD-1 downto 0);
    signal in2_out: std_logic_vector(NBIT_ADD-1 downto 0);
    signal rd1_out: std_logic_vector(NBIT_ADD-1 downto 0);
    signal mux1_out: std_logic_vector(NBIT_ADD-1 downto 0);
    signal mux2_out: std_logic_vector(NBIT_ADD-1 downto 0);
    signal alu_out: std_logic_vector(NBIT_ADD-1 downto 0);
    signal aluout_out: std_logic_vector(NBIT_ADD-1 downto 0);
    signal me_out: std_logic_vector(NBIT_ADD-1 downto 0);
    signal rd2_out: std_logic_vector(NBIT_ADD-1 downto 0);

    component ff
    generic (
    NBIT_DATA : integer := 64
  );
  port (
    clk   : in  std_logic;
    reset : in  std_logic;
    enable : in  std_logic;
    d     : in  std_logic_vector(NBIT_DATA-1 downto 0);
    q     : out std_logic_vector(NBIT_DATA-1 downto 0)
  );
    end component;

    component mux
    generic (
    NBIT_DATA : integer := 64
  );
  port (
    sel     : in  std_logic;
    in0     : in  std_logic_vector(NBIT_DATA-1 downto 0);
    in1     : in  std_logic_vector(NBIT_DATA-1 downto 0);
    output  : out std_logic_vector(NBIT_DATA-1 downto 0)
  );
    end component;

    component ALU
    generic (
    NBIT_DATA : integer := 64
  );
  port (
    alu1_sel : in  std_logic;
    alu2_sel : in  std_logic;
    oper1    : in  std_logic_vector(NBIT_DATA-1 downto 0);
    oper2    : in  std_logic_vector(NBIT_DATA-1 downto 0);
    result   : out std_logic_vector(NBIT_DATA-1 downto 0)
  );
    end component;

    component rf_comb
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
        CALL    : in  std_logic; --for subroutine call;     
        RTRN    : in  std_logic --for subroutine return       
    );
end component rf_comb;
  
begin
    
           RF : entity work.rf_comb --isntantiate register file and map signals
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
            ENABLE  =>  EN1    ,
            RD1     =>  RD1    ,
            RD2     =>  RD2    ,
            WR      =>  WF1     ,
            ADD_WR  =>  rd2_out ,
            ADD_RD1 =>  ADD_RD1,
            ADD_RD2 =>  ADD_RD2,
            DATAIN  =>  DATAIN ,
            OUT1    =>  RF_OUT1   ,
            OUT2    =>  RF_OUT2   ,
            CALL    =>  CALL   ,
            RTRN    =>  RTRN   
           -- FILL    =>  FILL   ,
           -- SPILL   =>  SPILL  ,
           -- D_BUS   =>  D_BUS
        );

       ff_in1 : ff Generic map (NBIT_DATA) Port Map (clk,reset,EN1,INP1,in1_out);

       ff_A : ff Generic map (NBIT_DATA) Port Map (clk,reset,EN1,RF_OUT1,A_out);

       ff_B : ff Generic map (NBIT_DATA) Port Map (clk,reset,EN1,RF_OUT2,B_out);

       ff_in2 : ff Generic map (NBIT_DATA) Port Map (clk,reset,EN1,INP2,in2_out);
       
       ff_rd1 : ff Generic map (NBIT_DATA) Port Map (clk,reset,EN1,ADD_WR,rd1_out);

       mux1 : mux Generic map (NBIT_DATA) Port Map (S1,in1_out,A_out,mux1_out);

       mux2 : mux Generic map (NBIT_DATA) Port Map (S2,B_out,in2_out,mux2_out);

       alu_mix : ALU Generic map (NBIT_DATA) Port Map (ALU1,ALU2,mux1_out,mux2_out,alu_out); 

       ff_aluout : ff Generic map (NBIT_DATA) Port Map (clk,reset,EN2,alu_out,aluout_out);

       ff_me : ff Generic map (NBIT_DATA) Port Map (clk,reset,EN2,B_out,me_out);

       ff_rd2 : ff Generic map (NBIT_DATA) Port Map (clk,reset,EN2,rd1_out,rd2_out);

       
        
end STRUCTURAL;


configuration cfg_combine_part2 of combine_part2 is
        for STRUCTURAL
               for all : ff
                        use configuration WORK.cfg_ff;
                end for;
                for all : mux
                        use configuration WORK.cfg_mux21;
                end for;
                for all : alu
                        use configuration WORK.cfg_alu;
                end for;
                for all : rf_comb
                        use configuration WORK.cfg_combine;
                end for;
        end for;
end cfg_combine_part2;
