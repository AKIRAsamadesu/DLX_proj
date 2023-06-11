library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;


entity if_stage is 
generic (
		MEM_DEPTH  : integer := 53; -- the number of instructions --.mem file setting
		data_width : integer := 32; -- the number of bit of each instruction
		addr_width : integer := 6  -- the size od pc -- total 53 instructions

	);
port(
	    if_clk_i           : in  std_logic;  -- Clock
    	if_rst_i           : in  std_logic;  -- Reset:Active-Low
    	if_curr_addr_i     : in  std_logic_vector(addr_width-1 downto 0); -- the port used to receive the addr from decode stage mu
    	if_instruction_o   : out std_logic_vector(data_width-1 downto 0);
    	if_ins_mem_state   : out std_logic

	);
end if_stage;

architecture str of if_stage is

	component IRAM is
		  generic (
				    RAM_DEPTH : integer := 48; -- the number of instructurns
				    I_SIZE : integer := 32);
		  port   (
		  		Clk  : in std_logic;
			    Rst  : in  std_logic;
			    Addr : in  std_logic_vector(I_SIZE - 1 downto 0);
			    Dout : out std_logic_vector(I_SIZE - 1 downto 0)
		        );

	end component;

	signal inst_mem_out       :	std_logic_vector(data_width-1 downto 0)  :=(others => '0'); -- the output from Instruction memory

 begin

    	UMEM : IRAM
    	generic map (MEM_DEPTH, data_width)
    	port map (if_clk_i, if_rst_i, if_curr_addr_i, inst_mem_out);
    	if_instruction_o <= inst_mem_out;
    	if_ins_mem_state <= '1';

 end str; 	



	




