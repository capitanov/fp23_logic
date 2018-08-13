-------------------------------------------------------------------------------
--
-- Title       : fp23_complex_tst_m1
-- Design      : fpfftk
-- Author      : Kapitanov
-- Company     :
--
-------------------------------------------------------------------------------
--
-- Description : floating point multiplier
--
-------------------------------------------------------------------------------
--
--	Version 1.0  19.12.2015
--			   	 Description: Complex floating point multiplier for tests only	
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
use ieee.std_logic_unsigned.all;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;

library work;
use work.fp_m1_pkg.all;

entity fp23_complex_tst_m1 is
	generic (
		td		: time:=1ns			--! Time delay for simulation	
	);
	port(
		ARE        : in  STD_LOGIC_VECTOR(15 downto 0); --! Real part of A
		AIM        : in  STD_LOGIC_VECTOR(15 downto 0); --! Imag part of A
		BRE        : in  STD_LOGIC_VECTOR(15 downto 0); --! Real part of B
		BIM        : in  STD_LOGIC_VECTOR(15 downto 0); --! Imag part of B      
		ENA        : in  STD_LOGIC;	--! Input data enable
		           
		CRE        : out STD_LOGIC_VECTOR(15 downto 0); --! Real part of C 
		CIM        : out STD_LOGIC_VECTOR(15 downto 0); --! Imag part of C 		
		VAL        : out STD_LOGIC;	--! Output data valid
		
		SCALE      : in  STD_LOGIC_VECTOR(05 downto 0); --! SCALE for FP converter 
		
		RESET      : in  STD_LOGIC;	--! Reset            
		CLK        : in  STD_LOGIC	--! Clock	         
	);	
end fp23_complex_tst_m1;

architecture test_fp23_cm_m1 of fp23_complex_tst_m1 is

signal are_z 		: std_logic_vector(15 downto 0);
signal aim_z 		: std_logic_vector(15 downto 0);
signal bre_z 		: std_logic_vector(15 downto 0);
signal bim_z 		: std_logic_vector(15 downto 0);
signal ena_z 		: std_logic_vector(03 downto 0);
signal rst 			: std_logic_vector(11 downto 0);

signal fp23_aa		: fp23_complex;	
signal fp23_bb		: fp23_complex;
signal fp23_val		: std_logic;

signal fp23_are_bre	: fp23_data;	
signal fp23_are_bim	: fp23_data;
signal fp23_aim_bre	: fp23_data;	
signal fp23_aim_bim	: fp23_data;
signal fp23_mult	: std_logic;

signal fp23_cc		: fp23_complex;	
signal fp23_add		: std_logic;   

signal fix_cc_re	: std_logic_vector(15 downto 0);
signal fix_cc_im	: std_logic_vector(15 downto 0);
signal fix_val		: std_logic;

signal scale_z		: std_logic_vector(5 downto 0);

begin
   
are_z <= ARE after td when rising_edge(clk);	
aim_z <= AIM after td when rising_edge(clk);	
bre_z <= BRE after td when rising_edge(clk);	
bim_z <= BIM after td when rising_edge(clk);

---------------- FIX2FLOAT CONVERTER ----------------
ARE_CONV : entity work.fp23_fix2float_m1
	generic map( td	=> td)
	port map (
		din 		=> are_z,
		ena 		=> ena_z(0),
		dout 		=> fp23_aa.re,
		vld 		=> fp23_val,
		reset 		=> rst(0),
		clk 		=> clk
	);	
	
AIM_CONV : entity work.fp23_fix2float_m1
	generic map( td	=> td)
	port map (
		din 		=> aim_z,
		ena 		=> ena_z(1),
		dout 		=> fp23_aa.im,
		vld 		=> open,
		reset 		=> rst(1),
		clk 		=> clk
	);
	
BRE_CONV : entity work.fp23_fix2float_m1
	generic map( td	=> td)
	port map (
		din 		=> bre_z,
		ena 		=> ena_z(2),
		dout 		=> fp23_bb.re,
		vld 		=> open,
		reset 		=> rst(2),
		clk 		=> clk
	);	
	
BIM_CONV : entity work.fp23_fix2float_m1
	port map (
		din 		=> bim_z,
		ena 		=> ena_z(3),
		dout 		=> fp23_bb.im,
		vld 		=> open,
		reset 		=> rst(3),
		clk 		=> clk
	);		
	
---------------- FlOAT MULTIPLY A*B ----------------		
ARExBRE : entity work.fp23_mult_m1
	generic map( td	=> td)
	port map (
		aa 		=> fp23_aa.re,	
		bb 		=> fp23_bb.re,	
		cc 		=> fp23_are_bre,	
		enable 	=> fp23_val,	
		valid	=> fp23_mult,	
		reset  	=> rst(4),	
		clk 	=> clk
	);	
	
AIMxBIM : entity work.fp23_mult_m1
	port map(
		aa 		=> fp23_aa.im,	
		bb 		=> fp23_bb.im,	
		cc 		=> fp23_aim_bim,	
		enable 	=> fp23_val,	
		valid	=> open,
		reset  	=> rst(5),	
		clk 	=> clk
	);	
	
	
ARExBIM : entity work.fp23_mult_m1
	generic map( td	=> td)
	port map (
		aa 		=> fp23_aa.re,	
		bb 		=> fp23_bb.im,	
		cc 		=> fp23_are_bim,	
		enable 	=> fp23_val,	
		valid	=> open,
		reset  	=> rst(6),	
		clk 	=> clk
	);		
	
AIMxBRE : entity work.fp23_mult_m1
	generic map( td	=> td)
	port map (
		aa 		=> fp23_aa.im,	
		bb 		=> fp23_bb.re,	
		cc 		=> fp23_aim_bre,	
		enable 	=> fp23_val,	
		valid	=> open,	
		reset  	=> rst(7),	
		clk 	=> clk
	);		
		
---------------- FlOAT ADD/SUB +/- ----------------	
AB_ADD : entity work.fp23_addsub_m1
	generic map( td	=> td)
	port map (
		aa 		=> fp23_are_bim,	
		bb 		=> fp23_aim_bre,	
		cc 		=> fp23_cc.im,	
		addsub	=> '0',
		enable 	=> fp23_mult,	
		valid	=> fp23_add,	
		reset  	=> rst(8),	
		clk 	=> clk
	);
	
AB_SUB : entity work.fp23_addsub_m1
	generic map( td	=> td)
	port map (
		aa 		=> fp23_are_bre,	
		bb 		=> fp23_aim_bim,	
		cc 		=> fp23_cc.re,	
		addsub	=> '1',
		enable 	=> fp23_mult,	
		valid	=> open,	
		reset  	=> rst(9),	
		clk 	=> clk
	);		
	
---------------- FLOAT TO FIX ----------------	
scale_z <= scale after td when rising_edge(clk);	

FIX_RE : entity work.fp23_float2fix_m1
	generic map( td	=> td)
	port map (
		din 		=> fp23_cc.re,
		ena 		=> fp23_add,
		dout 		=> fix_cc_re,
		vld 		=> fix_val,
		scale		=> scale_z,
		reset 		=> rst(10),
		clk 		=> clk,
		overflow	=> open
	);	
	
FIX_IM : entity work.fp23_float2fix_m1
	generic map( td	=> td)
	port map (
		din 		=> fp23_cc.im,
		ena 		=> fp23_add,
		dout 		=> fix_cc_im,
		vld 		=> open,
		scale		=> scale_z,
		reset 		=> rst(11),
		clk 		=> clk,
		overflow	=> open
	);	   
	
CRE	<= fix_cc_re after td when rising_edge(clk);
CIM	<= fix_cc_im after td when rising_edge(clk);
VAL	<= fix_val after td when rising_edge(clk);

G_ENA: for ii in 0 to 3 generate
	ena_z(ii) <= ENA after td when rising_edge(clk);	
end generate;
G_RST: for ii in 0 to 11 generate
	rst(ii) <= RESET after td when rising_edge(clk);	
end generate;

end test_fp23_cm_m1;