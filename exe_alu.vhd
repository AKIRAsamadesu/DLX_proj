library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ALU is
  generic (
    DATA_WIDTH: positive := 8;
    func_code_width: positive := 11
  );
  port (
    A: in std_logic_vector(DATA_WIDTH - 1 downto 0);
    B: in std_logic_vector(DATA_WIDTH - 1 downto 0);
    Op: in std_logic_vector(10 downto 0);               ----
    Result: out std_logic_vector(DATA_WIDTH - 1 downto 0);
    exe_add_state_o: out std_logic;
    exe_mult_state_o: out std_logic;
    exe_div_state_o: out std_logic;
    O: out std_logic
  );
end entity ALU;               ----


architecture Behavioral of ALU is
  
  signal SUBTRACT_signal: std_logic; --  signal for SUBTRACT value
  signal AdderResult: std_logic_vector(DATA_WIDTH - 1 downto 0);
  signal MulResult: std_logic_vector(2*DATA_WIDTH - 1 downto 0);
  signal O_Result: std_logic := '0';    --overlow flag
  signal DivResult: std_logic_vector(DATA_WIDTH - 1 downto 0);


  component RCA is
    generic (
      DATA_WIDTH: positive := 32
    );
    port (
      A: in std_logic_vector(DATA_WIDTH - 1 downto 0);
      B: in std_logic_vector(DATA_WIDTH - 1 downto 0);
      SUBTRACT: in std_logic;
      Ci: in std_logic;
      S: out std_logic_vector(DATA_WIDTH - 1 downto 0);
      Co: out std_logic;
      O: out std_logic
    );
  end component;

  component BOOTHMUL is
    generic (NBIT : integer := 32);
    Port (
        A : in   std_logic_vector(NBIT-1 downto 0);
        B : in   std_logic_vector(NBIT-1 downto 0);
        Y : out  std_logic_vector(2*NBIT-1 downto 0)
    );
  end component;

  component Restoring_Division is
   generic (
        DATA_WIDTH: positive := 32
    );
    port (
        dividend: in std_logic_vector(DATA_WIDTH - 1 downto 0);
        divisor: in std_logic_vector(DATA_WIDTH - 1 downto 0);
        quotient: out std_logic_vector(DATA_WIDTH - 1 downto 0);
        remainder: out std_logic_vector(DATA_WIDTH - 1 downto 0)
    );
  end component;

begin

  -- Adder component instance
  Adder_inst: entity work.RCA
    generic map (
      DATA_WIDTH => DATA_WIDTH
    )
    port map (
      A => A,
      B => B,
      SUBTRACT => SUBTRACT_signal,  -- Use SUBTRACT_signal for SUBTRACT input
      Ci => '0',
      S => AdderResult,
      Co => open,
      O => O_Result
    );

  -- Mul component instance
  Mul_inst: entity work.BOOTHMUL
    generic map (
      NBIT => DATA_WIDTH
    )
    port map (
      A => A,
      B => B,
      Y => MulResult
    );


    Div_inst: entity work.Restoring_Division 
    generic map (
      DATA_WIDTH => DATA_WIDTH
    )
    port map (
      dividend => A,
      divisor => B,
      quotient => DivResult,
      remainder => open
    );

  -- Output multiplexer based on Op
  process(A,B,op,AdderResult,MulResult)
  variable Temp_or: std_logic_vector(DATA_WIDTH - 1 downto 0) := (others => '0');
  variable Temp_and: std_logic_vector(DATA_WIDTH - 1 downto 0) := (others => '0');
  variable Temp_xor: std_logic_vector(DATA_WIDTH - 1 downto 0) := (others => '0');
  variable Temp_lsl: std_logic_vector(DATA_WIDTH - 1 downto 0) := (others => '0');
  variable shift_amount_l: integer range 0 to DATA_WIDTH - 1;
  variable Temp_lsr: std_logic_vector(DATA_WIDTH - 1 downto 0) := (others => '0');
  variable shift_amount_r: integer range 0 to DATA_WIDTH - 1;
  variable Temp_sra: std_logic_vector(DATA_WIDTH - 1 downto 0) := (others => '0');
  variable shift_arith_r: integer range 0 to DATA_WIDTH - 1;
  variable result_comp: std_logic_vector(DATA_WIDTH - 1 downto 0);


  begin
    exe_add_state_o <= '0';
    exe_mult_state_o <= '0';
    exe_div_state_o <= '0';

    for i in 0 to DATA_WIDTH - 1 loop       --or
      Temp_or(i) := A(i) or B(i);     
    end loop;

    for i in 0 to DATA_WIDTH - 1 loop       --and
      Temp_and(i) := A(i) and B(i);     
    end loop;

    for i in 0 to DATA_WIDTH - 1 loop       --xor
      Temp_xor(i) := A(i) xor B(i);     
    end loop;

    shift_amount_l := to_integer(unsigned(B));
    for i in 0 to DATA_WIDTH - 1 loop
      if i < shift_amount_l then
        Temp_lsl(i) := '0';
      else
        Temp_lsl(i) := A(i - shift_amount_l);
      end if;
    end loop;                               --sll

    shift_amount_r := to_integer(unsigned(B));
    for i in 0 to DATA_WIDTH - 1 loop
      if i + shift_amount_r >= DATA_WIDTH then
        Temp_lsr(i) := '0';
      else
        Temp_lsr(i) := A(i + shift_amount_r);
      end if;
    end loop;                                --slr

    shift_arith_r := to_integer(unsigned(B));
    for i in 0 to DATA_WIDTH - 1 loop
      if i + shift_arith_r >= DATA_WIDTH then
        Temp_sra(i) := A(DATA_WIDTH -1);
      else
        Temp_sra(i) := A(i + shift_amount_r);
      end if;
    end loop;                                --sra



    case Op is                  --change "xx" to cooperate the operation
      when "00000100101" => Result <= std_logic_vector(Temp_or);
      O <= '0';                                              -- Logic OR  1
      when "00000100100" => Result <= std_logic_vector(Temp_and);  
      O <= '0';                                              -- Logic and  2
      when "00000100110" => Result <= std_logic_vector(Temp_xor); 
      O <= '0';                                              -- Logic xor  3
      when "00000000100" => Result <= std_logic_vector(Temp_lsl);  
      O <= '0';                                              -- Logic Left Shift  4
      when "00000000110" => Result <= std_logic_vector(Temp_lsr);  
      O <= '0';                                              -- Logic Right Shift  5
      when "00000000111" => Result <= std_logic_vector(Temp_sra);  
      O <= '0';                                              -- Arith Right Shift  5
      when "00000100000" =>                                        -- Perform add  6
          SUBTRACT_signal <= '0';
          Result <= AdderResult;
          O <= O_Result;       --overflow   
          exe_add_state_o <= '1';                      
      when "00000100010" =>                                        -- Perform sub  7
          SUBTRACT_signal <= '1';
          Result <= AdderResult;
          O <= O_Result; 
          exe_add_state_o <= '1';                                                       
      when "00000101001" =>                                        -- Perform sne  8
          SUBTRACT_signal <= '1';
          result_comp := AdderResult;
          if to_integer(unsigned(result_comp)) = 0 then
            Result <= (others => '0');
          else
            Result <= (others => '0');
            Result(0) <= '1';
            end if; 
          O <= '0';
          exe_add_state_o <= '1';
      when "00000101100" =>                                        -- Perform sle  9
          SUBTRACT_signal <= '1';
          result_comp := AdderResult;
          if to_integer(signed(result_comp)) > 0 then
            Result <= (others => '0');
          else
            Result <= (others => '0');
            Result(0) <= '1';
            end if; 
          O <= '0';
          exe_add_state_o <= '1';
      when "00000101010" =>                                        -- Perform slt  10
          SUBTRACT_signal <= '1';
          result_comp := AdderResult;
          if to_integer(signed(result_comp)) < 0 then
            Result <= (others => '0');
            Result(0) <= '1';
          else
            Result <= (others => '0');
            end if; 
          O <= '0';
          exe_add_state_o <= '1';
      when "00000101101" =>                                        -- Perform sge  11 
          SUBTRACT_signal <= '1';
          result_comp := AdderResult;
          if to_integer(signed(result_comp)) < 0 then
            Result <= (others => '0');
          else
            Result <= (others => '0');
            Result(0) <= '1';
            end if; 
          O <= '0';
      when "00000101011" =>                                        -- Perform sgt  12
          SUBTRACT_signal <= '1';
          result_comp := AdderResult;
          if to_integer(signed(result_comp)) > 0 then
            Result <= (others => '0');
            Result(0) <= '1';
          else
            Result <= (others => '0');
            end if; 
          O <= '0';
          exe_add_state_o <= '1';
      when "00000100001" =>                                        -- Perform addu  13
          SUBTRACT_signal <= '0';
          Result <= AdderResult; 
          O <= '0';
          exe_add_state_o <= '1';                           
      when "00000100011" =>                                        -- Perform subu  14
          SUBTRACT_signal <= '1';
          Result <= AdderResult;
          O <= '0';
          exe_add_state_o <= '1';
      when "00000101000" =>                                        -- Perform seq  15
          SUBTRACT_signal <= '1';
          result_comp := AdderResult;
          if to_integer(signed(result_comp)) = 0 then
            Result <= (others => '0');
            Result(0) <= '1';
          else
            Result <= (others => '0');
            end if;  
          O <= '0';
          exe_add_state_o <= '1';
      when "00000001110" =>                                        -- Perform mul  16
          Result(DATA_WIDTH - 1 downto 0) <= MulResult(DATA_WIDTH - 1 downto 0);
          O <= '0'; 
          exe_mult_state_o <= '1';   
      when "10000001110" =>                                        -- Perform div  17 -- bad funccode-
          Result(DATA_WIDTH - 1 downto 0) <= DivResult(DATA_WIDTH - 1 downto 0);
          O <= '0';   
          exe_div_state_o <= '1';                       

      -- Add other cases for different operations
      when others => Result <= (others => '0');
    end case;
  end process;

end architecture Behavioral;
