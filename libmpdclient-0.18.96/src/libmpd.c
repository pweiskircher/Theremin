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

static void mpd_free_queue_ob(MpdObj *mi);
static void mpd_server_free_commands(MpdObj *mi);


char *libmpd_version = LIBMPD_VERSION;
#ifndef HAVE_STRNDUP
/**
 * Not every platfarm has strndup, so here we have a nice little custom implementation
 */
char * strndup(const char *s, size_t n)
{
	size_t nAvail;
	char *p;

	if(!s) {
		return NULL;
	}

	/*  nAvail = min( strlen(s)+1, n+1 ); */
	nAvail=((strlen(s)+1) > (n+1)) ? n+1 : strlen(s)+1;
	if(!(p=malloc(nAvail))) {
		return NULL;
	}
	memcpy(p, s, nAvail);
	p[nAvail - 1] = 0;
	return p;
}
#endif
/**
 * @param state a #MpdServerState to initialize
 *
 * Initialize #MpdServerState. To stop duplicating code.
 */
static void mpd_init_MpdServerState(MpdServerState *state)
{
	state->playlistid 	= -1;
	state->storedplaylistid = -1;
	state->state 		= -1;
	state->songid 		= -1;     	
	state->songpos 		= -1;
    state->nextsongpos  = -1;
    state->nextsongid   = -1;
	state->dbUpdateTime 	= 0;
	state->updatingDb 	= 0;
	state->repeat 		= -1;
	state->random 		= -1;
	state->volume 		= -2;
	state->xfade		= -1;
	state->totaltime 	= 0;
	state->elapsedtime 	= 0;
	state->bitrate 		= 0;
	state->samplerate 	= 0;
	state->channels 	= 0;
	state->bits 		= 0;
    state->consume      = 0;
    state->single       = 0;
    state->playlistLength = 0;
    state->error[0]            = '\0';

}


static MpdObj * mpd_create()
{
	MpdObj * mi = calloc(1, sizeof(MpdObj));

	/* set default values */
	/* we start not connected */
	mi->connected = FALSE;
	/* port 6600 is the default mpd port */
	mi->port = 6600;
	/* localhost */
	mi->hostname = strdup("localhost");
	/* 1 second timeout */
	mi->connection_timeout = 1.0;
	/* info */
	mpd_init_MpdServerState(&(mi->CurrentState));
	mpd_init_MpdServerState(&(mi->OldState));

	/* connection is locked because where not connected */
	mi->connection_lock = TRUE;

	/* search stuff */
	mi->search_type = MPD_SEARCH_TYPE_NONE;
	/* no need to initialize, but set it to anything anyway*/
	mi->search_field = MPD_TAG_ITEM_ARTIST;

	return mi;
}

void mpd_free(MpdObj *mi)
{
	debug_printf(DEBUG_INFO, "destroying MpdObj object\n");
	if(mi->connected)
	{
		/* disconnect */
		debug_printf(DEBUG_WARNING, "Connection still running, disconnecting\n");
		mpd_disconnect(mi);
	}
	if(mi->hostname)
	{
		free(mi->hostname);
	}
	if(mi->password)
	{
		free(mi->password);
	}
	if(mi->error_msg)
	{
		free(mi->error_msg);
	}
	if(mi->connection)
	{
		/* obsolete */
		mpd_closeConnection(mi->connection);
	}
	if(mi->status)
	{
		mpd_freeStatus(mi->status);
	}
	if(mi->stats)
	{
		mpd_freeStats(mi->stats);
	}
	if(mi->CurrentSong)
	{
		mpd_freeSong(mi->CurrentSong);
	}
	mpd_free_queue_ob(mi);
	mpd_server_free_commands(mi);		
	free(mi);
}

int mpd_check_error(MpdObj *mi)
{
	if(mi == NULL)
	{
		debug_printf(DEBUG_ERROR, "mi == NULL?");
		return MPD_ARGS_ERROR;
	}
	
	/* this shouldn't happen, ever */
	if(mi->connection == NULL)
	{
		debug_printf(DEBUG_ERROR, "mi->connection == NULL?");
		return MPD_FATAL_ERROR;
	}

	/* TODO: map these errors in the future */
	mi->error = mi->connection->error;
	mi->error_mpd_code = mi->connection->errorCode;
	/*TODO: do I need to strdup this? */
	mi->error_msg = strdup(mi->connection->errorStr);

	/* Check for permission */
	/* First check for an error reported by MPD
	 * Then check what type of error mpd reported
	 */
	if(mi->error == MPD_ERROR_ACK)
	{

		debug_printf(DEBUG_ERROR,"clearing errors in mpd_Connection: %i-%s", mi->connection->errorCode, mi->connection->errorStr);
		mpd_clearError(mi->connection);
		if (mi->the_error_callback)
		{
            debug_printf(DEBUG_ERROR, "Error callback 1 (ACK)");
			if(mi->the_error_callback(mi, mi->error_mpd_code, mi->error_msg, mi->the_error_signal_userdata ))
            {
                debug_printf(DEBUG_ERROR, "Error callback told me to disconnect");
                mpd_disconnect(mi);
                free(mi->error_msg);
                mi->error_msg = NULL;

                return MPD_SERVER_ERROR;
            }
		}
		free(mi->error_msg);
		mi->error_msg = NULL;
		return TRUE;
	}
	if(mi->error)
	{

		debug_printf(DEBUG_ERROR, "Following error occurred: %i: code: %i msg: %s", mi->error,mi->connection->errorCode, mi->error_msg);

		if (mi->the_error_callback)
		{
            debug_printf(DEBUG_ERROR, "Error callback 2");
			mi->the_error_callback(mi, mi->error, mi->error_msg, mi->the_error_signal_userdata );
		}
		mpd_disconnect(mi);
		free(mi->error_msg);
		mi->error_msg = NULL;

		return MPD_SERVER_ERROR;
	}
	free(mi->error_msg);
	mi->error_msg = NULL;	
	return MPD_OK;
}



int mpd_lock_conn(MpdObj *mi)
{

	if(mi->connection_lock)
	{
		debug_printf(DEBUG_WARNING, "Failed to lock connection, already locked\n");
		return MPD_LOCK_FAILED;
	}
	mi->connection_lock = TRUE;
	return MPD_OK;
}

int mpd_unlock_conn(MpdObj *mi)
{
	if(!mi->connection_lock)
	{
		debug_printf(DEBUG_ERROR, "Failed to unlock connection, already unlocked\n");
		return MPD_LOCK_FAILED;
	}

	mi->connection_lock = FALSE;

	return mpd_check_error(mi);
}

MpdObj * mpd_new_default()
{
	debug_printf(DEBUG_INFO, "creating a new mpdInt object\n");
	return mpd_create();
}

MpdObj *mpd_new(char *hostname,  int port, char *password)
{
	MpdObj *mi = mpd_create();
	if(mi == NULL)
	{
		return NULL;
	}
	if(hostname != NULL)
	{
		mpd_set_hostname(mi, hostname);
	}
	if(port != 0)
	{
		mpd_set_port(mi, port);
	}
	if(password != NULL)
	{
		mpd_set_password(mi, password);
	}
	return mi;
}


const char * mpd_get_hostname(MpdObj *mi)
{
	if(mi == NULL)
	{
		return NULL;
	}
	return mi->hostname;
}

int mpd_set_hostname(MpdObj *mi, char *hostname)
{
	if(mi == NULL)
	{
		debug_printf(DEBUG_ERROR, "mi == NULL\n");
		return MPD_ARGS_ERROR;
	}

	if(mi->hostname != NULL)
	{
		free(mi->hostname);
	}
	/* possible location todo some post processing of hostname */
	mi->hostname = strdup(hostname);
	return MPD_OK;
}

int mpd_set_password(MpdObj *mi, const char *password)
{
	if(mi == NULL)
	{
		debug_printf(DEBUG_ERROR, "mi == NULL\n");
		return MPD_ARGS_ERROR;
	}

	if(mi->password != NULL)
	{
		free(mi->password);
	}
	/* possible location todo some post processing of password */
	mi->password = strdup(password);
	return MPD_OK;
}


int mpd_send_password(MpdObj *mi)
{
	if(!mi) return MPD_ARGS_ERROR;
	if(mi->password && mpd_check_connected(mi) && strlen(mi->password))
	{
		if(mpd_lock_conn(mi))
		{
			debug_printf(DEBUG_WARNING, "failed to lock connection");
			return MPD_LOCK_FAILED;
		}
		mpd_sendPasswordCommand(mi->connection, mi->password);
		mpd_finishCommand(mi->connection);
		if(mpd_unlock_conn(mi))
		{
			debug_printf(DEBUG_ERROR, "Failed to unlock connection\n");
			return MPD_LOCK_FAILED;
		}
		mpd_server_get_allowed_commands(mi);
		/*TODO: should I do it here, or in the
		 * mpd_server_get_allowed_command, so it also get's executed on
		 * connect
		 */
		if((mi->the_status_changed_callback != NULL))
        {
            /* If permission updates, we should also call an output update, The data might be available now. */
            mi->the_status_changed_callback( mi,
                    MPD_CST_PERMISSION|MPD_CST_OUTPUT, mi->the_status_changed_signal_userdata );
        }
	}
	return MPD_OK;
}

int mpd_set_port(MpdObj *mi, int port)
{
	if(mi == NULL)
	{
		debug_printf(DEBUG_ERROR, "mi == NULL\n");
		return MPD_ARGS_ERROR;
	}
	mi->port = port;
	return MPD_OK;
}

int mpd_set_connection_timeout(MpdObj *mi, float timeout)
{
	if(mi == NULL)
	{
		debug_printf(DEBUG_ERROR, "mi == NULL\n");
		return MPD_ARGS_ERROR;
	}
	mi->connection_timeout = timeout;
	if(mpd_check_connected(mi))
	{
		/*TODO: set timeout */	
		if(mpd_lock_conn(mi))
		{
			debug_printf(DEBUG_ERROR,"lock failed\n");
			return MPD_LOCK_FAILED;
		}
		mpd_setConnectionTimeout(mi->connection, timeout);
		mpd_finishCommand(mi->connection);

		mpd_unlock_conn(mi);

	}
	return MPD_OK;
}

static void mpd_server_free_commands(MpdObj *mi)
{
	if(mi->commands)
	{
		int i=0;
		while(mi->commands[i].command_name)
		{
			free(mi->commands[i].command_name);
			i++;
		}
		free(mi->commands);
		mi->commands = NULL;
	}
}

char *mpd_server_get_version(MpdObj *mi)
{
	char *retval = NULL;
	if(!mi || !mpd_check_connected(mi))
		return NULL;
	retval = malloc(10*sizeof(char));
	snprintf(retval,10,"%i.%i.%i", mi->connection->version[0], mi->connection->version[1], mi->connection->version[2]);
	/* always make sure the string is terminated */
	retval[9] = '\0';
	return retval;
}

int mpd_server_get_allowed_commands(MpdObj *mi)
{
	char *temp = NULL;
	int num_commands = 0;
	if(!mi){
		debug_printf(DEBUG_ERROR, "mi != NULL failed\n");
	       	return MPD_ARGS_ERROR;
	}
	if(!mpd_check_connected(mi)) {
		debug_printf(DEBUG_WARNING, "Not Connected");
		return MPD_NOT_CONNECTED;
	}
	if(!mpd_server_check_version(mi,0,12,0)){
		debug_printf(DEBUG_INFO, "Not supported by mpd");
	       	return MPD_SERVER_NOT_SUPPORTED;
	}

	mpd_server_free_commands(mi);

	if(mpd_lock_conn(mi))
	{
		debug_printf(DEBUG_ERROR, "lock failed");
		return MPD_LOCK_FAILED;
	}
	mpd_sendCommandsCommand(mi->connection);
	while((temp = mpd_getNextCommand(mi->connection)))
	{
		num_commands++;
		mi->commands = realloc(mi->commands, (num_commands+1)*sizeof(MpdCommand));
		mi->commands[num_commands-1].command_name = temp;
		mi->commands[num_commands-1].enabled = TRUE;
		mi->commands[num_commands].command_name = NULL;
		mi->commands[num_commands].enabled = FALSE;
        if(strcmp(mi->commands[num_commands-1].command_name, "idle") == 0) {
            mi->has_idle = TRUE;
        }
	}
	mpd_finishCommand(mi->connection);
	mpd_sendNotCommandsCommand(mi->connection);
	while((temp = mpd_getNextCommand(mi->connection)))
	{
		num_commands++;
		mi->commands = realloc(mi->commands, (num_commands+1)*sizeof(MpdCommand));
		mi->commands[num_commands-1].command_name = temp;
		mi->commands[num_commands-1].enabled = FALSE;
		mi->commands[num_commands].command_name = NULL;
		mi->commands[num_commands].enabled = FALSE;
	}
	mpd_finishCommand(mi->connection);

	if(mpd_unlock_conn(mi))
    {
        return MPD_LOCK_FAILED;
    }
	return MPD_OK;
}



int mpd_disconnect(MpdObj *mi)
{

	/* lock */
	mpd_lock_conn(mi);
	debug_printf(DEBUG_INFO, "disconnecting\n");

	if(mi->connection)
	{
		mpd_closeConnection(mi->connection);
		mi->connection = NULL;
	}
	if(mi->status)
	{
		mpd_freeStatus(mi->status);
		mi->status = NULL;
	}
	if(mi->stats)
	{
		mpd_freeStats(mi->stats);
		mi->stats = NULL;
	}
	if(mi->CurrentSong)
	{
		mpd_freeSong(mi->CurrentSong);
		mi->CurrentSong = NULL;
	}
	mi->CurrentState.playlistid = -1;
	mi->CurrentState.storedplaylistid = -1;
	mi->CurrentState.state = -1;
	mi->CurrentState.songid = -1;
	mi->CurrentState.songpos = -1;
    mi->CurrentState.nextsongid = -1;
    mi->CurrentState.nextsongpos = -1;
	mi->CurrentState.dbUpdateTime = 0;
	mi->CurrentState.updatingDb = 0;
	mi->CurrentState.repeat = -1;
	mi->CurrentState.random = -1;
	mi->CurrentState.volume = -2;
	mi->CurrentState.xfade	= -1;
	mi->CurrentState.totaltime = 0;
	mi->CurrentState.elapsedtime = 0;
	mi->CurrentState.bitrate = 0;
	mi->CurrentState.samplerate = 0; 
	mi->CurrentState.channels = 0; 
	mi->CurrentState.bits = 0;
    mi->CurrentState.playlistLength = 0;
    mi->CurrentState.error[0] = '\0';
	/* search stuff */
	mi->search_type = MPD_SEARCH_TYPE_NONE;
	/* no need to initialize, but set it to anything anyway*/
	mi->search_field = MPD_TAG_ITEM_ARTIST;
    /* outputs */
    mi->num_outputs = 0;
    if(mi->output_states)
        free(mi->output_states);
    mi->output_states = NULL;


    mi->has_idle = 0;
	
	memcpy(&(mi->OldState), &(mi->CurrentState) , sizeof(MpdServerState));

	mpd_free_queue_ob(mi);
	mpd_server_free_commands(mi);	
	/*don't reset errors */
	/* Remove this signal, we don't actually disconnect */
	if(mi->connected)
	{
		/* set disconnect flag */
		mi->connected = FALSE;

		if(mi->the_connection_changed_callback != NULL)
		{
			mi->the_connection_changed_callback( mi, FALSE, mi->the_connection_changed_signal_userdata );
		}
	}
	debug_printf(DEBUG_INFO, "Disconnect completed\n");
	return MPD_OK;
}
int mpd_connect(MpdObj *mi)
{
	return mpd_connect_real(mi,NULL);
}
int mpd_connect_real(MpdObj *mi,mpd_Connection *connection)
{
    int retv;
    if(mi == NULL)
	{
		/* should return some spiffy error here */
		debug_printf(DEBUG_ERROR, "mi != NULL failed");
		return MPD_ARGS_ERROR;
	}
	/* reset errors */
	mi->error = 0;
	mi->error_mpd_code = 0;
	if(mi->error_msg != NULL)
	{
		free(mi->error_msg);
	}
	mi->error_msg = NULL;

	debug_printf(DEBUG_INFO, "connecting\n");
	mpd_init_MpdServerState(&(mi->CurrentState));

	memcpy(&(mi->OldState), &(mi->CurrentState), sizeof(MpdServerState));

	if(mi->connected)
	{
		/* disconnect */
		mpd_disconnect(mi);
	}

	if(mi->hostname == NULL)
	{
		mpd_set_hostname(mi, "localhost");
	}
	/* make sure this is locked */
	if(!mi->connection_lock)
	{
		mpd_lock_conn(mi);
	}
	if(connection) {
		mi->connection = connection;
	} else {
		/* make timeout configurable */
		mi->connection = mpd_newConnection(mi->hostname,mi->port,mi->connection_timeout);
	}
	if(mi->connection == NULL)
	{
		/* TODO: make seperate error message? */
		return MPD_NOT_CONNECTED;
	}
	if(mpd_check_error(mi) != MPD_OK)
	{
		/* TODO: make seperate error message? */
		return MPD_NOT_CONNECTED;
	}

	/* set connected state */
	mi->connected = TRUE;
	if(mpd_unlock_conn(mi))
	{
		return MPD_LOCK_FAILED;
	}

	/* get the commands we are allowed to use */
	retv = mpd_server_get_allowed_commands(mi);
    if(retv!= MPD_OK)
    {
        return retv;
    }
    /* Trying to send password, this is needed to get right outputs and tag_types */
    if(mi->password && strlen(mi->password) > 0)
    {
        mpd_send_password(mi);
    }
/*

    retv = mpd_server_update_outputs(mi);
    if(retv != MPD_OK)
        return retv;
*/

    retv = mpd_server_update_outputs(mi);
    /** update the supported tags */
    debug_printf(DEBUG_INFO,  "Propagating connection changed");

    if(mi->the_connection_changed_callback != NULL)
	{
		mi->the_connection_changed_callback( mi, TRUE, mi->the_connection_changed_signal_userdata );
	}
    /*
    if(retv != MPD_OK)
        return retv;
        */
	debug_printf(DEBUG_INFO, "Connected to mpd");
	return MPD_OK;
}

int mpd_check_connected(MpdObj *mi)
{
	if(mi == NULL)
	{
		return FALSE;
	}
	return mi->connected;
}


/* SIGNALS */
void	mpd_signal_connect_status_changed        (MpdObj *mi, StatusChangedCallback status_changed, void *userdata)
{
	if(mi == NULL)
	{
		debug_printf(DEBUG_ERROR, "mi != NULL failed");
		return;
	}
	mi->the_status_changed_callback = status_changed;
	mi->the_status_changed_signal_userdata = userdata;
}


void	mpd_signal_connect_error(MpdObj *mi, ErrorCallback error_callback, void *userdata)
{
	if(mi == NULL)
	{
		debug_printf(DEBUG_ERROR, "mi != NULL failed");
		return;
	}
	mi->the_error_callback = error_callback;
	mi->the_error_signal_userdata = userdata;
}

void	mpd_signal_connect_connection_changed(MpdObj *mi, ConnectionChangedCallback connection_changed, void *userdata)
{
	if(mi == NULL)
	{
		debug_printf(DEBUG_ERROR, "mi != NULL failed");
		return;
	}
	mi->the_connection_changed_callback = connection_changed;
	mi->the_connection_changed_signal_userdata = userdata;
}


/* more playlist */
/* MpdData Part */
MpdData *mpd_new_data_struct(void)
{
	return (MpdData*) calloc(1, sizeof(MpdData_real));
}

MpdData *mpd_new_data_struct_append(MpdData  * data)
{
	MpdData_real *data_real = (MpdData_real*)data;
	if(data_real == NULL)
	{
		data_real = (MpdData_real*)mpd_new_data_struct();
        data_real->first = data_real;
	}
	else
	{
		data_real->next = (MpdData_real*)mpd_new_data_struct(); 	
		data_real->next->prev = data_real;
		data_real = data_real->next;
		data_real->next = NULL;
        data_real->first = data_real->prev->first;
	}
	return (MpdData*)data_real;
}

MpdData * mpd_data_get_first(MpdData const * const data)
{
	MpdData_real const * const data_real = (MpdData_real const * const)data;
	if(data_real != NULL)
	{
        return (MpdData*)data_real->first;
    }
	return NULL;
}


MpdData * mpd_data_get_next(MpdData * const data) 
{
	return mpd_data_get_next_real(data, TRUE);
}

MpdData * mpd_data_get_next_real(MpdData * const data, int kill_list)
{
	MpdData_real *data_real = (MpdData_real*)data;
	if (data_real != NULL) 
	{
		if (data_real->next != NULL )
		{
			return (MpdData*)data_real->next;
		}
		else		
		{
			if (kill_list) mpd_data_free((MpdData*)data_real);
			return NULL;
		}
	}
	return (MpdData*)data_real;	
}

int mpd_data_is_last(MpdData const * const data)
{
	MpdData_real const * const data_real = (MpdData_real const * const)data;
	if(data_real != NULL)
	{
		if (data_real->next == NULL)
		{
			return TRUE;
		}
	}
	return FALSE;	
}
/*
MpdData_head *mpd_data_get_head(MpdData const * const data) {
	return ((MpdData_real*)data)->head;
}
*/
MpdData* mpd_data_concatenate( MpdData  * const first, MpdData  * const second) 
{
	MpdData_real *first_real  = (MpdData_real*)first;
	MpdData_real *second_real = (MpdData_real*)second;
	MpdData_real *first_head  = NULL;

	if ( first == NULL ) {
		if ( second != NULL ) 
			return (MpdData*)second_real;
		else
			return NULL;
	} else {
		if ( second == NULL )
			return (MpdData*)first_real;
	}

	first_head = (MpdData_real *)mpd_data_get_first(first);

	/* find last element in first data list */	
	while (!mpd_data_is_last((MpdData*)first_real)) first_real = (MpdData_real*)mpd_data_get_next_real((MpdData*)first_real, FALSE);
	second_real =(MpdData_real*) mpd_data_get_first((MpdData*)second_real);

	first_real->next = second_real;
	second_real->prev = first_real;

	/* I need to set all the -> first correct */
	while (second_real)
	{
		second_real->first = first_head;
		second_real = (MpdData_real*)mpd_data_get_next_real((MpdData*)second_real, FALSE);
	} 

	return (MpdData*)first_head;
}
/** 
 * Deletes an item from the list. It returns the next item in the list.
 * if that is not available, it will return the last item
 */
MpdData * mpd_data_delete_item(MpdData *data)
{
    MpdData_real *temp = NULL, *data_real = (MpdData_real*)data;
    if(data_real == NULL) return NULL;
    /* if there is a next item, fix the prev pointer of the next item */
    if (data_real->next)
    {
        data_real->next->prev = data_real->prev;
        temp = data_real->next;
    }                                               		
    /* if there is a previous item, fix the next pointer of the previous item */
    if (data_real->prev)
    {
        /* the next item of the previous is the next item of the current */
        data_real->prev->next = data_real->next;
        /* temp is the previous item */
        temp = data_real->prev;
    }

    /* fix first,  if removed item is the first */  
    if(temp && temp->first == data_real)
    {
        MpdData_real *first,*node = temp;
        /* get first */
        for(;node->prev;node = node->prev);
        first = node;
        while(node){
            node->first = first;
            node = node->next;
        }
    }
    /* make the removed row a valid list, so I can use the default free function to free it */
    data_real->next = NULL;
    data_real->prev = NULL;
    data_real->first = data_real;
    /* free it */
    mpd_data_free((MpdData *)data_real);

    return (MpdData *)temp;
}

void mpd_data_free(MpdData *data)
{
    MpdData_real *data_real,*temp;
    if(data == NULL)
    {
        debug_printf(DEBUG_ERROR, "data != NULL Failed");
        return;
    }
    data_real = (MpdData_real *)mpd_data_get_first(data);
    while(data_real){
        temp = data_real;
        if (data_real->type == MPD_DATA_TYPE_SONG) {
            if(data_real->song) mpd_freeSong(data_real->song);
        } else if (data_real->type == MPD_DATA_TYPE_OUTPUT_DEV) {
            mpd_freeOutputElement(data_real->output_dev);
        } else if(data_real->type == MPD_DATA_TYPE_DIRECTORY) {
            if(data_real->directory)free(data_real->directory);
        } else if(data_real->type == MPD_DATA_TYPE_PLAYLIST) {
            if(data_real->playlist) mpd_freePlaylistFile(data_real->playlist);				
        } else {
            free((void*)(data_real->tag));
        }
        if(data_real->freefunc)
        {
            if(data_real->userdata)
                data_real->freefunc(data_real->userdata);
        }
        data_real = data_real->next;
        free(temp);
    }
}

/* clean this up.. make one while loop */
static void mpd_free_queue_ob(MpdObj *mi)
{
    MpdQueue *temp = NULL;
    if(mi == NULL)
    {
        debug_printf(DEBUG_ERROR, "mi != NULL failed");
        return;
    }
    if(mi->queue == NULL)
    {
        debug_printf(DEBUG_INFO, "mi->queue != NULL failed, nothing to clean.");
        return;
    }	
    mi->queue = mi->queue->first;
    while(mi->queue != NULL)
    {
        temp = mi->queue->next;

        if(mi->queue->path != NULL)
        {
            free(mi->queue->path);
        }

        free(mi->queue);
        mi->queue = temp;
    }
    mi->queue = NULL;

}

MpdQueue *mpd_new_queue_struct()
{
    return calloc(1, sizeof(MpdQueue));
}


void mpd_queue_get_next(MpdObj *mi)
{
    if(mi->queue != NULL && mi->queue->next != NULL)
    {
        mi->queue = mi->queue->next;
    }
    else if(mi->queue->next == NULL)
    {
        mpd_free_queue_ob(mi);
        mi->queue = NULL;
    }
}

long unsigned mpd_server_get_database_update_time(MpdObj *mi)
{
    if(!mpd_check_connected(mi))
    {
        debug_printf(DEBUG_WARNING,"not connected\n");
        return MPD_NOT_CONNECTED;
    }
    if(mpd_stats_check(mi) != MPD_OK)
    {
        debug_printf(DEBUG_WARNING,"Failed grabbing status\n");
        return MPD_STATS_FAILED;
    }
    return mi->stats->dbUpdateTime;
}


MpdData * mpd_server_get_output_devices(MpdObj *mi)
{
    mpd_OutputEntity *output = NULL;
    MpdData *data = NULL;
    if(!mpd_check_connected(mi))
    {
        debug_printf(DEBUG_WARNING,"not connected\n");
        return NULL;
    }
    /* TODO: Check version */
    if(mpd_lock_conn(mi))
    {
        debug_printf(DEBUG_ERROR,"lock failed\n");
        return NULL;
    }

    mpd_sendOutputsCommand(mi->connection);
    while (( output = mpd_getNextOutput(mi->connection)) != NULL)
    {	
        data = mpd_new_data_struct_append(data);
        data->type = MPD_DATA_TYPE_OUTPUT_DEV; 
        data->output_dev = output;
    }
    mpd_finishCommand(mi->connection);

    /* unlock */
    if(mpd_unlock_conn(mi) != MPD_OK)
    {
        if(data)mpd_data_free(data);
        return NULL;
    }
    if(data == NULL) 
    {
        return NULL;
    }
    return mpd_data_get_first(data);
}

int mpd_server_set_output_device(MpdObj *mi,int device_id,int state)
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
    if(state)
    {
        mpd_sendEnableOutputCommand(mi->connection, device_id);
    }
    else
    {
        mpd_sendDisableOutputCommand(mi->connection, device_id);
    }	
    mpd_finishCommand(mi->connection);

    mpd_unlock_conn(mi);
    mpd_status_queue_update(mi);
    return FALSE;
}

int mpd_server_check_version(MpdObj *mi, int major, int minor, int micro)
{
    if(!mpd_check_connected(mi))
    {
        debug_printf(DEBUG_WARNING,"not connected\n");
        return FALSE;
    }
    if(major > mi->connection->version[0]) return FALSE;
    if(mi->connection->version[0] > major) return TRUE;
    if(minor > mi->connection->version[1]) return FALSE;
    if(mi->connection->version[1] > minor) return TRUE;
    if(micro > mi->connection->version[2]) return FALSE;
    if(mi->connection->version[2] > micro) return TRUE; 	
    return TRUE;
}	

int mpd_server_check_command_allowed(MpdObj *mi, const char *command)
{
    int i;
    if(!mi || !command) return MPD_SERVER_COMMAND_ERROR;
    /* when we are connected to a mpd server that doesn't support commands and not commands
     * feature. (like mpd 0.11.5) allow everything
     */
    if(!mpd_server_check_version(mi, 0,12,0)) return MPD_SERVER_COMMAND_ALLOWED;
    /*
     * Also when somehow we failted to get commands
     */
    if(mi->commands == NULL) return MPD_SERVER_COMMAND_ALLOWED;



    for(i=0;mi->commands[i].command_name;i++)
    {
        if(!strcasecmp(mi->commands[i].command_name, command))
            return mi->commands[i].enabled;
    }
    return MPD_SERVER_COMMAND_NOT_SUPPORTED;
}


char ** mpd_server_get_tag_types(MpdObj *mi)
{
    char *temp = NULL;
    int i=0;
    char **retv = NULL;
    if(!mpd_check_connected(mi))
    {
        debug_printf(DEBUG_WARNING,"not connected\n");
        return FALSE;
    }
    if(mpd_lock_conn(mi))
    {
        debug_printf(DEBUG_ERROR,"lock failed\n");
        return NULL;
    }                                           
    mpd_sendTagTypesCommand(mi->connection);
    while((temp = mpd_getNextTagType(mi->connection)) != NULL)
    {
        retv = realloc(retv,(i+2)*sizeof(*retv));
        retv[i]   = temp;
        retv[i+1] = NULL;
        i++;
    } 
    mpd_finishCommand(mi->connection);


    mpd_unlock_conn(mi);
    return retv;
}

int mpd_misc_get_tag_by_name(char *name)
{
    int i;
    if(name == NULL)
    {
        return MPD_ARGS_ERROR;
    }
    for(i=0; i < MPD_TAG_NUM_OF_ITEM_TYPES; i++)
    {
        if(!strcasecmp(mpdTagItemKeys[i], name))
        {
            return i;
        }
    }
    return MPD_TAG_NOT_FOUND;
}

int mpd_server_update_outputs(MpdObj *mi)
{
    mpd_OutputEntity *output = NULL;
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
    mpd_sendOutputsCommand(mi->connection);
    while (( output = mpd_getNextOutput(mi->connection)) != NULL)
    {	
        mi->num_outputs++;
        mi->output_states = realloc(mi->output_states,mi->num_outputs*sizeof(int));
        mi->output_states[mi->num_outputs-1] = FALSE;/*output->enabled;*/
        mpd_freeOutputElement(output);
    }
    mpd_finishCommand(mi->connection);
    return mpd_unlock_conn(mi);
}

int mpd_server_has_idle(MpdObj *mi)
{
    return mi->has_idle;
}

