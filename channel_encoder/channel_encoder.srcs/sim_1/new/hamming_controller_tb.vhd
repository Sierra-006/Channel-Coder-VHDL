library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity hamming_controller_tb is
end entity;

architecture bench of hamming_controller_tb is

  signal clk             : STD_LOGIC := '0';
  signal start_encode    : STD_LOGIC := '0';
  signal start_decode    : STD_LOGIC := '0';
  signal data_in         : STD_LOGIC_VECTOR(7 downto 0) := (others => '0');
  signal err_sel         : STD_LOGIC_VECTOR(3 downto 0) := (others => '0');
  signal orig_data       : STD_LOGIC_VECTOR(7 downto 0);
  signal codeword        : STD_LOGIC_VECTOR(11 downto 0);
  signal corrupted       : STD_LOGIC_VECTOR(11 downto 0);
  signal data_out        : STD_LOGIC_VECTOR(7 downto 0);
  signal error_detect    : STD_LOGIC;
  signal error_corrected : STD_LOGIC;
  signal error_pos       : STD_LOGIC_VECTOR(3 downto 0);
  signal enc_done        : STD_LOGIC;
  signal dec_done        : STD_LOGIC;

begin

  uut : entity work.hamming_controller
    port map (
      clk             => clk,
      start_encode    => start_encode,
      start_decode    => start_decode,
      data_in         => data_in,
      err_sel         => err_sel,
      orig_data       => orig_data,
      codeword        => codeword,
      corrupted       => corrupted,
      data_out        => data_out,
      error_detect    => error_detect,
      error_corrected => error_corrected,
      error_pos       => error_pos,
      enc_done        => enc_done,
      dec_done        => dec_done
    );

  -- PYNQ-Z2 system clock: 125 MHz (8 ns period)
  clk <= not clk after 4 ns;

  -- Inputs change and outputs are checked on the FALLING edge.
  -- The controller samples on the RISING edge in between.
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
    -- Run 1: 0x6D, no error (err_sel = 0)
    ----------------------------------------------------------------
    data_in      <= "01101101";
    start_encode <= '1';
    tick;
    start_encode <= '0';
    tick(2);   -- controller latches, encoder runs, controller captures
    assert enc_done = '1'                 report "Run 1: enc_done not high"     severity error;
    assert orig_data = "01101101"         report "Run 1: wrong orig_data"       severity error;
    assert codeword = "011001100111"      report "Run 1: wrong codeword"        severity error;
    assert dec_done = '0'                 report "Run 1: dec_done high early"   severity error;

    tick(2);   -- user is deciding

    err_sel      <= "0000";
    start_decode <= '1';
    tick;
    start_decode <= '0';
    tick(2);
    assert dec_done = '1'                 report "Run 1: dec_done not high"     severity error;
    assert corrupted = "011001100111"     report "Run 1: corrupted should equal clean" severity error;
    assert data_out = "01101101"          report "Run 1: wrong data_out"        severity error;
    assert error_detect = '0'             report "Run 1: false error_detect"    severity error;
    assert error_corrected = '0'          report "Run 1: false error_corrected" severity error;
    assert error_pos = "0000"             report "Run 1: error_pos not 0"       severity error;

    tick(2);

    ----------------------------------------------------------------
    -- Run 2: 0x6D, flip position 10
    ----------------------------------------------------------------
    data_in      <= "01101101";
    start_encode <= '1';
    tick;
    start_encode <= '0';
    tick(2);
    assert enc_done = '1'                 report "Run 2: enc_done not high"     severity error;
    assert codeword = "011001100111"      report "Run 2: wrong codeword"        severity error;
    -- results of run 1 must be cleared
    assert dec_done = '0'                 report "Run 2: dec_done not cleared"  severity error;
    assert corrupted = "000000000000"     report "Run 2: corrupted not cleared" severity error;
    assert data_out = "00000000"          report "Run 2: data_out not cleared"  severity error;
    assert error_detect = '0'             report "Run 2: error_detect not cleared"    severity error;
    assert error_corrected = '0'          report "Run 2: error_corrected not cleared" severity error;
    assert error_pos = "0000"             report "Run 2: error_pos not cleared" severity error;

    tick(2);

    err_sel      <= "1010";
    start_decode <= '1';
    tick;
    start_decode <= '0';
    tick(2);
    assert dec_done = '1'                 report "Run 2: dec_done not high"     severity error;
    assert corrupted = "010001100111"     report "Run 2: wrong corrupted"       severity error;
    assert data_out = "01101101"          report "Run 2: not corrected"         severity error;
    assert error_detect = '1'             report "Run 2: error_detect not set"  severity error;
    assert error_corrected = '1'          report "Run 2: error_corrected not set" severity error;
    assert error_pos = "1010"             report "Run 2: error_pos not 10"      severity error;

    tick(2);

    ----------------------------------------------------------------
    -- Run 3: 0xA1, flip position 12
    ----------------------------------------------------------------
    data_in      <= "10100001";
    start_encode <= '1';
    tick;
    start_encode <= '0';
    tick(2);
    assert enc_done = '1'                 report "Run 3: enc_done not high"     severity error;
    assert orig_data = "10100001"         report "Run 3: wrong orig_data"       severity error;
    assert codeword = "101000001101"      report "Run 3: wrong codeword"        severity error;

    tick(2);

    err_sel      <= "1100";
    start_decode <= '1';
    tick;
    start_decode <= '0';
    tick(2);
    assert dec_done = '1'                 report "Run 3: dec_done not high"     severity error;
    assert corrupted = "001000001101"     report "Run 3: wrong corrupted"       severity error;
    assert data_out = "10100001"          report "Run 3: not corrected"         severity error;
    assert error_detect = '1'             report "Run 3: error_detect not set"  severity error;
    assert error_corrected = '1'          report "Run 3: error_corrected not set" severity error;
    assert error_pos = "1100"             report "Run 3: error_pos not 12"      severity error;

    tick(2);
    report "hamming_controller_tb finished" severity note;
    wait;
  end process;

end architecture;
