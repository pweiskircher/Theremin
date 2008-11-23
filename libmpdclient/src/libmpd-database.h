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

#ifndef __MPD_LIB_DATABASE__
#define __MPD_LIB_DATABASE__

/** \defgroup database Database
 */
/*@{*/



/**
 * @param mi A #MpdObj
 * @param artist an artist name
 *
 * Grab's a list of albums of a certain artist from mpd.
 * if artist is %NULL it grabs all albums
 *
 * @returns A #MpdData list.
 */
MpdData *	mpd_database_get_albums		(MpdObj *mi, char *artist);


/**
 * @param mi a #MpdObj
 *
 * returns a list of all availible artists.
 *
 * @returns a #MpdData list
 */
MpdData *	mpd_database_get_artists		(MpdObj *mi);


/**
 * @param mi a #MpdObj
 *
 * Get's the complete datababse, only returns songs
 *
 * @returns a #MpdData list with songs
 */

MpdData * mpd_database_get_complete(MpdObj *mi);


/**
 *@param mi A #MpdObj
 *@param path The path mpd should update.
 *
 * Force mpd to update (parts of )the database.
 *
 * @returns a #MpdError
 */
int 	mpd_database_update_dir		(MpdObj *mi, char *path);



/**
 * @param mi A #MpdObj
 * @param string The search string
 *
 * client side search function with best "match" option..
 * It splits the search string into tokens. (on the ' ')  every token is then matched using regex.
 * It not tokenize between [()].
 *
 * So f.e. Murder Hooker|Davis  matches songs where title/filename/artist/album contains murder and hooker or murder and davis in any order.
 *
 * Warning: This function can be slow.
 *
 * @returns a #MpdData list
 */
MpdData *	mpd_database_token_find		(MpdObj *mi , char *string);



/**
 * @param mi A #MpdObj
 * @param path path of the playlist
 *
 * Deletes a playlist.
 * @returns
 */

int mpd_database_delete_playlist(MpdObj *mi, const char *path);



/**
 * @param mi a #MpdObj
 * @param name The name of the playlist
 *
 * Saves the current playlist to a file.
 *
 * @returns a #MpdError. #MPD_OK if succesfull,
 * #MPD_DATABASE_PLAYLIST_EXIST when the playlist allready exists.
 */ 
int		mpd_database_save_playlist			(MpdObj *mi, const char *name);

/**
 * @param mi a #MpdObj
 * @param table table
 * @param string string to search for
 * @param exact if #TRUE only return exact matches
 * WARNING: This function is deprecated, use mpd_database_search_start 
 * @returns a #MpdData list
 */
MpdData * mpd_database_find(MpdObj *mi, int table, char *string, int exact);

/**
 * @param mi a #MpdObj
 * @param path a NULL terminated path string
 *
 * Gets the contents of a directory, it can return songs, directories and playlists
 *
 * @returns a #MpdData list with songs, directories and playlists
 */
MpdData * mpd_database_get_directory(MpdObj *mi,char *path);


/**
 * @param mi a #MpdObj
 * @param playlist the playlist you need the content off.
 *
 * Only works with patched mpd.
 * Check for %mpd_server_command_allowed(mi, "listPlaylistInfo");
 *
 * @returns a #MpdData list
 */
MpdData *mpd_database_get_playlist_content(MpdObj *mi,char *playlist);

/*@}*/

/** \defgroup advsearch Database Advanced Search 
 * \ingroup database 
 * The following functions provide an interface to the improved search capabilities of mpd 0.12.0. 
 */
/*@{*/
/**
 * @param mi A #MpdObj
 * @param path an Path to a file
 *
 * Grabs the song info for a single file. Make sure you pass an url to a song
 * and not a directory, that might result in strange behauviour.
 *
 * @returns a #mpd_Song
 */
mpd_Song * mpd_database_get_fileinfo(MpdObj *mi,const char *path);

/**
 * @param mi A #MpdObj
 * @param field A #mpd_TagItems
 * @param value a string that %field needs to match
 *
 * Adds a constraint to the search 
 */
void mpd_database_search_add_constraint(MpdObj *mi, mpd_TagItems field, char *value);

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
 * Starts a field search, f.e. if you want a list of all albums, you do;
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
 * @returns a #MpdData list with the search result,or NULL when nothing is found
 */
MpdData * mpd_database_search_commit(MpdObj *mi);



/*@}*/

/** \defgroup searchdeprecated Deprecated database search functions
 * \ingroup database
 * The following functions are deprecated
 */
/*@{*/
/**
 * @param mi a #MpdObj
 * @param field The table field
 * @returns a #MpdData
 */
MpdData *	mpd_database_get_unique_tags		(MpdObj *mi, int field,...) __attribute__((deprecated));
/**
 * @param mi a #MpdObj
 * @param exact 1 for exact search 0 for fuzzy
 *
 * WARNING: This function is deprecated, use mpd_database_search_start 
 * @returns a #MpdData
 */
MpdData *	mpd_database_find_adv		(MpdObj *mi,int exact, ...) __attribute__((deprecated));
/*@}*/

#endif
