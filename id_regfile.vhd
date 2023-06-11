library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use work.all;

entity windowed_register_file is
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
end windowed_register_file;

architecture A of windowed_register_file is

    subtype REG_ADDR is natural range 0 to F*2*N + M - 1; -- two blocks(in/out, and local) of N registers allocation for each window + a block of M registers for global registers
    type REG_ARRAY is array (REG_ADDR) of std_logic_vector(NBIT_DATA-1 downto 0);
    signal REGISTERS, NEXTREGISTERS : REG_ARRAY; --internal register file

    --actual physical addresses to internal RF signals
    signal PHY_ADD_WR  : integer; --write
    signal PHY_ADD_RD1 : integer; --read1
    signal PHY_ADD_RD2 : integer; --read2

    signal CANSAVE      : std_logic; --true if subroutine can be called without need of window spilling
    signal CANRESTORE   : std_logic; --true if subroutine can return without without need of window filling

    --internal registers
    type STATETYPE is (init, normalRF, signalSpill, spilling, signalFill, filling);
    signal state, nextState : STATETYPE;
    signal CWP, nextCWP     : integer; --current window pointer
    signal SWP, nextSWP     : integer; --saved window pointer
    signal count, nextCount : integer; --for spilling and filling data

begin

    --Address translation
    --to in,local and out registers : addressing start from current window's first register
    --  window registers in circular buffer
    --to global registers: addressing always to the last M registers
    PHY_ADD_WR  <= ( (CWP*2*N+conv_integer(ADD_WR)) mod (F*2*N) )    when (ADD_WR < 3*N) else --addressing in, local or out registers
                  ( F*2*N-3*N+conv_integer(ADD_WR) )                when (ADD_WR >= 3*N); --addressing global registers
    PHY_ADD_RD1 <= ( (CWP*2*N+conv_integer(ADD_RD1)) mod (F*2*N) )   when (ADD_RD1 < 3*N) else
                   ( F*2*N-3*N+conv_integer(ADD_RD1) )               when (ADD_RD1 >= 3*N);
    PHY_ADD_RD2 <= ( (CWP*2*N+conv_integer(ADD_RD2)) mod (F*2*N) )   when (ADD_RD2 < 3*N) else
                   ( F*2*N-3*N+conv_integer(ADD_RD2) )               when (ADD_RD2 >= 3*N);

    CANSAVE     <= '0' when ((CWP+1) = SWP) else '1'; --true if subroutine call does not need spilling to external memory
    --can save if writing to new wndow does not overwrite oldest window data in the register file
    --otherwise need to save the oldest window data to external memory to restore later

    CANRESTORE  <= '0' when ((CWP-1+F) = SWP) else '1'; --true if subroutine return does not need filling from external memory
    --can restore if new window already contains its data in the register file
    --otherwise need to restore its saved data from external memory

    --process to decide next register values
    CL: process(state,cwp,swp,count,ENABLE,RD1,RD2,WR,PHY_ADD_WR,PHY_ADD_RD1,PHY_ADD_RD2,DATAIN,CALL,RTRN,D_BUS)
    begin
        --default no change in registers and registerfile,
        --bidirectional bus output disabled
        NEXTREGISTERS <= REGISTERS ;
        nextCWP   <= CWP;       --can del
        nextSWP   <= SWP;       --can del?
        nextCount <= count;
        nextState <= state;
        SPILL   <= '0';
        FILL    <= '0';
        D_BUS   <= (others => 'Z');

        if (ENABLE = '1') then --if enabled
            case state is --at different states
                when init => --if init state, reset registers to default values 
                    NEXTREGISTERS <= (others => (others => '0')) ;
                    nextCWP <= 0;
                    nextSWP <= F-1;
                    nextCount <= 0;
                    nextState <= normalRF; --then move to normalRF state
                    D_BUS   <= (others => 'Z');
                when normalRF => --at normalRF, work as normal register file, operations on the current window
                    if(WR = '1') then
                        NEXTREGISTERS(PHY_ADD_WR) <= DATAIN;
                    end if;
                    if(RD1 = '1') then
                        OUT1 <= REGISTERS(PHY_ADD_RD1);
                    end if;
                    if(RD2 = '1') then
                        OUT2 <= REGISTERS(PHY_ADD_RD2);
                    end if;
                    --if subroutine operation
                    if(CALL = '1' and RTRN = '0') then --if subroutine is called
                        if(CANSAVE = '1') then nextCWP <= (CWP + 1); end if; --if spilling not needed, switch window
                        if(CANSAVE = '0') then nextState <= signalSpill; end if; --otherwise, change state
                    end if;
                    if(CALL = '0' and RTRN = '1' and CWP > 0) then --if subroutine returns
                        if(CANRESTORE = '1') then nextCWP <= (CWP-1); end if; --if filling not needed, switch window
                        if(CANRESTORE = '0') then nextState <= signalFill; end if; --otherwise, change state
                    end if;
                when signalSpill => --if signalSpill state, signal SPILL needed signal and prepare to move data out
                    SPILL <= '1'; --signal spill needed
                    nextCount <= 0; --get ready to move data out
                    nextState <= spilling; --change state
                when spilling => --in spilling mode, move 2*N register data value, a register at  a clock and update windwo
                    SPILL <= '1';
                    D_BUS <= REGISTERS((((SWP + 1) mod F)*2*N + count ) mod (F*2*N)); --output registerfile data in current window to D_BUS
                    nextCount <= count + 1;
                    if (count = 2*N-1) then --if all data of current 2 window moved out, update window and switch to normalRF state
                        nextCount <= 0;
                        nextSWP <= (SWP + 1);
                        nextCWP <= (CWP + 1);
                        nextState <= normalRF;
                    end if;
                when signalFill => --if signalFill state, signal FILL needed and prepare to receive data
                    FILL <= '1'; --signal FILL needed
                    nextCount <= 0; --reset count
                    nextState <= filling; --switch to filling state when fill takes place
                when filling => --if filling state, receive window register values, on reg at a time
                    FILL <= '1';
                    --D_BUS <= (others => 'Z');
                    NEXTREGISTERS(((SWP)*2*N + 2*N-1 - count) mod (F*2*N)) <= D_BUS; --save D_BUS value in register file in current window
                    nextCount <= count + 1;
                    if (count = 2*N-1) then --when all data received, update window and move to normalRF state
                        nextCount <= 0;
                        nextSWP <= (SWP - 1);
                        nextCWP <= (CWP - 1);
                        nextState <= normalRF;
                    end if;
                when others =>
                    --illegal state to safe state
                    nextState <= init;
            end case;
        end if;
    end process CL;

--update registers to new value on rising edge of clock
    SR : process(CLK)
    begin
        if(rising_edge (clk)) then
            if (RESET = '1') then --if reset change to init state which resets registers value
                state <= init;
            elsif(RESET = '0') then --otherwise, update registers,trigger process 1 eg CL
                REGISTERS <= NEXTREGISTERS;
                CWP   <= nextCWP;
                SWP   <= nextSWP;
                count <= nextCount;
                state <= nextState;
            end if;
        end if;
    end process SR;

end ;

configuration cfg_regfile of windowed_register_file is
  for A
  end for;
end cfg_regfile;