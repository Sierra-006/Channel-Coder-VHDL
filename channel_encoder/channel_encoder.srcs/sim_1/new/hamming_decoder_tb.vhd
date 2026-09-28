-- Self-checking testbench for the clocked Hamming(12,8) decoder.
-- For all 256 data values: no error, all 12 single-bit flips, all 66 double flips.

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity hamming_decoder_tb is
end entity;

architecture bench of hamming_decoder_tb is

  constant CLK_PERIOD : time := 10 ns;

  signal clk                 : STD_LOGIC := '0';
  signal valid_in            : STD_LOGIC := '0';
  signal data_in             : STD_LOGIC_VECTOR(11 downto 0) := (others => '0');
  signal data_out            : STD_LOGIC_VECTOR(7 downto 0);
  signal error_detect        : STD_LOGIC;
  signal error_corrected     : STD_LOGIC;
  signal uncorrectable_error : STD_LOGIC;
  signal ready_out           : STD_LOGIC;
  signal done                : boolean := false;

  -- Reference encoder (XOR of positions of set data bits = parity bits)
  function ref_encode(d : STD_LOGIC_VECTOR(7 downto 0)) return STD_LOGIC_VECTOR is
    type int_arr is array (0 to 7) of integer;
    constant POS : int_arr := (3, 5, 6, 7, 9, 10, 11, 12);
    variable f : STD_LOGIC_VECTOR(11 downto 0) := (others => '0');
    variable s : unsigned(3 downto 0) := (others => '0');
  begin
    for i in 0 to 7 loop
      f(POS(i) - 1) := d(i);
      if d(i) = '1' then
        s := s xor to_unsigned(POS(i), 4);
      end if;
    end loop;
    f(0) := s(0);
    f(1) := s(1);
    f(3) := s(2);
    f(7) := s(3);
    return f;
  end function;

begin

  uut : entity work.hamming_decoder
    port map (
      clk                 => clk,
      valid_in            => valid_in,
      data_in             => data_in,
      data_out            => data_out,
      error_detect        => error_detect,
      error_corrected     => error_corrected,
      uncorrectable_error => uncorrectable_error,
      ready_out           => ready_out
    );

  clk_gen : process
  begin
    while not done loop
      clk <= '0'; wait for CLK_PERIOD / 2;
      clk <= '1'; wait for CLK_PERIOD / 2;
    end loop;
    wait;
  end process;

  stimulus : process
    variable errors : integer := 0;
    variable d      : STD_LOGIC_VECTOR(7 downto 0);
    variable cw     : STD_LOGIC_VECTOR(11 downto 0);
    variable syn    : integer;

    -- Drive one codeword, wait one clock, return
    procedure apply(w : STD_LOGIC_VECTOR(11 downto 0)) is
    begin
      data_in  <= w;
      valid_in <= '1';
      wait until rising_edge(clk);
      wait for 1 ns;
    end procedure;

    procedure fail(msg : string) is
    begin
      report msg severity error;
      errors := errors + 1;
    end procedure;
  begin
    wait for 2 * CLK_PERIOD;

    for v in 0 to 255 loop
      d  := std_logic_vector(to_unsigned(v, 8));
      cw := ref_encode(d);

      -- No error
      apply(cw);
      if ready_out /= '1' or data_out /= d or error_detect /= '0'
         or error_corrected /= '0' or uncorrectable_error /= '0' then
        fail("data=" & integer'image(v) & ": clean codeword failed");
      end if;

      -- Every single-bit error must be corrected
      for p in 0 to 11 loop
        cw    := ref_encode(d);
        cw(p) := not cw(p);
        apply(cw);
        if data_out /= d or error_detect /= '1' or error_corrected /= '1'
           or uncorrectable_error /= '0' then
          fail("data=" & integer'image(v) & " flip pos " & integer'image(p + 1)
               & ": single error not corrected");
        end if;
      end loop;

      -- Every double-bit error: syndrome = posA xor posB
      for a in 0 to 10 loop
        for b in a + 1 to 11 loop
          cw    := ref_encode(d);
          cw(a) := not cw(a);
          cw(b) := not cw(b);
          syn   := to_integer(to_unsigned(a + 1, 4) xor to_unsigned(b + 1, 4));
          apply(cw);
          if error_detect /= '1' then
            fail("double error not detected");
          elsif syn > 12 then
            if uncorrectable_error /= '1' or error_corrected /= '0' then
              fail("double error, syndrome " & integer'image(syn) & ": expected uncorrectable");
            end if;
          else
            -- aliases to a single error: miscorrected, flagged as corrected
            if uncorrectable_error /= '0' or error_corrected /= '1' then
              fail("double error, syndrome " & integer'image(syn) & ": expected miscorrection flags");
            end if;
          end if;
        end loop;
      end loop;
    end loop;

    -- valid_in low: ready_out drops
    valid_in <= '0';
    wait until rising_edge(clk);
    wait for 1 ns;
    if ready_out /= '0' then
      fail("ready_out did not drop when valid_in low");
    end if;

    if errors = 0 then
      report "hamming_decoder_tb: ALL TESTS PASSED" severity note;
    else
      report "hamming_decoder_tb: " & integer'image(errors) & " ERRORS" severity failure;
    end if;
    done <= true;
    wait;
  end process;

end architecture;
