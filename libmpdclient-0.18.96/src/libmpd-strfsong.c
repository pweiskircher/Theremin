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

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include "libmpd.h"
#include "libmpd-internal.h"

static char * skip(char * p) 
{
	int stack = 0;

	while (*p != '\0') {
		if(*p == '[') stack++;
		if(*p == '#' && p[1] != '\0') {
			/* skip escaped stuff */
			++p;
		}
		else if(stack) {
			if(*p == ']') stack--;
		}
		else {
			if(*p == '&' || *p == '|' || *p == ']') {
				break;
			}
		}
		++p;
	}

	return p;
}

static unsigned int _strfsong(char *s, 
		unsigned int max, 
		const char *format, 
		mpd_Song *song, 
		char **last)
{
	char *p, *end;
	char *temp;
	unsigned int n, length = 0;
	int i;
	short int found = FALSE;

	memset(s, 0, max);
	if( song==NULL )
		return 0;

	for( p=(char *) format; *p != '\0' && length<max; )
	{
		/* OR */
		if (p[0] == '|') 
		{
			++p;
			if(!found) 
			{
				memset(s, 0, max);
				length = 0;
			}
			else 
			{
				p = skip(p);
			}
			continue;
		}

		/* AND */
		if (p[0] == '&') 
		{
			++p;
			if(!found) 
			{
				p = skip(p);
			}
			else 
			{
				found = FALSE;
			}
			continue;
		}

		/* EXPRESSION START */
		if (p[0] == '[')
		{
			temp = malloc(max);
			if( _strfsong(temp, max, p+1, song, &p) >0 )
			{
				strncat(s, temp, max-length);
				length = strlen(s);
				found = TRUE;
			}
			free(temp);
			continue;
		}

		/* EXPRESSION END */
		if (p[0] == ']')
		{
			if(last) *last = p+1;
			if(!found && length) 
			{
				memset(s, 0, max);
				length = 0;
			}
			return length;
		}

		/* pass-through non-escaped portions of the format string */
		if (p[0] != '#' && p[0] != '%' && length<max)
		{
			strncat(s, p, 1);
			length++;
			++p;
			continue;
		}

		/* let the escape character escape itself */
		if (p[0] == '#' && p[1] != '\0' && length<max)
		{
			strncat(s, p+1, 1);
			length++;
			p+=2;
			continue;
		}

		/* advance past the esc character */

		/* find the extent of this format specifier (stop at \0, ' ', or esc) */
		temp = NULL;
		end  = p+1;
		while(*end >= 'a' && *end <= 'z')
		{
			end++;
		}
		n = end - p + 1;
		if(*end != '%')
			n--;
		else if (memcmp("%file%", p, n) == 0)
			temp = strdup(song->file);
		else if (memcmp("%artist%", p, n) == 0)
			temp = song->artist ? strdup(song->artist) : NULL;
		else if (memcmp("%title%", p, n) == 0)
			temp = song->title ? strdup(song->title) : NULL;
		else if (memcmp("%album%", p, n) == 0)
			temp = song->album ? strdup(song->album) : NULL;
		else if (memcmp("%track%", p, n) == 0)
			temp = song->track ? strdup(song->track) : NULL;
		else if (memcmp("%name%", p, n) == 0)
			temp = song->name ? strdup(song->name) : NULL;
		else if (memcmp("%date%", p, n) == 0)
			temp = song->date ? strdup(song->date) : NULL;		
		else if (memcmp("%genre%", p, n) == 0)
			temp = song->genre ? strdup(song->genre) : NULL;		
		else if (memcmp("%performer%", p, n) == 0)
			temp = song->performer ? strdup(song->performer) : NULL;		
		else if (memcmp("%composer%", p, n) == 0)
			temp = song->composer ? strdup(song->composer) : NULL;		
		else if (memcmp("%track%",p,n) == 0)
			temp = song->track? strdup(song->track): NULL;
		else if (memcmp("%comment%", p, n) == 0)
			temp = song->comment? strdup(song->comment): NULL;
		else if (memcmp("%plpos%", p, n) == 0 || memcmp("%songpos%",p,n) == 0){
			temp = NULL;
			if(song->pos >= 0){
				char str[32];
				int length;
				if((length = snprintf(str,32, "%i", song->pos)) >=0)
				{
					temp = strndup(str,length);				
				}
			}
		}

		else if (memcmp("%time%", p, n) == 0)
		{
			temp = NULL;
			if (song->time != MPD_SONG_NO_TIME) {
				char str[32];
				int length;
				if((length = snprintf(str,32, "%02d:%02d", song->time/60, song->time%60))>=0)
				{
					temp = strndup(str,length);
				}
			}
		}
        else if (memcmp("%disc%", p, n) == 0)
        {
			temp = song->disc? strdup(song->disc) : NULL;		
        }
        if(temp != NULL) {
            unsigned int templen = strlen(temp);
            found = TRUE;
            if( length+templen > max )
                templen = max-length;
            strncat(s, temp, templen);
            length+=templen;
            free(temp);
        }

        /* advance past the specifier */
        p += n;
    }

    for(i=0; i < length;i++)
    {
        if(s[i] == '_') s[i] = ' ';
    }	

    if(last) *last = p;

    return length;
}

unsigned int mpd_song_markup(char *s, unsigned int max,const char *format, mpd_Song *song)
{
    return _strfsong(s, max, format, song, NULL);
}

