//
//  PWVolumeImage.h
//  Theremin
//
//  Created by Patrik Weiskircher on 09.06.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class PWVolumeSlider;

@interface PWVolumeImage : NSImageView {
	PWVolumeSlider *mVolume;
}
- (void) setVolumeSlider:(PWVolumeSlider *)slider;
@end