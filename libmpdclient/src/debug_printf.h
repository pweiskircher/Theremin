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
/*@}*/
#endif
