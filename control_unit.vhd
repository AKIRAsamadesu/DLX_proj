-- library ieee;
-- use ieee.std_logic_1164.all;
-- use ieee.numeric_std.all;
-- use work.myTypes.all;
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;
use work.myTypes.all;
use ieee.numeric_std.all;
use work.all;

entity control_unit is
    generic(func_code_size: integer :=11;
            op_code_size  : integer :=6);
    port(
    -- input signals
    	clk_i        : in std_logic;
    	rst_i        : in std_logic;
    	opcode_i     : in std_logic_vector(op_code_size-1 downto 0);
    	func_i       : in std_logic_vector(func_code_size-1 downto 0);

    -- output signals
    	--decode stage
	    rf_enable_i:              out std_logic;-- '0'=disable '1'= enable
	    rf_r_enable_i:            out std_logic;-- '0' = diable;'1' read data
	  --  rf_w_enable_i:            out std_logic;-- '0' = diable;'1' write data
	    --exe stage
	    jn_sel_i:                 out std_logic;--  '0' = mormal '1'= branch
	    ri_sel_i:                 out std_logic;-- '0'=r-type, '1'=i-type
	    b_condition_sel_i:        out std_logic;-- '0'="=", '1'="!="
	    jb_sel_i:                 out std_logic;-- '0'=jump, '1'=branch
	    --mem stage
	    memory_rw_control_i:      out std_logic;
	    memory_enable_i:          out std_logic;
	    --writeback stage
	    output_sel_i:             out std_logic;
	    rf_w_enable_i:            out std_logic-- '0' = diable;'1' write data
        );
end entity;

architecture str of control_unit is

	signal cw   : std_logic_vector(CW_SIZE - 1 downto 0); -- full control word read from cw_mem
	  -- control word is shifted to the correct stage
	  --signal cw1 : std_logic_vector(CW_SIZE -1 downto 0); -- first stage
	signal cw2 : std_logic_vector(CW_SIZE - 1 downto 0); -- decode stage
	signal cw3 : std_logic_vector(CW_SIZE - 1 - 2 downto 0); -- exe stage
	signal cw4 : std_logic_vector(CW_SIZE - 1 - 2 -4 downto 0); -- mem stage
	signal cw5 : std_logic_vector(CW_SIZE -1 - 2 - 4 - 2 downto 0); -- writeback stage
	signal cw_mem_pointer : integer := 0; -- the pointer of cw_mem
    signal int_opcode  : integer := 0; -- the integer value of opcode


    begin
    	int_opcode <= conv_integer(opcode_i);
    	--cw <= (others => '0');
    	cw <= cw_mem(cw_mem_pointer);

    	CW_GET: process (int_opcode)
    	begin
    	    if (int_opcode = 21) then
		        cw_mem_pointer <= 0; --NOP
		    elsif (int_opcode = 0) then
		        cw_mem_pointer <= 1; --RTYPE
		    elsif    (int_opcode = 8) 
		          or (int_opcode = 10) 
		          or (int_opcode = 12)
		          or (int_opcode = 13)
		          or (int_opcode = 14)
		          or (int_opcode = 26)
		          or (int_opcode = 27)
		          or (int_opcode = 28)
		          or (int_opcode = 29)
		          or (int_opcode = 20)
		          or (int_opcode = 22)
		          or (int_opcode = 23)
		          or (int_opcode = 24)
		          or (int_opcode = 25)
		          or (int_opcode = 9)
		          or (int_opcode = 11)
		          or (int_opcode = 59)
		          or (int_opcode = 58)
		          or (int_opcode = 61)  then
		          cw_mem_pointer <= 2;  --ITYPE
		    elsif    (int_opcode = 35)
		          or (int_opcode = 36) 
		          or (int_opcode = 15)
		          or (int_opcode = 37) then
		          cw_mem_pointer <= 3; --ITYPE_L
		    elsif    (int_opcode = 43)
		          or (int_opcode = 40) then
		          cw_mem_pointer <= 4; --ITYPE_S
		    elsif    (int_opcode = 2) then
		          cw_mem_pointer <= 5;
		    elsif    (int_opcode = 3) then
		          cw_mem_pointer <= 6;
		    elsif    (int_opcode = 4) then
		          cw_mem_pointer <= 7;
		    elsif    (int_opcode = 5) then
		          cw_mem_pointer <= 8;
		    elsif    (int_opcode = 18) then
		          cw_mem_pointer <= 9;
		    elsif    (int_opcode = 19) then
		          cw_mem_pointer <= 10;
		    end if;
		  -- cw <= cw_mem(cw_mem_pointer);
	end process CW_GET;

	  -- process to pipeline control words
	CW_PIPE: process (clk_i, rst_i)
	begin  -- process Clk
	    if rst_i = '0' then                   -- asynchronous reset (active low)
	      --cw1 <= (others => '0');
	      cw2 <= (others => '0');
	      cw3 <= (others => '0');
	      cw4 <= (others => '0');
	      cw5 <= (others => '0');
	    elsif clk_i'event and clk_i = '1' then  -- rising clock edge
	      cw2 <= cw;
	      cw3 <= cw2(CW_SIZE -1 - 2 downto 0);
	      cw4 <= cw3(CW_SIZE -1 - 2 - 4 downto 0);
	      cw5 <= cw4(CW_SIZE -1 - 2 - 4 - 2 downto 0);
	    end if;
	end process CW_PIPE;

		  -- stage two control signals
	  rf_enable_i   <= cw2(CW_SIZE -1);            
	  rf_r_enable_i <= cw2(CW_SIZE -2);        
	  
	  -- stage three control signals
	 jn_sel_i          <= cw3(CW_SIZE -3);
	 ri_sel_i          <= cw3(CW_SIZE -4);
	 b_condition_sel_i <= cw3(CW_SIZE -5);
	 jb_sel_i          <= cw3(CW_SIZE -6);
	  
	  -- stage four control signals
	  memory_rw_control_i   <= cw4(CW_SIZE -7);
	  memory_enable_i      <= cw4(CW_SIZE -8);
	  
	  -- stage five control signals;
	  output_sel_i     <= cw5(CW_SIZE -9);
	  rf_w_enable_i    <= cw5(CW_SIZE -10);




end str;