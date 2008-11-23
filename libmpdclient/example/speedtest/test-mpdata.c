#include <stdio.h>
#include "libmpd.h"


int main(int argc, char **argv)
{
	MpdData *data = NULL;
	int i = 0;
	for(i=0; i < 100000;i++)
	{

		data =mpd_new_data_struct_append(data);
	}
	do{




	}while((data = mpd_data_get_next(data)));



}
