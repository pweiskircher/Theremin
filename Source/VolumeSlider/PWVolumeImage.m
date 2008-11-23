//
//  PWVolumeImage.m
//  Theremin
//
//  Created by Patrik Weiskircher on 09.06.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "PWVolumeImage.h"
#import "PWVolumeSlider.h"


@implementation PWVolumeImage

- (void) setVolumeSlider:(PWVolumeSlider *)slider {
	mVolume = slider;
}

- (void) mouseDown:(NSEvent *)theEvent {
}

- (void) mouseUp:(NSEvent *)theEvent {
	[mVolume toggleMute];
}

@end