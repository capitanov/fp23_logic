-------------------------------------------------------------------------------
--
-- Title       : fp23_float2fix_m1
-- Design      : fpfftk
-- Author      : Kapitanov
-- Company     :
--
-------------------------------------------------------------------------------
--
-- Description : Float fp23 to signed fix converter
--
-------------------------------------------------------------------------------
--
--	Version 1.5  15.08.2013
--			   	 Description:
--					Bus width for:
--					din = 23
--					dout = 16	
-- 					exp = 6
-- 					sign = 1
-- 					mant = 15 + 1
--				 Math expression: 
--					A = (-1)^sign(A) * 2^(exp(A)-31) * mant(A)
--				 NB: 
--				 Converting from float to fixed takes only 7 clock cycles
--
--				Another algorithm: double precision with 2 DSP48E1.
--	 
--	Version 1.1  22.08.2014
--			   	 Description: Data width has been changed from 27 to 24.
--					16 bits - fraction,
--					1 bit   - sign,
--					7 bits  - exponent
--
--					> 2 DSP48E1 blocks used (MEGA_DSP);
--				
--	Version 1.2  14.05.2015
--
--					> SLICEL logic has been simplified;	  
--
--	Version 1.3  01.11.2015
--
--					> remove 1 block DSP48E1;
--
--	Version 1.4  01.11.2015
--
--					> Clear all unrouted signals and components;  
-- 
--	Version 1.5  01.02.2016
--
--					> Add Barrel shifter instead of DSP48E1;  
--
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
--
--	The MIT License (MIT)
--	Copyright (c) 2016 Kapitanov Alexander 													 
--		                                          				 
-- Permission is hereby granted, free of charge, to any person obtaining a copy 
-- of this software and associated documentation files (the "Software"), 
-- to deal in the Software without restriction, including without limitation 
-- the rights to use, copy, modify, merge, publish, distribute, sublicense, 
-- and/or sell copies of the Software, and to permit persons to whom the 
-- Software is furnished to do so, subject to the following conditions:
--
-- The above copyright notice and this permission notice shall be included in 
-- all copies or substantial portions of the Software.
--
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR 
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, 
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL 
-- THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER 
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, 
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS 
-- IN THE SOFTWARE.
-- 	                                                 
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
library unisim;
use unisim.vcomponents.LUT6;

library work;
use work.fp_m1_pkg.fp23_data;
use work.reduce_pack.all;

entity fp23_float2fix_m1 is
	generic(
		td			: time:=1ns --! Time delay for simulation
	);
	port(
		din			: in  fp23_data;						--! Float input data	
		ena			: in  std_logic;						--! Data enable                        
		scale		: in  std_logic_vector(05 downto 0);	--! Scale factor 	   
		dout		: out std_logic_vector(15 downto 0);	--! Fixed output data
		vld			: out std_logic;						--! Data out valid
		clk			: in  std_logic;						--! Clock
		reset		: in  std_logic;						--! Negative reset			
		overflow	: out std_logic							--! Flag overflow 		                      
	);
end fp23_float2fix_m1;

architecture fp23_float2fix_m1 of fp23_float2fix_m1 is 

component sp_addsub_m1 is
	generic(	
		N 		: integer
	);
	port(
		data_a 	: in  std_logic_vector(N-1 downto 0);
		data_b 	: in  std_logic_vector(N-1 downto 0);
		data_c 	: out std_logic_vector(N-1 downto 0);
		add_sub	: in  std_logic;  -- '0' - add, '1' - sub
		cin     : in  std_logic:='0';
		cout    : out std_logic;
		clk    	: in  std_logic;
		ce 		: in  std_logic:='1';	
		aclr  	: in  std_logic:='1'
	);
end component;

signal exp_dif			: std_logic_vector(5 downto 0);	  --
signal mant				: std_logic_vector(16 downto 0);
signal rstp				: std_logic;
signal implied			: std_logic;
signal frac				: std_logic_vector(15 downto 0);  -- 
signal sign_z			: std_logic_vector(2 downto 0);	
signal valid			: std_logic_vector(3 downto 0);	
signal shift			: std_logic_vector(5 downto 0);

signal man_shift		: std_logic_vector(31 downto 0);
signal norm_man			: std_logic_vector(15 downto 0);

signal overflow_i		: std_logic;

begin	
  
rstp <= not reset after td when rising_edge(clk); 
shift <= scale after td when rising_edge(clk);	

-- (EXP(A) - SCALE)
EXP_DIFF: sp_addsub_m1
	generic map(N => 6) 
	port map(
		data_a 	=> din.exp, 
		data_b 	=> shift, 
		data_c 	=> exp_dif, 		
		add_sub	=> '0', 				
		cin     => '1',--0 	
		--cout    => c_zero,	
		clk    	=> clk, 				
		ce 		=> valid(0), 						
		aclr  	=> rstp 				
	); 

-- implied for mantissa and find sign
pr_impl: process(clk) is
begin 
	if rising_edge(clk) then
		if (rstp = '1') then
			implied <= '0' after td;
		else
			if (din.exp = "000000") then
				implied	<='0' after td;
			else 
				implied	<='1' after td;
			end if;
		end if;	
	end if;
end process;	

-- find fraction --
frac <= din.man after td when rising_edge(clk);
pr_man: process(clk) is
begin 
	if rising_edge(clk) then
		if (rstp = '1') then
			mant <= (others => '0');	
		else
			if (valid(0) = '1') then
				mant <=	implied & frac after td;
			end if;
		end if;
	end if;
end process;
sign_z <= sign_z(1 downto 0) & din.sig after td when rising_edge(clk);

-- barrel shifter --
man_shift <= "000" & x"000" & mant;
norm_man <= man_shift(31-conv_integer(exp_dif(3 downto 0)) downto 16-conv_integer(exp_dif(3 downto 0))) after td when rising_edge(clk); 	

-- data valid and data out --
pr_out: process(clk) is
begin
	if rising_edge(clk) then
		if (rstp = '1') then
			dout <= (others => '0') after td;	
		elsif (valid(2) = '1') then	
			for ii in 0 to 15 loop
				dout(ii) <=	norm_man(ii) xor sign_z(2) after td;	 
			end loop;
		end if;
	end if;	
end process;

valid <= valid(2 downto 0) & ena after td when rising_edge(clk);	
vld <= valid(3);	

-- overflow --	
overflow_i <= and_reduce(exp_dif) after td when rising_edge(clk);
overflow <= overflow_i after td when rising_edge(clk); 

end fp23_float2fix_m1;