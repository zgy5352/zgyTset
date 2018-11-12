//
//  ViewController.m
//  TestAll
//
//  Created by zhaoguoying on 2017/9/27.
//  Copyright © 2017年 ZDHS. All rights reserved.
//

#import "ViewController.h"


@interface ViewController ()
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    
    [self _initView1];
}
#pragma mark - _init
#pragma mark - delegate
#pragma mark - action
#pragma mark - other
-(void)_initView1{
    
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(100, 100, 100, 100)];
    view.backgroundColor = [UIColor redColor];
    [self.view addSubview:view];
    
}


@end
