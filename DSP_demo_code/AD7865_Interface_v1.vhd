----------------------------------------------------------------------------------
-- Company: 
-- Engineer: Felix Vietmeyer
-- 
-- Create Date:    19:19:23 09/06/2014 
-- Design Name: 
-- Module Name:    ADS7818_Interface - Behavioral 
-- Project Name: Test for AD7685 board (v1)
-- Target Devices: Papilio Pro
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 1.0 - File Created
-- Additional Comments: 
-- Currently needs a 20 MHz clock to run at 250 kSPS
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL; 

entity AD7685_Interface_v2 is
    Port ( ADC_CLK : out  STD_LOGIC := '0';
			  ADC_DATA : in  STD_LOGIC := '0';
			  ADC_CONV : out  STD_LOGIC := '1';

			  Trigger_out : out STD_LOGIC := '0';
			  ADC_OUT : out STD_LOGIC_VECTOR(15 downto 0);
				
			  clk : in  STD_LOGIC); --Should be 20 MHz for 250 kSPS
end AD7685_Interface_v2;

architecture Behavioral of AD7685_Interface_v2 is

	signal counter : STD_LOGIC_VECTOR(6 downto 0) := (others => '0');
	signal ADCvalue : STD_LOGIC_VECTOR(15 downto 0) := (others => '0'); --16-bit ADC output

begin

	clk_proc: process(clk)
	begin
		if rising_edge(clk) then
			if counter = "1001110" then
					counter <= (others => '1');
			else 
				counter <= counter+1;
			end if;
			
			Trigger_out <= '0';
			
			if counter(0) = '1' then
					ADC_CLK <= '1';
				else
					ADC_CLK <= '0';
			end if;
			
			case counter is
				when "0000000" =>
					ADC_CONV <= '1';
				when "0101101" =>
					ADC_CONV <= '0';
				when "0101110" =>
					ADCvalue(15) <= ADC_DATA;
				when "0110000" =>
					ADCvalue(14) <= ADC_DATA;
				when "0110010" =>
					ADCvalue(13) <= ADC_DATA;
				when "0110100" =>
					ADCvalue(12) <= ADC_DATA;
				when "0110110" =>
					ADCvalue(11) <= ADC_DATA;
				when "0111000" =>
					ADCvalue(10) <= ADC_DATA;
				when "0111010" =>
					ADCvalue(9) <= ADC_DATA;
				when "0111100" =>
					ADCvalue(8) <= ADC_DATA;
				when "0111110" =>
					ADCvalue(7) <= ADC_DATA;
				when "1000000" =>
					ADCvalue(6) <= ADC_DATA;
				when "1000010" =>
					ADCvalue(5) <= ADC_DATA;
				when "1000100" =>
					ADCvalue(4) <= ADC_DATA;
				when "1000110" =>
					ADCvalue(3) <= ADC_DATA;
				when "1001000" =>
					ADCvalue(2) <= ADC_DATA;
				when "1001010" =>
					ADCvalue(1) <= ADC_DATA;
				when "1001100" =>
					ADCvalue(0) <= ADC_DATA;
				when "1001101" =>
					Trigger_out <= '1';
				when others =>
			end case;
		end if;
				
	end process;

ADC_OUT <= ADCvalue;
	
end Behavioral;

