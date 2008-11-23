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

/**
 * \example testcase.c
 * A small example of a console client using libmpd.
 */

/** \defgroup 1Basic Basic
 */
/*@{*/

#ifdef __cplusplus
extern "C" {
#endif

#ifndef __MPD_LIB__
#define __MPD_LIB__
#ifdef WIN32
#define __REGEX_IMPORT__ 1
#define __W32API_USE_DLLIMPORT__ 1
#endif

#include "libmpdclient.h"
#include <regex.h>

#ifndef TRUE
/** Defined for readability: True is 1. */
#define TRUE 1
#endif

#ifndef FALSE
/** Defined for readability: False is 0. */
#define FALSE 0
#endif
#include "libmpd-version.h"
extern char *libmpd_version;

/**
 * Enum that represent the errors libmpd functions can return 
 */

typedef enum {
	/** Command/function completed succesfull */
	MPD_OK = 0,
	/** Error in the function's arguments */
	MPD_ARGS_ERROR = -5,
	/** Action failed because there is no connection to an mpd daemon */
	MPD_NOT_CONNECTED = -10,
	/** Failed to grab status*/
	MPD_STATUS_FAILED  = -20,
	/** Connection is still locked	 */
	MPD_LOCK_FAILED  = -30,
	/** Failed to grab status	 */
	MPD_STATS_FAILED = -40,
	/** Mpd server returned an error	 */
	MPD_SERVER_ERROR = -50,
	/** Mpd doesn't support this feature */
	MPD_SERVER_NOT_SUPPORTED = -51,
	
	/**  The playlist allready extists	 */
	MPD_DATABASE_PLAYLIST_EXIST  = -60,
	/** Playlist is empty */
	MPD_PLAYLIST_EMPTY = -70,
	/** Playlist queue is empty */
	MPD_PLAYLIST_QUEUE_EMPTY = -75,
	/** Player isn't Playing */
	MPD_PLAYER_NOT_PLAYING = -80,

	/** Tag ITem not found */
	MPD_TAG_NOT_FOUND = -90,
	
	/** Fatal error, something I am not sure what todo with */
	MPD_FATAL_ERROR = -1000
}MpdError;



/**
 *  The Main Mpd Object. Don't access any of the internal values directly, but use the provided functions.
 */
typedef struct _MpdObj MpdObj;

/**
 *
 * enum that represents the state of a command.
 */
typedef enum {
	MPD_SERVER_COMMAND_ALLOWED = TRUE,
	MPD_SERVER_COMMAND_NOT_ALLOWED = FALSE,
	MPD_SERVER_COMMAND_NOT_SUPPORTED = -1,
	MPD_SERVER_COMMAND_ERROR = -2
} MpdServerCommand;


/**
 * \ingroup MpdData
 * enumeration to determine what value the MpdData structure hold.
 * The MpdData structure can hold only one type of value,
 * but a list of MpdData structs can hold structs with different type of values.
 * It's required to check every MpdData Structure.
 */
typedef enum {
	/** The MpdData structure holds no value*/
	MPD_DATA_TYPE_NONE,
	/** Holds an Tag String. value->tag is filled value->tag_type defines what type of tag.*/
	MPD_DATA_TYPE_TAG,
	/** Holds an Directory String. value->directory is filled.*/
	MPD_DATA_TYPE_DIRECTORY,
	/** Holds an MpdSong Structure. value->song is valid.*/
	MPD_DATA_TYPE_SONG,
	/** Holds an Playlist String. value->playlist is filled.*/
	MPD_DATA_TYPE_PLAYLIST,
	/** Holds an MpdOutputDevice structure. value->output_dev is valid.*/
	MPD_DATA_TYPE_OUTPUT_DEV
} MpdDataType;

/**
 * \ingroup #MpdData
 * A fast linked list that is used to pass data from libmpd to the client.
 */
typedef struct _MpdData {
	/** a #MpdDataType */
	MpdDataType type;
	union {
		struct {
			/** a #mpd_TagType defining what #tag contains */
			int tag_type;
			/** a string containing the tag*/
			char *tag;
		};
		/** a directory */
		char *directory;
		/** a path to a playlist */
		char *playlist;
		/** a  mpd_Song */
		mpd_Song *song;
		/** an output device entity */
		mpd_OutputEntity *output_dev;
	};
} MpdData;


#include "libmpd-player.h"
#include "libmpd-status.h"
#include "libmpd-database.h"
#include "libmpd-playlist.h"
#include "libmpd-strfsong.h"



/**
 * mpd_new_default
 *
 * Create an new #MpdObj with default settings.
 * Hostname will be set to "localhost".
 * Port will be 6600.
 * 
 * same as calling:
 * @code
 * mpd_new("localhost",6600,NULL);
 * @endcode
 *
 * @returns the new #MpdObj
 */
MpdObj *mpd_new_default();



/**
 * @param hostname The hostname to connect to
 * @param port The port to connect to
 * @param password The password to use for the connection, or NULL for no password
 *
 * Create a new #MpdObj with provided settings:
 *
 * @returns the new #MpdObj
 */

MpdObj *mpd_new(char *hostname, int port, char *password);


	
/**
 *@param mi a #MpdObj
 *@param hostname The new hostname to use
 *
 * set the hostname
 *
 * @returns a #MpdError. (#MPD_OK if everything went ok)
 */
int mpd_set_hostname(MpdObj * mi, char *hostname);

/** 
 * @param mi a #MpdObj
 *
 * gets the set hostname 
 * returns: a const char
 */
const char * mpd_get_hostname(MpdObj *mi);
	
/**
 * @param mi a #MpdObj
 * @param password The new password to use
 *
 * Set the password
 *
 * @returns a #MpdError. (#MPD_OK if everything went ok)
 */
int mpd_set_password(MpdObj * mi, char *password);
	
	
/**
 * @param mi a #MpdObj
 * @param port The port to use. (Default: 6600)
 *
 * Set the Port number
 *
 *
 * @returns a #MpdError. (#MPD_OK if everything went ok)
 */
int mpd_set_port(MpdObj * mi, int port);



	
/**
 * @param mi a #MpdObj
 * @param timeout: A timeout (in seconds)
 *
 * Set the timeout of the connection.
 * If allready connected the timeout of the running connection
 *
 * @returns a #MpdError. (MPD_OK if everything went ok)
 */
int mpd_set_connection_timeout(MpdObj * mi, float timeout);


	
/**
 * @param mi a #MpdObj
 *
 * Connect to the mpd daemon.
 * Warning: mpd_connect connects anonymous, to authentificate use #mpd_send_password
 * 
 * @returns returns a #MpdError, MPD_OK when successful
 */
int mpd_connect(MpdObj * mi);

	
/**
 * @param mi The #MpdObj to disconnect
 *
 * Disconnect the current connection
 * @returns MPD_OK (always)
 */
int mpd_disconnect(MpdObj * mi);

	
	
/**
 * @param mi	a #MpdObj
 *
 * Checks if #MpdObj is connected
 * @returns True when connected
 */
int mpd_check_connected(MpdObj * mi);

	
	
/**
 * @param mi a #MpdObj
 *
 * Checks if there was an error
 * @returns True when there is an error
 */
int mpd_check_error(MpdObj * mi);


	
/**
 * @param mi a #MpdObj
 *
 * Free the #MpdObj, when still connected the connection will be disconnected first
 */
void mpd_free(MpdObj * mi);


	
/**
 * @param mi a #MpdObj
 *
 * Forces libmpd to re-authenticate itself.
 * 
 * When succesfull it will trigger the "permission" changed signal.
 *
 * @returns: a #MpdError
 */
int mpd_send_password(MpdObj * mi);

	

/*
 * signals
 */

/**
 * Bitwise enumeration to determine what triggered the status_changed signals
 * This is used in combination with the #StatusChangedCallback
 * @code
 * void status_changed_callback(MpdObj *mi, ChangedStatusType what)
 * {
 *	if(what&MPD_CST_SONGID)
 *	{
 *		// act on song change 
 *
 *	}
 *	if(what&MPD_CST_RANDOM)
 *	{
 *		// act on random change
 *	}
 *	// etc.
 * }
 * @endcode
 */
typedef enum {
	/** The playlist has changed */
	MPD_CST_PLAYLIST      = 0x0001,
	/** The song position of the playing song has changed*/
	MPD_CST_SONGPOS       = 0x0002,
	/** The songid of the playing song has changed */
	MPD_CST_SONGID        = 0x0004,
	/** The database has changed. */
	MPD_CST_DATABASE      = 0x0008,
	/** the state of updating the database has changed.*/
	MPD_CST_UPDATING      = 0x0010,
	/** the volume has changed */
	MPD_CST_VOLUME        = 0x0020,
	/** The total time of the currently playing song has changed*/
	MPD_CST_TOTAL_TIME    = 0x0040,
 	/** The elapsed time of the current song has changed.*/
	MPD_CST_ELAPSED_TIME  = 0x0080,
	/** The crossfade time has changed. */
	MPD_CST_CROSSFADE     = 0x0100,
	/** The random state is changed.     */                 
	MPD_CST_RANDOM        = 0x0200,
	/** repeat state is changed.     */                
	MPD_CST_REPEAT        = 0x0400,
	/** Not implemented  */                                  
	MPD_CST_AUDIO         = 0x0800,
	/** The state of the player has changed.*/               
	MPD_CST_STATE         = 0x1000,
	/** The permissions the client has, has changed.*/  
	MPD_CST_PERMISSION    = 0x2000,
	/** The bitrate of the playing song has changed.    */ 
	MPD_CST_BITRATE       = 0x4000,
	/** the audio format of the playing song changed.*/
	MPD_CST_AUDIOFORMAT   = 0x8000
} ChangedStatusType;


/* callback typedef's */
/**
 * @param mi a #MpdObj
 * @param what a #ChangedStatusType that determines what changed triggered the signal. This is a bitmask.
 * @param userdata user data set when the signal handler was connected.
 * 
 * Signal that get's called when the state of mpd changed. Look #ChangedStatusType to see the possible events.
 */
typedef void (*StatusChangedCallback) (MpdObj * mi, ChangedStatusType what, void *userdata);



	
/**
 * @param mi a #MpdObj
 * @param id The error Code.
 * @param msg human-readable informative error message.
 * @param userdata  user data set when the signal handler was connected.
 * This signal is called when an error has occured in the communication with mpd.
 */
typedef void (*ErrorCallback) (MpdObj * mi, int id, char *msg, void *userdata);


	
/**
 * @param mi a #MpdObj
 * @param connect 1 if you are now connect, 0 if you are disconnect.
 * @param userdata  user data set when the signal handler was connected.
 * Signal is triggered when the connection state changes.
 */

typedef void (*ConnectionChangedCallback) (MpdObj * mi, int connect, void *userdata);



/* new style signal connectors */
/**
 * @param mi a #MpdObj
 * @param status_changed a #StatusChangedCallback
 * @param userdata user data passed to the callback
 */
void mpd_signal_connect_status_changed(MpdObj * mi, StatusChangedCallback status_changed,
					       void *userdata);



/**
 * @param mi a #MpdObj
 * @param error a #ErrorCallback
 * @param userdata user data passed to the callback
 */
void mpd_signal_connect_error(MpdObj * mi, ErrorCallback error, void *userdata);


	
/**
 * @param mi a #MpdObj
 * @param connection_changed a #ConnectionChangedCallback
 * @param userdata user data passed to the callback
 */
void mpd_signal_connect_connection_changed(MpdObj * mi,
						   ConnectionChangedCallback connection_changed,
						   void *userdata);

/*@}*/



/**\defgroup MpdData Data Object
 * This is a fast linked list implementation where data returned from mpd is stored in.
 */

/*@{*/

/**
 * @param data a #MpdData
 *
 * Check's if the passed #MpdData is the last in a list
 * @returns TRUE when data is the last in the list.
 */
int mpd_data_is_last(MpdData const *data);


/**
 * @param data a #MpdData
 *
 * Free's a #MpdData List
 */
void mpd_data_free(MpdData * data);


	
/**
 * @param data a #MpdData
 *
 * Returns the next #MpdData in the list.
 * If it's the last item in the list, it will free the list.
 *
 * You can itterate through a list like this and have it free'ed afterwards.
 * @code
 *	for(data = mpd_database_get_albums(mi);data != NULL; data = mpd_data_get_next(data))
 *	{
 *		// do your thing
 *	}
 * @endcode
 * @returns The next #MpdData or %NULL
 */
MpdData *mpd_data_get_next(MpdData * data);


	

/**
 * @param data a #MpdData
 *
 * Returns the first #MpdData in the list.
 *
 * @returns The first #MpdData or %NULL
 */
MpdData *mpd_data_get_first(MpdData const *data);


	
/**
 * @param data a #MpdData item
 *
 * removes the passed #MpdData from the underlying list, and returns the element before data
 *
 * @returns a #MpdData list
 */
MpdData *mpd_data_delete_item(MpdData * data);


	
/*@}*/

	
/** \defgroup Server Server
 * Functions to get information about the mpd daemon and or modify it.
 */
/*@{*/

	
/**
 * @param mi a #MpdObj
 *
 * Returns a list of audio output devices stored in a #MpdData list
 *
 * @returns a #MpdData
 */
MpdData *mpd_server_get_output_devices(MpdObj * mi);


	
/**
 * @param mi a #MpdObj
 * @param device_id The id of the output device
 * @param state The state to change the output device to, 1 is enable, 0 is disable.
 *
 * Enable or Disable an audio output device
 *
 * @returns 0 if successful
 */
int mpd_server_set_output_device(MpdObj * mi, int device_id, int state);


	
/**
 * @param mi a #MpdObj
 *
 * Get's a unix timestamp of the last time the database was updated.
 *
 * @returns unix Timestamp
 */
long unsigned mpd_server_get_database_update_time(MpdObj * mi);


	
/**
 * @param mi a #MpdObj
 * @param major the major version number
 * @param minor the minor version number
 * @param micro the micro version number
 *
 * Checks if the connected mpd server version is equal or higer.
 *
 * @returns #TRUE when version of mpd equals or is higher, else #FALSE
 */
int mpd_server_check_version(MpdObj * mi, int major, int minor, int micro);

/**
 * @param mi a #MpdObj
 *
 * @return a string with version or NULL when not connected
 */

char *mpd_server_get_version(MpdObj *mi);
/**
 * @param mi a #MpdObj
 * @param command the command to check
 *
 * Checks if the user is allowed to execute the command and if the server supports it
 *
 * @returns Returns #MpdServerCommand
 */
int mpd_server_check_command_allowed(MpdObj * mi, const char *command);

/*@}*/

	
/** \defgroup Misc Misc
 * Helper functions.
 */
/*@{*/


/**
 * @param string A NULL terminated string
 *
 * Splits a string in tokens while keeping ()[] in tact.
 * This can be used to match a string tokenized
 * and with regex support agains a user defined string.
 *
 * @returns An array of regex patterns
 */
regex_t **mpd_misc_tokenize(char *string);


/**
 * @param tokens an array of regex patterns.
 *
 * Free's a list of regex patterns
 */
void mpd_misc_tokens_free(regex_t ** tokens);


/**
 * @param name a NULL terminated string
 *
 * gets the Matching #MpdDataType matching at the string
 *
 * @returns a #MpdDataType
 */
int mpd_misc_get_tag_by_name(char *name);


/*@}*/
#endif

#ifdef __cplusplus
}
#endif
