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

#ifndef __DEBUG_PRINTF_H__
#define __DEBUG_PRINTF_H__

/**\defgroup 100debug Debug
 */
/*@{*/

/**
 */
typedef enum _DebugLevel {
	/** No debug output */
	DEBUG_NO_OUTPUT = 0,
	/** Print only error messages */
	DEBUG_ERROR = 1,
	/** Print Error and Warning messages */
	DEBUG_WARNING = 2,
	/** Print only error message */
	DEBUG_INFO = 3
} DebugLevel;

/**
 * @param dl a #DebugLevel
 *
 * Set the debug level. if set to DEBUG_INFO everything is printed to stdout.
 */
void debug_set_level(DebugLevel dl);

/** Internal function, do no use */
void debug_printf_real(DebugLevel dp, const char *file,const int line,const char *function, const char *format,...);

/** 
 * @param dp The debug level the message is at.
 * @param format a printf style string
 * @param ARGS arguments for format
 */
#define debug_printf(dp, format, ARGS...) debug_printf_real(dp,__FILE__,__LINE__,__FUNCTION__,format,##ARGS)

/**
 * @param fp a #FILE
 *
 * Redirect the output from stdout to fp.
 * Set to NULL, to revert back to stdout.
 */
void debug_set_output(FILE *fp);
/*@}*/
#endif
