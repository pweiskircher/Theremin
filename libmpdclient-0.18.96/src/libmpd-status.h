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


#ifndef __MPD_LIB_STATUS__
#define __MPD_LIB_STATUS__
/**\defgroup 20status Status
 * Functions to get and modify the status/state of mpd.
 */
/*@{*/

/**
 * @param mi a #MpdObj
 *
 * Checks if there is status information available. if not available, it tries to fetch it.
 * This function is called from within libmpd, and shouldn't be called from the program.
 *
 * @returns 0 when successful
 */
int 		mpd_status_check			(MpdObj *mi);



/**
 * @param mi a #MpdObj
 *
 * Marks the current status invalid, the next time status is needed it will be fetched from mpd.
 *
 * @returns 0 when successful
 */
int 		mpd_status_queue_update			(MpdObj *mi);



/**
 * @param mi a #MpdObj
 *
 * Updates the status field from mpd.
 * Call this function every 0.x seconds from the program's main-loop to receive signals when mpd's status has changed.
 *
 * @returns 0 when succesfull
 */
int 		mpd_status_update			(MpdObj *mi);



/**
 * @param mi a #MpdObj
 * @param fvol a float between 0.0 and 1.0
 *
 * Set the output volume
 * @returns the new volume or a value below 0 when failed.
 */
float 		mpd_status_set_volume_as_float		(MpdObj *mi, float fvol);


/**
 * @param mi a #MpdObj
 * @param volume a value between 0 and 100.
 *
 * Set the output volume
 *
 * @returns the new volume or < 0 when failed.
 */
int 		mpd_status_set_volume			(MpdObj *mi,int volume);



/**
 * @param mi a #MpdObj
 *
 * Get the audio output volume.
 *
 * @returns the audio output volume between 0 and 100 or < 0 when failed
 */
int 		mpd_status_get_volume			(MpdObj *mi);



/**
 * @param mi a #MpdObj
 *
 * get the bitrate of the currently playing song in kbs. This is a constantly updating value. (for vbr songs)
 *
 * @returns bitrate in kbs
 */
int 		mpd_status_get_bitrate			(MpdObj *mi);



/**
 * @param mi a #MpdObj
 *
 * get the samplerate of the currently playing song in bps. 
 *
 * @returns samplerate in bps
 */
unsigned int 	mpd_status_get_samplerate			(MpdObj *mi);



/**
 * @param mi a #MpdObj
 *
 * get the number of channels in the currently playing song. This is usually only 1(mono) or 2(stereo), but this might change in the future.
 *
 * @returns number of channels
 */
int 		mpd_status_get_channels			(MpdObj *mi);



/**
 * @param mi a #MpdObj
 *
 * get the number of bits per sample of the currently playing song. 
 *
 * @returns bits per sample 
 */
int 		mpd_status_get_bits			(MpdObj *mi);



/**
 * @param mi a #MpdObj
 *
 * get the total length of the currently playing song.
 *
 * @returns time in seconds or <0 when failed.
 */
int		mpd_status_get_total_song_time		(MpdObj *mi);


/**
 * @param mi a #MpdObj 
 *
 * Gets the elapsed time of the currently playing song.
 *
 * @returns Time in seconds
 */
int		mpd_status_get_elapsed_song_time	(MpdObj *mi);


/**
 * @param mi a #MpdObj
 * 
 * Get the crossfade time. 0 is disabled.
 *
 * @returns The crossfade time in seconds
 */
int		mpd_status_get_crossfade		(MpdObj *mi);



/**
 * @param mi a #MpdObj
 * @param crossfade_time the time to crossfade in seconds
 *
 * Sets the crossfade time. 0 to disable crossfade.
 *
 * @returns 0 when successful
 */
int		mpd_status_set_crossfade		(MpdObj *mi, int crossfade_time);



/**
 * @param mi a #MpdObj
 *
 * Checks if mpd is updating it's music db.
 * 
 * @returns TRUE if mpd is still updating, FALSE if not.
 */
int 		mpd_status_db_is_updating		(MpdObj *mi);

/**
 * @param mi a #MpdObj
 * 
 * @returns the error message that mpd last reported, or NULL. Needs to be freed.
 */

char * mpd_status_get_mpd_error(MpdObj *mi);

/*@}*/

/**\defgroup 20stats Stats
 * Functions to get mpd statistics
 */
/*@{*/




/**
 * @param mi a #MpdObj
 *
 * Shouldn't be used from the program.
 */
int		mpd_stats_update			(MpdObj *mi);


/**
 * @param mi a #MpdObj
 *
 * Gets the total number of songs in the database
 *
 * @returns The total number of songs
 */
int		mpd_stats_get_total_songs		(MpdObj *mi);


/**
 * @param mi a #MpdObj
 *
 * Gets the total number of artists in the database.
 *
 * @returns The number of artists in the database
 */
int		mpd_stats_get_total_artists		(MpdObj *mi);



/**
 * @param mi a #MpdObj
 *
 * Gets the total number of albums in the database
 *
 * @returns The number of albums in the database
 */
int		mpd_stats_get_total_albums		(MpdObj *mi);



/**
 * @param mi a #MpdObj
 *
 * Gets the time since mpd has been running
 * 
 * @returns time since mpd has been running in seconds
 */
int		mpd_stats_get_uptime			(MpdObj *mi);
/**
 * @param mi a #MpdObj
 *
 * Gets the total time of the database
 *
 * @returns the total time of the database
 */
int 		mpd_stats_get_db_playtime		(MpdObj *mi);



/**
 * @param mi a #MpdObj
 *
 * Gets the time mpd is playing
 * 
 * @returns time that mpd is playing in seconds
 */
int		mpd_stats_get_playtime			(MpdObj *mi);




/*@}*/
#endif
