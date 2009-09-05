#include <stdio.h>
#include <stdlib.h>
#define __USE_GNU
#include <glib.h>
#include <string.h>
#include <stdarg.h>
#include <config.h>
#include "debug_printf.h"
#include "libmpd.h"
#include "libmpd-internal.h"


int mpd_sticker_supported ( MpdObj *mi)
{
    if(mi == NULL) return FALSE;

    if(mpd_server_check_command_allowed(mi, "sticker") == MPD_SERVER_COMMAND_ALLOWED) {
        return TRUE;
    }

    return FALSE;    
}

char * mpd_sticker_song_get(MpdObj *mi, const char *path, const char *tag)
{
    char *retv_value = NULL;
    char *retv = NULL;
	if(!mpd_check_connected(mi))
	{
		debug_printf(DEBUG_INFO,"not connected\n");
		return NULL;
	}
    if(mpd_server_check_command_allowed(mi, "sticker") != MPD_SERVER_COMMAND_ALLOWED) {
        debug_printf(DEBUG_WARNING, "Command not allowed\n");
        return NULL;
    }
	if(mpd_lock_conn(mi))
	{
		debug_printf(DEBUG_ERROR,"lock failed\n");
		return NULL;
	}

    mpd_sendGetSongSticker(mi->connection,path, tag); 
    retv_value = mpd_getNextSticker(mi->connection);
    mpd_finishCommand(mi->connection);
    if(retv_value && strlen(retv_value) > strlen(tag)){
            retv = g_strdup(&retv_value[strlen(tag)]+1);
    }
    free(retv_value);
    if(mi->connection->error == MPD_ERROR_ACK && mi->connection->errorCode == MPD_ACK_ERROR_NO_EXIST)
    {
		mpd_clearError(mi->connection);
		g_free(retv);
        retv = NULL;
    }
    if(mpd_unlock_conn(mi))
    {
		debug_printf(DEBUG_ERROR, "Failed to unlock");
        g_free(retv);
		return NULL;
	}
    return retv;
}

int mpd_sticker_song_set(MpdObj *mi, const char *path, const char *tag, const char *value)
{
	if(!mpd_check_connected(mi))
	{
		debug_printf(DEBUG_INFO,"not connected\n");
		return MPD_NOT_CONNECTED;
	}
    if(mpd_server_check_command_allowed(mi, "sticker") != MPD_SERVER_COMMAND_ALLOWED) {
        debug_printf(DEBUG_WARNING, "Command not allowed\n");
        return MPD_SERVER_NOT_SUPPORTED;
    }
	if(mpd_lock_conn(mi))
	{
		debug_printf(DEBUG_ERROR,"lock failed\n");
		return MPD_LOCK_FAILED;
	}

    mpd_sendSetSongSticker(mi->connection,path, tag,value); 
    mpd_finishCommand(mi->connection);
    if(mpd_unlock_conn(mi))
    {
		debug_printf(DEBUG_ERROR, "Failed to unlock");
		return MPD_LOCK_FAILED;
	}
    return MPD_OK;
}
