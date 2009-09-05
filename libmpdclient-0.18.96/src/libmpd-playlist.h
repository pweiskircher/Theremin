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
 * @param start a Songpos
 * @param stop  a Songpos
 *
 * returns the MpdData list with song from the playlist from pos start until stop.
 * so start = 0, stop = 5 will return song 0,1,2,3,4,5.
 *
 * @returns a MdpData 
 */
MpdData * mpd_playlist_get_song_from_pos_range(MpdObj *mi, int start, int stop);


/**
 * @param mi a #MpdObj
 *
 * returns the mpd_Song for the currently playing song
 *
 * @returns a mpd_Song, this is an internally cached version, and should not be freed. It's also not guaranteed to stay valid (it will be inside the same function if no other mpd_* function gets called.)
 * if you need to keep it around, make a copy.
 */
mpd_Song *	mpd_playlist_get_current_song		(MpdObj *mi);


/**
 * mpd_playlist_clear
 * @param mi a #MpdObj
 *
 * Clears the playlist
 *
 * @returns 0 on success or #MpdError on error.
 */
int		mpd_playlist_clear			(MpdObj *mi);


/**
 * @param mi a #MpdObj
 *
 * Shuffles the order of the playlist, this is different than playing random
 *
 * @returns 0 on success or #MpdError on error.
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
 * @param old_playlist_id The id of the old playlist you want to get the changes with.
 *
 * Gets a list of songs that changed between the current and the old playlist
 *
 * @returns a #MpdData list
 */
MpdData *	mpd_playlist_get_changes		(MpdObj *mi,int old_playlist_id);

/**
 * @param mi a #MpdObj
 * @param old_playlist_id The id of the old playlist you want to get the changes with.
 *
 * Gets a list of the song id/pos that changed between the current and the old playlist
 * Check if this command is available.
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
 * Adds a song to the playlist, use #mpd_playlist_queue_add to add multiple songs.
 *
 * @returns a #MpdError
 */
int		mpd_playlist_add			(MpdObj *mi,const char *path);

/**
 * @param mi a #MpdObj
 * @param songid a song id.
 *
 * Deletes a single song by it's id.
 *
 * @returns a #MpdError
 */
int mpd_playlist_delete_id(MpdObj *mi, int songid);

/**
 * @param mi a #MpdObj
 * @param songpos a song pos.
 *
 * Deletes a single song by it's position.
 *
 * @returns a #MpdError
 */
int mpd_playlist_delete_pos(MpdObj *mi, int songpos);	

/** 
 * @param mi a #MpdObj
 * @param path a path to a song
 *
 * Add a single path and return the id
 * Only use this to add a single song, if you need to add multiple songs,
 * use the #mpd_playlist_queue_add for improved performance
 *
 * @returns a #MpdError or the songid of the added song
 */

int mpd_playlist_add_get_id(MpdObj *mi,const char *path);

/*@}*/


/** \defgroup comqueue Command Queue 
 * \ingroup Playlist
 * These functions allow you to queue commands, and send them 
 * in one command list to mpd. This is very efficient.
 * It's advised to use these for large deletions and additions.
 * These functions don't cause an extra overhead compared to the non_queue functions.
 * Because the non_queue functions just wrap the following.
 */
/*@{*/

/**
 * @param mi a #MpdObj
 * @param path The path to a song to add
 *
 * This queues an add command. The actual add isn't done until #mpd_playlist_queue_commit is called
 *
 * @returns a #MpdError
 */
int	mpd_playlist_queue_add		(MpdObj *mi,const char *path);



/**
 * @param mi a #MpdObj
 * @param path The path to a playlist to load
 *
 * This queues a load command. The actual load isn't done until #mpd_playlist_queue_commit is called
 *
 * @returns a #MpdError
 */
int	mpd_playlist_queue_load		(MpdObj *mi,const char *path);


/**
 * @param mi a #MpdObj
 * @param id The songid of the song you want to delete
 *
 * This queues a delete song from playlist command. The actually delete isn't done until #mpd_playlist_queue_commit is called
 * @returns a #MpdError
 */
int	mpd_playlist_queue_delete_id	(MpdObj *mi,int id);


/**
 * @param mi a #MpdObj
 * @param songpos a song pos.
 *
 * Queues the deletion of a single song by it's position.
 *
 * @returns a #MpdError
 */
int  	mpd_playlist_queue_delete_pos	(MpdObj *mi,int songpos);


/**
 * @param mi a #MpdObj
 * 
 * Commits the queue'd commands in a command list. This is an efficient way of doing a lot of adds/removes.
 *
 * @returns a #MpdError
 */
int	mpd_playlist_queue_commit		(MpdObj *mi);

/*@}*/

/** \defgroup playlistsearch Playlist Search 
 * \ingroup Playlist
 *	Allow server side search of the current playlist. 
 */
/*@{*/

/**
 * @param mi a #MpdObj 
 * @param exact if #TRUE only return exact matches 
 *
 * Starts a playlist search. Add constraints using #mpd_playlist_search_add_constraint
 * And execute the search with #mpd_playlist_search_commit
 *
 */
void mpd_playlist_search_start(MpdObj *mi, int exact);

/**
 * @param mi a #MpdObj
 *
 * Executes the playlist search. This needs to be started with #mpd_playlist_search_start
 *
 * @returns a #MpdData list
 */
MpdData * mpd_playlist_search_commit(MpdObj *mi);

/**
 * @param mi A #MpdObj
 * @param field A #mpd_TagItems
 * @param value a string to match the field against
 *
 * Adds a constraint to the playlist search.
 */
void mpd_playlist_search_add_constraint(MpdObj *mi, mpd_TagItems field, const char *value);

/*@}*/

/** \defgroup playlistqueue Playlist Queue 
 * \ingroup Playlist
 *	Allow control of MPD new queue system 
 */
/*@{*/


/**
 * @param mi a #MpdObj
 * @param songid the id of the song to add
 *
 * Add the song from the playlist with id songid.
 *
 * @returns a #MpdError
 */
int mpd_playlist_mpd_queue_add(MpdObj *mi, int songid);


/**
 * @param mi a #MpdObj
 * @param songpos the pos of the song to remove
 *
 * Removes the song from the queue at position songpos
 * 
 * @returns a #MpdError
 */
int mpd_playlist_mpd_queue_remove(MpdObj *mi, int songpos);

/*@}*/

int	mpd_playlist_swap_id (MpdObj *mi, int old_id, int new_id);

#endif
