library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity hamming_decoder_tb is
end entity;

architecture Behavioral of hamming_decoder_tb is

  -- Signals for the DUT (Device Under Test)
  signal valid_in            : STD_LOGIC;
  signal data_in             : STD_LOGIC_VECTOR(6 downto 0);
  signal data_out            : STD_LOGIC_VECTOR(3 downto 0);
  signal error_detect        : STD_LOGIC;
  signal error_corrected     : STD_LOGIC;
  signal uncorrectable_error : STD_LOGIC;
  signal ready_out           : STD_LOGIC;

  -- Component Declaration
  component hamming_decoder is
    port (
      valid_in            : in  STD_LOGIC;
      data_in             : in  STD_LOGIC_VECTOR(6 downto 0);
      data_out            : out STD_LOGIC_VECTOR(3 downto 0);
      error_detect        : out STD_LOGIC;
      error_corrected     : out STD_LOGIC;
      uncorrectable_error : out STD_LOGIC;
      ready_out           : out STD_LOGIC
    );
  end component;

begin

  -- Instantiate the DUT
  uut: hamming_decoder
    port map (
      valid_in            => valid_in,
      data_in             => data_in,
      data_out            => data_out,
      error_detect        => error_detect,
      error_corrected     => error_corrected,
      uncorrectable_error => uncorrectable_error,
      ready_out           => ready_out
    );

  -- Test Process
  process
  begin
    -- Test Case 1: No Error (Valid Codeword)
    valid_in <= '1';
    data_in <= "0110100"; -- Correct codeword (data = 7)
    wait for 20 ns;

    -- Test Case 2: Single-Bit Error
    valid_in <= '1';
    data_in <= "1110100"; -- Bit 6 flipped
    wait for 20 ns;

    -- Test Case 3: Double-Bit Error
    valid_in <= '1';
    data_in <= "1110110"; -- Bits 6 and 5 flipped
    wait for 20 ns;

    -- Test Case 4: Valid Input Disabled
    valid_in <= '0';
    wait for 20 ns;

    -- Test Case 5: Out-of-Bounds Syndrome
    valid_in <= '1';
    data_in <= "1011111"; -- Noise-induced invalid syndrome
    wait for 20 ns;

    -- Test Case 6: Correct Codeword (Different Data)
    valid_in <= '1';
    data_in <= "1001111"; -- Correct codeword (data = 1)
    wait for 20 ns;

    -- Test Case 7: No Error, Different Valid Codeword
    valid_in <= '1';
    data_in <= "0001111"; -- Correct codeword (data = 1)
    wait for 20 ns;

    -- End Simulation
    wait;
  end process;

end architecture;
