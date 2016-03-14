-------------------------------------------------------------------------------
--
-- Title       : fp_m1_pkg
-- Design      : fpfftk
-- Author      : Kapitanov
-- Company     :
--
-- Description : FP useful package
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

package	fp_m1_pkg is	
		
	type fp23_data is record
		exp 	: std_logic_vector(5 downto 0); 
		sig 	: std_logic;
		man 	: std_logic_vector(15 downto 0);
	end record;	
	
	type fp23_complex is record
		re : fp23_data;
		im : fp23_data;
	end record;
	
	component fp23_fix2float_m1 is
		generic(
			td		: time:=1ns			
		);	
		port(
			din    : in  std_logic_vector(15 downto 0);	
			ena    : in  std_logic;
			dout   : out fp23_data;
			vld    : out std_logic;
			clk    : in  std_logic;
			reset  : in  std_logic
		);
	end component;	
	
	component fp23_float2fix_m1 is
		generic(
			td		: time:=1ns			
		);	
		port(
			din      : in  fp23_data;	
			dout     : out std_logic_vector(15 downto 0);
			clk      : in  std_logic;
			reset    : in  std_logic;
			ena      : in  std_logic;                       
			scale    : in  std_logic_vector(05 downto 0);    
			vld      : out std_logic;                    
			overflow : out std_logic                       
		);
	end component;
	
	component fp23_mult_m1 is
		generic(
			td		: time:=1ns			
		);	
		port(
			aa        : in  fp23_data;	
			bb        : in  fp23_data;	
			cc        : out fp23_data;	
			enable    : in  std_logic;						
			valid     : out std_logic;						
			reset     : in  std_logic;						
			clk       : in  std_logic							
		);	
	end component;	
	
	component fp23_addsub_m1 is
		generic(
			td		: time:=1ns			
		);	
		port(
			aa       : in  fp23_data;
			bb       : in  fp23_data;   
			cc       : out fp23_data;
			addsub   : in  std_logic;
			enable   : in  std_logic;
			valid    : out std_logic;
			reset    : in  std_logic;
			clk      : in  std_logic							
		);
	end component;	

end fp_m1_pkg;
