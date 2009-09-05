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

int mpd_player_get_state(MpdObj * mi)
{
	if (!mpd_check_connected(mi)) {
		debug_printf(DEBUG_WARNING, "not connected\n");
		return MPD_NOT_CONNECTED;
	}
	if (mpd_status_check(mi) != MPD_OK) {
		debug_printf(DEBUG_WARNING, "Failed to get status\n");
		return MPD_STATUS_FAILED;
	}
	return mi->status->state;
}
int mpd_player_get_next_song_id(MpdObj *mi)
{
	if (!mpd_check_connected(mi)) {
		debug_printf(DEBUG_WARNING, "not connected\n");
		return MPD_NOT_CONNECTED;
	}
	if (mpd_status_check(mi) != MPD_OK) {
		debug_printf(DEBUG_ERROR, "Failed to get status\n");
		return MPD_STATUS_FAILED;
	}
	/* check if in valid state */
	if (mpd_player_get_state(mi) != MPD_PLAYER_PLAY &&
			mpd_player_get_state(mi) != MPD_PLAYER_PAUSE) {
		return MPD_PLAYER_NOT_PLAYING;
	}
	/* just to be sure check */
	if (!mi->status->playlistLength) {
		return MPD_PLAYLIST_EMPTY;
	}
	return mi->status->nextsongid;
}
int mpd_player_get_next_song_pos(MpdObj *mi)
{
	if (!mpd_check_connected(mi)) {
		debug_printf(DEBUG_WARNING, "not connected\n");
		return MPD_NOT_CONNECTED;
	}
	if (mpd_status_check(mi) != MPD_OK) {
		debug_printf(DEBUG_ERROR, "Failed to get status\n");
		return MPD_STATUS_FAILED;
	}
	/* check if in valid state */
	if (mpd_player_get_state(mi) != MPD_PLAYER_PLAY &&
			mpd_player_get_state(mi) != MPD_PLAYER_PAUSE) {
		return MPD_PLAYER_NOT_PLAYING;
	}
	/* just to be sure check */
	if (!mi->status->playlistLength) {
		return MPD_PLAYLIST_EMPTY;
	}
	return mi->status->nextsong;
}
int mpd_player_get_current_song_id(MpdObj * mi)
{
	if (!mpd_check_connected(mi)) {
		debug_printf(DEBUG_WARNING, "not connected\n");
		return MPD_NOT_CONNECTED;
	}
	if (mpd_status_check(mi) != MPD_OK) {
		debug_printf(DEBUG_ERROR, "Failed to get status\n");
		return MPD_STATUS_FAILED;
	}
	/* check if in valid state */
	if (mpd_player_get_state(mi) != MPD_PLAYER_PLAY &&
			mpd_player_get_state(mi) != MPD_PLAYER_PAUSE) {
		return MPD_PLAYER_NOT_PLAYING;
	}
	/* just to be sure check */
	if (!mi->status->playlistLength) {
		return MPD_PLAYLIST_EMPTY;
	}
	return mi->status->songid;
}

int mpd_player_get_current_song_pos(MpdObj * mi)
{
	if (!mpd_check_connected(mi)) {
		debug_printf(DEBUG_WARNING, "not connected\n");
		return MPD_NOT_CONNECTED;
	}
	if (mpd_status_check(mi)!= MPD_OK) {
		debug_printf(DEBUG_ERROR, "Failed to get status\n");
		return MPD_STATUS_FAILED;
	}
	/* check if in valid state */
	if (mpd_player_get_state(mi) != MPD_PLAYER_PLAY &&
			mpd_player_get_state(mi) != MPD_PLAYER_PAUSE) {
		return MPD_PLAYER_NOT_PLAYING;
	}
	/* just to be sure check */
	if (!mi->status->playlistLength) {
		return MPD_PLAYLIST_EMPTY;
	}
	return mi->status->song;
}

int mpd_player_play_id(MpdObj * mi, int id)
{
	debug_printf(DEBUG_INFO, "trying to play id: %i\n", id);
	if (!mpd_check_connected(mi)) {
		debug_printf(DEBUG_WARNING, "not connected\n");
		return MPD_NOT_CONNECTED;
	}
	if (mpd_lock_conn(mi)) {
		debug_printf(DEBUG_WARNING, "lock failed\n");
		return MPD_LOCK_FAILED;
	}

	mpd_sendPlayIdCommand(mi->connection, id);
	mpd_finishCommand(mi->connection);


	mpd_unlock_conn(mi);
	if (mpd_status_update(mi)) {
		return MPD_STATUS_FAILED;
	}
	return MPD_OK;
}

int mpd_player_play(MpdObj * mi)
{
	return mpd_player_play_id(mi, -1);
}

int mpd_player_stop(MpdObj * mi)
{
	if (!mpd_check_connected(mi)) {
		debug_printf(DEBUG_WARNING, "not connected\n");
		return MPD_NOT_CONNECTED;
	}
	if (mpd_lock_conn(mi)) {
		debug_printf(DEBUG_WARNING, "lock failed\n");
		return MPD_LOCK_FAILED;
	}

	mpd_sendStopCommand(mi->connection);
	mpd_finishCommand(mi->connection);


	mpd_unlock_conn(mi);
	if (mpd_status_update(mi)) {
		return MPD_STATUS_FAILED;
	}
	return MPD_OK;
}

int mpd_player_next(MpdObj * mi)
{
	if (!mpd_check_connected(mi)) {
		debug_printf(DEBUG_WARNING, "not connected\n");
		return MPD_NOT_CONNECTED;
	}
	if (mpd_lock_conn(mi)) {
		debug_printf(DEBUG_WARNING, "lock failed\n");
		return MPD_LOCK_FAILED;
	}

	mpd_sendNextCommand(mi->connection);
	mpd_finishCommand(mi->connection);


	mpd_unlock_conn(mi);
	if (mpd_status_update(mi)) {
		return MPD_STATUS_FAILED;
	}
	return MPD_OK;
}

int mpd_player_prev(MpdObj * mi)
{
	if (!mpd_check_connected(mi)) {
		debug_printf(DEBUG_WARNING, "not connected\n");
		return MPD_NOT_CONNECTED;
	}
	if (mpd_lock_conn(mi)) {
		debug_printf(DEBUG_WARNING, "lock failed\n");
		return MPD_LOCK_FAILED;
	}

	mpd_sendPrevCommand(mi->connection);
	mpd_finishCommand(mi->connection);


	mpd_unlock_conn(mi);
	if (mpd_status_update(mi)) {
		return MPD_STATUS_FAILED;
	}
	return MPD_OK;
}


int mpd_player_pause(MpdObj * mi)
{
	if (!mpd_check_connected(mi)) {
		debug_printf(DEBUG_WARNING, "not connected\n");
		return MPD_NOT_CONNECTED;
	}
	if (mpd_lock_conn(mi)) {
		debug_printf(DEBUG_WARNING, "lock failed\n");
		return MPD_LOCK_FAILED;
	}

	if (mpd_player_get_state(mi) == MPD_PLAYER_PAUSE) {
		mpd_sendPauseCommand(mi->connection, 0);
		mpd_finishCommand(mi->connection);
	} else if (mpd_player_get_state(mi) == MPD_PLAYER_PLAY) {
		mpd_sendPauseCommand(mi->connection, 1);
		mpd_finishCommand(mi->connection);
	}


	mpd_unlock_conn(mi);
	if (mpd_status_update(mi)) {
		return MPD_STATUS_FAILED;
	}
	return MPD_OK;
}

int mpd_player_seek(MpdObj * mi, int sec)
{
	int cur_song = mpd_player_get_current_song_pos(mi);
	if (cur_song < 0) {
		debug_printf(DEBUG_ERROR, "mpd_player_get_current_song_pos returned error\n");
		return cur_song;
	}
	if (!mpd_check_connected(mi)) {
		debug_printf(DEBUG_WARNING, "not connected\n");
		return MPD_NOT_CONNECTED;
	}
	if (mpd_lock_conn(mi)) {
		debug_printf(DEBUG_WARNING, "lock failed\n");
		return MPD_LOCK_FAILED;
	}

	debug_printf(DEBUG_INFO, "seeking in song %i to %i sec\n", cur_song, sec);

	mpd_sendSeekCommand(mi->connection, cur_song, sec);
	mpd_finishCommand(mi->connection);


	mpd_unlock_conn(mi);
	if (mpd_status_update(mi)) {
		return MPD_STATUS_FAILED;
	}
	return MPD_OK;
}

int mpd_player_get_consume(MpdObj * mi)
{
	if (!mpd_check_connected(mi)) {
		debug_printf(DEBUG_WARNING, "not connected\n");
		return MPD_NOT_CONNECTED;
	}
	if (mpd_status_check(mi) != MPD_OK) {
		debug_printf(DEBUG_WARNING, "Failed grabbing status\n");
		return MPD_NOT_CONNECTED;
	}
	return mi->status->consume;
}
int mpd_player_set_single(MpdObj * mi, int single)
{
	if (!mpd_check_connected(mi)) {
		debug_printf(DEBUG_WARNING, "not connected\n");
		return MPD_NOT_CONNECTED;
	}
	if (mpd_lock_conn(mi)) {
		debug_printf(DEBUG_WARNING, "lock failed\n");
		return MPD_LOCK_FAILED;
	}
	mpd_sendSingleCommand(mi->connection, single);
	mpd_finishCommand(mi->connection);

	mpd_unlock_conn(mi);
	mpd_status_queue_update(mi);
	return MPD_OK;
}
int mpd_player_get_single(MpdObj * mi)
{
	if (!mpd_check_connected(mi)) {
		debug_printf(DEBUG_WARNING, "not connected\n");
		return MPD_NOT_CONNECTED;
	}
	if (mpd_status_check(mi) != MPD_OK) {
		debug_printf(DEBUG_WARNING, "Failed grabbing status\n");
		return MPD_NOT_CONNECTED;
	}
	return mi->status->single;
}
int mpd_player_set_consume(MpdObj * mi, int consume)
{
	if (!mpd_check_connected(mi)) {
		debug_printf(DEBUG_WARNING, "not connected\n");
		return MPD_NOT_CONNECTED;
	}
	if (mpd_lock_conn(mi)) {
		debug_printf(DEBUG_WARNING, "lock failed\n");
		return MPD_LOCK_FAILED;
	}
	mpd_sendConsumeCommand(mi->connection, consume);
	mpd_finishCommand(mi->connection);

	mpd_unlock_conn(mi);
	mpd_status_queue_update(mi);
	return MPD_OK;
}


int mpd_player_get_repeat(MpdObj * mi)
{
	if (!mpd_check_connected(mi)) {
		debug_printf(DEBUG_WARNING, "not connected\n");
		return MPD_NOT_CONNECTED;
	}
	if (mpd_status_check(mi) != MPD_OK) {
		debug_printf(DEBUG_WARNING, "Failed grabbing status\n");
		return MPD_NOT_CONNECTED;
	}
	return mi->status->repeat;
}


int mpd_player_set_repeat(MpdObj * mi, int repeat)
{
	if (!mpd_check_connected(mi)) {
		debug_printf(DEBUG_WARNING, "not connected\n");
		return MPD_NOT_CONNECTED;
	}
	if (mpd_lock_conn(mi)) {
		debug_printf(DEBUG_WARNING, "lock failed\n");
		return MPD_LOCK_FAILED;
	}
	mpd_sendRepeatCommand(mi->connection, repeat);
	mpd_finishCommand(mi->connection);

	mpd_unlock_conn(mi);
	mpd_status_queue_update(mi);
	return MPD_OK;
}



int mpd_player_get_random(MpdObj * mi)
{
	if (!mpd_check_connected(mi)) {
		debug_printf(DEBUG_WARNING, "not connected\n");
		return MPD_NOT_CONNECTED;
	}
	if (mpd_status_check(mi) != MPD_OK) {
		debug_printf(DEBUG_WARNING, "Failed grabbing status\n");
		return MPD_NOT_CONNECTED;
	}
	return mi->status->random;
}


int mpd_player_set_random(MpdObj * mi, int random)
{
	if (!mpd_check_connected(mi)) {
		debug_printf(DEBUG_WARNING, "not connected\n");
		return MPD_NOT_CONNECTED;
	}
	if (mpd_lock_conn(mi)) {
		debug_printf(DEBUG_WARNING, "lock failed\n");
		return MPD_LOCK_FAILED;
	}
	mpd_sendRandomCommand(mi->connection, random);
	mpd_finishCommand(mi->connection);

	mpd_unlock_conn(mi);
	mpd_status_queue_update(mi);
	return MPD_OK;
}
