//
//  PlayerMore.m
//  Madv360_v1
//
//  Created by 张巧隔 on 2017/4/18.
//  Copyright © 2017年 Cyllenge. All rights reserved.
//

#import "PlayerMoreView.h"
#import "Masonry.h"
#import "ScreenCapSetCell.h"
#import "ScreenCapSetSizeCell.h"

@interface PlayerMoreView()<UITableViewDelegate,UITableViewDataSource,PlayerMoreCellDelegate,ScreenCapSetCellDelegate,ScreenCapSetSizeCellDelegate>
@property(nonatomic,weak)UITableView * tableView;
@end

@implementation PlayerMoreView

- (void)loadPlayerMoreView
{
    UITableView * tableView = [[UITableView alloc] init];
    [self addSubview:tableView];
    [tableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(@0);
        make.left.equalTo(@0);
        make.right.equalTo(@0);
        make.bottom.equalTo(@-1);
    }];
    //tableView.frame = CGRectMake(0, 0, self.width, self.height-1);
    tableView.dataSource = self;
    tableView.delegate = self;
    tableView.backgroundColor = [UIColor clearColor];
    tableView.separatorColor = [UIColor colorWithHexString:@"#FFFFFF" alpha:0.2];
    tableView.bounces = NO;
    tableView.indicatorStyle=UIScrollViewIndicatorStyleWhite;
    self.tableView = tableView;
    
    UIView * lineView = [[UIView alloc] init];
    [self addSubview:lineView];
    [lineView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(@0);
        make.left.equalTo(@0);
        make.right.equalTo(@0);
        make.height.equalTo(@1);
    }];
    //lineView.frame = CGRectMake(0, self.height-1, self.width, 1);
    lineView.backgroundColor = [UIColor colorWithHexString:@"#ffffff" alpha:0.2];
    self.lineView = lineView;
}
#pragma mark --UITableViewDataSource代理方法的实现--
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.dataSource.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    PlayerMoreModel * playerMoreModel = self.dataSource[indexPath.row];
    NSString * identifier;
    Class class;
    if (playerMoreModel.moreType == Phone_Gyroscope_NoImage || playerMoreModel.moreType == Watermark) {
        identifier = @"ScreenCapSetCell";
        class = [ScreenCapSetCell class];
    }else if(playerMoreModel.moreType == Screen_Size)
    {
        identifier = @"Screen_Size";
        class = [ScreenCapSetSizeCell class];
    }else
    {
        identifier = @"PlayerMore";
        class = [PlayerMoreCell class];
    }
    [tableView registerClass:class forCellReuseIdentifier:identifier];
    
    UITableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    cell.contentView.backgroundColor = [UIColor clearColor];
    cell.textLabel.textColor = [UIColor whiteColor];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.backgroundColor = [UIColor clearColor];
    
    if (playerMoreModel.moreType == Phone_Gyroscope_NoImage || playerMoreModel.moreType == Watermark) {
        ScreenCapSetCell * screenCapSetCell = (ScreenCapSetCell *)cell;
        screenCapSetCell.playerMoreModel = playerMoreModel;
        screenCapSetCell.delegate = self;
        
    }else if (playerMoreModel.moreType == Screen_Size)
    {
        ScreenCapSetSizeCell * screenCapSetSizeCell = (ScreenCapSetSizeCell *)cell;
        screenCapSetSizeCell.playerMoreModel = playerMoreModel;
        screenCapSetSizeCell.delegate = self;
        
    }else
    {
        PlayerMoreCell * moreCell = (PlayerMoreCell *)cell;
        moreCell.playerMoreModel = playerMoreModel;
        moreCell.delegate = self;
    }
    
    
    if (indexPath.row == self.dataSource.count - 1) {
        cell.separatorInset = UIEdgeInsetsMake(0, self.width, 0, 0);
    }else{
        cell.separatorInset = UIEdgeInsetsMake(0, 15, 0, 0);
    }
    return cell;
}

#pragma mark --UITableViewDelegate代理方法的实现--
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    PlayerMoreModel * playerMoreModel = self.dataSource[indexPath.row];
    if (playerMoreModel.moreType == Screen_Size || playerMoreModel.moreType == Watermark || playerMoreModel.moreType == Phone_Gyroscope_NoImage) {
        return 69;
    }
    return 51;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"dfjkdsjkf");
    PlayerMoreModel * playerMoreModel = self.dataSource[indexPath.row];
    if (!playerMoreModel.isGyroscope && !(playerMoreModel.moreType == Export && playerMoreModel.isExported) && playerMoreModel.moreType != Watermark && playerMoreModel.moreType != Phone_Gyroscope_NoImage) {
        if ([self.delegate respondsToSelector:@selector(playerMoreView:playerMoreModel:switchOn:index:)]) {
            [self.delegate playerMoreView:self playerMoreModel:playerMoreModel switchOn:NO index:indexPath.item];
        }
    }
    
    
}

#pragma mark --PlayerMoreCellDelegate代理方法的实现--
- (void)playerMoreCell:(PlayerMoreCell *)playerMoreCell switchOn:(BOOL)on
{
    if ([self.delegate respondsToSelector:@selector(playerMoreView:playerMoreModel:switchOn:index:)]) {
        [self.delegate playerMoreView:self playerMoreModel:playerMoreCell.playerMoreModel switchOn:on index:0];
    }
}

#pragma mark --ScreenCapSetCellDelegate代理方法的实现--
- (void)screenCapSetCell:(ScreenCapSetCell *)screenCapSetCell switchOn:(BOOL)on
{
    if ([self.delegate respondsToSelector:@selector(playerMoreView:playerMoreModel:switchOn:index:)]) {
        [self.delegate playerMoreView:self playerMoreModel:screenCapSetCell.playerMoreModel switchOn:on index:0];
    }
}

#pragma mark --ScreenCapSetSizeCellDelegate代理方法的实现--
- (void)screenCapSetSizeCell:(ScreenCapSetSizeCell *)screenCapSetSizeCell index:(NSInteger)index
{
    if ([self.delegate respondsToSelector:@selector(playerMoreView:playerMoreModel:switchOn:index:)]) {
        [self.delegate playerMoreView:self playerMoreModel:screenCapSetSizeCell.playerMoreModel switchOn:NO index:index];
    }
}
- (void)refresh
{
    [self.tableView reloadData];
}

- (void)setDataSource:(NSArray *)dataSource
{
    _dataSource = dataSource;
    [self.tableView reloadData];
}

#pragma mark --是否可滑动--
- (void)setBounces:(BOOL)bounces
{
    _bounces = bounces;
    self.tableView.bounces = bounces;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
