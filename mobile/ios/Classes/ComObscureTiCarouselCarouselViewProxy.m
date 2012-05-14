//
//  ComObscureTiCarouselCarouselViewProxy.m
//  ticarousel
//
//  Created by Paul Mietz Egli on 5/10/12.
//  Copyright (c) 2012 Paul Mietz Egli. All rights reserved.
//

#import "ComObscureTiCarouselCarouselViewProxy.h"
#import "ComObscureTiCarouselCarouselView.h"

#define kCarouselEventObjectName @"carousel"
#define kCarouselScrollEvent @"scroll"
#define kCarouselChangeEvent @"change"
#define kCarouselSelectEvent @"select"

NSArray * carouselKeySequence;


@implementation ComObscureTiCarouselCarouselViewProxy

@synthesize horizontalPadding=_horizontalPadding;
@synthesize numberOfVisibleItems=_numberOfVisibleItems;
@synthesize wrap=_wrap;
@synthesize doubleSided=_doubleSided;

- (id)init {
    if (self = [super init]) {
        self.horizontalPadding = 0;
        self.numberOfVisibleItems = 3;
        self.doubleSided = YES;
    }
    return self;
}

- (void)dealloc {
    RELEASE_TO_NIL(carouselKeySequence)

    // clean up views
	pthread_rwlock_destroy(&viewsLock);
	[viewProxies makeObjectsPerformSelector:@selector(setParent:) withObject:nil];
	[viewProxies release];
    [super dealloc];
}

#pragma mark View Management

- (void)lockViews {
	pthread_rwlock_rdlock(&viewsLock);
}

- (void)lockViewsForWriting {
	pthread_rwlock_wrlock(&viewsLock);
}

- (void)unlockViews {
	pthread_rwlock_unlock(&viewsLock);
}

#pragma mark -
#pragma mark Public API

#pragma mark Titanium-specific Methods

- (void)setViews:(id)args {
	ENSURE_ARRAY(args);
	for (id newViewProxy in args) {
		[self rememberProxy:newViewProxy];
		[newViewProxy setParent:self];
        [newViewProxy view].layer.doubleSided = self.doubleSided;
	}
	[self lockViewsForWriting];
	for (id oldViewProxy in viewProxies) {
		if (![args containsObject:oldViewProxy]) {
			[oldViewProxy setParent:nil];
			TiThreadPerformOnMainThread(^{[oldViewProxy detachView];}, NO);
			[self forgetProxy:oldViewProxy];
		}
	}
	[viewProxies autorelease];
	viewProxies = [args mutableCopy];
	[self unlockViews];
	[self replaceValue:args forKey:@"views" notification:YES];
}

// TODO placeholders


#pragma mark iCarousel Methods

// both scrollToItemAtIndex variants are supported:
// - (void)scrollToItemAtIndex:(NSInteger)index animated:(BOOL)animated;
// - (void)scrollToItemAtIndex:(NSInteger)index duration:(NSTimeInterval)scrollDuration;
- (void)scrollToIndex:(id)args {
    [(ComObscureTiCarouselCarouselView *)[self view] scrollToIndex:args];
}

// - (void)scrollByNumberOfItems:(NSInteger)itemCount duration:(NSTimeInterval)duration;
- (void)scrollByNumberOfItems:(id)args {
    [(ComObscureTiCarouselCarouselView *)[self view] scrollByNumberOfItems:args];
}

- (void)reloadData:(id)args {
    [(ComObscureTiCarouselCarouselView *)[self view] reloadData:args];
}

- (id)itemViewAtIndex:(id)args {
    [(ComObscureTiCarouselCarouselView *)[self view] itemViewAtIndex:args];
}

- (id)indexOfItemView:(id)args {
    [(ComObscureTiCarouselCarouselView *)[self view] indexOfItemView:args];
}

- (id)indexOfItemViewOrSubview:(id)args {
    [(ComObscureTiCarouselCarouselView *)[self view] indexOfItemViewOrSubview:args];
}

- (id)offsetForItemAtIndex:(id)args {
    [(ComObscureTiCarouselCarouselView *)[self view] offsetForItemAtIndex:args];
}

- (id)removeItemAtIndex:(id)args {
    [(ComObscureTiCarouselCarouselView *)[self view] removeItemAtIndex:args];
}

- (id)insertItemAtIndex:(id)args {
    [(ComObscureTiCarouselCarouselView *)[self view] insertItemAtIndex:args];
}

- (id)reloadItemAtIndex:(id)args {
    [(ComObscureTiCarouselCarouselView *)[self view] reloadItemAtIndex:args];
}

#pragma mark -
#pragma mark iCarouselDataSource

- (NSUInteger)numberOfItemsInCarousel:(iCarousel *)carousel {
    return [viewProxies count];
}

- (NSUInteger)numberOfVisibleItemsInCarousel:(iCarousel *)carousel {
    return self.numberOfVisibleItems;
}

- (UIView *)carousel:(iCarousel *)carousel viewForItemAtIndex:(NSUInteger)index reusingView:(UIView *)_view {
    // since we build the views in js-land, we don't reuse anything here
    TiViewProxy * proxy = [viewProxies objectAtIndex:index];
    return proxy.view;
}

#pragma mark -
#pragma mark iCarouselDelegate

- (CGFloat)carouselItemWidth:(iCarousel *)carousel {
    NSInteger max = 0;
    for (TiViewProxy * proxy in viewProxies) {
        max = MAX(max, proxy.view.bounds.size.width);
    }
    return max + self.horizontalPadding;
}

- (BOOL)carouselShouldWrap:(iCarousel *)carousel {
    return self.wrap;
}

- (void)carouselDidEndScrollingAnimation:(iCarousel *)carousel {
    NSDictionary * obj = [NSDictionary dictionaryWithObjectsAndKeys:
                          NUMINT(carousel.currentItemIndex), @"currentIndex",
                          nil];
    [self fireEvent:kCarouselScrollEvent withObject:obj];
}

- (void)carouselCurrentItemIndexUpdated:(iCarousel *)carousel {
    NSDictionary * obj = [NSDictionary dictionaryWithObjectsAndKeys:
                          NUMINT(carousel.currentItemIndex), @"currentIndex",
                          nil];
    [self fireEvent:kCarouselChangeEvent withObject:obj];
}

- (void)carousel:(iCarousel *)carousel didSelectItemAtIndex:(NSInteger)index {
    NSDictionary * obj = [NSDictionary dictionaryWithObjectsAndKeys:
                          NUMINT(index), @"selectedIndex",
                          nil];
    [self fireEvent:kCarouselSelectEvent withObject:obj];
}

@end