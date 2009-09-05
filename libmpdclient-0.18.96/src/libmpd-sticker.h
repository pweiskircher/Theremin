#ifndef __LIBMPD_STICKER_H__
#define __LIBMPD_STICKER_H__


char * mpd_sticker_song_get(MpdObj *mi, const char *path, const char *tag);

int mpd_sticker_song_set(MpdObj *mi, const char *path, const char *tag, const char *value);


int mpd_sticker_supported ( MpdObj *mi);
#endif
