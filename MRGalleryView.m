//
//  MRGalleryView.m
//
//  Created by junhai on 12-12-28.
//  Copyright (c) 2012年 mRocker. All rights reserved.
//

#import "MRGalleryView.h"

@interface MRGalleryPosition : NSObject

@property (nonatomic,assign) CGFloat x;
@property (nonatomic,assign) CGFloat width;
@property (nonatomic,assign) CGFloat widthWithSideBar;
@property (nonatomic,assign) NSInteger index;

@end

@implementation MRGalleryPosition

@synthesize x,width,index,widthWithSideBar;

@end


@interface MRGalleryView()<UIScrollViewDelegate>{
    
    NSMutableArray *positions;
    
    UIScrollView *container;
    dispatch_queue_t contentQueue;
    
    NSMutableArray *visibleCells;
    NSMutableArray *recycleCells;
    float preX;
    
    NSInteger galleryCount;
}

@property (nonatomic,assign) BOOL dataChangeAnimation;
@property (nonatomic,strong) UIScrollView *container;

@end

@implementation MRGalleryView
@synthesize dataSource;
@synthesize delegate;
@synthesize container;
@synthesize pagingEnabled;
@synthesize bounces;
@synthesize sideBarWidth;

@synthesize currentRow;


#pragma mark - init Method

- (id)init
{
    self = [super init];
    if (self) {
        [self buildView];
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self buildView];
        container.frame=CGRectMake(0, 0, frame.size.width, frame.size.height);
    }
    return self;
}

-(id)initWithCoder:(NSCoder *)aDecoder{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self buildView];
    }
    return self;
}

-(void)setFrame:(CGRect)frame{
    [super setFrame:frame];
    container.frame=CGRectMake(0, 0, frame.size.width+self.sideBarWidth, frame.size.height);
    if(visibleCells.count>0){
        container.contentSize=CGSizeMake(container.contentSize.width, frame.size.height);
        for (MRGalleryCell *cell in visibleCells) {
            CGRect _frame =cell.frame;
            _frame.size.height =frame.size.height;
            _frame.size.width =frame.size.width;
            cell.frame=_frame;
            
            if ([self.delegate respondsToSelector:@selector(galleryView:cellBoundsChange:)]){
                [self.delegate galleryView:self  cellBoundsChange:cell];
            }
            
        }
    }
    
}
-(void)setSideBarWidth:(CGFloat)_sideBarWidth{
    sideBarWidth =_sideBarWidth;
    
    container.frame=CGRectMake(0, 0, self.frame.size.width+_sideBarWidth, self.frame.size.height);
    
}

-(void)setPagingEnabled:(BOOL)_pagingEnabled{
    pagingEnabled=_pagingEnabled;
    container.pagingEnabled=_pagingEnabled;
}

-(void)buildView{
    
#define UIColorFromRGB(rgbValue) [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 green:((float)((rgbValue & 0xFF00) >> 8))/255.0 blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]
    
    positions =[[NSMutableArray alloc] init];
    
    //    self.backgroundColor=[UIColor colorWithPatternImage:[UIImage imageNamed:@"galleryview_bg.png"]];
    self.backgroundColor=UIColorFromRGB(0x2d3132);
    
    self.dataChangeAnimation = NO;
    contentQueue=dispatch_queue_create("com.mrocker.galleryView", nil);
    container=[[UIScrollView alloc] init];
    container.scrollsToTop = NO;
    container.showsVerticalScrollIndicator=YES;
    container.showsHorizontalScrollIndicator=NO;
    container.bounces =NO;
    container.delegate=self;
    [self addSubview:container];
	visibleCells = [[NSMutableArray alloc] init];
    recycleCells = [[NSMutableArray alloc] init];
    galleryCount=0;
}
-(void)setBounces:(BOOL)_bounces{
    bounces =_bounces;
    container.bounces=bounces;
}


#pragma mark - Inner Method

-(void)preparePosition{
    
    galleryCount=[self.dataSource numberOfRowsInGalleryView:self];
    
    float startX=0.0f;
    for (int i=0; i<galleryCount; i++) {
        float iw=[self.dataSource galleryView:self widthForRow:i];
        
        MRGalleryPosition *position =[[MRGalleryPosition alloc] init];
        position.index = i;
        position.width =iw;
        position.widthWithSideBar = iw+self.sideBarWidth;
        position.x = startX;
        
        [positions addObject:position];
        
        startX+=iw+self.sideBarWidth;
    }
    NSLog(@"   ------   self.container.frame.size.height:%f",self.container.frame.size.height);
    
    [self.container setContentSize:CGSizeMake(startX, self.container.frame.size.height)];
    
}

-(void)releaseAllCell{
    for (MRGalleryCell *cell in visibleCells) {
        [cell removeFromSuperview];
        
        if ([self.delegate respondsToSelector:@selector(galleryView:didRemoveCell:isReload:)]){
            [self.delegate galleryView:self didRemoveCell:cell isReload:YES];
        }
        [recycleCells addObject:cell];
    }
    [visibleCells removeObjectsInArray:recycleCells];
}

-(void)loadShowIndexWithCurrentIndex:(NSInteger *)showIndex x:(CGFloat *)x{
    MRGalleryPosition *position =[positions objectAtIndex:self.currentRow];
    
    CGFloat currentCenterX =position.x+position.widthWithSideBar/2.0f;
    
    //最左边
    if(currentCenterX-self.container.frame.size.width/2<0){
        *showIndex=0;
        *x=0;
    }else if(currentCenterX+self.container.frame.size.width/2>self.container.contentSize.width){
        CGFloat startX = self.container.contentSize.width-self.container.frame.size.width;
        
        for (int i=positions.count-1; i>=0; i--) {
            MRGalleryPosition *_position =[positions objectAtIndex:i];
            if(_position.x<=startX){
                *showIndex=i;
                *x=startX;
                break;
            }
        }
        
    }else{
        //中间
        CGFloat startX = currentCenterX-self.container.frame.size.width/2;
        for (int i=self.currentRow; i>=0; i--) {
            MRGalleryPosition *_position =[positions objectAtIndex:i];
            if(_position.x<=startX){
                *showIndex=i;
                *x=startX;
                break;
            }
        }
    }
}


-(void)computePage{
    
    NSInteger showIndex =-1;
    
    CGFloat offsetCenterX =self.container.contentOffset.x +self.container.frame.size.width/2.0f;
    
    for (MRGalleryCell *cell in visibleCells) {
        
        CGFloat _startX = offsetCenterX - cell.frame.size.width/2.0f;
        CGFloat _endX = offsetCenterX + cell.frame.size.width/2.0f;
        
        
        CGFloat cellCenterX = cell.center.x;
        
        
        if(cellCenterX>=_startX&&cellCenterX<=_endX){
            showIndex =cell.index;
            break;
        }
    }
    
    if(showIndex>=0){
        if(self.currentRow!=showIndex){
            self.currentRow =showIndex;
            if ([self.delegate respondsToSelector:@selector(galleryView:showRow:)]){
                [self.delegate galleryView:self showRow:showIndex];
            }
        }
    }
}



-(void)tapCell:(UITapGestureRecognizer *)gestureRecognizer{
    if(gestureRecognizer.view!=nil&&[gestureRecognizer.view isKindOfClass:[MRGalleryCell class]]){
        [self.delegate galleryView:self didSelectRow:((MRGalleryCell *)gestureRecognizer.view).index];
    }
}

-(void)reset{
    [positions removeAllObjects];
}


#pragma mark - Public Method

-(BOOL)isIsScroll{
    return self.container.decelerating||self.container.dragging;
}


-(void)reloadData{
    [self reloadDataAtIndex:self.currentRow cell:nil];
}

- (void)reloadDataAtIndex:(NSInteger)index{
    [self reloadDataAtIndex:index cell:nil];
}

- (void)reloadDataAtIndex:(NSInteger)index cell:(MRGalleryCell *)_cell{
    [self reset];
    
    if([self.dataSource respondsToSelector:@selector(galleryViewDidLoadStart)]){
        [self.dataSource galleryViewDidLoadStart];
    }
    
    self.currentRow = index;
    
    [self releaseAllCell];
    
    [self preparePosition];
    
    if(galleryCount==0){
        if([self.dataSource respondsToSelector:@selector(galleryViewDidLoadFinished)]){
            [self.dataSource galleryViewDidLoadFinished];
        }
        return;
    }
    
    NSInteger showIndex;
    CGFloat   startX;
    
    [self loadShowIndexWithCurrentIndex:&showIndex x:&startX];
    
    CGFloat endX =startX+self.container.frame.size.width;
    
    for (int i=showIndex; i<galleryCount; i++) {
        MRGalleryPosition *position =[positions objectAtIndex:i];
        
        if (position.x>=endX) {
            break;
        }
        MRGalleryCell *cell;
        if(i==index){
            cell = _cell;
        }
        if(!cell)
            cell=[self.dataSource galleryView:self cellAtRow:i];
        
        cell.frame=CGRectMake(position.x, 0, position.width, self.container.frame.size.height);
        cell.index=i;
        if(cell.selectionType==GalleryCellSelectionTypeSelect){
            UITapGestureRecognizer *tapGestureRecognizer=[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapCell:)];
            tapGestureRecognizer.numberOfTapsRequired=1;
            [cell addGestureRecognizer:tapGestureRecognizer];
        }
        [self.container addSubview:cell];
        [self.container sendSubviewToBack:cell];
        
        [visibleCells addObject:cell];
    }
    
    NSLog(@"---startX:%f",startX);
    [self.container setContentOffset:CGPointMake(startX, 0)];
    
    if([self.dataSource respondsToSelector:@selector(galleryViewDidLoadFinished)]){
        [self.dataSource galleryViewDidLoadFinished];
    }
}

- (void)removeCellAtIndex:(NSInteger)_index  animation:(BOOL)animation{
    self.dataChangeAnimation = YES;
    
    if(galleryCount==0)
        return;
    
    if([self.dataSource respondsToSelector:@selector(galleryViewDidLoadStart)]){
        [self.dataSource galleryViewDidLoadStart];
    }
    
    //删除并回收要删除的cell
    MRGalleryPosition *removePosition =[positions objectAtIndex:_index];
    [positions removeObjectAtIndex:_index];
    
    for (MRGalleryCell *cell in visibleCells) {
        if(cell.index == _index){
            [cell removeFromSuperview];
            if ([self.delegate respondsToSelector:@selector(galleryView:didRemoveCell:isReload:)]){
                [self.delegate galleryView:self didRemoveCell:cell isReload:NO];
            }
            [recycleCells addObject:cell];
        }
    }
    [visibleCells removeObjectsInArray:recycleCells];
    
    galleryCount--;
    if(galleryCount==0){
        self.dataChangeAnimation = NO;
        
        if([self.dataSource respondsToSelector:@selector(galleryViewNotAnyCell:)]){
            [self.dataSource galleryViewNotAnyCell:self];
        }
        return;
    }
    
    //重新定义后续所有cell的坐标
    for (int index = _index; index<galleryCount; index++) {
        MRGalleryPosition *position =[positions objectAtIndex:index];
        position.x = position.x - removePosition.widthWithSideBar;
        position.index =index;
    }
    
    //删除后宽度
    CGFloat contentWidth = self.container.contentSize.width-removePosition.widthWithSideBar;
    
    [self.container setContentSize:CGSizeMake(contentWidth, self.container.frame.size.height)];
    
    //将目前还在显示的cell建立字典，用于后续处理
    NSMutableDictionary *cellValue =[[NSMutableDictionary alloc] init];
    for (MRGalleryCell *cell in visibleCells) {
        if(cell.index >_index){
            //纠正错误的序号问题
            [cellValue setObject:cell forKey:[NSString stringWithFormat:@"%d",cell.index-1]];
        }else{
            [cellValue setObject:cell forKey:[NSString stringWithFormat:@"%d",cell.index]];
        }
        
        [cell removeFromSuperview];
        
    }
    
    [visibleCells removeAllObjects];
    
    //不考虑界面左右移动问题,直接完全重新绘制所有cell,需要复用cellValue中的数据
    
    //向左绘制
    for (int index = _index-1; index>=0; index--) {
        
        MRGalleryPosition *position =[positions objectAtIndex:index];
        
        if(position.x+position.widthWithSideBar<self.container.contentOffset.x){
            break;
            
        }else{
            
            MRGalleryCell *cell = [cellValue objectForKey:[NSString stringWithFormat:@"%d",position.index]];
            if(!cell){
                cell=[self.dataSource galleryView:self cellAtRow:position.index];
            }
            
            cell.frame=CGRectMake(position.x, 0, position.width, self.container.frame.size.height);
            cell.index=position.index;
            if(cell.selectionType==GalleryCellSelectionTypeSelect){
                UITapGestureRecognizer *tapGestureRecognizer=[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapCell:)];
                tapGestureRecognizer.numberOfTapsRequired=1;
                [cell addGestureRecognizer:tapGestureRecognizer];
            }
            [self.container addSubview:cell];
            [self.container sendSubviewToBack:cell];
            
            [visibleCells addObject:cell];
            
        }
    }
    
    //向右绘制
    for (int index = _index; index<galleryCount; index++) {
        MRGalleryPosition *position =[positions objectAtIndex:index];
        if(position.x>self.container.contentOffset.x+self.container.frame.size.width){
            break;
        }else{
            
            
            MRGalleryCell *cell = [cellValue objectForKey:[NSString stringWithFormat:@"%d",position.index]];
            if(!cell){
                cell=[self.dataSource galleryView:self cellAtRow:position.index];
            }
            
            cell.frame=CGRectMake(position.x, 0, position.width, self.container.frame.size.height);
            cell.index=position.index;
            if(cell.selectionType==GalleryCellSelectionTypeSelect){
                UITapGestureRecognizer *tapGestureRecognizer=[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapCell:)];
                tapGestureRecognizer.numberOfTapsRequired=1;
                [cell addGestureRecognizer:tapGestureRecognizer];
            }
            [self.container addSubview:cell];
            [self.container sendSubviewToBack:cell];
            
            [visibleCells addObject:cell];
        }
    }
    
    //TODO 动画
    if([self.dataSource respondsToSelector:@selector(galleryViewDidLoadFinished)]){
        [self.dataSource galleryViewDidLoadFinished];
    }
    
    self.dataChangeAnimation = NO;
    [self computePage];
    
}


- (void)insertCellAtIndex:(NSInteger)index  animation:(BOOL)animation{
    
    //TODO 算法比较复杂 后续处理
    
    
}

- (void)scrollToIndex:(NSInteger)index{
    MRGalleryPosition *position =[positions objectAtIndex:index];
    
    CGFloat offsetCenterX =position.x -(self.container.frame.size.width-position.x+position.widthWithSideBar)/2.0f;
    
    if(offsetCenterX<0){
        offsetCenterX = 0;
    }
    
    if(offsetCenterX+self.container.frame.size.width>self.container.contentSize.width){
        offsetCenterX = self.container.contentSize.width - self.container.frame.size.width;
    }
    
    
    [self.container setContentOffset:CGPointMake(offsetCenterX, 0) animated:YES];
}

- (MRGalleryCell *)dequeueReusableCellWithIdentifier:(NSString*)identifier
{
    NSInteger _index=-1;
    for (int i=0; i<recycleCells.count; i++) {
        MRGalleryCell *cell=[recycleCells objectAtIndex:i];
        if([cell.identifier isEqualToString:identifier]){
            _index=i;
            break;
        }
    }
    
    if(_index!=-1){
        MRGalleryCell *cell=[recycleCells objectAtIndex:_index];
        [recycleCells removeObjectAtIndex:_index];
        return cell;
    }else{
        return nil;
    }
}

- (MRGalleryCell *)cellAtRow:(NSInteger)row{
    for (MRGalleryCell *cell in visibleCells) {
        if(cell.index ==row)
            return cell;
    }
    
    
    return nil;
}

- (NSArray *)visibleCells{
    return visibleCells;
}


-(void)clearInvisibleCells{
    
    for (MRGalleryCell *cell in visibleCells) {
        if(cell.frame.origin.x>=(self.container.contentOffset.x+self.container.frame.size.width)){
            [cell removeFromSuperview];
            if ([self.delegate respondsToSelector:@selector(galleryView:didRemoveCell:isReload:)]){
                [self.delegate galleryView:self didRemoveCell:cell isReload:NO];
            }
            [recycleCells addObject:cell];
        }
        if((cell.frame.origin.x+cell.frame.size.width)<=self.container.contentOffset.x){
            [cell removeFromSuperview];
            if ([self.delegate respondsToSelector:@selector(galleryView:didRemoveCell:isReload:)]){
                [self.delegate galleryView:self didRemoveCell:cell isReload:NO];
            }
            [recycleCells addObject:cell];
        }
    }
    [visibleCells removeObjectsInArray:recycleCells];
    
    if([self.dataSource respondsToSelector:@selector(galleryViewDidScrollEnd)]){
        [self.dataSource galleryViewDidScrollEnd];
    }
    
}

- (void)resizeGalleryRect:(CGRect)rect{
    [self setFrame:rect];
    
    //TODO 更好的优化算法
    
    [self drawGalleryView];
}

#pragma mark - Scroll Method

-(void)drawGalleryView{
    
    if(visibleCells.count==0)
        return;
    
    BOOL scrollLeft=(preX-container.contentOffset.x)>0;
    
    if(scrollLeft){
        //向左滑动
        
        MRGalleryCell *cell=[visibleCells objectAtIndex:0];
        float x=cell.frame.origin.x;
        NSInteger _index=cell.index;
        
        
        for (MRGalleryCell *cell in visibleCells) {
            if(cell.frame.origin.x>(self.container.contentOffset.x+self.container.frame.size.width)){
                [cell removeFromSuperview];
                if ([self.delegate respondsToSelector:@selector(galleryView:didRemoveCell:isReload:)]){
                    [self.delegate galleryView:self didRemoveCell:cell isReload:NO];
                }
                [recycleCells addObject:cell];
            }
        }
        [visibleCells removeObjectsInArray:recycleCells];
        
        
        while (x>self.container.contentOffset.x) {
            _index-=1;
            if(_index<0){
                break;
            }
            
            float iw=[self.dataSource galleryView:self widthForRow:_index];
            
            MRGalleryCell *cell=[self.dataSource galleryView:self cellAtRow:_index];
            cell.frame=CGRectMake(x-(iw+self.sideBarWidth), 0, iw, self.container.frame.size.height);
            
            cell.index=_index;
            if(cell.selectionType==GalleryCellSelectionTypeSelect){
                UITapGestureRecognizer *tapGestureRecognizer=[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapCell:)];
                tapGestureRecognizer.numberOfTapsRequired=1;
                [cell addGestureRecognizer:tapGestureRecognizer];
            }
            [self.container addSubview:cell];
            
            [visibleCells insertObject:cell atIndex:0];
            
            x-=iw+self.sideBarWidth;
            
        }
        
    }else{
        //向右滑动
        
        MRGalleryCell *cell=[visibleCells lastObject];
        float x=cell.frame.origin.x+cell.frame.size.width+self.sideBarWidth;
        NSInteger _index=cell.index;
        
        for (MRGalleryCell *cell in visibleCells) {
            if((cell.frame.origin.x+cell.frame.size.width)<self.container.contentOffset.x){
                [cell removeFromSuperview];
                if ([self.delegate respondsToSelector:@selector(galleryView:didRemoveCell:isReload:)]){
                    [self.delegate galleryView:self didRemoveCell:cell isReload:NO];
                }
                [recycleCells addObject:cell];
            }
        }
        [visibleCells removeObjectsInArray:recycleCells];
        
        while (x<(self.container.contentOffset.x+self.container.frame.size.width)) {
            _index+=1;
            if(_index>(galleryCount-1)){
                break;
            }
            
            float iw=[self.dataSource galleryView:self widthForRow:_index];
            
            MRGalleryCell *cell=[self.dataSource galleryView:self cellAtRow:_index];
            cell.frame=CGRectMake(x, 0, iw, self.container.frame.size.height);
            cell.index=_index;
            if(cell.selectionType==GalleryCellSelectionTypeSelect){
                UITapGestureRecognizer *tapGestureRecognizer=[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapCell:)];
                tapGestureRecognizer.numberOfTapsRequired=1;
                [cell addGestureRecognizer:tapGestureRecognizer];
            }
            [self.container addSubview:cell];
            [self.container sendSubviewToBack:cell];
            
            [visibleCells addObject:cell];
            
            x+=iw+self.sideBarWidth;
            
        }
    }
    
}



- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView{
    if(galleryCount==0)
        return;
    
    if(self.dataChangeAnimation)
        return;
    
    if([self.dataSource respondsToSelector:@selector(galleryViewDidScrollStart)]){
        [self.dataSource galleryViewDidScrollStart];
    }
    
    
    preX=scrollView.contentOffset.x;
    [self drawGalleryView];
}
-(void)scrollViewDidScroll:(UIScrollView *)scrollView{
    
    if(galleryCount==0)
        return;
    
    if(self.dataChangeAnimation)
        return;
    
    [self computePage];
    
    [self drawGalleryView];
    preX=scrollView.contentOffset.x;
    
    //  NSLog(@"scrollView.contentSize.height:%f    scrollView.frame.size.height:%f",scrollView.contentSize.height,scrollView.frame.size.height);
}

-(void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView{
    
    if(galleryCount==0)
        return;
    
    if(self.dataChangeAnimation)
        return;
    
    [self computePage];
    
    [self clearInvisibleCells];
}

-(void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate{
    
    if(galleryCount==0)
        return;
    
    if(self.dataChangeAnimation)
        return;
    
    [self computePage];
    if(!decelerate){
        [self clearInvisibleCells];
    }
}


@end
