#include <math.h>
#include "fp_op.h"

/*****************************************************************/
int float_collapse23(VarFltst fRes)
{
	int _fp;
	_fp = ((fRes.ex << 16) & 0x003F0000) + ((fRes.sig << 22) & 0x400000) + (fRes.man);
	return _fp;
}
/*****************************************************************/
int float2fix23(int _fp, int _scale)
{
	int _mant = (_fp & 0xFFFF);
	int _exp =  (_fp >> 16) & 0x003F;
	int _sign = (_fp >> 22) & 0x0001;

	int new_exp = (_exp - _scale) & 0xF;
	
	if (_exp == 0)
		_mant = _mant;
	else
		_mant = _mant + 0x10000;

	int mant_16 = (_mant << new_exp) & 0xFFFF0000;
	mant_16 = (mant_16 >> 16) & 0xFFFF;

	int _FIX = 0;
	if (_sign == 1)
		_FIX = mant_16 ^ 0xFFFF;
	else
		_FIX = mant_16;

	return _FIX;
}
/*****************************************************************/
int fix2float23(int _fix)
{
	int msb = 1;
	int sign_fp = (_fix >> 15) & 0x1;
	
	int mant_fp = 0;
	if (sign_fp == 1)
		mant_fp = 0xFFFFFFFF ^ (_fix);
	else
		mant_fp = _fix;

	for (int jj=0; jj<16; jj++)
	{
		if (mant_fp==0) 
		{
			msb = 32;
			break;
		}
		else
		{
			if (mant_fp & 0x8000)
			{
				mant_fp = mant_fp << 1;
				break;
			}
			else 
			{
				mant_fp = mant_fp << 1;
				msb++;
			}
		}
	}
	int msb_fp = 32-msb;
	mant_fp &= 0xFFFF;
	int FP = ((sign_fp << 22) & 0x400000) + ((msb_fp << 16) & 0x3F0000) + (mant_fp);

	return FP;
}
/*****************************************************************/
VarFltst float_expand23(int _fp)
{
	VarFltst _fRes;

	_fRes.man	= (_fp & 0xFFFF);
	_fRes.sig	= (_fp >> 22) & 0x1;
	_fRes.ex	= (_fp >> 16) & 0x3F;

	return _fRes;
}
/*****************************************************************/
VarFltst float_mult23(VarFltst _aa, VarFltst _bb)
{
	VarFltst AA;
	VarFltst BB;
	VarFltst CC;

	AA.sig	= _aa.sig; 
	AA.ex	= _aa.ex;
	AA.man	= _aa.man;

	BB.sig	= _bb.sig;
	BB.ex	= _bb.ex;
	BB.man	= _bb.man;

	CC.sig = (AA.sig ^ BB.sig);

	long long a1 = AA.man | 0x00010000;
	long long a2 = BB.man | 0x00010000;	
	long long mant = (a1) * (a2);

	int msb = (mant >> 33) & 0x00000001;
	if (msb == 1)
		CC.man = (mant >> 17) & 0x0000FFFF;
	else
		CC.man = (mant >> 16) & 0x0000FFFF;

	CC.ex  = (AA.ex + BB.ex - 16) + msb; // double -16 for Fourier
	/*CC.ex  = (AA.ex + BB.ex - 16 - 16) + msb;*/

	if ((AA.ex == 0) | (BB.ex == 0))
	{
		CC.ex = 0x0;
		CC.man = 0x0;
		CC.sig = 0x0;
	}
	return CC;
}
/*****************************************************************/
VarFltst float_add23(VarFltst _aa, VarFltst _bb, int addsub)
{
	VarFltst AA;
	VarFltst BB;
	VarFltst CC;

	int Aexpman = 0;
	int Bexpman = 0;
	//int Cexp = 0;
	int Csub = 0;

	long long sum_man = 0;

	int impA = 0;
	int impB = 0;

	AA.sig	= _aa.sig;
	AA.ex	= _aa.ex;
	AA.man	= _aa.man;
	BB.sig	= _bb.sig;
	BB.ex	= _bb.ex;
	BB.man	= _bb.man;

	if (addsub == 0)
		BB.sig = (~BB.sig & 0x1);

	Aexpman = (AA.ex << 15) | AA.man;
	Bexpman = (BB.ex << 15) | BB.man;

	CC = AA;
	if ((Aexpman - Bexpman) < 0)
	{
		AA = BB;
		BB = CC;
	}

	if (AA.ex == 0)
		impA = 0x0;
	else
		impA = 0x00010000;
	if (BB.ex == 0)
		impB = 0x0;
	else
		impB = 0x00010000;

	AA.man |= impA;
	BB.man |= impB;

	int Cexp = 0;
	//Cexp = pow(2,-(BB.ex-AA.ex));
	Cexp = (0x80000000 >> (AA.ex-BB.ex)) >> 15;

	int exp_not56 = 0;
	exp_not56 = ((AA.ex-BB.ex) >> 5) & 0x0003;

	if (exp_not56 != 0)
	{
		Cexp = 0x0;
	}

	Csub = AA.sig ^ BB.sig;

	long long Bm = 0;
	long long Am = 0;
	long long Cm = 0;

	Cm = Cexp & 0x00000000FFFFFFFF;

	Am = AA.man;
	Am <<= 16;
	Bm = BB.man;
	Bm *= Cm;

	if (Csub == 0)
		sum_man = Am + Bm;
	else
		sum_man = Am - Bm;

	sum_man >>= 17;

	int msb_num = 0;
	int com_msb = 0;
	int Afor = 0;

	Afor = (((sum_man >> 1) & 0x0000FFFF) << 16) & 0xFFFF0000;
	// MSB SEEKER
	for (int ii=0;ii<32;ii++)
	{
		com_msb = Afor & 0x00000001;
		if (com_msb == 1)
			msb_num = ii;

		Afor = Afor >> 1;
	}

	int msbn = 0;
	int shmask = 0x0001;

	//msbn = ~(msb_num) & 0x0000001F;
	msbn = ~(msb_num) & 0x0000001F;
	shmask <<= msbn;
	shmask &= 0x0000FFFF;

	long long LUT = sum_man * shmask;

	int set_zero = 0;
	if ((AA.ex - msbn) < 0)
		set_zero = 1;
	else
		set_zero = 0;

	if (set_zero==0)
		CC.ex  = (AA.ex - msbn) + 1;
	else
		CC.ex  = 0x0;
	CC.sig = AA.sig; 
	CC.man = LUT & 0x0000FFFF;

	return CC;
}
