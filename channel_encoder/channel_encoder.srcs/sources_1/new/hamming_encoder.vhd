----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 15.12.2024 18:06:06
-- Design Name: 
-- Module Name: hamming_encoder - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: Hamming Encoder with asynchronous handshaking protocol.
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.std_logic_arith.ALL;


entity hamming_encoder is
  port (
    valid_in  : in  STD_LOGIC;                     -- Indicates data_in is valid
    data_in   : in  STD_LOGIC_VECTOR(3 downto 0);  -- Input: 4 data bits
    data_out  : out STD_LOGIC_VECTOR(6 downto 0);  -- Output: 7-bit codeword
    ready_out : out STD_LOGIC                      -- Indicates data_out is valid
  );
end entity;

architecture Behavioral of hamming_encoder is

  -- Internal signals for output and status
  signal output_data : STD_LOGIC_VECTOR(6 downto 0) := (others => '0');
  signal ready       : STD_LOGIC := '0'; -- Internal ready signal

begin

  -- Process for Hamming Encoding with Handshaking
  process(valid_in, data_in)
    -- Local variables for encoding
    type cw_array is array (6 downto 0) of STD_LOGIC_VECTOR(2 downto 0);
    variable code_word     : STD_LOGIC_VECTOR(2 downto 0) := (others => '0'); -- XORed codeword memory
    variable data_frame    : STD_LOGIC_VECTOR(6 downto 0) := (others => '0');
    variable bit_locations : cw_array                     := (others => "000");
  begin
    -- Check if input data is valid
    if valid_in = '1' then
      -- Put the data in the frame spots (indexes 3, 1, 0)
      data_frame(6) := data_in(3);
      data_frame(5) := data_in(2);
      data_frame(4) := data_in(1);
      data_frame(2) := data_in(0);

      -- For loop to locate '1's in the frame and store their positions
      for i in 0 to 6 loop
        if (data_frame(i) = '1') then
          bit_locations(i) := conv_std_logic_vector(i + 1, 3); -- Convert location to STD_LOGIC_VECTOR
        end if;
      end loop;

      -- XOR the contents of the bit_locations array into the codeword
      code_word := bit_locations(0) xor bit_locations(1) xor bit_locations(2) xor
                   bit_locations(3) xor bit_locations(4) xor bit_locations(5) xor
                   bit_locations(6);

      -- Insert the codeword into the data frame (parity bits)
      data_frame(3) := code_word(0);
      data_frame(1) := code_word(1);
      data_frame(0) := code_word(2);

      -- Send the encoded data and indicate readiness
      output_data <= data_frame;
      ready <= '1'; -- Indicate that the output is ready
    else
      -- If valid_in is not asserted, clear the ready signal
      ready <= '0';
    end if;
  end process;

  -- Assign output signals
  data_out <= output_data;
  ready_out <= ready;

end architecture;
