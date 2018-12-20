//
//  COSXMLTest512.m
//  COSXMLCommon
//
//  Created by karisli(李雪) on 2018/4/5.
//

#import "COSXMLTest512.h"
#import "COSXMLCommon.h"
@implementation COSXMLTest512

+ (void)setUp {
    [QCloudTestTempVariables sharedInstance].testBucket = [[QCloudCOSXMLTestUtility sharedInstance] createTestBucket];
    
}


+ (void)tearDown {
    [[QCloudCOSXMLTestUtility sharedInstance]deleteAllTestObjects];
    [[QCloudCOSXMLTestUtility sharedInstance]deleteTestBucket: [QCloudTestTempVariables sharedInstance].testBucket];
}

- (void)setUp {
    [super setUp];
    [COSXMLTest tool];
    [QCloudCOSXMLExceptionCoverage tool];
    self.tempFilePathArray = [[NSMutableArray alloc] init];
    self.bucket = [QCloudTestTempVariables sharedInstance].testBucket;
    [QCloudCOSXMLExceptionCoverage tool];
}

- (void)tearDown {
    [super tearDown];
    NSFileManager* manager = [NSFileManager defaultManager];
    
    for (NSString* tempFilePath in self.tempFilePathArray) {
        if ([manager fileExistsAtPath:tempFilePath]) {
            [manager removeItemAtPath:tempFilePath error:nil];
        }
    }
}

#pragma mark - demo


- (void) testLittleLimitAppendObject {
    QCloudAppendObjectRequest* put = [QCloudAppendObjectRequest new];
    put.object = [NSUUID UUID].UUIDString;
    put.bucket = self.bucket;
    put.body =  [NSURL fileURLWithPath:[QClouldCreateTempFile tempFileWithSize:2 unit:QCLOUD_TEMP_FILE_UNIT_KB]];
    
    XCTestExpectation* exp = [self expectationWithDescription:@"delete"];
    
    __block NSDictionary* result = nil;
    __block NSError* error;
    [put setFinishBlock:^(id outputObject, NSError *servererror) {
        result = outputObject;
        error = servererror;
        [exp fulfill];
    }];
    [[QCloudCOSXMLService defaultCOSXML] AppendObject:put];
    [self waitForExpectationsWithTimeout:80 handler:nil];
    XCTAssertNotNil(error);
}
+(void)tool{
    
}
@end
