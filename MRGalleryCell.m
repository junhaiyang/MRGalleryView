//
//  MRGalleryCell.m 
//
//  Created by junhai on 12-12-28.
//  Copyright (c) 2012年 mRocker. All rights reserved.
//

#import "MRGalleryCell.h"
@implementation MRGalleryCell
@synthesize index;
@synthesize identifier;
@synthesize selectionType;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.selectionType=GalleryCellSelectionTypeSelect;
    }
    return self;
}
- (id)init
{
    self = [super init];
    if (self) {
        self.selectionType=GalleryCellSelectionTypeSelect;
    }
    return self;
}
- (id)initWithIdentifier:(NSString*)_identifier
{
	if (self = [super init]){ 
		self.identifier = _identifier;
        self.selectionType=GalleryCellSelectionTypeSelect;
          NSLog(@"%f  %f ",self.frame.size.width, self.frame.size.width);
	}
	return self;
}

- (id)initWithFrame:(CGRect)frame identifier:(NSString*)_identifier
{
    self = [super initWithFrame:frame];
    if (self) {
		self.identifier = _identifier;
        self.selectionType=GalleryCellSelectionTypeSelect;
    }
    return self;
}
@end
