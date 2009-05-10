/*
 Copyright (C) 2009  Patrik Weiskircher
 
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

#import "LibraryOperationQueue.h"
#import "LibraryOperation.h"

#import "SqueezeLibToThereminTransformer.h"
#import "NSArray+Transformations.h"


@interface LibraryOperationQueue (PrivateMethods)
- (void) executeOperation:(LibraryOperation *)aOperation;
- (LibraryOperation *) getOldestOperationWithType:(PWDatabaseQueryEntityType)aType;
- (NSArray *) transformResult:(NSArray *)aResult withType:(PWDatabaseQueryEntityType)aType;
- (void) operationFinished:(LibraryOperation *)aOp;
@end

@implementation LibraryOperationQueue
- (id) initWithServer:(SLSqueezeServer *)aServer {
	self = [super init];
	if (self != nil) {
		_server = [aServer retain];
		_operations = [[NSMutableArray array] retain];
	}
	return self;
}

- (void) dealloc
{
	[_server release];
	[_operations release];
	[super dealloc];
}

- (void) queueOperationWithType:(PWDatabaseQueryEntityType)aType andFilters:(NSArray *)someFilters usingTarget:(id)aTarget andSelector:(SEL)aSel {
	LibraryOperation *op = [LibraryOperation libraryOperationUsingType:aType andFilters:someFilters andTarget:aTarget andSelector:aSel];
	
	BOOL executeNow = [self getOldestOperationWithType:aType] == nil;
	[_operations addObject:op];
	
	if (executeNow)
		[self executeOperation:op];
}

- (void) databaseQuery:(PWDatabaseQuery *)query finished:(NSArray *)result {
	LibraryOperation *op = [self getOldestOperationWithType:[query type]];
	if (op == nil) {
		[NSException raise:NSInternalInconsistencyException format:@"Unknown library operation finished."];
	}
	
	NSArray *transformedResult = [self transformResult:result withType:[query type]];
	[op reportResult:transformedResult];
	
	[self operationFinished:op];
}

@end

@implementation LibraryOperationQueue (PrivateMethods)
- (NSArray *) transformResult:(NSArray *)aResult withType:(PWDatabaseQueryEntityType)aType {
	switch (aType) {
		case PWDatabaseQueryEntityTypeArtist:
			return [aResult arrayByApplyingTransformationUsingTarget:[SqueezeLibToThereminTransformer class] andSelector:@selector(slArtistToArtistTransform:)];
		case PWDatabaseQueryEntityTypeAlbum:
			return [aResult arrayByApplyingTransformationUsingTarget:[SqueezeLibToThereminTransformer class] andSelector:@selector(slAlbumToAlbumTransform:)];
		case PWDatabaseQueryEntityTypeGenre:
			return [aResult arrayByApplyingTransformationUsingTarget:[SqueezeLibToThereminTransformer class] andSelector:@selector(slGenreToGenreTransform:)];
		case PWDatabaseQueryEntityTypeTitle:
			return [aResult arrayByApplyingTransformationUsingTarget:[SqueezeLibToThereminTransformer class] andSelector:@selector(slTitleToSongTransform:)];
	}
	[NSException raise:NSInternalInconsistencyException format:@"Unknown type %d", aType];
	return nil;
}

- (void) executeOperation:(LibraryOperation *)aOperation {
	[_server executeDatabaseQueryForType:[aOperation type] usingFilters:[aOperation filters]];
}

- (LibraryOperation *) getOldestOperationWithType:(PWDatabaseQueryEntityType)aType {
	for (int i = 0; i < [_operations count]; i++) {
		LibraryOperation *op = [_operations objectAtIndex:i];
		if ([op type] == aType)
			return op;
	}
	return nil;
}

- (void) operationFinished:(LibraryOperation *)aOp {
	PWDatabaseQueryEntityType type = [aOp type];
	
	[_operations removeObject:aOp];
	
	LibraryOperation *op = [self getOldestOperationWithType:type];
	if (op != nil) {
		[self executeOperation:op];
	}
}
@end