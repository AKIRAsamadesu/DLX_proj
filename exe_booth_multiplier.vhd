library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.std_logic_signed.all;


entity BOOTHMUL is
    generic (NBIT : integer := 32);
    Port (
        A : in   std_logic_vector(NBIT-1 downto 0);
        B : in   std_logic_vector(NBIT-1 downto 0);
        Y : out  std_logic_vector(2*NBIT-1 downto 0)
    );
end BOOTHMUL;

architecture MIXED of BOOTHMUL is

    --signal to add leading and trailing 0s to B 
    --  one trailing 0 always
    --  if even nbit, two leading 0 otherwise 1 leading 0.
    constant B_EXTENDED_MAXi :integer := NBIT + 1 - (NBIT mod 2); --max index in extended B where range is (B_EXTENDED_MAXi downto -1)
    signal B_extended : std_logic_vector(B_EXTENDED_MAXi +1 downto -1 +1) := (others => '0'); -- range (B_EXTENDED_MAXi downto -1) shifted left

    -- encoder output array, 
    --  as many as number of encoders
    --  3 bit output each
    constant NUM_ENCODER : integer := NBIT/2 + 1; --or B_EXTENDED_MAXi/2, --number of encoders or muxes  
    type ENCODER_OUTPUT_TYPE is array (0 to NUM_ENCODER-1) of std_logic_vector(2 downto 0);
    signal encoder_output : ENCODER_OUTPUT_TYPE := (others => (others => '0'));

    --array to hold the multiples of A (shifted A) for muxes to select from.
    --  NBIT/2+1 encoders needed for same amount of selection signals from encoders to muxes, generated from the extended B signal.
    --  size of shifted signals is  size of A + maximum shift amount to hold all needed multiples of A
    constant MAX_SHIFT : integer := NBIT+(2*NUM_ENCODER-1); --maximum shift amount
    type SHIFTED_ARRAY_TYPE is array (0 to NUM_ENCODER*2-1) of std_logic_vector(NBIT+MAX_SHIFT-1 downto 0);
    signal A_shifted_array : SHIFTED_ARRAY_TYPE := (others => (others => '0'));

    -- mux output array to hold output from muxes
    --  as many as encoders
    --  output size of maximum shifted A
    type MUX_OUTPUT_ARRAY_TYPE is array (0 to NUM_ENCODER-1) of std_logic_vector(NBIT+MAX_SHIFT-1 downto 0);
    signal mux_output_array : MUX_OUTPUT_ARRAY_TYPE := (others => (others => '0'));

    -- array to hold partial sums of outputs from muxes
    --  last value of array holds the final sum.
    type PARTIAL_SUM_ARRAY_TYPE  is array (0 to NUM_ENCODER*2-1) of std_logic_vector(NBIT+MAX_SHIFT-1 downto 0);
    signal partial_sum_array : PARTIAL_SUM_ARRAY_TYPE := (others => (others => '0'));

begin

    --extend B
    B_extended(NBIT-1 +1 downto 0 +1) <= B(NBIT-1 downto 0);

    --generate encoder signals
    encoder_out_gen : for i in 0 to NUM_ENCODER-1 generate
        encoder_output(i) <= B_extended((i+1)*2 -1  +1 downto (i)*2 -1 +1);
    end generate;

    --generate multiples of A (shifted A)
    A_shifted_array_gen : for i in 0 to NUM_ENCODER-1 generate
        A_shifted_array(2*i)(NBIT-1+(2*i) downto 0+(2*i)) <= A(NBIT-1 downto 0);
        A_shifted_array(2*i)((2*i)-1 downto 0) <= (others => '0');

        A_shifted_array(2*i+1)(NBIT-1+(2*i+1) downto 0+(2*i+1)) <= A(NBIT-1 downto 0);
        A_shifted_array(2*i+1)((2*i+1)-1 downto 0) <= (others => '0');
    end generate ;

    --select appropriate multiple of A from encoder signals
    mux_gen : for i in 0 to NUM_ENCODER - 1 generate
        with encoder_output(i) select mux_output_array(i) <=
            (others => '0') when "000"|"111",
            +A_shifted_array(2*i) when "001"|"010",
            -A_shifted_array(2*i) when "101"|"110", --for unsigned library, not(A_shifted_array(2*i))+1 [2's complement]
            +A_shifted_array(2*i+1) when "011",
            -A_shifted_array(2*i+1) when"100",
            (others => 'X') when others;
    end generate;

    --compute and store partial sum of selected multiple of A from muxes, top to bottom until final sum
    sum_gen0: partial_sum_array(0) <= mux_output_array(0);
    sum_gen : for i in 1 to NUM_ENCODER-1 generate
        partial_sum_array(i) <= partial_sum_array(i-1) + mux_output_array(i);
    end generate;

    --send final sum truncating to the output size
    Y <= partial_sum_array(NUM_ENCODER - 1)(2*NBIT-1 downto 0);

end MIXED;
