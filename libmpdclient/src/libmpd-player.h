/*
 * Copyright (C) 2004-2005 Qball Cow <Qball@qballcow.nl>
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License as
 * published by the Free Software Foundation; either version 2 of the
 * License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public
 * License along with this program; if not, write to the
 * Free Software Foundation, Inc., 59 Temple Place - Suite 330,
 * Boston, MA 02111-1307, USA.
 */


/**
 * @defgroup Player Player
 * These functions allow the client to control the player part of mpd. 
 * To use the read functions you need "read" permission on mpd.
 * To use the control functions you need "control" and "read" permission on mpd.
 */
/* @{*/
#ifndef __MPD_LIB_PLAYER__
#define __MPD_LIB_PLAYER__

/**
 * Enum representing the possible states of the player
 */

typedef enum {
	/** The player is paused */
	MPD_PLAYER_PAUSE = MPD_STATUS_STATE_PAUSE, 	
	/** The player is playing */
	MPD_PLAYER_PLAY =  MPD_STATUS_STATE_PLAY,
	/** The player is stopped */
	MPD_PLAYER_STOP =  MPD_STATUS_STATE_STOP,
	/** The player is in an unknown state */
	MPD_PLAYER_UNKNOWN = MPD_STATUS_STATE_UNKNOWN
} MpdState;

/**
 * \param mi a #MpdObj
 *
 * Sends mpd the play command.
 * 
 * This equals:
 * @code
 * mpd_player_play_id(mi, -1);
 * @endcode
 *
 * @returns a #MpdError
 */
int mpd_player_play(MpdObj * mi);


/**
 * 
 * \param mi a #MpdObj
 * \param id a songid.
 *
 * Plays the song with id
 *
 * @returns a #MpdError
 */
int mpd_player_play_id(MpdObj * mi, int id);


/** 
 * \param mi a #MpdObj
 *
 * Sends mpd the stop command.
 *
 * @returns a #MpdError
 */
int mpd_player_stop(MpdObj * mi);


/**
 * \param mi a #MpdObj
 *
 * Sends mpd the next command.
 *
 * @returns a #MpdError
 */
int mpd_player_next(MpdObj * mi);


/**
 * \param mi a #MpdObj
 *
 * Sends mpd the prev command.
 *
 * @returns a #MpdError
 */
int mpd_player_prev(MpdObj * mi);


/**
 * \param mi a #MpdObj
 *
 * Sends mpd the pause command.
 *
 * @returns a #MpdError
 */
int mpd_player_pause(MpdObj * mi);


/**
 * \param mi a #MpdObj
 *
 * Returns the mpd play state (play/paused/stop)
 *
 * @returns a #MpdState
 */
int mpd_player_get_state(MpdObj * mi);

/**
 * \param mi a #MpdObj
 *
 * Returns the id of the currently playing song
 *
 * @returns the songid of the playing song
 */
int mpd_player_get_current_song_id(MpdObj * mi);


/**
 * \param mi a #MpdObj
 *
 * Returns the position of the currently playing song in the playlist
 *
 * @returns the position of the playing song
 */
int mpd_player_get_current_song_pos(MpdObj * mi);


/**
 * \param mi a #MpdObj
 *
 * Get the state of repeat: 1 if enabled, 0 when disabled.
 *
 * @returns the state of repeat
 */
int mpd_player_get_repeat(MpdObj * mi);


/**
 * \param mi a #MpdObj
 * \param repeat New state of repeat (1 is enabled, 0 is disabled)
 *
 * Enable/disabled repeat
 *
 * @returns 0 when succesfull
 */
int mpd_player_set_repeat(MpdObj * mi, int repeat);
/**
 * \param mi a #MpdObj
 *
 * Get the state of random: 1 if enabled, 0 when disabled.
 *
 * @returns the state of random
 */

int mpd_player_get_random(MpdObj * mi);
/**
 * @param mi a #MpdObj
 * @param random New state of random (1 is enabled, 0 is disabled)
 *
 * Enable/disabled random
 *
 * @returns 0 when succesfull
 */
int mpd_player_set_random(MpdObj * mi, int random);


/**
 * @param mi a #MpdObj
 * @param sec Position to seek to. (in seconds)
 *
 * Seek through the current song.
 * @returns a #MpdError
 */
int mpd_player_seek(MpdObj * mi, int sec);

#endif

/*@}*/
