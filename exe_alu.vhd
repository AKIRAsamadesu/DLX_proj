library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ALU is
  generic (
    DATA_WIDTH: positive := 8
  );
  port (
    A: in std_logic_vector(DATA_WIDTH - 1 downto 0);
    B: in std_logic_vector(DATA_WIDTH - 1 downto 0);
    Op: in std_logic_vector(4 downto 0);
    Result: out std_logic_vector(DATA_WIDTH - 1 downto 0);
    O: out std_logic
  );
end entity ALU;

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
  variable result_comp: std_logic_vector(DATA_WIDTH - 1 downto 0);

  begin
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



    case Op is                  --change "xx" to cooperate the operation
      when "00000" => Result <= std_logic_vector(Temp_or);
      O <= '0';                                              -- Logic OR
      when "00001" => Result <= std_logic_vector(Temp_and);  
      O <= '0';                                              -- Logic and
      when "00010" => Result <= std_logic_vector(Temp_xor); 
      O <= '0';                                              -- Logic xor
      when "00011" => Result <= std_logic_vector(Temp_lsl);  
      O <= '0';                                              -- Logic Left Shift
      when "00100" => Result <= std_logic_vector(Temp_lsr);  
      O <= '0';                                              -- Logic Right Shift
      when "00101" =>                                        -- Perform add
          SUBTRACT_signal <= '0';
          Result <= AdderResult;
          O <= O_Result;       --overflow                         
      when "00110" =>                                        -- Perform sub
          SUBTRACT_signal <= '1';
          Result <= AdderResult;
          O <= O_Result;                                                        
      when "00111" =>                                        -- Perform sne
          SUBTRACT_signal <= '1';
          result_comp := AdderResult;
          if to_integer(unsigned(result_comp)) = 0 then
            Result <= (others => '0');
          else
            Result <= (others => '0');
            Result(0) <= '1';
            end if; 
          O <= '0';
      when "01000" =>                                        -- Perform sle
          SUBTRACT_signal <= '1';
          result_comp := AdderResult;
          if to_integer(signed(result_comp)) > 0 then
            Result <= (others => '0');
          else
            Result <= (others => '0');
            Result(0) <= '1';
            end if; 
          O <= '0';
      when "01001" =>                                        -- Perform sge
          SUBTRACT_signal <= '1';
          result_comp := AdderResult;
          if to_integer(signed(result_comp)) < 0 then
            Result <= (others => '0');
          else
            Result <= (others => '0');
            Result(0) <= '1';
            end if; 
          O <= '0';
      when "01010" =>                                        -- Perform addu
          SUBTRACT_signal <= '0';
          Result <= AdderResult; 
          O <= '0';                           
      when "01011" =>                                        -- Perform subu
          SUBTRACT_signal <= '1';
          Result <= AdderResult;
          O <= '0';
      when "01100" =>                                        -- Perform seq
          SUBTRACT_signal <= '1';
          result_comp := AdderResult;
          if to_integer(signed(result_comp)) = 0 then
            Result <= (others => '0');
            Result(0) <= '1';
          else
            Result <= (others => '0');
            end if;  
          O <= '0';
      when "01101" =>                                        -- Perform mul
          Result(DATA_WIDTH - 1 downto 0) <= MulResult(DATA_WIDTH - 1 downto 0);
          O <= '0';    
      when "01110" =>                                        -- Perform div
          Result(DATA_WIDTH - 1 downto 0) <= DivResult(DATA_WIDTH - 1 downto 0);
          O <= '0';                          

      -- Add other cases for different operations
      when others => Result <= (others => '0');
    end case;
  end process;

end architecture Behavioral;
