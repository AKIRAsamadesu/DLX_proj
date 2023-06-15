library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;


entity if_stage is 
generic (mem_depth  : integer := 53; -- the number of instructions --.mem file setting
		 data_width : integer := 32; -- the number of bit of each instruction
		 addr_width : integer := 32);  -- the size od pc -- total 53 instructions
port(if_clk_i           : in  std_logic;  -- clock
     if_rst_i           : in  std_logic;  -- 0=normal 1=reset
     if_curr_addr_i     : in  std_logic_vector(addr_width-1 downto 0); -- the port used to receive the addr from decode stage
     if_instruction_o   : out std_logic_vector(data_width-1 downto 0);
     if_ins_mem_state   : out std_logic);
end if_stage;

architecture str of if_stage is
	component iram is
		  generic (RAM_DEPTH : integer := 48; -- the number of instructurns
				   I_SIZE : integer := 32;
				   ADDR_SIZE : integer := 6);
		  port   (clk  : in std_logic;
			      rst  : in  std_logic;
			      addr : in  std_logic_vector(I_SIZE - 1 downto 0);
			      dout : out std_logic_vector(I_SIZE - 1 downto 0));
	end component;

 begin
    	UMEM : iram generic map (ram_depth=>mem_depth, 
    	                         i_size=>data_width,
    	                         addr_size=>addr_width)
    	            port map (clk=>if_clk_i, 
                              rst=>if_rst_i, 
                              addr=>if_curr_addr_i, 
                              dout=>if_instruction_o);
    	if_ins_mem_state <= '1';

 end str; 	---from ZhouCH



	




