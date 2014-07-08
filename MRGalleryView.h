//
//  MRGalleryView.h 
//
//  Created by junhai on 12-12-28.
//  Copyright (c) 2012年 mRocker. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MRGalleryCell.h"

@protocol MRGalleryViewDataSource;
@protocol MRGalleryViewDelegate;

@interface MRGalleryView : UIView

@property (nonatomic,assign) BOOL pagingEnabled; 

@property (nonatomic,weak) id<MRGalleryViewDataSource> dataSource;
@property (nonatomic,weak) id<MRGalleryViewDelegate>   delegate;
  
@property (nonatomic,assign) BOOL bounces;

@property (nonatomic,assign) NSInteger currentRow;

@property (nonatomic,assign) CGFloat sideBarWidth;    //间距

@property (nonatomic,assign,readonly) BOOL isScroll;

- (void)reloadData;                                                             //刷新整个cell

- (void)reloadDataAtIndex:(NSInteger)index;                                     //刷新cell并显示到指定row

- (void)reloadDataAtIndex:(NSInteger)index cell:(MRGalleryCell *)cell;          //刷新cell并显示到指定row

- (void)removeCellAtIndex:(NSInteger)index  animation:(BOOL)animation;          //删除一个cell 

- (void)insertCellAtIndex:(NSInteger)index  animation:(BOOL)animation;          //TODO，插入一个cell

- (void)scrollToIndex:(NSInteger)index;                                         //滑动指定cell居中显示
 
- (MRGalleryCell *)dequeueReusableCellWithIdentifier:(NSString*)identifier;     //从回收站中获取一个cell

- (MRGalleryCell *)cellAtRow:(NSInteger)row;        //获取某个位置的cell

- (NSArray *)visibleCells;               //可见cell

- (void)clearInvisibleCells;             //清理不可见的cell

- (void)resizeGalleryRect:(CGRect)rect;  //重新定义GalleryView的大小并且刷新整个cell布局方式
 
@end

@protocol MRGalleryViewDataSource <NSObject>

@required

- (NSInteger)numberOfRowsInGalleryView:(MRGalleryView *)GalleryView; 

- (MRGalleryCell *)galleryView:(MRGalleryView *)galleryView cellAtRow:(NSInteger)row;

- (CGFloat)galleryView:(MRGalleryView *)galleryView widthForRow:(NSInteger)row;

@optional

- (void)galleryViewDidLoadStart;

- (void)galleryViewDidLoadFinished;

- (void)galleryViewDidScrollStart;    //界面滑动开始后回调方法
- (void)galleryViewDidScrollEnd;    //界面滑动完成后回调方法

- (void)galleryViewNotAnyCell:(MRGalleryView *)galleryView ;
 
@end
 
@protocol MRGalleryViewDelegate<NSObject, UIScrollViewDelegate>

@optional


- (void)galleryView:(MRGalleryView *)galleryView didRemoveCell:(MRGalleryCell *)cell isReload:(BOOL)reload;   //cell被移除掉的回调方法，外部可以回收cell中部分数据
- (void)galleryView:(MRGalleryView *)galleryView didSelectRow:(NSInteger)row;
- (void)galleryView:(MRGalleryView *)galleryView cellBoundsChange:(MRGalleryCell *)cell; 

- (void)galleryView:(MRGalleryView *)galleryView showRow:(NSInteger)row;

@end
