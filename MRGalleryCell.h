//
//  MRGalleryCell.h 
//
//  Created by junhai on 12-12-28.
//  Copyright (c) 2012年 mRocker. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, GalleryCellSelectionType) {
    GalleryCellSelectionTypeNone,
    GalleryCellSelectionTypeSelect
};

@interface MRGalleryCell : UIView{


}
@property (nonatomic,assign) NSInteger index;  //位置编号
@property (nonatomic) NSString *identifier;
@property (nonatomic,assign) GalleryCellSelectionType selectionType;


- (id)initWithIdentifier:(NSString*)_identifier;

- (id)initWithFrame:(CGRect)frame identifier:(NSString*)_identifier;

@end
