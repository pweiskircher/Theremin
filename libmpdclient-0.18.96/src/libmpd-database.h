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

#ifndef __MPD_LIB_DATABASE__
#define __MPD_LIB_DATABASE__

/** \defgroup database Database
 */
/*@{*/



/**
 * @param mi A #MpdObj
 * @param artist an artist name
 *
 * Grabs a list of albums of a certain artist from mpd.
 * if artist is %NULL it grabs all albums
 *
 * @returns A #MpdData list.
 */
MpdData *	mpd_database_get_albums		(MpdObj *mi,const char *artist);


/**
 * @param mi a #MpdObj
 *
 * returns a list of all available artists.
 *
 * @returns a #MpdData list
 */
MpdData *	mpd_database_get_artists		(MpdObj *mi);


/**
 * @param mi a #MpdObj
 *
 * Gets the complete database, only returns songs
 *
 * @returns a #MpdData list with songs
 */

MpdData * mpd_database_get_complete(MpdObj *mi);


/**
 *@param mi A #MpdObj
 *@param path The path mpd should update.
 *
 * Force mpd to update (parts of) the database.
 *
 * @returns a #MpdError
 */
int 	mpd_database_update_dir		(MpdObj *mi,const char *path);


/**
 * @param mi a #MpdObj
 * @param table table
 * @param string string to search for
 * @param exact if #TRUE only return exact matches
 * WARNING: This function is deprecated, use mpd_database_search_start 
 * @returns a #MpdData list
 */
MpdData * mpd_database_find(MpdObj *mi, int table,const char *string, int exact);

/**
 * @param mi a #MpdObj
 * @param path a NULL terminated path string
 *
 * Gets the contents of a directory, it can return songs, directories and playlists
 *
 * @returns a #MpdData list with songs, directories and playlists
 */
MpdData * mpd_database_get_directory(MpdObj *mi,const char *path);

/**
 * @param mi a #MpdObj
 * @param path a string containing the  path
 *
 * Recursively list all the songs directory path
 *
 * @returns a #MpdData
 */
MpdData * mpd_database_get_directory_recursive(MpdObj *mi, const char *path);

/**
 * @param mi A #MpdObj
 * @param path an Path to a file
 *
 * Grabs the song info for a single file. Make sure you pass a url to a song
 * and not a directory, that might result in strange behaviour.
 *
 * @returns a #mpd_Song
 */
mpd_Song * mpd_database_get_fileinfo(MpdObj *mi,const char *path);

/*@}*/

/** \defgroup advsearch Database Advanced Search 
 * \ingroup database 
 * The following functions provide an interface to the improved search capabilities of mpd 0.12.0. 
 */
/*@{*/


/**
 * @param mi A #MpdObj
 * @param field A #mpd_TagItems
 * @param value a string that %field needs to match
 *
 * Adds a constraint to the search 
 */
void mpd_database_search_add_constraint(MpdObj *mi, mpd_TagItems field, const char *value);

/**
 * @param mi A #MpdObj
 * @param exact a boolean indicating if the search is fuzzy or exact
 *
 * Starts a search, you can add "constraints" by calling mpd_database_search_add_constraint
 * For Example if you want all songs by Eric Clapton you could do:
 *
 * @code
 * mpd_database_search_start(mi, TRUE);
 * mpd_database_search_add_constraint(mi, MPD_TAG_ITEM_ARTIST, "Eric Clapton");
 * data= mpd_database_search_commit(mi);
 * @endcode
 *
 * If you only want the songs from the album unplugged:
 *
 * @code
 * mpd_database_search_start(mi, TRUE);
 * mpd_database_search_add_constraint(mi, MPD_TAG_ITEM_ARTIST, "Eric Clapton");
 * mpd_database_search_add_constraint(mi, MPD_TAG_ITEM_ALBUM, "Unplugged");
 * data= mpd_database_search_commit(mi);
 * @endcode
 *
 * This function requires mpd 0.12.0 or higher 
 */

void mpd_database_search_start(MpdObj *mi, int exact);

/**
 * @param mi a #MpdObj
 * @param field a #mpd_TagItems
 *
 * Starts a field search, eg. if you want a list of all albums, you do;
 * 
 * @code 
 * mpd_database_search_field_start(mi, MPD_TAG_ITEM_ALBUM);
 * data = mpd_database_search_commit(mi);
 * @endcode
 * 
 * You can add constraints using mpd_database_search_add_constraint, for example if you want 
 * all albums by eric clapton:
 * 
 * @code
 * mpd_database_search_field_start(mi, MPD_TAG_ITEM_ALBUM);
 * mpd_database_search_add_constraint(mi, MPD_TAG_ITEM_ARTIST, "Eric Clapton");
 * data = mpd_database_search_commit(mi);
 * @endcode
 */
void mpd_database_search_field_start(MpdObj *mi, mpd_TagItems field);

/**
 * @param mi A #MpdObj
 *
 * Commits the search and gathers the result in a #MpdData list.
 *
 * @returns a #MpdData list with the search result, or NULL when nothing is found
 */
MpdData * mpd_database_search_commit(MpdObj *mi);



/*@}*/
/** \defgroup databaseSearchStats Database Search Statistics
 * \ingroup database
 * A extension to the database search, that instead of returning the full results.
 * Only reports back a few statistics about the result. 
 * For now Number of Songs are reported and total playtime.
 */
/*@{*/

/*! \var typedef mpd_SearchStat MpdDBStats 
    \brief A Structure containing numberOfSongs and playTime 
    
    see #mpd_SearchStats
*/

typedef mpd_SearchStats MpdDBStats;

/**
 * @param mi A #MpdObj
 *
 * Starts a search, you can add constraints by calling #mpd_database_search_add_constraint.
 * To get the result call #mpd_database_search_stats_commit
 * 
 * This function requires mpd 0.13.0 or higher 
 */

void mpd_database_search_stats_start(MpdObj *mi);


/**
 * @param mi A #MpdObj
 *
 * Gets statistics results of a search.
 * 
 * @returns a #MpdDBStats
 */
MpdDBStats * mpd_database_search_stats_commit(MpdObj *mi);

/**
 * @param data a #MpdDBStats
 *
 * frees the #MpdDBStats structure.
 */
void mpd_database_search_free_stats(MpdDBStats *data);

/*@}*/

/** \defgroup databasePlaylist Database Playlist
 * \ingroup database
 */
/*@{*/


/**
 * @param mi A #MpdObj
 * @param path path of the playlist
 *
 * Deletes a playlist.
 * @returns a #MpdError
 */

int mpd_database_delete_playlist(MpdObj *mi,const char *path);

/**
 * @param mi a #MpdObj
 * @param name The name of the playlist
 *
 * Saves the current playlist to a file.
 *
 * @returns a #MpdError. #MPD_OK if successful,
 * #MPD_DATABASE_PLAYLIST_EXIST when the playlist already exists.
 */ 
int		mpd_database_save_playlist			(MpdObj *mi,const char *name);

/**
 * @param mi a #MpdObj
 * @param playlist the playlist you need the content of.
 *
 * Needs mpd 0.12.0 or higher.
 *
 * @returns a #MpdData list
 */
MpdData *mpd_database_get_playlist_content(MpdObj *mi,const char *playlist);

/**
 * @param mi a #MpdObj
 * @param path a string contains the path of the playlist
 * @param file a string contains the path of the song to add
 *
 * Add a path to a stored playlist.
 * Needs 0.13.0
 */
void mpd_database_playlist_list_add(MpdObj *mi, const char *path, const char *file);

/**
 * @param mi a #MpdObj
 * @param path a string containing the path of the playlist
 * @param pos an int representing the position of a song
 *
 * Deletes the song at position pos from a playlist.
 * Needs mpd 0.13.0
 *
 */
void mpd_database_playlist_list_delete(MpdObj *mi, const char *path, int pos);

/**
 * @param mi a #MpdObj
 * @param path a string containing the path of the playlist
 *
 * Clears the content of a stored playlist, also used to create an empty playlist
 * Needs mpd 0.13.0
 */
void mpd_database_playlist_clear(MpdObj *mi,const char *path);

/**
 * @param mi a #MpdObj
 * @param old a string, old playlist name
 * @param new  a string, new playlist name
 * 
 * Renames a stored playlist
 * Needs mpd 0.13.0
 */
void mpd_database_playlist_rename(MpdObj *mi, const char *old_name, const char *new_name);

/**
 * @param mi a #MpdObj
 * @param playlist a string containing the path of the playlist
 * @param old_pos an integer representing old position
 * @param new_pos an integer representing the position to move old_pos to.
 *
 * Moves songs in a stored playlist
 * Needs mpd 0.13.0
 */
int mpd_database_playlist_move(MpdObj *mi, const char *playlist, int old_pos, int new_pos);
MpdData * mpd_database_playlist_list(MpdObj *mi);
/*@}*/
#endif
