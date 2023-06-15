library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use WORK.all;

entity MEM is
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
end MEM;

architecture A of MEM is
    type STACK_ARRAY is array (0 to SIZE-1) of std_logic_vector(DATA_WIDTH-1 downto 0);
    signal STACK : STACK_ARRAY;

    signal stack_pointer : integer range 0 to SIZE-1 := 0;

begin

    process (CLK)
begin
    if rising_edge(CLK) then
        if RESET = '1' then
            STACK <= (others => (others => '0'));
            stack_pointer <= 0;
            DATA <= (others => 'Z');  -- 在复位时初始化 DATA 总线
        elsif ENABLE = '1' then
            if PUSH = '1' then
                STACK(stack_pointer) <= DATA;
                stack_pointer <= stack_pointer + 1;
            end if;

            if POP = '1' then
                stack_pointer <= stack_pointer - 1;
                DATA <= STACK(stack_pointer);
            end if;
        end if;
    end if;
end process;

end architecture A;

configuration cfg_mem of MEM is
  for A
  end for;
end cfg_mem;