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

#ifndef __MPD_LIB_PLAYLIST__
#define __MPD_LIB_PLAYLIST__

/**
 * \defgroup Playlist Playlist
 */
/*@{*/


/**
 * mpd_playlist_get_playlist_id
 * @param mi a #MpdObj
 *
 * Returns the id of the current playlist
 *
 * @returns a long long
 */
long long	mpd_playlist_get_playlist_id		(MpdObj *mi);


/**
 * @param mi a #MpdObj
 *
 * Returns the id of the previous playlist
 *
 * @returns a long long
 */
long long	mpd_playlist_get_old_playlist_id         (MpdObj *mi);


/**
 * @param mi a #MpdObj
 * @param songid a SongId
 *
 * returns the mpd_Song for playlist entry with songid.
 *
 * @returns a mpd_Song
 */
mpd_Song *	mpd_playlist_get_song			(MpdObj *mi, int songid);


/**
 * @param mi a #MpdObj
 * @param songpos a Songpos
 *
 * returns the mpd_Song for playlist entry with songpos.
 *
 * @returns a mpd_Song
 */

mpd_Song * mpd_playlist_get_song_from_pos(MpdObj *mi, int songpos);


/**
 * @param mi a #MpdObj
 *
 * returns the mpd_Song for the currently playing song
 *
 * @returns a mpd_Song
 */
mpd_Song *	mpd_playlist_get_current_song		(MpdObj *mi);


/**
 * mpd_playlist_clear
 * @param mi a #MpdObj
 *
 * Clears the playlist
 *
 * @returns 
 */
int		mpd_playlist_clear			(MpdObj *mi);


/**
 * @param mi a #MpdObj
 *
 * Shuffle's the order of the playlist, this is different then playing random
 *
 * @returns 
 */
int		mpd_playlist_shuffle			(MpdObj *mi);


/**
 * @param mi a #MpdObj
 * @param old_pos The current position in the playlist
 * @param new_pos The new position in the playlist.
 *
 * Moves a song in the playlist. This uses the position of the song, not the id
 * @returns a #MpdError
 */
int		mpd_playlist_move_pos		(MpdObj *mi, int old_pos, int new_pos);


/**
 * @param mi a #MpdObj
 * @param old_id The id of the song to move
 * @param new_id The id of the song to move too.
 *
 * Moves a song in the playlist. This uses the id of the song, not the position
 * @returns a #MpdError
 */
int		mpd_playlist_move_id		(MpdObj *mi, int old_id, int new_id);

/**
* @param mi a #MpdObj
 * @param old_id 
 * @param new_id 
 *
 * Swaps two songs in the playlist.
 * @returns a #MpdError
 */
int		mpd_playlist_swap		(MpdObj *mi, int old_pos, int new_pos);

/**
* @param mi a #MpdObj
 * @param old_id 
 * @param new_id 
 *
 * Swaps two songs in the playlist.
 * @returns a #MpdError
 */
int		mpd_playlist_swap_id	(MpdObj *mi, int old_id, int new_id);

/**
 * @param mi a #MpdObj
 * @param old_playlist_id The id of the old playlist you want to get the changes with.
 *
 * Get's a list of the song that changed between the current and the old playlist
 *
 * @returns a #MpdData list
 */
MpdData *	mpd_playlist_get_changes		(MpdObj *mi,int old_playlist_id);

/**
 * @param mi a #MpdObj
 * @param old_playlist_id The id of the old playlist you want to get the changes with.
 *
 * Get's a list of the song id/pos that changed between the current and the old playlist
 * Check if this command is availible.
 *
 * @returns a #MpdData list
 */
MpdData * mpd_playlist_get_changes_posid(MpdObj *mi,int old_playlist_id);


/**
 * @param mi	a #MpdObj
 *
 * @returns The number of songs in the current playlist.
 */
int		mpd_playlist_get_playlist_length	(MpdObj *mi);

/**
 * @param mi a #MpdObj
 * @param path the path of the song to be added.
 *
 * Add's a song to the playlist, use #mpd_playlist_queue_add to add multiple songs.
 *
 * @returns a #MpdError
 */
int		mpd_playlist_add			(MpdObj *mi, char *path);

/**
 * @param mi a #MpdObj
 * @param songid a song id.
 *
 * Delete's a single song by it's id.
 *
 * @returns a #MpdError
 */
int mpd_playlist_delete_id(MpdObj *mi, int songid);

/**
 * @param mi a #MpdObj
 * @param songpos a song pos.
 *
 * Delete's a single song by it's position.
 *
 * @returns a #MpdError
 */
int mpd_playlist_delete_pos(MpdObj *mi, int songpos);	

/** 
 * @param mi a #MpdObj
 * @param path a path to a song
 *
 * Add a single path and return the id
 * Only use this to add a single list, if you need to add multiple songs,
 * use the #mpd_playlist_queue_add for improved performance
 *
 * @returns a #MpdError or the songid of the added song
 */

int mpd_playlist_add_get_id(MpdObj *mi, char *path);

/*@}*/


/** \defgroup comqueue Command Queue 
 * \ingroup Playlist
 * These functions allow you to queue commands, and send them 
 * in one command list to mpd. This is very efficient.
 * It's adviced to use these for large deletes and add's.
 * These functions doesn't cause an extra overhead compared to the non_queue functions.
 * Because the non_queue functions just wrap the following.
 */
/*@{*/

/**
 * @param mi a #MpdObj
 * @param path The path to a song to add
 *
 * This queue's an add command. The actuall add isn't done until #mpd_playlist_queue_commit is called
 *
 * @returns a #MpdError
 */
int	mpd_playlist_queue_add		(MpdObj *mi,char *path);



/**
 * @param mi a #MpdObj
 * @param path The path to a playlist to load
 *
 * This queue's an load command. The actuall load isn't done until #mpd_playlist_queue_commit is called
 *
 * @returns a #MpdError
 */
int	mpd_playlist_queue_load		(MpdObj *mi, const char *path);


/**
 * @param mi a #MpdObj
 * @param id The songid of the song you want to delete
 *
 * This queue's an delete song from playlist command. The actually delete isn't done until #mpd_playlist_queue_commit is called
 * @returns a #MpdError
 */
int	mpd_playlist_queue_delete_id	(MpdObj *mi,int id);


/**
 * @param mi a #MpdObj
 * @param songpos a song pos.
 *
 * Queue's the deletion of a single song by it's position.
 *
 * @returns a #MpdError
 */
int  	mpd_playlist_queue_delete_pos	(MpdObj *mi,int songpos);


/**
 * @param mi a #MpdObj
 * 
 * Commits the queue'd commands in a command list. This is an efficient way of doing alot of add's/removes.
 *
 * @returns a #MpdError
 */
int	mpd_playlist_queue_commit		(MpdObj *mi);

/*@}*/


#endif
