struct VarFltst
{
	int sig;
	int ex;
	int man;
};

int fix2float23(int _fix);
int float2fix23(int _fp, int _scale);

VarFltst float_expand23(int _fp);
int float_collapse23(VarFltst fRes);

VarFltst float_mult23(VarFltst _aa, VarFltst _bb);
VarFltst float_add23(VarFltst _aa, VarFltst _bb, int addsub);