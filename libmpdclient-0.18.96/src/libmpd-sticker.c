#include <stdio.h>
#include <stdlib.h>
#define __USE_GNU
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
	return NULL;
}

int mpd_sticker_song_set(MpdObj *mi, const char *path, const char *tag, const char *value)
{
	return 0;
}
