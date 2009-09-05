/* libmpd (high level libmpdclient library)
 * Copyright (C) 2004-2009 Qball Cow <qball@sarine.nl>
 * Project homepage: http://gmpcwiki.sarine.nl/
 
 * Based on mpc's songToFormatedString modified for glib and ncmpc
 * (c) 2003-2004 by normalperson and Warren Dukes (shank@mercury.chem.pitt.edu)
 *              and Daniel Brown (danb@cs.utexas.edu)
 *              and Kalle Wallin (kaw@linux.se)
 *              and Qball Cow (Qball@qballcow.nl)
 
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
