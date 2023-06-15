library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_textio.all;
use ieee.numeric_std.all;
use work.all;

entity tb_if is
end tb_if;

architecture tb of tb_if is 
	component if_stage is 
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

	end component;
	signal rst        :std_logic := '1';
	signal clk        :std_logic := '0';
	signal addr       :std_logic_vector(5 downto 0);
	--output
	signal dout 	  :std_logic_vector(31 downto 0);
	signal mem_state  : std_logic;
	
begin

	dut : if_stage
	generic map (53,32,6)
	port map (clk, rst, addr, dout, mem_state);

	clk <= not clk after 0.5 ns;

	test_p : process 
	begin
		rst <= '1';
		wait for 10 ns;
		rst <= '0';

		addr <= "000000";
		wait for 2 ns;

		addr <= "000001";
		wait for 2 ns;

		addr <= "000010";
		wait ;
	end process;
end tb;
