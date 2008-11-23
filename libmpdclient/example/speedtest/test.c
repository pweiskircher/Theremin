#include "libmpd.h"
#include "debug_printf.h"
#include <stdio.h>
#include <stdlib.h>

int main(int argc, char *argv)
{
	MpdObj *obj = mpd_new("192.150.0.50", 6600, "pass");
	debug_set_level(DEBUG_INFO);	
	if(!mpd_connect(obj))
//	for(i=0;i<1000;i++)
	{
		mpd_send_password(obj);
		int id = mpd_playlist_add_get_id(obj, "Sorted/0-K/C/Clapton, Eric/1992 - Unplugged/14 - Rollin' & Tumblin'.flac");
		printf("%i\n", id);
		mpd_player_play_id(obj, id);
	/*	MpdData * data = mpd_playlist_find(obj, MPD_TABLE_ARTIST,"(General)", TRUE);
		while(data != NULL)
		{
			char buffer[1024];
			mpd_song_markup(buffer, 1024,"[%name%: &[%artist% - ]%title%]|%name%|[%artist% - ]%title% &[(%time%)]|%shortfile%", data->song);
			printf("%s\n", buffer);


			data = mpd_data_get_next(data);
		}
*/
	}
	mpd_free(obj);
}
