#include <libmpd/libmpd.h>
#include <stdio.h>
#include <stdlib.h>

int main(int argc, char *argv)
{
	int i=0;
	MpdObj *obj = mpd_new("192.150.0.111", 6600, NULL);
	if(!mpd_connect(obj))
//	for(i=0;i<1000;i++)
	{
		MpdData *data;
		data = mpd_playlist_get_changes(obj,-1);
		while(data != NULL)
		{
			data = mpd_data_get_next(data);
		}
		mpd_status_update(obj);
		printf("play: %i\n", mpd_server_check_command_allowed(obj, "play"));
		printf("playlist: %i\n", mpd_server_check_command_allowed(obj, "playlist"));
/*		data = mpd_playlist_get_artists(obj);
		while(data != NULL)
		{
			MpdData *dat2 = mpd_playlist_get_albums(obj, data->tag);
			while(dat2 != NULL)
			{
				dat2 = mpd_data_get_next(dat2);
			}
			data = mpd_data_get_next(data);
		}
*/		//mpd_status_update(obj);
/*		data = mpd_server_get_output_devices(obj);
		while(data != NULL)
		{
			

			data = mpd_data_get_next(data);
		}
		mpd_status_update(obj);
		for(i=0; i < 100; i++)
		{		
			mpd_playlist_get_current_song(obj);
			mpd_stats_get_uptime(obj);
			mpd_status_update(obj);
		}

*/		
	}
	mpd_free(obj);
}
