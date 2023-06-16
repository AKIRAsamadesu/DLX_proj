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
		id_reg_enable_i:          out std_logic; --'0'=off '1'= on
	    rf_enable_i:              out std_logic;-- '0'=disable '1'= enable
	    rf_r_enable_i:            out std_logic;-- '0' = diable;'1' read data
	  --  rf_w_enable_i:            out std_logic;-- '0' = diable;'1' write data
	  
	  --exe stage
		operand_reg_enable_i:     out std_logic;--'0'=off '1'= on
	    jn_sel_i:                 out std_logic;--  '0' = mormal '1'= branch
	    ri_sel_i:                 out std_logic;-- '0'=r-type, '1'=i-type
	    b_condition_sel_i:        out std_logic;-- '0'="=", '1'="!="
	    jb_sel_i:                 out std_logic;-- '0'=jump, '1'=branch
	    --mem stage
		--operand_reg_enable_i:     out std_logic;--'0'=off '1'= on
	    memory_rw_control_i:      out std_logic; --'0'=read '1' =write
	    memory_enable_i:          out std_logic; -- '0' =off '1' = on
	    --writeback stage
	    output_sel_i:             out std_logic; --'0' = mem '1' = exe
	    rf_w_enable_i:            out std_logic; -- '0' = diable;'1' write data

		--output siganl to exe stage
		cu_func_code_out:        out std_logic_vector(func_code_size-1 downto 0) --used to as the input to exe stage to correspond the calculation
        );
end entity;

architecture str of control_unit is

	signal cw   : std_logic_vector(CW_SIZE - 1 downto 0); -- full control word read from cw_mem
	  -- control word is shifted to the correct stage
	  --signal cw1 : std_logic_vector(CW_SIZE -1 downto 0); -- first stage
	signal cw2 : std_logic_vector(CW_SIZE - 1 downto 0); -- decode stage
	signal cw3 : std_logic_vector(CW_SIZE - 1 - 3 downto 0); -- exe stage
	signal cw4 : std_logic_vector(CW_SIZE - 1 - 3 -5 downto 0); -- mem stage
	signal cw5 : std_logic_vector(CW_SIZE -1 - 3 - 5 - 2 downto 0); -- writeback stage

	signal cw2_j : std_logic_vector(CW_SIZE-1 downto 0); -- decode stage for jump ir
	signal cw3_j : std_logic_vector(CW_SIZE-1-3 downto 0); --exe stage for jump ir

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
	    if rst_i = '1' then                   -- asynchronous reset (active low)
	      --cw1 <= (others => '0');
		    cw2 <= (others => '0');
		    cw3 <= (others => '0');
		    cw4 <= (others => '0');
		    cw5 <= (others => '0');
		    cw2_j <= (others => '0');
		    cw3_j <= (others => '0');
	    elsif clk_i'event and clk_i = '1' then  -- rising clock edge
	        -- for jump ir, only need 2 stage control signal
		    -- if int_opcode=2 or int_opcode=3 or int_opcode=4 or int_opcode=5 or int_opcode=18 or int_opcode=19 then
			   --  cw2_j <= cw;
			   --  cw3_j <= cw2_j(CW_SIZE-1-3 downto 0);
			-- for other irs ,need 4 stage control signal
		    -- else
			    cw2 <= cw;
			    cw3 <= cw2(CW_SIZE -1 - 3 downto 0);
			    cw4 <= cw3(CW_SIZE -1 - 3 - 5 downto 0);
			    cw5 <= cw4(CW_SIZE -1 - 3 - 5 - 2 downto 0);
			-- end if;
	    end if;
	end process CW_PIPE;

	--to make the exe stage can use the same alu 
	TRAN_FUNC : process(opcode_i)
	begin
		if opcode_i=ITYPE_ADDI or opcode_i=JTYPE_J or opcode_i=JTYPE_BEQZ or opcode_i=JTYPE_BNEZ
		  or opcode_i=ITYPE_LW or opcode_i=ITYPE_LBU or opcode_i=ITYPE_LHI or opcode_i=ITYPE_LHU
		  or opcode_i=ITYPE_SW or opcode_i=ITYPE_SB then
			cu_func_code_out <= RTYPE_ADD;
		elsif opcode_i=ITYPE_SUBI then
			cu_func_code_out <= RTYPE_SUB;
		elsif opcode_i=ITYPE_ANDI then
				cu_func_code_out <= RTYPE_AND;
		elsif opcode_i=ITYPE_ORI then
				cu_func_code_out <= RTYPE_OR;
		elsif opcode_i=ITYPE_XORI then
				cu_func_code_out <= RTYPE_XOR;
		elsif opcode_i=ITYPE_SLTI then
				cu_func_code_out <= RTYPE_SLT;
		elsif opcode_i=ITYPE_SGTI then
				cu_func_code_out <= RTYPE_SGT;
		elsif opcode_i=ITYPE_SLEI then
				cu_func_code_out <= RTYPE_SLE;
		elsif opcode_i=ITYPE_SGEI then
				cu_func_code_out <= RTYPE_SGE;
		elsif opcode_i=ITYPE_SLLI then
				cu_func_code_out <= RTYPE_SLL;
		elsif opcode_i=ITYPE_SRLI then
				cu_func_code_out <= RTYPE_SRL;
		elsif opcode_i=ITYPE_SRAI then
				cu_func_code_out <= RTYPE_SRA;
		elsif opcode_i=ITYPE_SEQI then
				cu_func_code_out <= RTYPE_SEQ;
		elsif opcode_i=ITYPE_SNEI then
				cu_func_code_out <= RTYPE_SNE;
		elsif opcode_i=ITYPE_ADDUI then
				cu_func_code_out <= RTYPE_ADDU;
		elsif opcode_i=ITYPE_SUBUI then
				cu_func_code_out <= RTYPE_SUBU;
		elsif opcode_i=ITYPE_SGTUI then
				cu_func_code_out <= RTYPE_SGTU;
		elsif opcode_i=ITYPE_SLTUI then
				cu_func_code_out <= RTYPE_SLTU;
		elsif opcode_i=ITYPE_SGEUI then
				cu_func_code_out <= RTYPE_SGEU;
		end if;
	end process  TRAN_FUNC;

	-- OUTPUT_P : process (cw2_j, cw3_j, cw2, cw3, cw4, cw5)
	-- begin

		-- if int_opcode=2 or int_opcode=3 or int_opcode=4 or int_opcode=5 or int_opcode=18 or int_opcode=19 then
		-- 	--stage two control signals for jump ir
		-- 	id_reg_enable_i <= cw2_j(CW_SIZE -1);
		-- 	rf_enable_i   <= cw2_j(CW_SIZE -2);            
		-- 	rf_r_enable_i <= cw2_j(CW_SIZE -3); 
		-- 	-- stage three control signals for jump ir
		-- 	operand_reg_enable_i <= cw3_j(CW_SIZE -4);
		-- 	jn_sel_i         	 <= cw3_j(CW_SIZE -5);
		-- 	ri_sel_i         	 <= cw3_j(CW_SIZE -6);
		-- 	b_condition_sel_i 	 <= cw3_j(CW_SIZE -7);
		-- 	jb_sel_i          	 <= cw3_j(CW_SIZE -8);	
		-- 	-- stage four control signals
		-- 	memory_rw_control_i   <= cw4(CW_SIZE -9);
		-- 	memory_enable_i      <= cw4(CW_SIZE -10);
			  
		-- 	-- stage five control signals;
		-- 	output_sel_i     <= cw5(CW_SIZE -11);
		-- 	rf_w_enable_i    <= cw5(CW_SIZE -12);
		-- else		
			 -- stage two control signals
			id_reg_enable_i <= cw2(CW_SIZE -1);
			rf_enable_i   	 <= cw2(CW_SIZE -2);            
			rf_r_enable_i 	 <= cw2(CW_SIZE -3);        
			  
			-- stage three control signals
			operand_reg_enable_i <= cw3(CW_SIZE -4);
			jn_sel_i          	 <= cw3(CW_SIZE -5);
			ri_sel_i           	 <= cw3(CW_SIZE -6);
			b_condition_sel_i 	 <= cw3(CW_SIZE -7);
			jb_sel_i          	 <= cw3(CW_SIZE -8);
			  
			-- stage four control signals
			memory_rw_control_i   <= cw4(CW_SIZE -9);
			memory_enable_i      <= cw4(CW_SIZE -10);
			  
			-- stage five control signals;
			output_sel_i     <= cw5(CW_SIZE -11);
			rf_w_enable_i    <= cw5(CW_SIZE -12);
	-- 	end if;
	-- end process OUTPUT_P;



end str;