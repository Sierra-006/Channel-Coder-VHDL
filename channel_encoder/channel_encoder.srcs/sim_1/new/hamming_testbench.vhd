-- Round-trip testbench: encoder -> (optional single-bit error) -> decoder.
-- For all 256 data values, checks data survives with no error and with
-- each of the 12 possible single-bit errors.

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity hamming_testbench is
end entity;

architecture Behavioral of hamming_testbench is

  constant CLK_PERIOD : time := 10 ns;

  signal clk      : STD_LOGIC := '0';
  signal done     : boolean := false;

  -- Encoder side
  signal enc_valid : STD_LOGIC := '0';
  signal enc_din   : STD_LOGIC_VECTOR(7 downto 0) := (others => '0');
  signal enc_dout  : STD_LOGIC_VECTOR(11 downto 0);
  signal enc_ready : STD_LOGIC;

  -- Channel: XOR mask injects errors
  signal err_mask  : STD_LOGIC_VECTOR(11 downto 0) := (others => '0');
  signal channel   : STD_LOGIC_VECTOR(11 downto 0);

  -- Decoder side
  signal dec_dout      : STD_LOGIC_VECTOR(7 downto 0);
  signal dec_detect    : STD_LOGIC;
  signal dec_corrected : STD_LOGIC;
  signal dec_ready     : STD_LOGIC;

begin

  channel <= enc_dout xor err_mask;

  uut_encoder : entity work.hamming_encoder
    port map (
      clk       => clk,
      valid_in  => enc_valid,
      data_in   => enc_din,
      data_out  => enc_dout,
      ready_out => enc_ready
    );

  uut_decoder : entity work.hamming_decoder
    port map (
      clk                 => clk,
      valid_in            => enc_ready,
      data_in             => channel,
      data_out            => dec_dout,
      error_detect        => dec_detect,
      error_corrected     => dec_corrected,
      ready_out           => dec_ready
    );

  clk_gen : process
  begin
    while not done loop
      clk <= '0'; wait for CLK_PERIOD / 2;
      clk <= '1'; wait for CLK_PERIOD / 2;
    end loop;
    wait;
  end process;

  test_process : process
    variable errors : integer := 0;
    variable d      : STD_LOGIC_VECTOR(7 downto 0);

    -- mask_bit = -1 : no error, else flip codeword index mask_bit
    procedure run(v : integer; mask_bit : integer) is
    begin
      d := std_logic_vector(to_unsigned(v, 8));
      err_mask <= (others => '0');
      if mask_bit >= 0 then
        err_mask(mask_bit) <= '1';
      end if;
      enc_din   <= d;
      enc_valid <= '1';
      wait until rising_edge(clk);   -- encoder captures
      enc_valid <= '0';
      wait until rising_edge(clk);   -- decoder captures
      wait for 1 ns;

      if dec_ready /= '1' or dec_dout /= d then
        report "data=" & integer'image(v) & " errbit=" & integer'image(mask_bit)
               & ": round trip mismatch" severity error;
        errors := errors + 1;
      end if;
      if mask_bit < 0 then
        if dec_detect /= '0' then
          report "false error flag on clean word" severity error;
          errors := errors + 1;
        end if;
      else
        if dec_detect /= '1' or dec_corrected /= '1' then
          report "single error flags wrong, errbit=" & integer'image(mask_bit) severity error;
          errors := errors + 1;
        end if;
      end if;
    end procedure;
  begin
    wait for 2 * CLK_PERIOD;

    for v in 0 to 255 loop
      run(v, -1);
      for p in 0 to 11 loop
        run(v, p);
      end loop;
    end loop;

    if errors = 0 then
      report "hamming_testbench: ALL ROUND-TRIP TESTS PASSED" severity note;
    else
      report "hamming_testbench: " & integer'image(errors) & " ERRORS" severity failure;
    end if;
    done <= true;
    wait;
  end process;

end architecture;
