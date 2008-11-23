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

int mpd_stats_update_real(MpdObj *mi, ChangedStatusType* what_changed);

int mpd_status_queue_update(MpdObj *mi)
{

	if(!mpd_check_connected(mi))
	{
		debug_printf(DEBUG_INFO,"Where not connected\n");
		return MPD_NOT_CONNECTED;
	}
	if(mi->status != NULL)
	{
		mpd_freeStatus(mi->status);
		mi->status = NULL;
	}
	return MPD_OK;
}


int mpd_status_update(MpdObj *mi)
{
	ChangedStatusType what_changed=0;
	if(!mpd_check_connected(mi))
	{
		debug_printf(DEBUG_INFO,"Where not connected\n");
		return MPD_NOT_CONNECTED;
	}
	if(mpd_lock_conn(mi))
	{
		debug_printf(DEBUG_ERROR,"lock failed\n");
		return MPD_LOCK_FAILED;
	}


	if(mi->status != NULL)
	{
		mpd_freeStatus(mi->status);
		mi->status = NULL;
	}
	mpd_sendStatusCommand(mi->connection);
	mi->status = mpd_getStatus(mi->connection);
	if(mi->status == NULL)
	{
		debug_printf(DEBUG_ERROR,"Failed to grab status from mpd\n");
		mpd_unlock_conn(mi);
		return MPD_STATUS_FAILED;
	}
	if(mpd_unlock_conn(mi))
	{
		debug_printf(DEBUG_ERROR, "Failed to unlock");
		return MPD_LOCK_FAILED;
	}
	/*
	 * check for changes 
	 */
	/* first save the old status */
	memcpy(&(mi->OldState), &(mi->CurrentState), sizeof(MpdServerState));

	/* playlist change */
	if(mi->CurrentState.playlistid != mi->status->playlist)
	{
		/* print debug message */
		debug_printf(DEBUG_INFO, "Playlist has changed!");

		/* We can't trust the current song anymore. so we remove it */
		/* tags might have been updated */
		if(mi->CurrentSong != NULL)
		{
			mpd_freeSong(mi->CurrentSong);
			mi->CurrentSong = NULL;
		}

		/* set MPD_CST_PLAYLIST to be changed */
		what_changed |= MPD_CST_PLAYLIST;

		/* save new id */
		mi->CurrentState.playlistid = mi->status->playlist;
	}


	/* state change */
	if(mi->CurrentState.state != mi->status->state)
	{
		what_changed |= MPD_CST_STATE;
		mi->CurrentState.state = mi->status->state;
	}

	if(mi->CurrentState.songid != mi->status->songid)
	{
		/* print debug message */
		debug_printf(DEBUG_INFO, "Song has changed %i %i!", mi->OldState.songid, mi->status->songid);

		what_changed |= MPD_CST_SONGID;
		/* save new songid */
		mi->CurrentState.songid = mi->status->songid;

	}
	if(mi->CurrentState.songpos != mi->status->song)
	{
		/* print debug message */
		debug_printf(DEBUG_INFO, "Song has changed %i %i!", mi->OldState.songpos, mi->status->song);

		what_changed |= MPD_CST_SONGPOS;
		/* save new songid */
		mi->CurrentState.songpos = mi->status->song;

	}
	
	if(mi->CurrentState.repeat != mi->status->repeat)
	{
		what_changed |= MPD_CST_REPEAT;
		mi->CurrentState.repeat = mi->status->repeat;
	}
	if(mi->CurrentState.random != mi->status->random)
	{
		what_changed |= MPD_CST_RANDOM;
		mi->CurrentState.random = mi->status->random;
	}
	if(mi->CurrentState.volume != mi->status->volume)
	{
		what_changed |= MPD_CST_VOLUME;
		mi->CurrentState.volume = mi->status->volume;
	}
	if(mi->CurrentState.xfade != mi->status->crossfade)
	{
		what_changed |= MPD_CST_CROSSFADE;
		mi->CurrentState.xfade = mi->status->crossfade;
	}
	if(mi->CurrentState.totaltime != mi->status->totalTime)
	{
		what_changed |= MPD_CST_TOTAL_TIME;
		mi->CurrentState.totaltime = mi->status->totalTime;
	}
	if(mi->CurrentState.elapsedtime != mi->status->elapsedTime)
	{
		what_changed |= MPD_CST_ELAPSED_TIME;
		mi->CurrentState.elapsedtime = mi->status->elapsedTime;
	}

	/* Check if bitrate changed, happens with vbr encodings. */
	if(mi->CurrentState.bitrate != mi->status->bitRate)
	{
		what_changed |= MPD_CST_BITRATE;
		mi->CurrentState.bitrate = mi->status->bitRate;
	}

	/* The following 3 probly only happen on a song change, or is it possible in one song/stream? */
	/* Check if the sample rate changed */
	if(mi->CurrentState.samplerate != mi->status->sampleRate)
	{
		what_changed |= MPD_CST_AUDIOFORMAT;
		mi->CurrentState.samplerate = mi->status->sampleRate;
	}
	
	/* check if the sampling depth changed */
	if(mi->CurrentState.bits != mi->status->bits)
	{
		what_changed |= MPD_CST_AUDIOFORMAT;
		mi->CurrentState.bits = mi->status->bits;
	}
	
	/* Check if the amount of audio channels changed */
	if(mi->CurrentState.channels != mi->status->channels)
	{
		what_changed |= MPD_CST_AUDIOFORMAT;
		mi->CurrentState.channels = mi->status->channels;
	}

	/* Check if the updating changed,
	 * If it stopped, also update the stats for the new db-time.
	 */
	if(mi->CurrentState.updatingDb != mi->status->updatingDb )
	{
		what_changed |= MPD_CST_UPDATING;
		
		// as soon as mpd says its no longer updating, we check the stats
		if(mi->status->updatingDb == 0)
		{
			mpd_stats_update_real(mi, &what_changed);
		}
		mi->CurrentState.updatingDb = mi->status->updatingDb;
	}

	/* Run the callback */
	if((mi->the_status_changed_callback != NULL) && what_changed)
	{
		mi->the_status_changed_callback( mi, what_changed, mi->the_status_changed_signal_userdata );
	}

	/* We could have lost connection again during signal handling... so before we return check again if we are connected */
	if(!mpd_check_connected(mi))
	{
		return MPD_NOT_CONNECTED;
	}
	return MPD_OK;
}

/* returns TRUE when status is availible, when not availible and connected it tries to grab it */
int mpd_status_check(MpdObj *mi)
{
	if(!mpd_check_connected(mi))
	{
		debug_printf(DEBUG_INFO,"not connected\n");
		return MPD_NOT_CONNECTED;
	}
	if(mi->status == NULL)
	{
		/* try to update */
		if(mpd_status_update(mi))
		{
			debug_printf(DEBUG_INFO, "failed to update status\n");
			return MPD_STATUS_FAILED;
		}
	}
	return MPD_OK;
}


int mpd_stats_get_total_songs(MpdObj *mi)
{
	if(mi == NULL)
	{
		debug_printf(DEBUG_ERROR, "failed to check mi == NULL\n");
		return MPD_ARGS_ERROR;
	}
	if(mpd_stats_check(mi) != MPD_OK) 
	{
		debug_printf(DEBUG_ERROR,"Failed to get status\n");
		return MPD_STATUS_FAILED;
	}
	return mi->stats->numberOfSongs;
}

int mpd_stats_get_total_artists(MpdObj *mi)
{
	if(mi == NULL)
	{
		debug_printf(DEBUG_ERROR, "failed to check mi == NULL\n");
		return MPD_ARGS_ERROR;
	}
	if(mpd_stats_check(mi) != MPD_OK)
	{
		debug_printf(DEBUG_ERROR,"Failed to get status\n");
		return MPD_STATS_FAILED;
	}
	return mi->stats->numberOfArtists;
}

int mpd_stats_get_total_albums(MpdObj *mi)
{
	if(mi == NULL)
	{
		debug_printf(DEBUG_ERROR,"failed to check mi == NULL\n");
		return MPD_ARGS_ERROR;
	}
	if(mpd_stats_check(mi) != MPD_OK)
	{
		debug_printf(DEBUG_WARNING,"Failed to get status\n");
		return MPD_STATS_FAILED;
	}
	return mi->stats->numberOfAlbums;
}


int mpd_stats_get_uptime(MpdObj *mi)
{
	if(mi == NULL)
	{
		debug_printf(DEBUG_ERROR,"failed to check mi == NULL\n");
		return MPD_ARGS_ERROR;
	}
	if(mpd_stats_check(mi) != MPD_OK)
	{
		debug_printf(DEBUG_WARNING,"Failed to get status\n");
		return MPD_STATS_FAILED;
	}
	return mi->stats->uptime;
}

int mpd_stats_get_playtime(MpdObj *mi)
{
	if(mi == NULL)
	{
		debug_printf(DEBUG_ERROR, "failed to check mi == NULL\n");
		return MPD_ARGS_ERROR;
	}
	if(mpd_stats_check(mi) != MPD_OK)
	{
		debug_printf(DEBUG_WARNING,"Failed to get status\n");
		return MPD_STATS_FAILED;
	}
	return mi->stats->playTime;
}

int mpd_stats_get_db_playtime(MpdObj *mi)
{
	if(mi == NULL)
	{
		debug_printf(DEBUG_ERROR, "failed to check mi == NULL\n");
		return MPD_ARGS_ERROR;
	}
	if(mpd_stats_check(mi) != MPD_OK)
	{
		debug_printf(DEBUG_WARNING,"Failed to get stats\n");
		return MPD_STATS_FAILED;
	}
	return mi->stats->dbPlayTime;
}

















int mpd_status_get_volume(MpdObj *mi)
{
	if(mi == NULL)
	{
		debug_printf(DEBUG_ERROR, "failed to check mi == NULL\n");
		return MPD_ARGS_ERROR;
	}
	if(mpd_status_check(mi) != MPD_OK)
	{
		debug_printf(DEBUG_WARNING, "Failed to get status\n");
		return MPD_STATUS_FAILED;
	}
	return mi->status->volume;
}


int mpd_status_get_bitrate(MpdObj *mi)
{
	if(mi == NULL)
	{
		debug_printf(DEBUG_ERROR,"failed to check mi == NULL\n");
		return MPD_ARGS_ERROR;
	}
	if(mpd_status_check(mi) != MPD_OK)
	{
		debug_printf(DEBUG_WARNING, "Failed to get status\n");
		return MPD_STATUS_FAILED;
	}
	return mi->CurrentState.bitrate;
}

int mpd_status_get_channels(MpdObj *mi)
{
	if(mi == NULL)
	{
		debug_printf(DEBUG_ERROR,"failed to check mi == NULL\n");
		return MPD_ARGS_ERROR;
	}
	if(mpd_status_check(mi) != MPD_OK)
	{
		debug_printf(DEBUG_WARNING, "Failed to get status\n");
		return MPD_STATUS_FAILED;
	}
	return mi->CurrentState.channels;
}

unsigned int mpd_status_get_samplerate(MpdObj *mi)
{
	if(mi == NULL)
	{
		debug_printf(DEBUG_ERROR,"failed to check mi == NULL\n");
		return MPD_ARGS_ERROR;
	}
	if(mpd_status_check(mi) != MPD_OK)
	{
		debug_printf(DEBUG_WARNING, "Failed to get status\n");
		return MPD_STATUS_FAILED;
	}
	return mi->CurrentState.samplerate;
}

int mpd_status_get_bits(MpdObj *mi)
{
	if(mi == NULL)
	{
		debug_printf(DEBUG_WARNING,"failed to check mi == NULL\n");
		return MPD_ARGS_ERROR;
	}
	if(mpd_status_check(mi) != MPD_OK)
	{
		debug_printf(DEBUG_WARNING, "Failed to get status\n");
		return MPD_STATUS_FAILED;
	}
	return mi->CurrentState.bits;
}

/* TODO: error checking might be nice? */
int mpd_status_db_is_updating(MpdObj *mi)
{
	return mi->CurrentState.updatingDb;
}


int mpd_status_get_total_song_time(MpdObj *mi)
{
	if(!mpd_check_connected(mi))
	{
		debug_printf(DEBUG_ERROR, "failed to check mi == NULL\n");
		return MPD_ARGS_ERROR;
	}
	if(mpd_status_check(mi) != MPD_OK)
	{
		debug_printf(DEBUG_WARNING, "Failed to get status\n");
		return MPD_STATUS_FAILED;
	}
	return mi->status->totalTime;
}


int mpd_status_get_elapsed_song_time(MpdObj *mi)
{
	if(!mpd_check_connected(mi))
	{
		debug_printf(DEBUG_WARNING,"failed to check mi == NULL\n");
		return MPD_NOT_CONNECTED;
	}
	if(mpd_status_check(mi) != MPD_OK)
	{
		debug_printf(DEBUG_WARNING,"Failed to get status\n");
		return MPD_STATUS_FAILED;
	}
	return mi->status->elapsedTime;
}

int mpd_status_set_volume(MpdObj *mi,int volume)
{
	if(!mpd_check_connected(mi))
	{
		debug_printf(DEBUG_WARNING,"not connected\n");
		return MPD_NOT_CONNECTED;
	}
	/* making sure volume is between 0 and 100 */
	volume = (volume < 0)? 0:(volume>100)? 100:volume;

	if(mpd_lock_conn(mi))
	{
		debug_printf(DEBUG_ERROR,"lock failed\n");
		return MPD_LOCK_FAILED;
	}

	/* send the command */
	mpd_sendSetvolCommand(mi->connection , volume);
	mpd_finishCommand(mi->connection);
	/* check for errors */

	mpd_unlock_conn(mi);
	/* update status, because we changed it */
	mpd_status_queue_update(mi);
	/* return current volume */
	return mpd_status_get_volume(mi);
}

int mpd_status_get_crossfade(MpdObj *mi)
{
	if(!mpd_check_connected(mi))
	{
		debug_printf(DEBUG_WARNING,"not connected\n");
		return MPD_NOT_CONNECTED;
	}
	if(mpd_status_check(mi) != MPD_OK)
	{
		debug_printf(DEBUG_WARNING,"Failed grabbing status\n");
		return MPD_NOT_CONNECTED;
	}
	return mi->status->crossfade;
}

int mpd_status_set_crossfade(MpdObj *mi,int crossfade_time)
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
	mpd_sendCrossfadeCommand(mi->connection, crossfade_time);
	mpd_finishCommand(mi->connection);

	mpd_unlock_conn(mi);
	mpd_status_queue_update(mi);
	return MPD_OK;
}


float mpd_status_set_volume_as_float(MpdObj *mi, float fvol)
{
	int volume = mpd_status_set_volume(mi, (int)(fvol*100.0));
	if(volume > -1)
	{
		return (float)volume/100.0;
	}
	return (float)volume;
}

int mpd_stats_update(MpdObj *mi)
{
	return mpd_stats_update_real(mi, NULL);
}

int mpd_stats_update_real(MpdObj *mi, ChangedStatusType* what_changed)
{
	ChangedStatusType what_changed_here = 0;
	if ( what_changed == NULL ) {
		/* we need to save the current state, because we're called standalone */
		memcpy(&(mi->OldState), &(mi->CurrentState), sizeof(MpdServerState));
	}

	if(!mpd_check_connected(mi))
	{
		debug_printf(DEBUG_INFO,"Where not connected\n");
		return MPD_NOT_CONNECTED;
	}
	if(mpd_lock_conn(mi))
	{
		debug_printf(DEBUG_ERROR,"lock failed\n");
		return MPD_LOCK_FAILED;
	}

	if(mi->stats != NULL)
	{
		mpd_freeStats(mi->stats);
	}
	mpd_sendStatsCommand(mi->connection);
	mi->stats = mpd_getStats(mi->connection);
	if(mi->stats == NULL)
	{
		debug_printf(DEBUG_ERROR,"Failed to grab stats from mpd\n");
	}
	else if(mi->stats->dbUpdateTime != mi->OldState.dbUpdateTime)
	{
		debug_printf(DEBUG_INFO, "database updated\n");
		what_changed_here |= MPD_CST_DATABASE;

		mi->CurrentState.dbUpdateTime = mi->stats->dbUpdateTime;
	}

	if (what_changed) {
		(*what_changed) |= what_changed_here;
	} else {
		if((mi->the_status_changed_callback != NULL) & what_changed_here)
		{
			mi->the_status_changed_callback(mi, what_changed_here, mi->the_status_changed_signal_userdata);
		}
	}

	if(mpd_unlock_conn(mi))
	{
		debug_printf(DEBUG_ERROR, "unlock failed");
		return MPD_LOCK_FAILED;
	}
	return MPD_OK;
}


int mpd_stats_check(MpdObj *mi)
{
	if(!mpd_check_connected(mi))
	{
		debug_printf(DEBUG_WARNING,"not connected\n");
		return MPD_NOT_CONNECTED;
	}
	if(mi->stats == NULL)
	{
		/* try to update */
		if(mpd_stats_update(mi))
		{
			debug_printf(DEBUG_ERROR,"failed to update status\n");
			return MPD_STATUS_FAILED;
		}
	}
	return MPD_OK;
}
