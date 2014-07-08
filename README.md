MRGalleryView
=============

轻量级左右滑动View，基本实现tableView功能

创建方法：
	
    glleryview = [[MRGalleryView alloc] initWithFrame:self.view.bounds];
    glleryview.dataSource = self;
    glleryview.delegate = self;
    glleryview.pagingEnabled = YES;
    glleryview.bounces = NO;
    glleryview.sideBarWidth=5.0f;
    glleryview.backgroundColor = [UIColor clearColor];
    [self.view addSubview:glleryview];
    [glleryview reloadData];

数目：
	
	
	- (NSInteger)numberOfRowsInGalleryView:(MRGalleryView *)GalleryView{ 
    	return 5;
	}

宽度
	
	- (CGFloat)galleryView:(MRGalleryView *)galleryView widthForRow:	(NSInteger)row{
     	return self.view.frame.size.width;
	}

视图

	- (MRGalleryCell *)galleryView:(MRGalleryView *)galleryView cellAtRow:	(NSInteger)row{
    
    static NSString *CellIdentifier = @"Cell";
    MRGalleryCell *cell = [galleryView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[MRGalleryCell alloc] initWithIdentifier:CellIdentifier];
    }else{
        //TODO: clear
    }

    cell.selectionType=GalleryCellSelectionTypeNone;
    //TODO: 
    
    return cell;
	}

点击

	- (void)galleryView:(MRGalleryView *)galleryView didSelectRow:(NSInteger)row{
    
	}