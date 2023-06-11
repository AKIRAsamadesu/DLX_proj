library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use std.textio.all;
use ieee.std_logic_textio.all;


-- Instruction memory for DLX
-- Memory filled by a process which reads from a file
-- file name is "test.asm.mem"
entity iram is
  generic (
    RAM_DEPTH : integer := 48; -- the number of instructurns
    I_SIZE : integer := 32;
    ADDR_SIZE : integer := 6);
  port (
    Clk  : in std_logic;
    Rst  : in  std_logic;
    Addr : in  std_logic_vector(ADDR_SIZE - 1 downto 0);
    Dout : out std_logic_vector(I_SIZE - 1 downto 0)
    );

end iram;

architecture IRam_Bhe of iram is

  type RAMtype is array ( 0 to RAM_DEPTH - 1) of integer; --std_logic_vector(I_SIZE - 1 downto 0);-- std_logic_vector(I_SIZE - 1 downto 0);

  signal IRAM_mem : RAMtype;

begin  -- IRam_Bhe
  Output_data : process (Clk, Rst)
  begin
    if Rst = '0' then
      if Clk='1' and Clk'event then
        Dout <= conv_std_logic_vector(IRAM_mem(conv_integer(unsigned(Addr))),I_SIZE);
      end if;
    end if;
  end process Output_data;

  -- purpose: This process is in charge of filling the Instruction RAM with the firmware
  -- type   : combinational
  -- inputs : Rst
  -- outputs: IRAM_mem
  FILL_MEM_P: process (Rst)
    file mem_fp: text;
    variable file_line : line;
    variable index : integer := 0;
    variable tmp_data_u : std_logic_vector(I_SIZE-1 downto 0);
  begin  -- process FILL_MEM_P
    if (Rst = '0') then
      file_open(mem_fp,"test.asm.mem",READ_MODE);
      while (not endfile(mem_fp)) loop
        readline(mem_fp,file_line);
        hread(file_line,tmp_data_u);
        IRAM_mem(index) <= conv_integer(unsigned(tmp_data_u));       
        index := index + 1;
      end loop;
    end if;
  end process FILL_MEM_P;

end IRam_Bhe;
