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

#ifndef __MPD_INTERNAL_LIB_
#define __MPD_INTERNAL_LIB_

#include "libmpdclient.h"
struct _MpdData_real;

typedef struct _MpdData_real {
	/* MpdDataType */
	MpdDataType type;
    
	union {
		struct {
			int tag_type;
			char *tag;
		};
		char *directory;
		mpd_PlaylistFile *playlist;
		mpd_Song *song;
		mpd_OutputEntity *output_dev; /* from devices */
	};
    void *userdata;
    void (*freefunc)(void *userdata);

	struct _MpdData_real *next;
	/* Previous MpdData in the list */
	struct _MpdData_real *prev;
    struct _MpdData_real *first;
}MpdData_real;


/* queue struct */
typedef struct _MpdQueue MpdQueue;
typedef struct _MpdServerState {
	/* information needed to detect changes on mpd's side */
	long long 	    playlistid;
	long long	    storedplaylistid;
	int 		    songid;
	int 		    songpos;
    int             nextsongpos;
    int             nextsongid;
	int 		    state;
	unsigned long	dbUpdateTime;	
	int 		    updatingDb;
	int		        random;
	int		        repeat;
	int		        volume;
	int		        xfade;
	int 		    totaltime;
	int		        elapsedtime;
	int		        bitrate;
	unsigned int	samplerate;
	int		        bits;
	int		        channels;
    unsigned long   playlistLength;
    char            error[512];
    int             single;
    int             consume;
} MpdServerState;


/* command struct */
/* internal use only */
typedef struct _MpdCommand {
	char *command_name;
	int enabled;
} MpdCommand;



typedef struct _MpdObj {
	/* defines if we are connected */
	/* This should be made true if and only if the connection is up and running */
	short int 	connected;
	/* information needed to connect to mpd */
	char 		*hostname;
	int 		port;
	char 		*password;
	float 		connection_timeout;

	/* mpd's structures */
	mpd_Connection 	*connection;
	mpd_Status 	*status;
	mpd_Stats 	*stats;
	mpd_Song 	*CurrentSong;

	/* used to store/detect serverside status changes */
	MpdServerState CurrentState;
	MpdServerState OldState;
 
	/* new style signals */
	/* error signal */
	ErrorCallback the_error_callback;
	void *the_error_signal_userdata;
	/* song status changed */
	StatusChangedCallback the_status_changed_callback;
	void *the_status_changed_signal_userdata;
	/* (dis)connect signal */
	ConnectionChangedCallback the_connection_changed_callback;
	void *the_connection_changed_signal_userdata;

	/* error message */
	int error;
	int error_mpd_code;
	char *error_msg;

	/* internal values */
	/* this "locks" the connections. so we can't have to commands competing with eachother */
	short int connection_lock;

	/* queue */
	MpdQueue *queue;
	/* commands */
	/* TODO: this is a temporary implementation, I want something nice with commands that are and aren't allowed to use.
	 * so use commands and notcommands functions
	 *TODO: Make a callback when a commando isn't allowed, so the client application can actually offer the user to enter password
	 */
	MpdCommand * commands;
	/**
	 * tag type for a search
	 */
	int search_type;
	int search_field;

    /**
     * For tracking changed outputs.
     * A hack for retarted mpd
     */
    int num_outputs;
    int *output_states;


    int has_idle;
}_MpdObj;


typedef enum MpdQueueType {
	MPD_QUEUE_ADD,
	MPD_QUEUE_LOAD,
	MPD_QUEUE_DELETE_ID,
	MPD_QUEUE_DELETE_POS,
	MPD_QUEUE_COMMAND /* abuse!!! */
} MpdQueueType;

typedef struct _MpdQueue { 
	struct _MpdQueue *next;
	struct _MpdQueue *prev;
	struct _MpdQueue *first;

	/* what item to queue, (add/load/remove)*/
	int type;
	/* for adding files/load playlist/adding streams */
	char *path;
	/* for removing */
	int id;
}_MpdQueue;

/* Internal Queue struct functions */
MpdQueue *	mpd_new_queue_struct			();
void 		mpd_queue_get_next			(MpdObj *mi);

/* Internal Data struct functions */
MpdData *	mpd_new_data_struct			(void);
MpdData *	mpd_new_data_struct_append		(MpdData * data);
MpdData *	mpd_data_concatenate			(MpdData * const first, MpdData * const second);
MpdData *	mpd_data_get_next_real			(MpdData * const data, int kill_list);
/* more internal stuff*/

/**
 * @param mi a #MpdObj 
 *
 * Checks if mpd_stats is available, and updates when needed.
 * 
 * @returns a #MpdError
 */
int mpd_stats_check(MpdObj *mi);

int mpd_lock_conn(MpdObj *mi);
int mpd_unlock_conn(MpdObj *mi);
/*MpdData * mpd_playlist_sort_artist_list(MpdData *data);*/
MpdData * mpd_misc_sort_tag_list(MpdData *data);


#ifndef HAVE_STRNDUP
char * 		strndup					(const char *s, size_t n);
#endif

int mpd_server_get_allowed_commands(MpdObj *mi);
typedef enum _MpdSearchType {
	MPD_SEARCH_TYPE_NONE,
	MPD_SEARCH_TYPE_FIND,
	MPD_SEARCH_TYPE_SEARCH,
	MPD_SEARCH_TYPE_LIST,
	MPD_SEARCH_TYPE_PLAYLIST_FIND,
	MPD_SEARCH_TYPE_PLAYLIST_SEARCH,
	MPD_SEARCH_TYPE_STATS
}MpdSearchType;
int mpd_server_update_outputs(MpdObj *mi);
#endif
