#include <stdio.h>
#include <string.h>
#include <stdarg.h>
#include <stdlib.h>
#include "config.h"
#include "debug_printf.h"

#define RED "\x1b[31;01m"
#define DARKRED "\x1b[31;06m"
#define RESET "\x1b[0m"
#define GREEN "\x1b[32;06m"
#define YELLOW "\x1b[33;06m"

int debug_level = 0;

void debug_set_level(DebugLevel dl)
{
	debug_level = (dl<0)?DEBUG_NO_OUTPUT:((dl > DEBUG_INFO)?DEBUG_INFO:dl);
}


void debug_printf_real(DebugLevel dp, const char *file,const int line,const char *function, const char *format,...)
{
	if(debug_level >= dp)
	{
		va_list arglist;
		va_start(arglist,format);
		if(dp == DEBUG_INFO)
		{
			printf(GREEN"INFO:"RESET"    %s %s():#%d:\t",file,function,line);
		}
		else if(dp == DEBUG_WARNING)
		{
			printf(YELLOW"WARNING:"RESET" %s %s():#%i:\t",file,function,line);
		}
		else
		{
			printf(DARKRED"ERROR:"RESET"   %s %s():#%i:\t",file,function,line);
		}
		vprintf(format, arglist);
		if(format[strlen(format)-1] != '\n')
		{
			printf("\n");
		}
		fflush(NULL);
		va_end(arglist);
	}
}
