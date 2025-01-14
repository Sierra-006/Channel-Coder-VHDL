library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.std_logic_arith.ALL;

entity hamming_decoder is
  port (
    valid_in    : in  STD_LOGIC;                     -- Input: Indicates data_in is valid
    data_in     : in  STD_LOGIC_VECTOR(6 downto 0);  -- Input: 7-bit codeword
    data_out    : out STD_LOGIC_VECTOR(3 downto 0);  -- Output: 4 data bits
    error_detect : out std_logic;                   -- Output: Error detected (single or uncorrectable)
    error_corrected : out std_logic;                -- Output: Single-bit error corrected
    uncorrectable_error : out std_logic;            -- Output: Double-bit or invalid error
    ready_out   : out STD_LOGIC                      -- Output: Indicates data_out is valid
  );
end entity;

architecture Behavioral of hamming_decoder is
  signal corrected_frame : STD_LOGIC_VECTOR(6 downto 0); -- Corrected codeword
  signal syndrome        : STD_LOGIC_VECTOR(2 downto 0); -- Syndrome for error detection
  signal ready           : STD_LOGIC := '0';            -- Internal signal for ready_out
  signal error_bit_index : INTEGER := 0;                -- Calculated error bit index
begin

  hamming_calculation: process (valid_in, data_in)
    variable temp_syndrome : STD_LOGIC_VECTOR(2 downto 0) := (others => '0');
    variable error_found : BOOLEAN := FALSE;
  begin
    ready <= '0';  -- Default ready signal to low
    error_detect <= '0';
    error_corrected <= '0';
    uncorrectable_error <= '0';

    if valid_in = '1' then
      corrected_frame <= data_in;

      -- Compute syndrome
      temp_syndrome := "000";
      for i in 0 to 6 loop
        if corrected_frame(i) = '1' then
          temp_syndrome := temp_syndrome xor conv_std_logic_vector(i + 1, 3);
        end if;
      end loop;

      syndrome <= temp_syndrome;

      -- Determine error location
      if temp_syndrome = "000" then
        -- No error
        error_detect <= '0';
        error_corrected <= '0';
        uncorrectable_error <= '0';
      else
        error_detect <= '1'; -- Error detected
        error_bit_index <= conv_integer(unsigned(temp_syndrome)) - 1;

        if error_bit_index >= 0 and error_bit_index <= 6 then
          -- Single-bit error, correct it
          corrected_frame(error_bit_index) <= NOT corrected_frame(error_bit_index);
          error_corrected <= '1';
        else
          -- Uncorrectable error (e.g., invalid syndrome)
          uncorrectable_error <= '1';
        end if;
      end if;

      -- Output corrected data
      data_out <= corrected_frame(6) & corrected_frame(5) & corrected_frame(4) & corrected_frame(2);
      ready <= '1'; -- Indicate data_out is ready
    end if;
  end process;

  -- Assign ready signal
  ready_out <= ready;

end architecture;
