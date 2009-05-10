/*
 Copyright (C) 2008  Patrik Weiskircher
 
 This program is free software; you can redistribute it and/or
 modify it under the terms of the GNU General Public License
 as published by the Free Software Foundation; either version 2
 of the License, or (at your option) any later version.
 
 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with this program; if not, write to the Free Software
 Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, 
 MA 02110-1301, USA.
 */

#import <Cocoa/Cocoa.h>

@class Profile;

typedef enum {
	eLibraryDataSourceSupportsCustomCompilations = 0x01,
	eLibraryDataSourceSupportsImportingSongs     = 0x02,
	eLibraryDataSourceSupportsMultipleSelection	 = 0x04
} LibraryDataSourceCapabilities;

@protocol LibraryDataSourceProtocol <NSObject>
- (id) initWithProfile:(Profile *)aProfile;
- (Profile *) profile;

- (void) requestAlbumsWithFilters:(NSArray *)theFilters reportToTarget:(id)aTarget andSelector:(SEL)aSelector;
- (void) requestArtistsWithFilters:(NSArray *)theFilters reportToTarget:(id)aTarget andSelector:(SEL)aSelector;
- (void) requestGenresWithFilters:(NSArray *)theFilters reportToTarget:(id)aTarget andSelector:(SEL)aSelector;
- (void) requestSongsWithFilters:(NSArray *)theFilters reportToTarget:(id)aTarget andSelector:(SEL)aSelector;

- (int) supportsDataSourceCapabilities;

@optional
- (void) clear;
- (BOOL) insertSongs:(NSArray *)aArray withDatabaseIdentifier:(NSData *)aIdentifier;
- (BOOL) needsImport;

- (BOOL) setSongsAsCompilation:(NSArray *)aArray;
- (BOOL) removeSongsAsCompilation:(NSArray *)aArray;
- (NSArray *) compilationUniqueIdentifiers;
- (BOOL) setCompilationByUniqueIdentifiers:(NSArray *)uniqueIdentifiers;
@end

@interface LibraryDataSource : NSObject {

}
+ (id<LibraryDataSourceProtocol>) libraryDataSourceForProfile:(Profile *)aProfile;
@end
