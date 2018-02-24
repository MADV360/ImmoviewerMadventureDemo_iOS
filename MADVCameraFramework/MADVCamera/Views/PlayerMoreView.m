//
//  PlayerMore.m
//  Madv360_v1
//
//  Created by 张巧隔 on 2017/4/18.
//  Copyright © 2017年 Cyllenge. All rights reserved.
//

#import "PlayerMoreView.h"
#import "Masonry.h"

@interface PlayerMoreView()<UITableViewDelegate,UITableViewDataSource,PlayerMoreCellDelegate>
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
    [tableView registerClass:[PlayerMoreCell class] forCellReuseIdentifier:@"PlayerMore"];
    
    PlayerMoreCell * cell = [tableView dequeueReusableCellWithIdentifier:@"PlayerMore"];
    cell.contentView.backgroundColor = [UIColor clearColor];
    cell.textLabel.textColor = [UIColor whiteColor];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.backgroundColor = [UIColor clearColor];
    PlayerMoreModel * playerMoreModel = self.dataSource[indexPath.row];
    cell.playerMoreModel = playerMoreModel;
    cell.delegate = self;
    
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
    return 51;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"dfjkdsjkf");
    PlayerMoreModel * playerMoreModel = self.dataSource[indexPath.row];
    if (!playerMoreModel.isGyroscope && !(playerMoreModel.moreType == Export && playerMoreModel.isExported)) {
        if ([self.delegate respondsToSelector:@selector(playerMoreView:moreType:switchOn:)]) {
            [self.delegate playerMoreView:self moreType:playerMoreModel.moreType switchOn:NO];
        }
    }
    
    
}

#pragma mark --PlayerMoreCellDelegate代理方法的实现--
- (void)playerMoreCell:(PlayerMoreCell *)playerMoreCell switchOn:(BOOL)on
{
    if ([self.delegate respondsToSelector:@selector(playerMoreView:moreType:switchOn:)]) {
        [self.delegate playerMoreView:self moreType:playerMoreCell.playerMoreModel.moreType switchOn:on];
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
