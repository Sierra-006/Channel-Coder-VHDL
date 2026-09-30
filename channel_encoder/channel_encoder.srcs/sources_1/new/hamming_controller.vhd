----------------------------------------------------------------------------------
-- Module Name: hamming_controller - Behavioral
-- Description: Sequences the Hamming(12,8) encoder and decoder for a console demo.
--
--   Command 1 (start_encode): latch data_in, encode it, hold the codeword.
--                             enc_done goes high when codeword is valid.
--   Command 2 (start_decode): flip codeword position err_sel (1..12; 0 or
--                             13..15 = no flip), decode the result, hold
--                             everything. dec_done goes high when valid.
--
--   start_encode / start_decode are one-clock pulses, sampled on the rising
--   edge. start_encode is accepted in IDLE or DONE and clears every held result
--   so old data can't leak into the next set. start_decode is accepted only in
--   ENC_DONE. Pulses in any other state are ignored.
--
--   Encoder and decoder each give their result for exactly one clock
--   (ready_out high), so the controller captures it on that clock.
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity hamming_controller is
  port (
    clk             : in  STD_LOGIC;
    start_encode    : in  STD_LOGIC;                       -- Pulse: encode data_in
    start_decode    : in  STD_LOGIC;                       -- Pulse: inject err_sel and decode
    data_in         : in  STD_LOGIC_VECTOR(7 downto 0);    -- Message to encode
    err_sel         : in  STD_LOGIC_VECTOR(3 downto 0);    -- 0 = no error, 1..12 = position to flip

    orig_data       : out STD_LOGIC_VECTOR(7 downto 0);    -- Original message (latched at encode)
    codeword        : out STD_LOGIC_VECTOR(11 downto 0);   -- Clean codeword from encoder
    corrupted       : out STD_LOGIC_VECTOR(11 downto 0);   -- Codeword after the flip
    data_out        : out STD_LOGIC_VECTOR(7 downto 0);    -- Decoder output data
    error_detect    : out STD_LOGIC;                       -- Decoder results
    error_corrected : out STD_LOGIC;
    error_pos       : out STD_LOGIC_VECTOR(3 downto 0);

    enc_done        : out STD_LOGIC;                       -- codeword / orig_data valid
    dec_done        : out STD_LOGIC                        -- corrupted and decoder results valid
  );
end entity;

architecture Behavioral of hamming_controller is

  type state_t is (IDLE, ENC_WAIT, ENC_DONE, DEC_WAIT, DONE);
  signal state : state_t := IDLE;

  -- Encoder connections
  signal enc_din   : STD_LOGIC_VECTOR(7 downto 0)  := (others => '0');
  signal enc_valid : STD_LOGIC := '0';
  signal enc_dout  : STD_LOGIC_VECTOR(11 downto 0);
  signal enc_ready : STD_LOGIC;

  -- Decoder connections
  signal dec_din       : STD_LOGIC_VECTOR(11 downto 0) := (others => '0');
  signal dec_valid     : STD_LOGIC := '0';
  signal dec_dout      : STD_LOGIC_VECTOR(7 downto 0);
  signal dec_detect    : STD_LOGIC;
  signal dec_corrected : STD_LOGIC;
  signal dec_pos       : STD_LOGIC_VECTOR(3 downto 0);
  signal dec_ready     : STD_LOGIC;

  -- Held results
  signal orig_reg      : STD_LOGIC_VECTOR(7 downto 0)  := (others => '0');
  signal codeword_reg  : STD_LOGIC_VECTOR(11 downto 0) := (others => '0');
  signal corrupted_reg : STD_LOGIC_VECTOR(11 downto 0) := (others => '0');
  signal data_reg      : STD_LOGIC_VECTOR(7 downto 0)  := (others => '0');
  signal detect_reg    : STD_LOGIC := '0';
  signal corrected_reg : STD_LOGIC := '0';
  signal pos_reg       : STD_LOGIC_VECTOR(3 downto 0)  := (others => '0');
  signal enc_done_reg  : STD_LOGIC := '0';
  signal dec_done_reg  : STD_LOGIC := '0';

  -- One-hot flip mask for position 1..12; all zeros for anything else
  function make_mask(sel : STD_LOGIC_VECTOR(3 downto 0)) return STD_LOGIC_VECTOR is
    variable m : STD_LOGIC_VECTOR(11 downto 0) := (others => '0');
    variable v : integer range 0 to 15;
  begin
    v := to_integer(unsigned(sel));
    if v >= 1 and v <= 12 then
      m(v - 1) := '1';
    end if;
    return m;
  end function;

begin

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
      clk             => clk,
      valid_in        => dec_valid,
      data_in         => dec_din,
      data_out        => dec_dout,
      error_detect    => dec_detect,
      error_corrected => dec_corrected,
      error_pos       => dec_pos,
      ready_out       => dec_ready
    );

  -- Decoder input is the corrupted codeword register
  dec_din <= corrupted_reg;

  process(clk)
  begin
    if rising_edge(clk) then
      case state is

        when IDLE | DONE =>
          if start_encode = '1' then
            -- Clear every held result, then start a new set
            codeword_reg  <= (others => '0');
            corrupted_reg <= (others => '0');
            data_reg      <= (others => '0');
            detect_reg    <= '0';
            corrected_reg <= '0';
            pos_reg       <= (others => '0');
            enc_done_reg  <= '0';
            dec_done_reg  <= '0';

            orig_reg  <= data_in;
            enc_din   <= data_in;
            enc_valid <= '1';
            state     <= ENC_WAIT;
          end if;

        when ENC_WAIT =>
          enc_valid <= '0';                  -- one-clock valid pulse
          enc_din   <= (others => '0');      -- clear encoder input
          if enc_ready = '1' then
            codeword_reg <= enc_dout;        -- capture on the one ready clock
            enc_done_reg <= '1';
            state        <= ENC_DONE;
          end if;

        when ENC_DONE =>
          if start_decode = '1' then
            corrupted_reg <= codeword_reg xor make_mask(err_sel);
            dec_valid     <= '1';
            state         <= DEC_WAIT;
          end if;

        when DEC_WAIT =>
          dec_valid <= '0';                  -- one-clock valid pulse
          if dec_ready = '1' then
            data_reg      <= dec_dout;       -- capture on the one ready clock
            detect_reg    <= dec_detect;
            corrected_reg <= dec_corrected;
            pos_reg       <= dec_pos;
            dec_done_reg  <= '1';
            state         <= DONE;
          end if;

      end case;
    end if;
  end process;

  orig_data       <= orig_reg;
  codeword        <= codeword_reg;
  corrupted       <= corrupted_reg;
  data_out        <= data_reg;
  error_detect    <= detect_reg;
  error_corrected <= corrected_reg;
  error_pos       <= pos_reg;
  enc_done        <= enc_done_reg;
  dec_done        <= dec_done_reg;

end architecture;
