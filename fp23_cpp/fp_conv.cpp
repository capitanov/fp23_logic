// fp_conv.cpp : Defines the entry point for the console application.

#include <math.h>
#include <conio.h>
#include "stdafx.h"

#include "fp_op.h"

#define pi 3.141592653589793238462643383279502884
#define N_FFT pow(2.0, 16)//2048//65536//;2048

int _tmain(int argc, _TCHAR* argv[])
{
	
	VarFltst fp_res;
	int fp23_con;
	int fix_res;
	
	int fp23_int = 0x0;
	VarFltst fp23_flt;
	for (int i = 0; i < N_FFT; i++)
	{
		// fix2float
		fp23_int = fix2float23(i);
		fp23_flt = float_expand23(fp23_int);
		
		// base math op
		// fp_res = float_mult23(fp22_flt, fp23_flt); // MULT
		// fp_res = float_add23(fp23_flt, fp23_flt, 0x0); // SUB
		fp_res = float_add23(fp23_flt, fp23_flt, 0x1); // ADD

		// float2fix
		fp23_con = float_collapse23(fp_res);
		fix_res = float2fix23(fp23_con, 0x10); // SCALE FACTOR
		fix_res = fix_res & 0x0000FFFF;

		printf("Result: fp23 = (0x%02X 0x%01X 0x%04X), i = %04X, res = %04X %d\n", fp_res.ex, fp_res.sig, fp_res.man, (i & 0xFFFF), fix_res, fix_res);
	}

	getch();

}

