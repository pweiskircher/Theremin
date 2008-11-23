#ifndef __STRFSONG_H__
#define __STRFSONG_H__

#include "libmpd.h"
/**
 * \ingroup Misc 
 * @param s		A buffer to write the string in
 * @param max		The max length of the buffer
 * @param format	The markup string
 * @param song		A mpd_Song
 *
 * printfs a formatted string of a mpd_Song
 *
 * @returns The length of the new formatted string
 */

unsigned int mpd_song_markup(char *s, unsigned int max, const char *format, mpd_Song * song);

#endif
