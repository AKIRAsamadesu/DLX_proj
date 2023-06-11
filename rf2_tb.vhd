library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use WORK.all;

entity tb_windowregisterfile is
end tb_windowregisterfile;

architecture TEST_WINDOW_RF of tb_windowregisterfile is

    --function to find ceiling of base 2 logarithm of the value 
    --to calculate address bits needed from total registers in windowed register file.
    function CLOG2(
        numAddresses : integer
    )
    return integer is
        variable nbit: integer := 0;
    begin
        while(2**nbit < numAddresses) loop
            nbit := nbit + 1;
        end loop;
        return nbit;
    end function CLOG2;



    constant F : integer := 3;       --number of global registers                            
    constant N : integer := 2;       --number of registers in each IN,OUT,LOCAL fixed window 
    constant M : integer := 2;       --number of windows    

    constant NBIT_ADD : integer := CLOG2(F*2*N+M); --number of bits in address from total registers
    constant NBIT_DATA : integer := 8; --num bit in register

    component comb is
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
    end component;

    --testbench stack simulation for spilling and filling operation
    type STACKTYPE is array (0 to 10*F*2*N) of std_logic_vector(NBIT_DATA-1 downto 0); --upto 10 window data spilling
    signal stack : STACKTYPE := (others => (others =>'0'));
    signal stackpointer : integer := 0; --point to top of stack

    --window register file signals
    signal CLK     :  std_logic := '1';
    signal RESET   :  std_logic := '0';
    signal ENABLE  :  std_logic := '0';
    signal RD1     :  std_logic := '0';
    signal RD2     :  std_logic := '0';
    signal WR      :  std_logic := '0';
    signal ADD_WR  :  std_logic_vector(NBIT_ADD-1 downto 0) := (others => '0');
    signal ADD_RD1 :  std_logic_vector(NBIT_ADD-1 downto 0) := (others => '0');
    signal ADD_RD2 :  std_logic_vector(NBIT_ADD-1 downto 0) := (others => '0');
    signal DATAIN  :  std_logic_vector(NBIT_DATA-1 downto 0) := (others => '0');
    signal OUT1    :  std_logic_vector(NBIT_DATA-1 downto 0) := (others => '0');
    signal OUT2    :  std_logic_vector(NBIT_DATA-1 downto 0) := (others => '0');
    signal CALL    :  std_logic := '0';
    signal RTRN    :  std_logic := '0';
    --signal FILL    :  std_logic := '0';
    --signal SPILL   :  std_logic := '0';
    --signal D_BUS   :   std_logic_vector(NBIT_DATA-1 downto 0) :=  (others => 'Z'); --bidirectional data bus. default: Output disabled for reading

    constant T : TIME := 10 ns; --period of 1ns

begin

    UUT_WRF : comb --isntantiate register file and map signals
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
            ENABLE  =>  ENABLE ,
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
            RTRN    =>  RTRN   
            --FILL    =>  FILL   ,
            --SPILL   =>  SPILL  ,
           -- D_BUS   =>  D_BUS
        );

    --T periodic clock
    --CLOCK_PROCESS: CLK <= not CLK after T/2;
     CLK_PROCESS: process
begin
    CLK <= '0';
    wait for T/2;
    CLK <= '1';
    wait for T/2;
end process CLK_PROCESS;


    --generate signals for test
    VECTOR_PROCESS: process
        variable value  : std_logic_vector(NBIT_DATA-1 downto 0) := (others => '0');
        variable add    : std_logic_vector(NBIT_ADD-1 downto 0) := (others => '0');
    begin
        ENABLE <= '1';
        WR <= '1';
        RD1 <= '1';
        RD2 <= '1';

        RESET <= '1';
        wait for 1.5*T;
        RESET <= '0';
        wait for T;

        --start from 0 address 
        add := (others => '0');
        value := (others => '0');

        --call test
        call_test_loop: for subroutine in 0 to 4-1 loop --for 4 subroutine calls
        --before call, populate window registers with new values
            for i in 0 to 3*N+M-1 loop --in each register
            --write values in register
                ADD_WR <= add;
                DATAIN <= value;
                wait for T;
                add := add+1;
                value := value+1;
                --read just inserted value(previous address) and current value (current address) that is being overwritten 
                ADD_RD1 <= add-1;
                if(add < 3*N+M) then ADD_RD2 <= add; else ADD_RD2 <= (others => '0'); end if;
            end loop;
            if(subroutine < 4-1) then -- in all subroutines except last
                --call another subroutine
                CALL <= '1';
                wait for T;
                CALL <= '0';
                --check if spill is needed
                wait for 0.1*T;
                --if (SPILL = '1') then
                    --if spill needed, save the data, that will be spilled by wrf in next clocks, in stack incrementing stack pointer
                    --for i in 0 to 2*N-1 loop
                        --wait for T;
                        --stack(stackpointer)<= D_BUS;
                        --stackpointer <= stackpointer+1;
                    --end loop;
                --end if;
                wait for 0.9*T;
            end if;
            add := (others => '0');
        end loop call_test_loop;
        --

        --return test
        return_test_loop: for subroutine in 4-1 downto 0 loop --for all called subroutines
        --return from subroutine
            RTRN <= '1';
            wait for T;
            RTRN <= '0';
            wait for 0.1*T;
            --check if fill needed
            --if (FILL = '1') then
                  --if fill needed, in next clocks provide previously stored value from stack to D_BUS;
            --    for i in 0 to 2*N-1 loop
            --        stackpointer <= stackpointer-1;
            --        wait for T;
            --        D_BUS <=  stack(stackpointer);
            --    end loop;
            --end if;
            wait for 0.9*T;

            --after return populate window registers with new values
            add := (others => '0');
            for i in 0 to 3*N+M-1 loop --in each register in window
            --write value
                ADD_WR <= add;
                DATAIN <= value;
                wait for T;
                add := add+1;
                value := value+1;
                --read just inserted value(previos address) and value that is being overwritten(curent address)
                ADD_RD1 <= add-1;
                if(add < 3*N+M) then ADD_RD2 <= add; else ADD_RD2 <= (others => '0'); end if;
            end loop;
        end loop return_test_loop;
        wait;

    end process VECTOR_PROCESS;


end TEST_WINDOW_RF;


configuration cfg_tb2 of tb_windowregisterfile is
    for TEST_WINDOW_RF
        for all : comb
            use configuration WORK.cfg_combine;
        end for;
    end for;
end cfg_tb2;