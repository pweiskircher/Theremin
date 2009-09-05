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

#include <stdio.h>
#include <stdlib.h>
#define __USE_GNU

#include <string.h>
#include <stdarg.h>
#include <config.h>
#include "debug_printf.h"
#include "libmpd.h"
#include "libmpd-internal.h"


int mpd_playlist_get_playlist_length(MpdObj *mi)
{
	if(!mpd_check_connected(mi))
	{
		debug_printf(DEBUG_WARNING,"not connected\n");
		return MPD_NOT_CONNECTED;
	}
	if(mpd_status_check(mi) != MPD_OK)
	{
		debug_printf(DEBUG_ERROR,"Failed grabbing status\n");
		return MPD_STATUS_FAILED;
	}
	return mi->status->playlistLength;
}

long long mpd_playlist_get_old_playlist_id(MpdObj *mi)
{
	return mi->OldState.playlistid;
}

long long mpd_playlist_get_playlist_id(MpdObj *mi)
{
	if(!mpd_check_connected(mi))
	{
		debug_printf(DEBUG_WARNING,"not connected\n");
		return MPD_NOT_CONNECTED;
	}
	if(mpd_status_check(mi) != MPD_OK)
	{
		debug_printf(DEBUG_WARNING,"Failed grabbing status\n");
		return MPD_STATUS_FAILED;
	}
	return mi->status->playlist;
}
int mpd_playlist_add(MpdObj *mi,const char *path)
{
	int retv = mpd_playlist_queue_add(mi, path);
	if(retv != MPD_OK) return retv;
	return mpd_playlist_queue_commit(mi);
}

int mpd_playlist_delete_id(MpdObj *mi, int songid)
{
	int retv = mpd_playlist_queue_delete_id(mi, songid);
	if(retv != MPD_OK) return retv;
	return mpd_playlist_queue_commit(mi);
}

int mpd_playlist_delete_pos(MpdObj *mi, int songpos)
{
	int retv = mpd_playlist_queue_delete_pos(mi, songpos);
	if(retv != MPD_OK) return retv;
	return mpd_playlist_queue_commit(mi);
}
/*******************************************************************************
 * PLAYLIST
 */
mpd_Song * mpd_playlist_get_song(MpdObj *mi, int songid)
{
	mpd_Song *song = NULL;
	mpd_InfoEntity *ent = NULL;
	if(songid < 0){
		debug_printf(DEBUG_ERROR, "songid < 0 Failed");
		return NULL;
	}
	if(!mpd_check_connected(mi))
	{
		debug_printf(DEBUG_ERROR, "Not Connected\n");
		return NULL;
	}

	if(mpd_lock_conn(mi))
	{
		return NULL;
	}
	debug_printf(DEBUG_INFO, "Trying to grab song with id: %i\n", songid);
	mpd_sendPlaylistIdCommand(mi->connection, songid);
	ent = mpd_getNextInfoEntity(mi->connection);
	mpd_finishCommand(mi->connection);

	if(mpd_unlock_conn(mi))
	{
		if(ent) mpd_freeInfoEntity(ent);
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
		debug_printf(DEBUG_ERROR, "Failed to grab correct song type from mpd\n");
		return NULL;
	}
	song = ent->info.song;
	ent->info.song = NULL;

	mpd_freeInfoEntity(ent);

	return song;
}

int	mpd_playlist_swap_id (MpdObj *mi, int old_id, int new_id) {
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
	
	mpd_sendSwapIdCommand(mi->connection,old_id, new_id);
	mpd_finishCommand(mi->connection);
	
	/* unlock */
	mpd_unlock_conn(mi);
	return MPD_OK;
}

mpd_Song * mpd_playlist_get_song_from_pos(MpdObj *mi, int songpos)
{
	mpd_Song *song = NULL;
	mpd_InfoEntity *ent = NULL;
	if(songpos < 0){
		debug_printf(DEBUG_ERROR, "songpos < 0 Failed");
		return NULL;
	}
	if(!mpd_check_connected(mi))
	{
		debug_printf(DEBUG_ERROR, "Not Connected\n");
		return NULL;
	}

	if(mpd_lock_conn(mi))
	{
		return NULL;
	}
	debug_printf(DEBUG_INFO, "Trying to grab song with id: %i\n", songpos);
	mpd_sendPlaylistInfoCommand(mi->connection, songpos);
	ent = mpd_getNextInfoEntity(mi->connection);
	mpd_finishCommand(mi->connection);

	if(mpd_unlock_conn(mi))
	{
		/*TODO free entity. for now this can never happen */
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
		debug_printf(DEBUG_ERROR, "Failed to grab corect song type from mpd\n");
		return NULL;
	}
	song = ent->info.song;
	ent->info.song = NULL;

	mpd_freeInfoEntity(ent);

	return song;
}

MpdData * mpd_playlist_get_song_from_pos_range(MpdObj *mi, int start, int stop)
{
    MpdData *data = NULL;
    int i;
	mpd_InfoEntity *ent = NULL;
	if(!mpd_check_connected(mi))
	{
		debug_printf(DEBUG_ERROR, "Not Connected\n");
		return NULL;
	}
	if(mpd_status_check(mi) != MPD_OK)
	{
		debug_printf(DEBUG_ERROR,"Failed grabbing status\n");
		return NULL;
	}

	if(mpd_lock_conn(mi))
	{
		return NULL;
	}
    /* Don't check outside playlist length */
    if(!(stop < mi->status->playlistLength)) {
        stop = mi->status->playlistLength -1;
    }
    mpd_sendCommandListBegin(mi->connection);
    for(i=start; i <= stop; i++){
        mpd_sendPlaylistInfoCommand(mi->connection, i);
    }
	mpd_sendCommandListEnd(mi->connection);
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
	mpd_finishCommand(mi->connection);

	if(mpd_unlock_conn(mi))
	{
		/*TODO free entity. for now this can never happen */
		return NULL;
	}
    return data;
}

mpd_Song * mpd_playlist_get_current_song(MpdObj *mi)
{
	if(!mpd_check_connected(mi))
	{
		debug_printf(DEBUG_WARNING, "Not Connected\n");
		return NULL;
	}

	if(mpd_status_check(mi) != MPD_OK)
	{
		debug_printf(DEBUG_ERROR, "Failed to check status\n");
		return NULL;
	}

	if(mi->CurrentSong != NULL && mi->CurrentSong->id != mi->status->songid)
	{
		debug_printf(DEBUG_WARNING, "Current song not up2date, updating\n");
		mpd_freeSong(mi->CurrentSong);
		mi->CurrentSong = NULL;
	}
	/* only update song when playing/pasing */
	if(mi->CurrentSong == NULL && 
			(mpd_player_get_state(mi) != MPD_PLAYER_STOP && mpd_player_get_state(mi) != MPD_PLAYER_UNKNOWN))
	{
		/* TODO: this to use the geT_current_song_id function */
		mi->CurrentSong = mpd_playlist_get_song(mi, mpd_player_get_current_song_id(mi));
		if(mi->CurrentSong == NULL)
		{
			debug_printf(DEBUG_ERROR, "Failed to grab song\n");
			return NULL;
		}
	}
	return mi->CurrentSong;
}

int mpd_playlist_clear(MpdObj *mi)
{
	if(!mpd_check_connected(mi))
	{
		debug_printf(DEBUG_WARNING,"not connected\n");
		return MPD_NOT_CONNECTED;
	}
	if(mpd_lock_conn(mi))
	{
		debug_printf(DEBUG_WARNING,"lock failed\n");
		return MPD_LOCK_FAILED;
	}

	mpd_sendClearCommand(mi->connection);
	mpd_finishCommand(mi->connection);
	/* hack to make it update correctly when replacing 1 song */
	mi->CurrentState.songid = -1;
	/* unlock */
	mpd_unlock_conn(mi);
	mpd_status_update(mi);
	return FALSE;
}

int mpd_playlist_shuffle(MpdObj *mi)
{
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

	mpd_sendShuffleCommand(mi->connection);
	mpd_finishCommand(mi->connection);

	/* unlock */
	mpd_unlock_conn(mi);
	return FALSE;

}


int mpd_playlist_move_id(MpdObj *mi, int old_id, int new_id)
{
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

	mpd_sendMoveIdCommand(mi->connection,old_id, new_id);
	mpd_finishCommand(mi->connection);

	/* unlock */
	mpd_unlock_conn(mi);
	return MPD_OK;
}

int mpd_playlist_move_pos(MpdObj *mi, int old_pos, int new_pos)
{
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

	mpd_sendMoveCommand(mi->connection,old_pos, new_pos);
	mpd_finishCommand(mi->connection);

	/* unlock */
	mpd_unlock_conn(mi);
	return MPD_OK;
}

MpdData * mpd_playlist_get_changes(MpdObj *mi,int old_playlist_id)
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
		debug_printf(DEBUG_WARNING,"lock failed\n");
		return NULL;
	}

	if(old_playlist_id == -1)
	{
		debug_printf(DEBUG_INFO,"get fresh playlist\n");
		mpd_sendPlChangesCommand (mi->connection, 0);
/*		mpd_sendPlaylistIdCommand(mi->connection, -1); */
	}
	else
	{
		mpd_sendPlChangesCommand (mi->connection, old_playlist_id);
	}

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
	mpd_finishCommand(mi->connection);

	/* unlock */
	if(mpd_unlock_conn(mi))
	{
		debug_printf(DEBUG_WARNING,"mpd_playlist_get_changes: unlock failed.\n");
		mpd_data_free(data);
		return NULL;
	}
	if(data == NULL)
	{
		return NULL;
	}
	return mpd_data_get_first(data);
}



MpdData * mpd_playlist_get_changes_posid(MpdObj *mi,int old_playlist_id)
{
	MpdData *data = NULL;
	mpd_InfoEntity *ent = NULL;
	debug_printf(DEBUG_INFO, "Fetching using new plchangesposid command");
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

	if(old_playlist_id == -1)
	{
		debug_printf(DEBUG_INFO,"get fresh playlist\n");
		mpd_sendPlChangesPosIdCommand (mi->connection, 0);
/*		mpd_sendPlaylistIdCommand(mi->connection, -1); */
	}
	else
	{
		mpd_sendPlChangesPosIdCommand (mi->connection, old_playlist_id);
	}

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
	mpd_finishCommand(mi->connection);

	/* unlock */
	if(mpd_unlock_conn(mi))
	{
		debug_printf(DEBUG_WARNING,"mpd_playlist_get_changes: unlock failed.\n");
		mpd_data_free(data);
		return NULL;
	}
	if(data == NULL)
	{
		return NULL;
	}
	return mpd_data_get_first(data);
}

int mpd_playlist_queue_add(MpdObj *mi,const char *path)
{
	if(!mpd_check_connected(mi))
	{
		debug_printf(DEBUG_WARNING,"not connected\n");
		return MPD_NOT_CONNECTED;
	}
	if(path == NULL)
	{
		debug_printf(DEBUG_ERROR, "path != NULL Failed");
		return MPD_ARGS_ERROR;
	}

	if(mi->queue == NULL)
	{
		mi->queue = mpd_new_queue_struct();
		mi->queue->first = mi->queue;
		mi->queue->next = NULL;
		mi->queue->prev = NULL;
	}
	else
	{
		mi->queue->next = mpd_new_queue_struct();
		mi->queue->next->first = mi->queue->first;
		mi->queue->next->prev = mi->queue;
		mi->queue = mi->queue->next;
		mi->queue->next = NULL;
	}
	mi->queue->type = MPD_QUEUE_ADD;
	mi->queue->path = strdup(path);
	return MPD_OK;
}

int mpd_playlist_queue_load(MpdObj *mi,const char *path)
{
	if(!mpd_check_connected(mi))
	{
		debug_printf(DEBUG_WARNING,"not connected\n");
		return MPD_NOT_CONNECTED;
	}
	if(path == NULL)
	{
		debug_printf(DEBUG_ERROR, "path != NULL Failed");
		return MPD_ARGS_ERROR;
	}

	if(mi->queue == NULL)
	{
		mi->queue = mpd_new_queue_struct();
		mi->queue->first = mi->queue;
		mi->queue->next = NULL;
		mi->queue->prev = NULL;
	}
	else
	{
		mi->queue->next = mpd_new_queue_struct();
		mi->queue->next->first = mi->queue->first;
		mi->queue->next->prev = mi->queue;
		mi->queue = mi->queue->next;
		mi->queue->next = NULL;
	}
	mi->queue->type = MPD_QUEUE_LOAD;
	mi->queue->path = strdup(path);
	return MPD_OK;
}


int mpd_playlist_queue_commit(MpdObj *mi)
{
	if(!mpd_check_connected(mi))
	{
		debug_printf(DEBUG_WARNING,"not connected\n");
		return MPD_NOT_CONNECTED;
	}
	if(mi->queue == NULL)
	{
		debug_printf(DEBUG_WARNING,"mi->queue is empty");
		return MPD_PLAYLIST_QUEUE_EMPTY;
	}
	if(mpd_lock_conn(mi))
	{
		debug_printf(DEBUG_WARNING,"lock failed\n");
		return  MPD_LOCK_FAILED;
	}
	mpd_sendCommandListBegin(mi->connection);
	/* get first item */
	mi->queue = mi->queue->first;
	while(mi->queue != NULL)
	{
		if(mi->queue->type == MPD_QUEUE_ADD)
		{
			if(mi->queue->path != NULL)
			{
				mpd_sendAddCommand(mi->connection, mi->queue->path);
			}
		}
		else if(mi->queue->type == MPD_QUEUE_LOAD)
		{
			if(mi->queue->path != NULL)
			{
				mpd_sendLoadCommand(mi->connection, mi->queue->path);
			}
		}
		else if (mi->queue->type == MPD_QUEUE_DELETE_ID)
		{
			if(mi->queue->id >= 0)
			{
				mpd_sendDeleteIdCommand(mi->connection, mi->queue->id);
			}
		}
		else if (mi->queue->type == MPD_QUEUE_DELETE_POS)
		{                                                                      		
			if(mi->queue->id >= 0)
			{
				mpd_sendDeleteCommand(mi->connection, mi->queue->id);
			}
		}

		mpd_queue_get_next(mi);
	}
	mpd_sendCommandListEnd(mi->connection);
	mpd_finishCommand(mi->connection);
	mpd_unlock_conn(mi);
	mpd_status_update(mi);
	return MPD_OK;
}
int mpd_playlist_queue_delete_id(MpdObj *mi,int id)
{
	if(!mpd_check_connected(mi))
	{
		debug_printf(DEBUG_WARNING,"not connected\n");
		return MPD_NOT_CONNECTED;
	}

	if(mi->queue == NULL)
	{
		mi->queue = mpd_new_queue_struct();
		mi->queue->first = mi->queue;
		mi->queue->next = NULL;
		mi->queue->prev = NULL;
	}
	else
	{
		mi->queue->next = mpd_new_queue_struct();
		mi->queue->next->first = mi->queue->first;
		mi->queue->next->prev = mi->queue;
		mi->queue = mi->queue->next;
		mi->queue->next = NULL;
	}
	mi->queue->type = MPD_QUEUE_DELETE_ID;
	mi->queue->id = id;
	mi->queue->path = NULL;
	return MPD_OK;
}

int mpd_playlist_queue_delete_pos(MpdObj *mi,int songpos)
{
	if(!mpd_check_connected(mi))
	{
		debug_printf(DEBUG_WARNING,"mpd_playlist_add: not connected\n");
		return MPD_NOT_CONNECTED;
	}

	if(mi->queue == NULL)
	{
		mi->queue = mpd_new_queue_struct();
		mi->queue->first = mi->queue;
		mi->queue->next = NULL;
		mi->queue->prev = NULL;
	}
	else
	{
		mi->queue->next = mpd_new_queue_struct();
		mi->queue->next->first = mi->queue->first;
		mi->queue->next->prev = mi->queue;
		mi->queue = mi->queue->next;
		mi->queue->next = NULL;
	}
	mi->queue->type = MPD_QUEUE_DELETE_POS;
	mi->queue->id = songpos;
	mi->queue->path = NULL;
	return MPD_OK;
}

int mpd_playlist_add_get_id(MpdObj *mi,const char *path)
{
	int songid = -1;
	if(mi == NULL || path == NULL)
	{
		debug_printf(DEBUG_ERROR, "mi == NULL || path == NULL failed");
		return MPD_ARGS_ERROR;
	}
	if(!mpd_check_connected(mi))
	{
		debug_printf(DEBUG_WARNING,"mpd_playlist_add: not connected\n");
		return MPD_NOT_CONNECTED;
	}
	if(mpd_lock_conn(mi))
	{
		debug_printf(DEBUG_WARNING,"lock failed\n");
		return MPD_LOCK_FAILED;
	}
	songid = mpd_sendAddIdCommand(mi->connection, path);
	mpd_finishCommand(mi->connection);

	mpd_unlock_conn(mi);
	return songid; 
}

void mpd_playlist_search_start(MpdObj *mi, int exact)
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
	if(!mpd_server_check_version(mi, 0,12,1))
	{
		debug_printf(DEBUG_ERROR, "Advanced search requires mpd 0.12.2 or higher");
		return ;
	}
	/* lock, so we can work on mi->connection */
	if(mpd_lock_conn(mi) != MPD_OK)
	{
		debug_printf(DEBUG_ERROR, "Failed to lock connection");
		return ;
	}
	mpd_startPlaylistSearch(mi->connection, exact);
	/* Set search type */
	mi->search_type = (exact)? MPD_SEARCH_TYPE_PLAYLIST_FIND:MPD_SEARCH_TYPE_PLAYLIST_SEARCH;
	/* unlock, let the error handler handle any possible error.
	 */
	mpd_unlock_conn(mi);
	return;
}

void mpd_playlist_search_add_constraint(MpdObj *mi, mpd_TagItems field,const char *value)
{
	mpd_database_search_add_constraint(mi, field, value);
}
MpdData * mpd_playlist_search_commit(MpdObj *mi)
{
	mpd_InfoEntity *ent = NULL;
	MpdData *data = NULL;
	if(!mpd_check_connected(mi))
	{
		debug_printf(DEBUG_WARNING,"not connected\n");
		return NULL;
	}
	if(mi->search_type < MPD_SEARCH_TYPE_PLAYLIST_FIND )
	{
		debug_printf(DEBUG_ERROR, "no or wrong search in progress to commit");
		return NULL;
	}
	if(mpd_lock_conn(mi))
	{
		debug_printf(DEBUG_ERROR,"lock failed\n");
		return NULL;
	}
	mpd_commitSearch(mi->connection);
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

