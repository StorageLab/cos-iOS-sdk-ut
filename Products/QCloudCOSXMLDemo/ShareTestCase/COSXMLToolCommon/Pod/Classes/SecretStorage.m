//
//  SecretStorage.m
//  QCloudCOSXMLDemo
//
//  Created by erichmzhang(张恒铭) on 27/01/2018.
//  Copyright © 2018 Tencent. All rights reserved.
//

#import "SecretStorage.h"

@implementation SecretStorage
+(instancetype)sharedInstance {
    static SecretStorage* instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[SecretStorage alloc] init];
    });
    return  instance;
}

-(instancetype) init {
    self = [super init];
    NSString* path = [[NSBundle mainBundle] pathForResource:@"key" ofType:@"json"];
    NSData* jsonData = [[NSData alloc] initWithContentsOfFile:path];
    NSDictionary* dict = [NSJSONSerialization JSONObjectWithData:jsonData options:kNilOptions error:nil];
    self.appID = dict[@"appID"];
    self.bucket = dict[@"bucket"];
    self.secretID = dict[@"secretID"];
    self.secretKey = dict[@"secretKey"];
    self.regionName = dict[@"regionName"];
    if (dict[@"authorizedUIN"]) {
	self.authorizedUIN = dict[@"authorizedUIN"];
    } else {
	self.authorizedUIN = self.appID;
    }
    if ([dict valueForKey:@"enableACLTest"]&&[dict[@"enableACLTest"] isEqualToString:@"YES"]) {
        self.enableACLTest = YES;
    } else {
        self.enableACLTest = NO;
    }
    
    return  self;
}
@end
