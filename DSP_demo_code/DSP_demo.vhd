----------------------------------------------------------------------------------
-- Company: 
-- Engineer: Felix Vietmeyer
-- 
-- Create Date:    17:37:49 09/10/2014 
-- Design Name: 
-- Module Name:    DSP_demo - Behavioral 
-- Project Name: 	OSPESA
-- Target Devices: Papilio pro
-- Tool versions: 14.7
-- Description: 
-- Some code that shows (the simplest possible way) to implement FIR filters on the Papilio
-- To cycle through the different filter settings, send any character through the virtual COM port
--	COM port settings: 57600 Baud, 8 data bits, 1 stop bit, no parity, no handshaking
--
-- Dependencies: 
--
-- Revision: 
-- Revision 1 - File Created
-- Additional Comments: 

----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.NUMERIC_STD.all;

entity DSP_demo is
    Port ( 
			  --status LEDS
			  LED_0 : out  STD_LOGIC;
           LED_1 : out  STD_LOGIC;
			  LED_2 : out  STD_LOGIC;
			  LED_3 : out  STD_LOGIC;
			  LED_4 : out  STD_LOGIC;
           LED_5 : out  STD_LOGIC;
			  LED_6 : out  STD_LOGIC;
			  LED_7 : out  STD_LOGIC;
			  LED_8 : out  STD_LOGIC;
           LED_9 : out  STD_LOGIC;
			  LED_10 : out  STD_LOGIC;
			  
			  --DAC1
			  DAC1_SDI : out  STD_LOGIC := '0';
			  DAC1_miso : in  STD_LOGIC := '0';
			  DAC1_CS : BUFFER  STD_LOGIC := '1';
			  DAC1_SCK : BUFFER  STD_LOGIC := '0';
			  DAC1_LDAC : out  STD_LOGIC := '0';
			  DAC1_SHDN : out  STD_LOGIC := '1';
			  
			  --DAC2
			  DAC2_SDI : out  STD_LOGIC := '0';
			  DAC2_miso : in  STD_LOGIC := '0';
			  DAC2_CS : BUFFER  STD_LOGIC := '1';
			  DAC2_SCK : BUFFER  STD_LOGIC := '0';
			  DAC2_LDAC : out  STD_LOGIC := '0';
			  DAC2_SHDN : out  STD_LOGIC := '1';
			  
			  --ADC1
			  ADC1_CLK : out  STD_LOGIC := '0';
			  ADC1_DATA : in  STD_LOGIC := '0';
			  ADC1_CONV : out  STD_LOGIC := '0';
			  
			  --ADC2
			  ADC2_CLK : out  STD_LOGIC := '0';
			  ADC2_DATA : in  STD_LOGIC := '0';
			  ADC2_CONV : out  STD_LOGIC := '0';
			
			  --RS_232
			  TX : in STD_LOGIC;
			  RX : out STD_LOGIC;
			  
			  --32 MHz FPGA XTAL
			  clk : in  STD_LOGIC);
end DSP_demo;

architecture Behavioral of DSP_demo is

signal clk32_out : STD_LOGIC;
signal clk20_out : STD_LOGIC;

signal ctr32 : STD_LOGIC_VECTOR(25 downto 0) := (others => '0'); --overflows roughly once every two seconds

--RS_232
signal RS232_rx_data : std_logic_vector(7 downto 0) := (others => '0');
signal RS232_tx_data : std_logic_vector(7 downto 0) := (others => '0');
signal RS232_tx_req : std_logic := '0';
signal RS232_rx_req : std_logic := '0';
signal RS232_tx_busy : std_logic := '0';
signal RS232_delay : std_logic_vector(7 downto 0) := (others => '0');

--ADC1
signal adc1_value : STD_LOGIC_VECTOR(15 downto 0) := (others => '0');
signal adc1_value_hold : STD_LOGIC_VECTOR(15 downto 0) := (others => '0');
signal adc1_Trigger : STD_LOGIC := '0';

--ADC2
signal adc2_value : STD_LOGIC_VECTOR(15 downto 0) := (others => '0');
signal adc2_value_hold : STD_LOGIC_VECTOR(15 downto 0) := (others => '0');
signal adc2_Trigger : STD_LOGIC := '0';

--DAC1
signal DAC1out : STD_LOGIC_VECTOR(15 downto 0) := "0001011111111111"; --16-bit DAC output word (12 LSB are output)
signal DAC1enable : STD_LOGIC := '0';

--DAC2
signal DAC2out : STD_LOGIC_VECTOR(15 downto 0) := "0001011111111111"; --16-bit DAC output word (12 LSB are output)
signal DAC2enable : STD_LOGIC := '0';

--Test clock for DAC
signal us_tick : STD_LOGIC_VECTOR(4 downto 0) := (others => '0');

--Filter select
signal Filter_select : STD_LOGIC_VECTOR(2 downto 0) := (others => '0');

--FIR filter out
signal Filter1_out : std_logic_vector(35 downto 0) := (others => '0');
signal Filter1_out_converted : signed(11 downto 0) := (others => '0');
signal Filter1_out_converted2 : std_logic_vector(11 downto 0) := (others => '0');

signal Filter2_out : std_logic_vector(33 downto 0) := (others => '0');
signal Filter2_out_converted : signed(11 downto 0) := (others => '0');
signal Filter2_out_converted2 : std_logic_vector(11 downto 0) := (others => '0');

signal Filter3_out : std_logic_vector(36 downto 0) := (others => '0');
signal Filter3_out_converted : signed(11 downto 0) := (others => '0');
signal Filter3_out_converted2 : std_logic_vector(11 downto 0) := (others => '0');

signal Filter4_out : std_logic_vector(32 downto 0) := (others => '0');
signal Filter4_out_converted : signed(11 downto 0) := (others => '0');
signal Filter4_out_converted2 : std_logic_vector(11 downto 0) := (others => '0');

signal Filter5_out : std_logic_vector(34 downto 0) := (others => '0');
signal Filter5_out_converted : signed(11 downto 0) := (others => '0');
signal Filter5_out_converted2 : std_logic_vector(11 downto 0) := (others => '0');

--UART fsm
type datatransferstate is (pack1, send1,wait1,pack2,send2,wait2,pack3,send3,wait3,pack4,send4,wait4,pack5,send5,wait5);
signal state : datatransferstate := pack1;

component DCM
port
 (-- Clock in ports
  CLK_IN1           : in     std_logic;
  -- Clock out ports
  CLK_OUT1          : out    std_logic;
  CLK_OUT2          : out    std_logic;
  -- Status and control signals
  LOCKED            : out    std_logic
 );
end component;

COMPONENT spi_master
	PORT(
		clock : IN std_logic;
		reset_n : IN std_logic;
		enable : IN std_logic;
		cpol : IN std_logic;
		cpha : IN std_logic;
		cont : IN std_logic;
		clk_div : INTEGER;
		addr : INTEGER := 0;
		tx_data : IN std_logic_vector(15 downto 0);
		miso : IN std_logic;          
		sclk : BUFFER std_logic;
		ss_n : BUFFER std_logic_vector(0 to 0);
		mosi : OUT std_logic;
		busy : OUT std_logic;
		rx_data : OUT std_logic_vector(15 downto 0)
		);
	END COMPONENT;

component Filter1
	port (
	clk: in std_logic;
	rfd: out std_logic;
	rdy: out std_logic;
	din: in std_logic_vector(15 downto 0);
	dout: out std_logic_vector(35 downto 0));
end component;

component Filter2
	port (
	clk: in std_logic;
	rfd: out std_logic;
	rdy: out std_logic;
	din: in std_logic_vector(15 downto 0);
	dout: out std_logic_vector(33 downto 0));
end component;

component Filter3
	port (
	clk: in std_logic;
	rfd: out std_logic;
	rdy: out std_logic;
	din: in std_logic_vector(15 downto 0);
	dout: out std_logic_vector(36 downto 0));
end component;

component Filter4
	port (
	clk: in std_logic;
	rfd: out std_logic;
	rdy: out std_logic;
	din: in std_logic_vector(15 downto 0);
	dout: out std_logic_vector(32 downto 0));
end component;

component Filter5
	port (
	clk: in std_logic;
	rfd: out std_logic;
	rdy: out std_logic;
	din: in std_logic_vector(15 downto 0);
	dout: out std_logic_vector(34 downto 0));
end component;

component AD7685_Interface_v2
port
 (
			  ADC_CLK : out  STD_LOGIC := '0';
			  ADC_DATA : in  STD_LOGIC := '0';
			  ADC_CONV : out  STD_LOGIC := '1';

			  ADC_OUT : out STD_LOGIC_VECTOR(15 downto 0);
			  Trigger_out : out STD_LOGIC := '0';
			  
			  clk : in  STD_LOGIC
 );
end component;

COMPONENT RS232_Interface_v1
	PORT(
		clk : IN std_logic;
		rs232_rxd : IN std_logic;
		rs232_tra_en : IN std_logic;
		rs232_dat_in : IN std_logic_vector(7 downto 0);          
		rs232_txd : OUT std_logic;
		rs232_rec_en : OUT std_logic;
		rs232_txd_busy : OUT std_logic;
		rs232_dat_out : OUT std_logic_vector(7 downto 0)
		);
	END COMPONENT;


begin

DCM_Global : DCM
  port map
   (-- Clock in ports
    CLK_IN1 => clk,
    -- Clock out ports
    CLK_OUT1 => clk32_out,
    CLK_OUT2 => clk20_out,
    -- Status and control signals
    LOCKED => open);
			
LP50Hz : Filter1
		port map (
			clk => clk32_out,
			rfd => open,
			rdy => open,
			din => adc1_value,
			dout => Filter1_out);
			
HP4000Hz : Filter2
		port map (
			clk => clk32_out,
			rfd => open,
			rdy => open,
			din => adc1_value,
			dout => Filter2_out);

BP1500Hz : Filter3
		port map (
			clk => clk32_out,
			rfd => open,
			rdy => open,
			din => adc1_value,
			dout => Filter3_out);

BS1500Hz : Filter4
		port map (
			clk => clk32_out,
			rfd => open,
			rdy => open,
			din => adc1_value,
			dout => Filter4_out);

BP250Hz_650Hz : Filter5
		port map (
			clk => clk32_out,
			rfd => open,
			rdy => open,
			din => adc1_value,
			dout => Filter5_out);

DAC1: spi_master PORT MAP(
	 clock => clk32_out,                            --system clock
    reset_n => '1',                          --asynchronous reset
    enable => DAC1enable,                    --initiate transaction
    cpol => '1',                             --spi clock polarity
    cpha => '1',                             --spi clock phase
    cont => '0',                             --continuous mode command
    clk_div => 2,                           --system clock cycles per 1/2 period of sclk
    addr => 0,                               --address of slave
    tx_data => DAC1out,			  					--data to transmit
    miso => DAC1_miso,                            --master in, slave out
    sclk => DAC1_SCK,                            --spi clock
    ss_n(0) => DAC1_CS,    --BUFFER STD_LOGIC_VECTOR(slaves-1 DOWNTO 0);   --slave select
    mosi => DAC1_SDI,                            --master out, slave in
    busy => open,                             --busy / data ready signal
    rx_data => open									--data received
);

DAC2: spi_master PORT MAP(
	 clock => clk32_out,                            --system clock
    reset_n => '1',                          --asynchronous reset
    enable => DAC2enable,                    --initiate transaction
    cpol => '1',                             --spi clock polarity
    cpha => '1',                             --spi clock phase
    cont => '0',                             --continuous mode command
    clk_div => 2,                           --system clock cycles per 1/2 period of sclk
    addr => 0,                               --address of slave
    tx_data => DAC2out,			  					--data to transmit
    miso => DAC2_miso,                            --master in, slave out
    sclk => DAC2_SCK,                            --spi clock
    ss_n(0) => DAC2_CS,    --BUFFER STD_LOGIC_VECTOR(slaves-1 DOWNTO 0);   --slave select
    mosi => DAC2_SDI,                            --master out, slave in
    busy => open,                             --busy / data ready signal
    rx_data => open									--data received
);

ADC1: AD7685_Interface_v2 PORT MAP(
		ADC_CLK => ADC1_CLK,
		ADC_DATA => ADC1_DATA,
		ADC_CONV => ADC1_CONV,
		ADC_OUT => adc1_value,
		Trigger_out => adc1_Trigger,
		clk => clk20_out
	);
	
ADC2: AD7685_Interface_v2 PORT MAP(
		ADC_CLK => ADC2_CLK,
		ADC_DATA => ADC2_DATA,
		ADC_CONV => ADC2_CONV,
		ADC_OUT => adc2_value,
		Trigger_out => adc2_Trigger,
		clk => clk20_out
	);
	
UART1: RS232_Interface_v1 PORT MAP(
	clk => clk32_out,
	rs232_rxd => TX,
	rs232_tra_en => RS232_tx_req,
	rs232_dat_in => RS232_tx_data,
	rs232_txd => RX,
	rs232_rec_en => RS232_rx_req,
	rs232_txd_busy => RS232_tx_busy,
	rs232_dat_out => RS232_rx_data
);

uart_proc: process(RS232_rx_req)
begin
if rising_edge(RS232_rx_req) then
	if Filter_select = "101" then
		Filter_select <= "000";
	else
		Filter_select <= Filter_select + 1;
	end if;
end if;
end process;

clk32_proc: process(clk32_out)
begin
if rising_edge(clk32_out) then
	ctr32 <= ctr32+1;
	us_tick <= us_tick + 1; --this counts from "00000" (0) to "11111" (31) on the 32 MHz clock
	
	
	
		if us_tick = "00000" then
		--do this every microsecond
			LED_5 <= '0';
			LED_6 <= '0';
			LED_7 <= '0';
			LED_8 <= '0';
			LED_9 <= '0';
			LED_10 <= '0';
			
			case Filter_select is
				when "000" =>
					DAC1out <= "0001" & adc1_value(15 downto 4);
					LED_9 <= '1';--TL
				when "001" =>
					DAC1out <= "0001" & Filter1_out_converted2;
					LED_8 <= '1';--TM
				when "010" =>
					DAC1out <= "0001" & Filter2_out_converted2;
					LED_6 <= '1';--TR
				when "011" =>
					DAC1out <= "0001" & Filter3_out_converted2;
					LED_10 <= '1';--BL
				when "100" =>
					DAC1out <= "0001" & Filter4_out_converted2;
					LED_7 <= '1';--BM
				when "101" =>
					DAC1out <= "0001" & Filter5_out_converted2;
					LED_5 <= '1'; --BR
				when others =>
			end case;
		DAC2out <= "0001" & adc2_value(15 downto 4);
		elsif us_tick = "0001" then
			DAC1enable <= '1';
			DAC2enable <= '1';
		elsif us_tick = "0010" then
			DAC1enable <= '0';
			DAC2enable <= '0';
		end if;
end if;
end process;

LED_0 <= ctr32(25);
LED_1 <= ctr32(24);
LED_2 <= ctr32(23);
LED_3 <= ctr32(22);
LED_4 <= ctr32(21);

Filter1_out_converted <= signed(Filter1_out(35 downto 24))+2048;
Filter1_out_converted2 <= std_logic_vector(unsigned(Filter1_out_converted));

Filter2_out_converted <= signed(Filter2_out(33 downto 22))+2048;
Filter2_out_converted2 <= std_logic_vector(unsigned(Filter2_out_converted));

Filter3_out_converted <= signed(Filter3_out(36 downto 25))+2048;
Filter3_out_converted2 <= std_logic_vector(unsigned(Filter3_out_converted));

Filter4_out_converted <= signed(Filter4_out(32 downto 21))+2048;
Filter4_out_converted2 <= std_logic_vector(unsigned(Filter4_out_converted));

Filter5_out_converted <= signed(Filter5_out(34 downto 23))+2048;
Filter5_out_converted2 <= std_logic_vector(unsigned(Filter5_out_converted));

end Behavioral;

