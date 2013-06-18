#import "MXMChartLoader.h"
#import "MXMRequest.h"
#import "MXMTrack.h"
#import "GDataXMLNode.h"

@implementation MXMChartLoader
@synthesize request;
@synthesize delegate;

+(id)loaderWithCountry:(NSString*)_country {
	return [[[MXMChartLoader alloc] initWithCountry:_country] autorelease];
}

-(id)initWithCountry:(NSString*)_country {
	if (self = [super init]) {
		self.request = [MXMRequest requestWithAction:@"track.chart.get" params:[NSDictionary dictionaryWithObjectsAndKeys: @"it", @"country",
																								@"30", @"page_size",
																								@"1", @"f_has_lyrics",
																								nil]];
		self.request.delegate = self;
	}

	return self;
}

- (void)start {
	[self.request start];
}

-(void) mXmRequestDidFinish:(NSData*)data {
	NSError *error = nil;
	GDataXMLDocument *document = [[GDataXMLDocument alloc] initWithData:data options:0 error:&error];
	if (document == nil || error) {
		[self handleError:error];
		return;
	}
	[self parseXMLDocument:document];
	[document release];
}

-(void)parseXMLDocument:(GDataXMLDocument *)document {
	[document retain];
	NSError *error = nil;
	NSArray *trackNodes = [document nodesForXPath:@"//track" error:&error];
	NSMutableArray *tracks = [[NSMutableArray alloc] init];
	for(unsigned i = 0; i < [trackNodes count]; i++) {
		GDataXMLNode *trackNode = [trackNodes objectAtIndex:i];
		NSArray *trackIdNodes = [trackNode nodesForXPath:@"track_id/text()" error:&error];
		NSArray *lyricsIdNodes = [trackNode nodesForXPath:@"lyrics_id/text()" error:&error];
		NSArray *trackNameNodes = [trackNode nodesForXPath:@"track_name/text()" error:&error];
		NSArray *artistIdNodes = [trackNode nodesForXPath:@"artist_id/text()" error:&error];
		NSArray *albumCoverArtNodes = [trackNode nodesForXPath:@"album_coverart_100x100/text()" error:&error];
		NSArray *artistNameNodes = [trackNode nodesForXPath:@"artist_name/text()" error:&error];
		if ([trackIdNodes count] > 0 && [lyricsIdNodes count] > 0 && [trackNameNodes count] > 0 &&
			[artistIdNodes count] > 0 && [albumCoverArtNodes count] > 0 && [artistNameNodes count] > 0) {
			MXMTrack *track = [MXMTrack trackWithTrackId:[[trackIdNodes objectAtIndex:0] stringValue]
										lyricsId:[[lyricsIdNodes objectAtIndex:0] stringValue]
										trackName:[[trackNameNodes objectAtIndex:0] stringValue]
										artistId:[[artistIdNodes objectAtIndex:0] stringValue]
										albumCoverArt:[[albumCoverArtNodes objectAtIndex:0] stringValue]
										artistName:[[artistNameNodes objectAtIndex:0] stringValue]];
			[tracks addObject:track];
		}
	}
	if (self.delegate && [self.delegate respondsToSelector:@selector(mXmChartLoaderDidFinish:)]) {
		[self.delegate mXmChartLoaderDidFinish:tracks];
	}
	[tracks release];
	[document release];
}

-(void) mXmRequestError:(NSError *)error {
	[self handleError:error];
}

-(void)handleError:(NSError *)error {
	if (self.delegate && [self.delegate respondsToSelector:@selector(mXmChartLoaderError:)]) {
		[self.delegate mXmChartLoaderError:error];
	}
}

-(void) cancel {
	if (self.request) {
		[request cancel];
	}
}

-(void) dealloc {
	[self cancel];
	[delegate release];
	[request release];
	[super dealloc];
}

@end
