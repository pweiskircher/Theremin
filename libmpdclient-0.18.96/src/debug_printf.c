/* libmpd (high level libmpdclient library)
 * Copyright (C) 2004-2009 Qball Cow <qball@sarine.nl>
 * Project homepage: http://gmpcwiki.sarine.nl/
 
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.

 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.

 * You should have received a copy of the GNU General Public License along
 * with this program; if not, write to the Free Software Foundation, Inc.,
 * 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
*/

#include <stdio.h>
#include <string.h>
#include <stdarg.h>
#include <stdlib.h>
#include <unistd.h>
#include <time.h>
#include "config.h"
#include "debug_printf.h"

int debug_level = 0;
/* Compiler does not like it when I initialize this to stdout, complaints about
 * not being constant. stoud is a macro..
 * So use this "hack"
 */
FILE *rout = NULL;
#define ERROR_BUFFER_SIZE 2048
char error_buffer[ERROR_BUFFER_SIZE];

void debug_set_output(FILE *fp)
{
    rout = fp;
}

void debug_set_level(DebugLevel dl)
{
	debug_level = (dl<0)?DEBUG_NO_OUTPUT:((dl > DEBUG_INFO)?DEBUG_INFO:dl);
}


void debug_printf_real(DebugLevel dp, const char *file,const int line,const char *function, const char *format,...)
{
	if(debug_level >= dp)
	{
		va_list arglist;
        time_t ts = time(NULL);
        struct tm tm;
        char buffer[32];
        FILE *out = stdout;
        if(rout) out = rout;
        va_start(arglist,format);
  
  /* Windows has no thread-safe localtime_r function, so ignore it for now */
#ifndef WIN32
        localtime_r(&ts, &tm);
        strftime(buffer, 32, "%d/%m/%y %T",&tm); 
#else
        buffer[0] = '\0';
#endif

		if(dp == DEBUG_INFO)
		{
			fprintf(out,"%s: INFO:    %s %s():#%d:\t",buffer,file,function,line);
		}
		else if(dp == DEBUG_WARNING)
		{
			fprintf(out,"%s: WARNING: %s %s():#%i:\t",buffer,file,function,line);
		}
		else
		{
			fprintf(out,"%s: ERROR:   %s %s():#%i:\t",buffer,file,function,line);
		}
		vsnprintf(error_buffer,ERROR_BUFFER_SIZE,format, arglist);
		if(format[strlen(format)-1] != '\n')
		{
			fprintf(out,"\n");
		}
		fflush(out);
		va_end(arglist);
	}
}
