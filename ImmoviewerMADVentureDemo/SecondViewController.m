//
//  SecondViewController.m
//  ImmoviewerMADVentureDemo
//
//  Created by QiuDong on 2018/1/24.
//  Copyright © 2018年 QiuDong. All rights reserved.
//

#import "SecondViewController.h"
#import "AppDelegate.h"
#import <MVGLView.h>

static NSString* MediaCellIdentifier = @"MediaCellIdentifier";

@interface MediaCell : UITableViewCell

@property (nonatomic, strong) IBOutlet UIImageView* photoView;

@end

@implementation MediaCell

@end

@interface SecondViewController () <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) IBOutlet UITableView* tableView;

@end

@implementation SecondViewController

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(downloadedListUpdated:) name:kNotificationDownloadedListUpdated object:nil];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark    UITableViewDataSource

-(void) downloadedListUpdated:(NSNotification*)notification {
    [self.tableView reloadData];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return g_downloadedFileNames.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    MediaCell* cell = [tableView dequeueReusableCellWithIdentifier:MediaCellIdentifier forIndexPath:indexPath];
    NSString* fileName = [g_downloadedFileNames objectAtIndex:indexPath.row];
    NSString* filePath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0] stringByAppendingPathComponent:fileName];
    //UIImage* image = [UIImage imageWithContentsOfFile:filePath];
    ///!!!cell.photoView.image = image;
    return cell;
}

@end
