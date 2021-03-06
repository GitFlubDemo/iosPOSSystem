//
//  POSSubCategoryViewController.m
//  POSsystem
//
//  Created by Andrew Charkin on 2/27/13.
//  Copyright (c) 2013 POS. All rights reserved.
//

#import "POSSubCategoryViewController.h"
#import "POSCollectionViewCell.h"
#import "POSConstants.h"
#import "POSProductGroup.h"

@interface POSSubCategoryViewController ()

@end

@implementation POSSubCategoryViewController

#pragma mark - getters/setters
@synthesize coordinatorDelegate = _coordinatorDelegate;

@synthesize collectionView = _collectionView;
- (UICollectionView *) collectionView {
    if(_collectionView) return _collectionView;
    UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
    _collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:flowLayout];
    [_collectionView registerClass:[POSCollectionViewCell class] forCellWithReuseIdentifier:COLLECTION_VIEW_CELL_IDENTIFIER];
    _collectionView.dataSource = self;
    _collectionView.delegate = self;
    _collectionView.backgroundColor = [UIColor clearColor];
    
    _collectionView.translatesAutoresizingMaskIntoConstraints = NO;
    return _collectionView;
}

@synthesize data = _data;
-(NSMutableArray *) data {
    _data = [[NSMutableArray alloc] init];
    [_data addObject:[[NSMutableArray alloc] init]];
    for(NSString *obj in [[NSMutableArray alloc] initWithObjects:@"Sofa", @"nicer sofa", @"sooper nice sofa", @"TEST", @"TEST", @"TEST", nil]){
        POSProductGroup *p = [[POSProductGroup alloc] init];
        p.title = obj;
        p.description = @"test";
        [[_data objectAtIndex:0] addObject:p];
    }
    
    return _data;
}


#pragma mark - view methods
- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.view addSubview:self.collectionView];
    
    ADD_CONSTRAINT(self.view, self.collectionView, NSLayoutAttributeLeading, NSLayoutRelationEqual, self.view, NSLayoutAttributeLeading, 1.f, 0.f);
    ADD_CONSTRAINT(self.view, self.collectionView, NSLayoutAttributeTop, NSLayoutRelationEqual, self.view, NSLayoutAttributeTop, 1.f, 0.f);
    ADD_CONSTRAINT(self.view, self.collectionView, NSLayoutAttributeTrailing, NSLayoutRelationEqual, self.view, NSLayoutAttributeTrailing, 1.f, 0.f);
    ADD_CONSTRAINT(self.view, self.collectionView, NSLayoutAttributeBottom, NSLayoutRelationEqual, self.view, NSLayoutAttributeBottom, 1.f, 0.f);
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    [self.collectionView.collectionViewLayout invalidateLayout];
}

#pragma mark - UICollectionViewDataSource
- (NSInteger) numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return [self.data count];
}
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return [[self.data objectAtIndex:section] count];
}
- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    POSCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:COLLECTION_VIEW_CELL_IDENTIFIER forIndexPath:indexPath];
    if(cell == nil) cell = [[POSCollectionViewCell alloc] init];
    
    POSProductGroup *p = [[self.data objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
    [cell setupWithProduct:p];
    return cell;
}

#pragma mark - UICollectionViewDelegate
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    POSCollectionViewCell * cell = (POSCollectionViewCell *)[collectionView cellForItemAtIndexPath:indexPath];
    [self.coordinatorDelegate subCategoryClicked: cell.nameLabel.text];
}

#pragma mark - UICollectionViewDelegateFlowLayout
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    CGFloat width = collectionView.frame.size.width;
    //does magic to adjust widths of cells based on sizes... hard to explain what... try rotating nad see
    NSInteger numberOfCellsInRow = (int)((width-COLLECTION_VIEW_CELL_SPACING)/(COLLECTION_VIEW_MIN_CELLS_WIDTH-COLLECTION_VIEW_CELL_SPACING));
    NSInteger cellWidth = (width-COLLECTION_VIEW_CELL_SPACING)/numberOfCellsInRow - COLLECTION_VIEW_CELL_SPACING;
    
    return CGSizeMake(cellWidth, cellWidth);
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section {
    return COLLECTION_VIEW_CELL_SPACING;
}

-(UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
    return UIEdgeInsetsMake(COLLECTION_VIEW_CELL_SPACING, COLLECTION_VIEW_CELL_SPACING, COLLECTION_VIEW_CELL_SPACING, COLLECTION_VIEW_CELL_SPACING);
}

@end
