//
//  CommentCell.m
//  Madv360_v1
//
//  Created by 张巧隔 on 17/2/20.
//  Copyright © 2017年 Cyllenge. All rights reserved.
//

#import "CommentCell.h"
#import "Masonry.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import "helper.h"

@interface CommentCell()
@property(nonatomic,weak)UIImageView * avatarImageView;
@property(nonatomic,weak)UILabel * commentTimeLabel;
@property(nonatomic,weak)UILabel * authorNameLabel;
@property(nonatomic,weak)UILabel * connentLabel;
@property(nonatomic,weak)UIButton * deleteBtn;
@property(nonatomic,weak)UIImageView * vipImageView;
@property(nonatomic,weak)UIImageView * inviteImageView;
@end

@implementation CommentCell
- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        UIImageView * avatarImageView = [[UIImageView alloc] init];
        [self.contentView addSubview:avatarImageView];
        [avatarImageView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(@15);
            make.left.equalTo(@15);
            make.width.equalTo(@25);
            make.height.equalTo(@25);
        }];
        avatarImageView.layer.masksToBounds = YES;
        avatarImageView.layer.cornerRadius = 12.5;
        self.avatarImageView = avatarImageView;
        
        UIImageView * vipImageView = [[UIImageView alloc] init];
        [self.contentView addSubview:vipImageView];
        [vipImageView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.right.equalTo(avatarImageView.mas_right);
            make.bottom.equalTo(avatarImageView.mas_bottom).offset(5);
            make.width.equalTo(@10);
            make.height.equalTo(@10);
        }];
        vipImageView.image = [UIImage imageNamed:@"vip.png"];
        self.vipImageView = vipImageView;
        
        UIImageView * inviteImageView = [[UIImageView alloc] init];
        [self.contentView addSubview:inviteImageView];
        
        inviteImageView.image = [UIImage imageNamed:@"invite.png"];
        self.inviteImageView = inviteImageView;
        
        UILabel * commentTimeLabel = [[UILabel alloc] init];
        [self.contentView addSubview:commentTimeLabel];
        [commentTimeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.right.equalTo(@-15);
            make.centerY.equalTo(avatarImageView.mas_centerY);
            make.height.equalTo(@15);
            make.width.equalTo(@80);
        }];
        commentTimeLabel.textAlignment = NSTextAlignmentRight;
        commentTimeLabel.font = [UIFont systemFontOfSize:12];
        commentTimeLabel.textColor = [UIColor colorWithHexString:@"#000000" alpha:0.5];
        self.commentTimeLabel = commentTimeLabel;
        
        UILabel * authorNameLabel = [[UILabel alloc] init];
        [self.contentView addSubview:authorNameLabel];
        authorNameLabel.frame = CGRectMake(53, 20, 100, 15);
        
//        [authorNameLabel mas_makeConstraints:^(MASConstraintMaker *make) {
//            make.left.equalTo(avatarImageView.mas_right).offset(13);
//            make.right.equalTo(commentTimeLabel.mas_left);
//            make.centerY.equalTo(avatarImageView.mas_centerY);
//            make.height.equalTo(@15);
//        }];
        authorNameLabel.font = [UIFont systemFontOfSize:12];
        authorNameLabel.textColor = [UIColor colorWithHexString:@"#000000" alpha:0.6];
        self.authorNameLabel = authorNameLabel;
        
        UILabel * connentLabel = [[UILabel alloc] init];
        [self.contentView addSubview:connentLabel];
        connentLabel.frame = CGRectMake(53, 50, ScreenWidth-50-25, 0);
        connentLabel.font = [UIFont systemFontOfSize:14];
        connentLabel.textColor = [UIColor colorWithHexString:@"#000000" alpha:0.8];
        connentLabel.numberOfLines = 0;
        self.connentLabel = connentLabel;
        
        UIButton * deleteBtn = [[UIButton alloc] init];
        [self.contentView addSubview:deleteBtn];
        [deleteBtn mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(connentLabel.mas_left);
            make.top.equalTo(connentLabel.mas_bottom).offset(5);
            make.width.equalTo(@50);
            make.height.equalTo(@30);
        }];
        [deleteBtn setTitle:FGGetStringWithKeyFromTable(DELETEPRO, nil) forState:UIControlStateNormal];
        [deleteBtn setTitleColor:[UIColor colorWithHexString:@"#576b95"] forState:UIControlStateNormal];
        deleteBtn.titleLabel.font = [UIFont systemFontOfSize:14];
        deleteBtn.titleLabel.textAlignment = NSTextAlignmentLeft;
        [deleteBtn addTarget:self action:@selector(deleteBtn:) forControlEvents:UIControlEventTouchUpInside];
        [deleteBtn setTitleEdgeInsets:UIEdgeInsetsMake(0, -20, 0, 0)];
        deleteBtn.hidden = YES;
        self.deleteBtn = deleteBtn;
        
    }
    return self;
}

- (void)setCommentDetail:(CommentDetail *)commentDetail
{
    _commentDetail = commentDetail;
    self.connentLabel.width = ScreenWidth-50-25;
    self.connentLabel.height = 0;
    [self.avatarImageView sd_setImageWithURL:[NSURL URLWithString:commentDetail.avatar] placeholderImage:[UIImage imageNamed:@"Default avatar.png"]];
    
    if ([commentDetail.level isEqualToString:@"0"]) {
        self.vipImageView.hidden = YES;
        self.inviteImageView.hidden = YES;
    }else
    {
        self.vipImageView.hidden = NO;
        self.inviteImageView.hidden = NO;
    }
    
    if (commentDetail.nickname == nil) {
        commentDetail.nickname = @"";
    }
    
    NSMutableAttributedString * authorNameAttributed = [[NSMutableAttributedString alloc] initWithString:commentDetail.nickname];
    self.authorNameLabel.attributedText=authorNameAttributed;
    [self.authorNameLabel sizeToFit];
    [self.inviteImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.authorNameLabel.mas_right).offset(9);
        make.centerY.equalTo(self.authorNameLabel.mas_centerY).offset(-5);
        make.width.equalTo(@39);
        make.height.equalTo(@24);
    }];
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init] ;
    [formatter setDateFormat:FGGetStringWithKeyFromTable(MEDIALIBRARYDATEFORMATTER, nil)];
    NSTimeInterval time = [commentDetail.createtime doubleValue];
    self.commentTimeLabel.text = [formatter stringFromDate:[NSDate dateWithTimeIntervalSince1970:time]];
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:commentDetail.content];
    self.connentLabel.attributedText = attributedString;
    [self.connentLabel sizeToFit];
    commentDetail.contentHeight = self.connentLabel.height;
    
    if (![helper isNull:[helper readProfileString:@"token"]] && [[helper readProfileString:USERNAME] isEqualToString:commentDetail.username]) {
        self.deleteBtn.hidden = NO;
    }else
    {
        self.deleteBtn.hidden = YES;
    }
    
}

- (void)deleteBtn:(UIButton *)btn
{
    NSLog(@"删除");
    if ([self.delegate respondsToSelector:@selector(commentCellDeleteCom:)]) {
        [self.delegate commentCellDeleteCom:self];
    }
}
- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
