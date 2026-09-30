library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity hamming_decoder_tb is
end entity;

architecture bench of hamming_decoder_tb is

  signal clk                 : STD_LOGIC := '0';
  signal valid_in            : STD_LOGIC := '0';
  signal data_in             : STD_LOGIC_VECTOR(11 downto 0) := (others => '0');
  signal data_out            : STD_LOGIC_VECTOR(7 downto 0);
  signal error_detect        : STD_LOGIC;
  signal error_corrected     : STD_LOGIC;
  signal error_pos           : STD_LOGIC_VECTOR(3 downto 0);
  signal ready_out           : STD_LOGIC;

begin

  uut : entity work.hamming_decoder
    port map (
      clk                 => clk,
      valid_in            => valid_in,
      data_in             => data_in,
      data_out            => data_out,
      error_detect        => error_detect,
      error_corrected     => error_corrected,
      error_pos           => error_pos,
      ready_out           => ready_out
    );

  -- PYNQ-Z2 system clock: 125 MHz (8 ns period)
  clk <= not clk after 4 ns;

  -- Inputs change and outputs are checked on the FALLING edge.
  -- The DUT samples on the RISING edge in between.
  stimulus : process

    procedure tick(n : positive := 1) is
    begin
      for i in 1 to n loop
        wait until falling_edge(clk);
      end loop;
    end procedure;

  begin
    tick(3);  -- idle a few clocks

    ----------------------------------------------------------------
    -- Test 1: no error. 0110_0110_0111 -> data 0x6D, no flags
    ----------------------------------------------------------------
    data_in  <= "011001100111";
    valid_in <= '1';
    tick;
    assert ready_out = '1'            report "Test 1: ready_out not high"      severity error;
    assert data_out = "01101101"      report "Test 1: wrong data"              severity error;
    assert error_detect = '0'         report "Test 1: false error_detect"      severity error;
    assert error_corrected = '0'      report "Test 1: false error_corrected"   severity error;
    assert error_pos = "0000"         report "Test 1: error_pos not 0"         severity error;

    -- Clear: all-zero codeword in (valid codeword for data 0), so all zeros out
    data_in  <= (others => '0');
    tick;
    assert ready_out = '1'            report "Clear 1: ready_out not high"     severity error;
    assert data_out = "00000000"      report "Clear 1: data_out not 0"         severity error;
    assert error_detect = '0'         report "Clear 1: error_detect not 0"     severity error;
    assert error_corrected = '0'      report "Clear 1: error_corrected not 0"  severity error;
    assert error_pos = "0000"         report "Clear 1: error_pos not 0"       severity error;
    valid_in <= '0';
    tick(2);

    ----------------------------------------------------------------
    -- Test 2: single data-bit error at position 10.
    -- 0100_0110_0111 (syndrome 10) -> corrected to data 0x6D
    ----------------------------------------------------------------
    data_in  <= "010001100111";
    valid_in <= '1';
    tick;
    assert ready_out = '1'            report "Test 2: ready_out not high"      severity error;
    assert data_out = "01101101"      report "Test 2: not corrected"           severity error;
    assert error_detect = '1'         report "Test 2: error_detect not set"    severity error;
    assert error_corrected = '1'      report "Test 2: error_corrected not set" severity error;
    assert error_pos = "1010"         report "Test 2: error_pos not 10"        severity error;

    -- Clear
    data_in  <= (others => '0');
    tick;
    assert ready_out = '1'            report "Clear 2: ready_out not high"     severity error;
    assert data_out = "00000000"      report "Clear 2: data_out not 0"         severity error;
    assert error_detect = '0'         report "Clear 2: error_detect not 0"     severity error;
    assert error_corrected = '0'      report "Clear 2: error_corrected not 0"  severity error;
    assert error_pos = "0000"         report "Clear 2: error_pos not 0"       severity error;
    valid_in <= '0';
    tick(2);

    ----------------------------------------------------------------
    -- Test 3: single parity-bit error at position 4.
    -- 0110_0110_1111 (syndrome 4) -> data still 0x6D
    ----------------------------------------------------------------
    data_in  <= "011001101111";
    valid_in <= '1';
    tick;
    assert ready_out = '1'            report "Test 3: ready_out not high"      severity error;
    assert data_out = "01101101"      report "Test 3: wrong data"              severity error;
    assert error_detect = '1'         report "Test 3: error_detect not set"    severity error;
    assert error_corrected = '1'      report "Test 3: error_corrected not set" severity error;
    assert error_pos = "0100"         report "Test 3: error_pos not 4"         severity error;

    -- Clear
    data_in  <= (others => '0');
    tick;
    assert ready_out = '1'            report "Clear 3: ready_out not high"     severity error;
    assert data_out = "00000000"      report "Clear 3: data_out not 0"         severity error;
    assert error_detect = '0'         report "Clear 3: error_detect not 0"     severity error;
    assert error_corrected = '0'      report "Clear 3: error_corrected not 0"  severity error;
    assert error_pos = "0000"         report "Clear 3: error_pos not 0"       severity error;
    valid_in <= '0';
    tick(2);

    report "hamming_decoder_tb finished" severity note;
    wait;
  end process;

end architecture;
