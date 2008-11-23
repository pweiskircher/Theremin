/*
 *Copyright (C) 2004-2006 Qball Cow <Qball@qballcow.nl>
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

#include <stdio.h>
#include <stdlib.h>
#define __USE_GNU

#include <string.h>
#include <regex.h>
#include <stdarg.h>
#include <config.h>
#include "debug_printf.h"
#include "libmpd.h"
#include "libmpd-internal.h"

int mpd_database_update_dir(MpdObj *mi, char *path)
{
	if(path == NULL || !strlen(path))
	{
		debug_printf(DEBUG_ERROR, "path != NULL  and strlen(path) > 0 failed");
		return MPD_ARGS_ERROR;
	}
	if(!mpd_check_connected(mi))
	{
		debug_printf(DEBUG_WARNING,"not connected\n");
		return MPD_NOT_CONNECTED;
	}
	if(mpd_lock_conn(mi))
	{
		debug_printf(DEBUG_ERROR,"lock failed\n");
		return MPD_LOCK_FAILED;
	}

	mpd_sendUpdateCommand(mi->connection,path);
	mpd_finishCommand(mi->connection);
	/* I have no idea why do this ?? it even makes gmpc very very unhappy.
	 * Because it doesnt trigger an signal anymore when updating starts
	 * mi->CurrentState.updatingDb = mpd_getUpdateId(mi->connection);
	*/

	/* unlock */
	mpd_unlock_conn(mi);
	/* What I think you should do is to force a direct status updated
	 */
	mpd_status_update(mi);
	return MPD_OK;
}

MpdData * mpd_database_get_artists(MpdObj *mi)
{
	char *string = NULL;
	MpdData *data = NULL;
	if(!mpd_check_connected(mi))
	{
		debug_printf(DEBUG_WARNING,"not connected\n");
		return NULL;
	}
	if(mpd_lock_conn(mi))
	{
		debug_printf(DEBUG_ERROR,"lock failed\n");
		return NULL;
	}

	mpd_sendListCommand(mi->connection,MPD_TABLE_ARTIST,NULL);
	while (( string = mpd_getNextArtist(mi->connection)) != NULL)
	{
		data = mpd_new_data_struct_append(data);
		data->type = MPD_DATA_TYPE_TAG;
		data->tag_type = MPD_TAG_ITEM_ARTIST;
		data->tag = string;
	}
	mpd_finishCommand(mi->connection);

	/* unlock */
	mpd_unlock_conn(mi);
	if(data == NULL)
	{
		return NULL;
	}
	data = mpd_misc_sort_tag_list(data);
	return mpd_data_get_first(data);
}

MpdData * mpd_database_get_albums(MpdObj *mi,char *artist)
{
	char *string = NULL;
	MpdData *data = NULL;
	if(!mpd_check_connected(mi))
	{
		debug_printf(DEBUG_WARNING,"not connected\n");
		return NULL;
	}
	if(mpd_lock_conn(mi))
	{
		debug_printf(DEBUG_ERROR,"lock failed\n");
		return NULL;
	}

	mpd_sendListCommand(mi->connection,MPD_TABLE_ALBUM,artist);
	while (( string = mpd_getNextAlbum(mi->connection)) != NULL)
	{
		data = mpd_new_data_struct_append(data);
		data->type = MPD_DATA_TYPE_TAG;
		data->tag_type = MPD_TAG_ITEM_ALBUM;
		data->tag = string;
	}
	mpd_finishCommand(mi->connection);

	/* unlock */
	mpd_unlock_conn(mi);
	if(data == NULL)
	{
		return NULL;
	}
	return mpd_data_get_first(data);
}

MpdData * mpd_database_get_complete(MpdObj *mi)
{
	MpdData *data = NULL;
	mpd_InfoEntity *ent = NULL;
	if(!mpd_check_connected(mi))
	{
		debug_printf(DEBUG_WARNING,"not connected\n");
		return NULL;
	}
	if(mpd_lock_conn(mi))
	{
		debug_printf(DEBUG_ERROR,"lock failed\n");
		return NULL;
	}
	mpd_sendListallInfoCommand(mi->connection, "/");
	while (( ent = mpd_getNextInfoEntity(mi->connection)) != NULL)
	{

		if (ent->type == MPD_INFO_ENTITY_TYPE_SONG)
		{
			data = mpd_new_data_struct_append(data);
			data->type = MPD_DATA_TYPE_SONG;
			data->song = ent->info.song;
			ent->info.song = NULL;
		}
		mpd_freeInfoEntity(ent);
	}
	mpd_finishCommand(mi->connection);

	/* unlock */
	mpd_unlock_conn(mi);
	if(data == NULL)
	{
		return NULL;
	}
	return mpd_data_get_first(data);
}

MpdData *mpd_database_token_find(MpdObj *mi , char *string)
{
	MpdData *data = NULL;
	mpd_InfoEntity *ent = NULL;
	regex_t ** strdata = NULL;
	if(!mpd_check_connected(mi))
	{
		debug_printf(DEBUG_WARNING,"not connected\n");
		return NULL;
	}
	if(mpd_lock_conn(mi))
	{
		debug_printf(DEBUG_ERROR,"lock failed\n");
		return NULL;
	}

	if(string == NULL || !strlen(string) )
	{
		debug_printf(DEBUG_INFO, "no string found");
		mpd_unlock_conn(mi);
		return NULL;
	}
	else{
		strdata = mpd_misc_tokenize(string);
	}
	if(strdata == NULL)
	{
		mpd_unlock_conn(mi);
		debug_printf(DEBUG_INFO, "no split string found");
		return NULL;
	}

	mpd_sendListallInfoCommand(mi->connection, "/");
	while (( ent = mpd_getNextInfoEntity(mi->connection)) != NULL)
	{
		if (ent->type == MPD_INFO_ENTITY_TYPE_SONG)
		{
			int i = 0;
			int match = 0;
			int loop = 1;
			for(i=0; strdata[i] != NULL && loop; i++)
			{
				match = 0;
				if(ent->info.song->file && !regexec(strdata[i],ent->info.song->file, 0, NULL, 0))
				{
					match = 1;
				}
				else if(ent->info.song->artist && !regexec(strdata[i],ent->info.song->artist, 0, NULL, 0))
				{
					match = 1;
				}
				else if(ent->info.song->title && !regexec(strdata[i],ent->info.song->title, 0, NULL, 0)) 
				{
					match = 1;
				}
				else if(ent->info.song->album && !regexec(strdata[i],ent->info.song->album, 0, NULL, 0))
				{
					match = 1;
				}
				if(!match)
				{
					loop = 0;
				}
			}

			if(match)
			{
				data = mpd_new_data_struct_append(data);
				data->type = MPD_DATA_TYPE_SONG;
				/*
				data->song = mpd_songDup(ent->info.song);
				*/
				data->song = ent->info.song;
				ent->info.song = NULL;
			}
		}
		mpd_freeInfoEntity(ent);
	}
	mpd_finishCommand(mi->connection);
	mpd_misc_tokens_free(strdata);




	mpd_unlock_conn(mi);
	if(data == NULL)
	{
		return NULL;
	}
	return mpd_data_get_first(data);
}

int mpd_database_delete_playlist(MpdObj *mi, const char *path)
{
	if(path == NULL)
	{
		debug_printf(DEBUG_WARNING, "path == NULL");
		return MPD_ARGS_ERROR;
	}
	if(!mpd_check_connected(mi))
	{
		debug_printf(DEBUG_WARNING,"not connected\n");
		return MPD_NOT_CONNECTED;
	}
	if(mpd_lock_conn(mi))
	{
		debug_printf(DEBUG_ERROR,"lock failed\n");
		return MPD_LOCK_FAILED;
	}

	mpd_sendRmCommand(mi->connection,path);
	mpd_finishCommand(mi->connection);

	/* unlock */
	mpd_unlock_conn(mi);
	return MPD_OK;
}

int mpd_database_save_playlist(MpdObj *mi, const char *name)
{
	if(name == NULL || !strlen(name))
	{
		debug_printf(DEBUG_WARNING, "mpd_playlist_save: name != NULL  and strlen(name) > 0 failed");
		return MPD_ARGS_ERROR;
	}
	if(!mpd_check_connected(mi))
	{
		debug_printf(DEBUG_WARNING,"mpd_playlist_save: not connected\n");
		return MPD_NOT_CONNECTED;
	}
	if(mpd_lock_conn(mi))
	{
		debug_printf(DEBUG_ERROR,"mpd_playlist_save: lock failed\n");
		return MPD_LOCK_FAILED;
	}

	mpd_sendSaveCommand(mi->connection,name);
	mpd_finishCommand(mi->connection);
	if(mi->connection->error == MPD_ERROR_ACK && mi->connection->errorCode == MPD_ACK_ERROR_EXIST)
	{
		mpd_clearError(mi->connection);
		mpd_unlock_conn(mi);
		return MPD_DATABASE_PLAYLIST_EXIST;

	}
	/* unlock */
	mpd_unlock_conn(mi);
	return MPD_OK;
}

/* "hack" to keep the compiler happy */
typedef int (* QsortCompare)(const void *a, const void *b);

static int compa(char **a, char **b)
{
	char *c =*a;
	char *d =*b;
#ifndef NO_SMART_SORT
	if(!strncasecmp(c, "The ",4) && strlen(c) > 4)
	{
		c = &c[4];
	}
	if(!strncasecmp(d, "The ",4) && strlen(d) > 4)
	{
		d = &d[4];
	}
#endif

	return strcasecmp(c,d);
}

MpdData *mpd_misc_sort_tag_list(MpdData *data)
{
	char **array;
	MpdData *test;
	int i=0;
	int length=0;
	test = data = mpd_data_get_first(data);

	do{
		length++;
		test = mpd_data_get_next_real(test, FALSE);
	}while(test != NULL);
	array = malloc(length*sizeof(char*));
	test = data;

	do
	{
		array[i] = test->tag;
		test = mpd_data_get_next_real(test, FALSE);
		i++;
	}while(test != NULL);

	qsort(array,length,sizeof(char *),(QsortCompare)compa);

	/* reset list */
	test = mpd_data_get_first(data);
	i=0;
	do
	{
		test->tag = array[i];
		test = mpd_data_get_next_real(test, FALSE);
		i++;
	}while(test != NULL);
	free(array);
	return mpd_data_get_first(data);
}


/* TODO need a rewrite */
/* Should be named: mpd_database_find_adv */
MpdData *mpd_database_find_adv(MpdObj *mi,int exact, ...)
{
	int table = 0;
	MpdData *data = NULL;
	mpd_InfoEntity *ent = NULL;
	va_list arglist;
	if(!mpd_check_connected(mi))
	{
		debug_printf(DEBUG_WARNING,"not connected\n");
		return NULL;
	}
	if(!mpd_server_check_version(mi, 0,12,0))
	{
		debug_printf(DEBUG_WARNING, "only works with mpd higher then 0.12.0");
		return NULL;
	}
	if(mpd_lock_conn(mi))
	{
		debug_printf(DEBUG_WARNING,"lock failed\n");
		return NULL;
	}
	va_start(arglist, exact);
	mpd_startSearch(mi->connection, exact);
	while((table = va_arg(arglist, int)) != -1)
	{
		if(table >= 0 && table < MPD_TAG_NUM_OF_ITEM_TYPES)
		{
			char *str = va_arg(arglist,char *);
			mpd_addConstraintSearch(mi->connection, table, str);
		}	
	}
	mpd_commitSearch(mi->connection);
	va_end(arglist);
	while (( ent = mpd_getNextInfoEntity(mi->connection)) != NULL)
	{
		data = mpd_new_data_struct_append( data );
		if(ent->type == MPD_INFO_ENTITY_TYPE_DIRECTORY)
		{
			data->type = MPD_DATA_TYPE_DIRECTORY;
			data->directory = ent->info.directory->path;
			ent->info.directory->path = NULL;
		}
		else if (ent->type == MPD_INFO_ENTITY_TYPE_SONG)
		{
			data->type = MPD_DATA_TYPE_SONG;
			data->song = ent->info.song;
			ent->info.song = NULL;
		}
		else if (ent->type == MPD_INFO_ENTITY_TYPE_PLAYLISTFILE)
		{
			data->type = MPD_DATA_TYPE_PLAYLIST;
			data->playlist = ent->info.playlistFile->path;
			ent->info.playlistFile->path = NULL;
		}

		mpd_freeInfoEntity(ent);
	}
	mpd_finishCommand(mi->connection);

	/* unlock */
	mpd_unlock_conn(mi);
	if(data == NULL)
	{
		return NULL;
	}
	return mpd_data_get_first(data);
}

/* should be called mpd_database_find */
MpdData * mpd_database_find(MpdObj *mi, int table, char *string, int exact)
{
	MpdData *data = NULL;
/*	MpdData *artist = NULL;
	MpdData *album = NULL;
*/	mpd_InfoEntity *ent = NULL;
	if(!mpd_check_connected(mi))
	{
		debug_printf(DEBUG_WARNING,"not connected\n");
		return NULL;
	}
	if(mpd_lock_conn(mi))
	{
		debug_printf(DEBUG_WARNING,"lock failed\n");
		return NULL;
	}
	if(exact)
	{
		mpd_sendFindCommand(mi->connection,table,string);
	}
	else
	{
		mpd_sendSearchCommand(mi->connection, table,string);
	}
	while (( ent = mpd_getNextInfoEntity(mi->connection)) != NULL)
	{
		data = mpd_new_data_struct_append(data);
		/* mpd_sendSearch|Find only returns songs */
		/*
		if(ent->type == MPD_INFO_ENTITY_TYPE_DIRECTORY)
		{
			data->type = MPD_DATA_TYPE_DIRECTORY;
			data->directory = ent->info.directory->path;
			ent->info.directory->path = NULL;
		}
		else*/ if (ent->type == MPD_INFO_ENTITY_TYPE_SONG)
		{
			data->type = MPD_DATA_TYPE_SONG;
			data->song = ent->info.song;
			ent->info.song = NULL;
			/* This is something the client can and should do */
/*			if(data->song->artist != NULL)
			{
				int found = FALSE;
				if(artist != NULL)
				{
					MpdData *fartist = mpd_data_get_first(artist);
					do{
						if( (fartist->type == MPD_DATA_TYPE_TAG) && (fartist->tag_type == MPD_TAG_ITEM_ARTIST))
						{
							if(fartist->tag == NULL)
							{
								printf("crap this should'nt be \n");
							}
							if(!strcmp(fartist->tag, data->song->artist))
							{
								found = TRUE;
							}
						}
						fartist = mpd_data_get_next_real(fartist, FALSE);
					}while(fartist && !found);
				}
				if(!found)
				{
					artist= mpd_new_data_struct_append(artist);
					artist->type = MPD_DATA_TYPE_TAG;
					artist->tag_type = MPD_TAG_ITEM_ARTIST;
					artist->tag = strdup(data->song->artist);
				}
			}
			if(data->song->album != NULL)
			{
				int found = FALSE;
				if(album != NULL)
				{
					MpdData *falbum = mpd_data_get_first(album);
					do{
						if( (falbum->type == MPD_DATA_TYPE_TAG) && (falbum->tag_type == MPD_TAG_ITEM_ALBUM))
						{
							if(falbum->tag == NULL)
							{
								printf("crap this should'nt be \n");
							}
							if(!strcmp(falbum->tag, data->song->album))
							{
								found = TRUE;
							}
						}
						falbum = mpd_data_get_next_real(falbum, FALSE);
					}while(falbum && !found);
				}
				if(!found)
				{
					album = mpd_new_data_struct_append(album);
					album->type = MPD_DATA_TYPE_TAG;
					album->tag_type = MPD_TAG_ITEM_ALBUM;
					album->tag = strdup(data->song->album);
				}
			}
*/
		}
		/*
		else if (ent->type == MPD_INFO_ENTITY_TYPE_PLAYLISTFILE)
		{
			data->type = MPD_DATA_TYPE_PLAYLIST;
			data->playlist = ent->info.playlistFile->path;
			ent->info.playlistFile->path = NULL;
		}
		*/

		mpd_freeInfoEntity(ent);
	}
	mpd_finishCommand(mi->connection);

	/* unlock */
	mpd_unlock_conn(mi);
	if(data == NULL)
	{
		return NULL;
	}
	data = mpd_data_get_first(data);
	/* prepend the album then artists*/
/*	if(album != NULL)
	{
		if(data){
			data  = mpd_data_concatenate( album, data);
		}else{
			data = album;
		}
	}
	if(artist != NULL)
	{
		if(data) {
			album = mpd_data_concatenate( artist, data );
		}else{
			data = artist;
		}
	}                                                     	
*/
	return mpd_data_get_first(data);
}

MpdData * mpd_database_get_unique_tags(MpdObj *mi, int field,...)
{
	int table = 0;
	char *string = NULL;
	MpdData *data = NULL;
	va_list arglist;
	if(!mpd_check_connected(mi))
	{
		debug_printf(DEBUG_WARNING,"mpd_playlist_get_artists: not connected\n");
		return NULL;
	}

	if(!mpd_server_check_version(mi,0,12,0))
	{

		debug_printf(DEBUG_WARNING, "mpd_playlist_get_unique_tag:For this feature you need at least mpd version 0.12.0");
		return NULL;
	}
	if(table < 0 || table >= MPD_TAG_NUM_OF_ITEM_TYPES)
	{
		debug_printf(DEBUG_ERROR, "mpd_playlist_get_unique_tag: Undefined table defined");
		return NULL;
	}
	if(mpd_lock_conn(mi))
	{
		debug_printf(DEBUG_WARNING,"mpd_playlist_get_artists: lock failed\n");
		return NULL;
	}
	mpd_startFieldSearch(mi->connection,field);
	va_start(arglist, field);
	while((table = va_arg(arglist, int)) != -1)
	{
		if(table >= 0 && table < MPD_TAG_NUM_OF_ITEM_TYPES)         	
		{
			char *str = va_arg(arglist,char *);
			mpd_addConstraintSearch(mi->connection, table, str);
		}	                                                   	
	}
	va_end(arglist);
	mpd_commitSearch(mi->connection);
	/* TODO check for errors */
	//	mpd_sendVListTagCommand(mi->connection,table,arglist);

	while (( string = mpd_getNextTag(mi->connection,field)) != NULL)
	{
		data = mpd_new_data_struct_append(data);
		data->type = MPD_DATA_TYPE_TAG;
		data->tag = string;
	}
	/* we need todo this here? can't hurt */
	mpd_finishCommand(mi->connection);
	
	/* unlock */
	mpd_unlock_conn(mi);
	if(data == NULL)
	{
		return NULL;
	}
	data = mpd_misc_sort_tag_list(data);
	return mpd_data_get_first(data);
}


MpdData * mpd_database_get_directory(MpdObj *mi,char *path)
{
	MpdData *data = NULL;
	mpd_InfoEntity *ent = NULL;
	if(!mpd_check_connected(mi))
	{
		debug_printf(DEBUG_WARNING,"not connected\n");
		return NULL;
	}
	if(path == NULL)
	{
		path = "/";
	}
	if(mpd_lock_conn(mi))
	{
		debug_printf(DEBUG_WARNING,"lock failed\n");
		return NULL;
	}

	mpd_sendLsInfoCommand(mi->connection,path);
	while (( ent = mpd_getNextInfoEntity(mi->connection)) != NULL)
	{
		data = mpd_new_data_struct_append(data);
		if(ent->type == MPD_INFO_ENTITY_TYPE_DIRECTORY)
		{
			data->type = MPD_DATA_TYPE_DIRECTORY;
			data->directory = ent->info.directory->path;
			ent->info.directory->path = NULL;
		}
		else if (ent->type == MPD_INFO_ENTITY_TYPE_SONG)
		{
			data->type = MPD_DATA_TYPE_SONG;
			data->song = ent->info.song;
			ent->info.song = NULL;
		}
		else if (ent->type == MPD_INFO_ENTITY_TYPE_PLAYLISTFILE)
		{
			data->type = MPD_DATA_TYPE_PLAYLIST;
			data->playlist = ent->info.playlistFile->path;
			ent->info.playlistFile->path = NULL;
		}

		mpd_freeInfoEntity(ent);
	}
	mpd_finishCommand(mi->connection);

	/* unlock */
	mpd_unlock_conn(mi);
	if(data == NULL)
	{
		return NULL;
	}
	return mpd_data_get_first(data);
}

MpdData *mpd_database_get_playlist_content(MpdObj *mi,char *playlist)
{
	MpdData *data = NULL;
	mpd_InfoEntity *ent = NULL;
	if(!mpd_check_connected(mi))
	{
		debug_printf(DEBUG_WARNING,"not connected\n");
		return NULL;
	}
	if(!mpd_server_check_version(mi, 0,12,0))
	{
		debug_printf(DEBUG_WARNING, "only works with mpd higher then 0.12.0");
		return NULL;
	}
	if(mpd_server_check_command_allowed(mi, "listplaylistinfo") != MPD_SERVER_COMMAND_ALLOWED)
	{
		debug_printf(DEBUG_WARNING, "Listing playlist content not supported or allowed");
		return NULL;
	}
	if(mpd_lock_conn(mi))
	{
		debug_printf(DEBUG_WARNING,"lock failed\n");
		return NULL;
	}
	mpd_sendListPlaylistInfoCommand(mi->connection, playlist);
	while (( ent = mpd_getNextInfoEntity(mi->connection)) != NULL)
	{
		data = mpd_new_data_struct_append( data );
		if(ent->type == MPD_INFO_ENTITY_TYPE_DIRECTORY)
		{
			data->type = MPD_DATA_TYPE_DIRECTORY;
			data->directory = ent->info.directory->path;
			ent->info.directory->path = NULL;
		}
		else if (ent->type == MPD_INFO_ENTITY_TYPE_SONG)
		{
			data->type = MPD_DATA_TYPE_SONG;
			data->song = ent->info.song;
			ent->info.song = NULL;
		}
		else if (ent->type == MPD_INFO_ENTITY_TYPE_PLAYLISTFILE)
		{
			data->type = MPD_DATA_TYPE_PLAYLIST;
			data->playlist = ent->info.playlistFile->path;
			ent->info.playlistFile->path = NULL;
		}

		mpd_freeInfoEntity(ent);
	}
	mpd_finishCommand(mi->connection);

	/* unlock */
	mpd_unlock_conn(mi);
	if(data == NULL)
	{
		return NULL;
	}
	return mpd_data_get_first(data);
}
/**
 * @param mi A #MpdObj
 * @param path an Path to a file
 *
 * Grabs the song info for a single file. Make sure you pass an url to a song
 * and not a directory, that might result in strange behauviour.
 *
 * @returns a #mpd_Song
 */
mpd_Song * mpd_database_get_fileinfo(MpdObj *mi,const char *path)
{
	mpd_Song *song = NULL;
	mpd_InfoEntity *ent = NULL;
	/*
	 * Check path for availibility and length
	 */
	if(path == NULL || path[0] == '\0')
	{
		debug_printf(DEBUG_ERROR, "path == NULL || strlen(path) == 0");
		return NULL;
	}
	if(!mpd_check_connected(mi))
	{
		debug_printf(DEBUG_ERROR, "Not Connected\n");
		return NULL;
	}
	/* lock, so we can work on mi->connection */
	if(mpd_lock_conn(mi) != MPD_OK)
	{
		debug_printf(DEBUG_ERROR, "Failed to lock connection");
		return NULL;
	}
	/* send the request */
	mpd_sendListallInfoCommand(mi->connection, path);
	/* get the first (and only) result */
	ent = mpd_getNextInfoEntity(mi->connection);
	/* finish and clean up libmpdclient */
	mpd_finishCommand(mi->connection);
	/* unlock again */
	if(mpd_unlock_conn(mi))
	{
		if(ent) mpd_freeInfoEntity(ent);
		debug_printf(DEBUG_ERROR, "Failed to unlock");
		return NULL;
	}

	if(ent == NULL)
	{
		debug_printf(DEBUG_ERROR, "Failed to grab song from mpd\n");
		return NULL;
	}

	if(ent->type != MPD_INFO_ENTITY_TYPE_SONG)
	{
		mpd_freeInfoEntity(ent);
		debug_printf(DEBUG_ERROR, "Failed to grab correct song type from mpd, path might not be a file\n");
		return NULL;
	}
	/* get the song */
	song = ent->info.song;
	/* remove reference to song from the entity */
	ent->info.song = NULL;
	/* free the entity */
	mpd_freeInfoEntity(ent);

	return song;
}


void mpd_database_search_field_start(MpdObj *mi, mpd_TagItems field)
{
	/*
	 * Check argument
	 */
	if(mi == NULL || field >= MPD_TAG_NUM_OF_ITEM_TYPES || field < 0) 
	{
		debug_printf(DEBUG_ERROR, "Argument error");
		return ;
	}
	if(!mpd_check_connected(mi))
	{
		debug_printf(DEBUG_ERROR, "Not Connected\n");
		return ;
	}
	if(!mpd_server_check_version(mi, 0,12,0))
	{
		debug_printf(DEBUG_ERROR, "Advanced field list requires mpd 0.12.0 or higher");
		return ;
	}
	/* lock, so we can work on mi->connection */
	if(mpd_lock_conn(mi) != MPD_OK)
	{
		debug_printf(DEBUG_ERROR, "Failed to lock connection");
		return ;
	}
	mpd_startFieldSearch(mi->connection, field);
	/* Set search type */
	mi->search_type = MPD_SEARCH_TYPE_LIST;
	mi->search_field = field;
	/* unlock, let the error handler handle any possible error.
	 */
	mpd_unlock_conn(mi);
	return;
}







/**
 * @param mi A #MpdObj
 * @param exact a boolean indicating if the search is fuzzy or exact
 *
 * Starts a search, you can add "constraints" by calling mpd_database_search_add_constraint
 * 
 * This function requires mpd 0.12.0 or higher 
 */

void mpd_database_search_start(MpdObj *mi, int exact)
{
	/*
	 * Check argument
	 */
	if(mi == NULL || exact > 1 || exact < 0) 
	{
		debug_printf(DEBUG_ERROR, "Argument error");
		return ;
	}
	if(!mpd_check_connected(mi))
	{
		debug_printf(DEBUG_ERROR, "Not Connected\n");
		return ;
	}
	if(!mpd_server_check_version(mi, 0,12,0))
	{
		debug_printf(DEBUG_ERROR, "Advanced search requires mpd 0.12.0 or higher");
		return ;
	}
	/* lock, so we can work on mi->connection */
	if(mpd_lock_conn(mi) != MPD_OK)
	{
		debug_printf(DEBUG_ERROR, "Failed to lock connection");
		return ;
	}
	mpd_startSearch(mi->connection, exact);
	/* Set search type */
	mi->search_type = (exact)? MPD_SEARCH_TYPE_FIND:MPD_SEARCH_TYPE_SEARCH;
	/* unlock, let the error handler handle any possible error.
	 */
	mpd_unlock_conn(mi);
	return;
}
/**
 * @param mi A #MpdObj
 * @param field A #mpd_TagItems
 *
 * Adds a constraint to the search 
 */
void mpd_database_search_add_constraint(MpdObj *mi, mpd_TagItems field, char *value)
{
	if(mi == NULL || value == NULL || value[0] == '\0')
	{
		debug_printf(DEBUG_ERROR,"Failed to parse arguments");
		return;
	}
	if(mi->search_type == MPD_SEARCH_TYPE_NONE)
	{
		debug_printf(DEBUG_ERROR, "No search to constraint");
		return;
	}
	if(!mpd_check_connected(mi))
	{
		debug_printf(DEBUG_ERROR, "Not Connected\n");
		return ;
	}
	if(!mpd_server_check_version(mi, 0,12,0))
	{
		debug_printf(DEBUG_ERROR, "Advanced search requires mpd 0.12.0 or higher");
		return ;
	}
	/* lock, so we can work on mi->connection */
	if(mpd_lock_conn(mi) != MPD_OK)
	{
		debug_printf(DEBUG_ERROR, "Failed to lock connection");
		return ;
	}
	mpd_addConstraintSearch(mi->connection, field, value);
	/* unlock, let the error handler handle any possible error.
	 */
	mpd_unlock_conn(mi);
	return;
}

MpdData * mpd_database_search_commit(MpdObj *mi)
{
	mpd_InfoEntity *ent = NULL;
	MpdData *data = NULL;
	if(!mpd_check_connected(mi))
	{
		debug_printf(DEBUG_WARNING,"not connected\n");
		return NULL;
	}
	if(mi->search_type == MPD_SEARCH_TYPE_NONE)
	{
		debug_printf(DEBUG_ERROR, "no search in progress to commit");
		return NULL;
	}
	if(mpd_lock_conn(mi))
	{
		debug_printf(DEBUG_ERROR,"lock failed\n");
		return NULL;
	}
	mpd_commitSearch(mi->connection);
	if(mi->search_type == MPD_SEARCH_TYPE_LIST)
	{
		char *string = NULL;
		while((string = mpd_getNextTag(mi->connection, mi->search_field)))
		{
			data = mpd_new_data_struct_append(data);
			data->type = MPD_DATA_TYPE_TAG;
			data->tag_type = mi->search_field;
			data->tag = string;
		}
	}
	else
	{
		while (( ent = mpd_getNextInfoEntity(mi->connection)) != NULL)
		{
			if(ent->type == MPD_INFO_ENTITY_TYPE_SONG)
			{
				data = mpd_new_data_struct_append(data);
				data->type = MPD_DATA_TYPE_SONG;
				data->song = ent->info.song;
				ent->info.song = NULL;
			}
			mpd_freeInfoEntity(ent);
		}
	}
	mpd_finishCommand(mi->connection);
	/*
	 * reset search type
	 */
	mi->search_type = MPD_SEARCH_TYPE_NONE;
	mi->search_field = MPD_TAG_ITEM_ARTIST;
	/* unlock */
	if(mpd_unlock_conn(mi))
	{
		debug_printf(DEBUG_ERROR, "Failed to unlock connection");
		if(data)mpd_data_free(data);
		return NULL;
	}
	if(data == NULL)
	{
		return NULL;
	}
	return mpd_data_get_first(data);
}
