//
//  COSXMLTest.m
//  COSXMLCommon
//
//  Created by karisli(李雪) on 2018/3/28.
//


#import "COSXMLCommon.h"
#import "COSXMLBaseCommon.h"
@implementation COSXMLTest


- (void)signatureWithFields:(QCloudSignatureFields *)fileds request:(QCloudBizHTTPRequest *)request urlRequest:(NSMutableURLRequest *)urlRequst compelete:(QCloudHTTPAuthentationContinueBlock)continueBlock {
    
    QCloudCredential* credential = [QCloudCredential new];
    credential.secretID = kSecretID;
    credential.secretKey = kSecretKey;
    QCloudAuthentationV5Creator* creator = [[QCloudAuthentationV5Creator alloc] initWithCredential:credential];
    QCloudSignature* signature =  [creator signatureForData:urlRequst];
    continueBlock(signature, nil);
    
}
- (void) setupSpecialCOSXMLShareService {
    QCloudServiceConfiguration* configuration = [QCloudServiceConfiguration new];
    configuration.appID = kAppID;
    configuration.signatureProvider = self;
    QCloudCOSXMLEndPoint* endpoint = [[QCloudCOSXMLEndPoint alloc] init];
    endpoint.regionName = kRegion;
    configuration.endpoint = endpoint;
    
    [QCloudCOSXMLService registerCOSXMLWithConfiguration:configuration withKey:@"aclService"];
}

- (void)registerHTTPTransferManager {
    QCloudServiceConfiguration* configuration = [QCloudServiceConfiguration new];
    configuration.appID = kAppID;
    configuration.signatureProvider = self;
    QCloudCOSXMLEndPoint* endpoint = [[QCloudCOSXMLEndPoint alloc] init];
    endpoint.useHTTPS = YES;
    endpoint.regionName = kRegion;
    configuration.endpoint = endpoint;
    
    [QCloudCOSTransferMangerService registerCOSTransferMangerWithConfiguration:configuration withKey:kHTTPServiceKey];
    [QCloudCOSXMLService registerCOSXMLWithConfiguration:configuration withKey:kHTTPServiceKey];
}

+ (void)setUp {
    [QCloudTestTempVariables sharedInstance].testBucket = [[QCloudCOSXMLTestUtility sharedInstance] createTestBucket];
    
}


+ (void)tearDown {
    [[QCloudCOSXMLTestUtility sharedInstance]deleteAllTestObjects];
    [[QCloudCOSXMLTestUtility sharedInstance]deleteTestBucket: [QCloudTestTempVariables sharedInstance].testBucket];
}

- (void)setUp {
    [super setUp];
    [COSXMLBaseCommon tool];
    [self setupSpecialCOSXMLShareService];
    self.tempFilePathArray = [[NSMutableArray alloc] init];
     self.bucket = [QCloudTestTempVariables sharedInstance].testBucket;
    [self registerHTTPTransferManager];
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

#pragma mark - transfer
- (void)testChineseFileNameSmallFileUpload {
    QCloudCOSXMLUploadObjectRequest* put = [QCloudCOSXMLUploadObjectRequest new];
    int randomNumber = arc4random()%100;
    NSURL* url = [NSURL fileURLWithPath:[QClouldCreateTempFile tempFileWithSize:randomNumber unit:QCLOUD_TEMP_FILE_UNIT_KB]];
    __block NSString *bucketName = [[QCloudCOSXMLTestUtility sharedInstance] createTestBucket];
    put.bucket = bucketName;
    put.object = @"中文名小文件";
    put.body =  url;
    [put setSendProcessBlock:^(int64_t bytesSent, int64_t totalBytesSent, int64_t totalBytesExpectedToSend) {
        NSLog(@"upload %lld totalSend %lld aim %lld", bytesSent, totalBytesSent, totalBytesExpectedToSend);
    }];
    XCTestExpectation* exp = [self expectationWithDescription:@"delete33"];
    __block id result;
    [put setFinishBlock:^(id outputObject, NSError *error) {
        result = outputObject;
        [[QCloudCOSXMLTestUtility sharedInstance]deleteTestBucket:bucketName];
        [exp fulfill];
    }];
    [[QCloudCOSTransferMangerService defaultCOSTransferManager] UploadObject:put];
    [self waitForExpectationsWithTimeout:18000 handler:^(NSError * _Nullable error) {
    }];
    XCTAssertNotNil(result);
}





- (void)testIntegerTimesSliceMultipartUpload {
    QCloudCOSXMLUploadObjectRequest* put = [QCloudCOSXMLUploadObjectRequest new];
    NSURL* url = [NSURL fileURLWithPath:[QClouldCreateTempFile tempFileWithSize:10 unit:QCLOUD_TEMP_FILE_UNIT_MB]];
    put.object = [NSUUID UUID].UUIDString;
    __block NSString *bucketName = [[QCloudCOSXMLTestUtility sharedInstance] createTestBucket];
    put.bucket = bucketName;
    put.body =  url;
    [put setSendProcessBlock:^(int64_t bytesSent, int64_t totalBytesSent, int64_t totalBytesExpectedToSend) {
        NSLog(@"upload %lld totalSend %lld aim %lld", bytesSent, totalBytesSent, totalBytesExpectedToSend);
    }];
    XCTestExpectation* exp = [self expectationWithDescription:@"delete33"];
    __block id result;
    [put setFinishBlock:^(id outputObject, NSError *error) {
        result = outputObject;
        [[QCloudCOSXMLTestUtility sharedInstance] deleteTestBucket:bucketName];
        [exp fulfill];
    }];
    [[QCloudCOSTransferMangerService defaultCOSTransferManager] UploadObject:put];
    [self waitForExpectationsWithTimeout:25000 handler:^(NSError * _Nullable error) {
    }];
//    XCTAssertNotNil(result);
}


- (void) testChineseObjectName {
    QCloudCOSXMLUploadObjectRequest* put = [QCloudCOSXMLUploadObjectRequest new];
    NSURL* url = [NSURL fileURLWithPath:[QClouldCreateTempFile tempFileWithSize:1 unit:QCLOUD_TEMP_FILE_UNIT_KB]];
    put.object = @"一个文件名→↓←→↖↗↙↘! \"#$%&'()*+,-./0123456789:;<=>@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_";
    __block NSString *bucketName = [[QCloudCOSXMLTestUtility sharedInstance] createTestBucket];
    put.bucket = bucketName;
    put.body =  url;
    [put setSendProcessBlock:^(int64_t bytesSent, int64_t totalBytesSent, int64_t totalBytesExpectedToSend) {
        NSLog(@"upload %lld totalSend %lld aim %lld", bytesSent, totalBytesSent, totalBytesExpectedToSend);
    }];
    XCTestExpectation* exp = [self expectationWithDescription:@"delete33"];
    __block id result;
    [put setFinishBlock:^(id outputObject, NSError *error) {
        XCTAssertNil(error);
        result = outputObject;
          [[QCloudCOSXMLTestUtility sharedInstance] deleteTestBucket:bucketName];
        [exp fulfill];
    }];
    [[QCloudCOSTransferMangerService defaultCOSTransferManager] UploadObject:put];
    [self waitForExpectationsWithTimeout:18000 handler:^(NSError * _Nullable error) {
    }];
    XCTAssertNotNil(result);
}


- (void)testSmallSizeUpload {
    
    QCloudCOSXMLUploadObjectRequest* put = [QCloudCOSXMLUploadObjectRequest new];
    NSURL* url = [NSURL fileURLWithPath:[QClouldCreateTempFile tempFileWithSize:1 unit:QCLOUD_TEMP_FILE_UNIT_KB]];
    put.object = [NSUUID UUID].UUIDString;
    __block NSString *bucketName = [[QCloudCOSXMLTestUtility sharedInstance] createTestBucket];
    put.bucket = bucketName;
    put.body =  url;
    [put setSendProcessBlock:^(int64_t bytesSent, int64_t totalBytesSent, int64_t totalBytesExpectedToSend) {
        NSLog(@"upload %lld totalSend %lld aim %lld", bytesSent, totalBytesSent, totalBytesExpectedToSend);
    }];
    XCTestExpectation* exp = [self expectationWithDescription:@"delete33"];
    __block id result;
    [put setFinishBlock:^(id outputObject, NSError *error) {
        result = outputObject;
        [[QCloudCOSXMLTestUtility sharedInstance] deleteTestBucket:bucketName];
        [exp fulfill];
    }];
    [[QCloudCOSTransferMangerService defaultCOSTransferManager] UploadObject:put];
    [self waitForExpectationsWithTimeout:18000 handler:^(NSError * _Nullable error) {
    }];
    XCTAssertNotNil(result);
    
}
- (void) testAbortMultiUpload{
    __block NSString *bucketName = [[QCloudCOSXMLTestUtility sharedInstance] createTestBucket];
    XCTestExpectation* exp = [self expectationWithDescription:@"delete"];
    QCloudInitiateMultipartUploadRequest* initrequest = [QCloudInitiateMultipartUploadRequest new];
    initrequest.bucket = bucketName; //存储桶名称(cos v5 的 bucket格式为：xxx-appid, 如 test-1253960454)
    __block NSString *object = [[QCloudCOSXMLTestUtility sharedInstance]createCanbeDeleteTestObject];
    initrequest.object = object;
    __block QCloudInitiateMultipartUploadResult* initResult;
    [initrequest setFinishBlock:^(QCloudInitiateMultipartUploadResult* outputObject, NSError *error) {
        initResult = outputObject;
        XCTAssertNil(error);
        XCTAssertNotNil(outputObject);
        QCloudAbortMultipfartUploadRequest *abortRequest = [QCloudAbortMultipfartUploadRequest new];
        abortRequest.bucket = bucketName ;////存储桶名称(cos v5 的 bucket格式为：xxx-appid, 如 test-1253960454)
        abortRequest.object = object;
        abortRequest.uploadId = outputObject.uploadId;
        [abortRequest setFinishBlock:^(id outputObject, NSError *error) {
                //additional actions after finishing
            XCTAssertNil(error);
            [exp fulfill];
        }];
        dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
        dispatch_semaphore_wait(semaphore, 10*NSEC_PER_SEC);
        [[QCloudCOSXMLService defaultCOSXML]AbortMultipfartUpload:abortRequest];
    }];
    [[QCloudCOSXMLService defaultCOSXML] InitiateMultipartUpload:initrequest];
    [self waitForExpectationsWithTimeout:80000 handler:nil];
}

#ifndef BUILD_FOR_TEST
- (void) testMultiUpload {
    QCloudCOSXMLUploadObjectRequest* put = [QCloudCOSXMLUploadObjectRequest new];
    int randomNumber = (arc4random() % 10) + 10;
    NSURL* url = [NSURL fileURLWithPath:[QClouldCreateTempFile tempFileWithSize:randomNumber unit:QCLOUD_TEMP_FILE_UNIT_MB]];
    put.object = [NSUUID UUID].UUIDString;
    __block NSString *bucketName = [[QCloudCOSXMLTestUtility sharedInstance] createTestBucket];
    put.bucket = bucketName;
    put.body =  url;
    [put setSendProcessBlock:^(int64_t bytesSent, int64_t totalBytesSent, int64_t totalBytesExpectedToSend) {
        NSLog(@"upload %lld totalSend %lld aim %lld", bytesSent, totalBytesSent, totalBytesExpectedToSend);
    }];
    XCTestExpectation* exp = [self expectationWithDescription:@"delete33"];
    __block id result;
    [put setFinishBlock:^(id outputObject, NSError *error) {
        result = outputObject;
        XCTAssertNil(error);
        [[QCloudCOSXMLTestUtility sharedInstance] deleteTestBucket:bucketName];
        [exp fulfill];
    }];
    [[QCloudCOSTransferMangerService defaultCOSTransferManager] UploadObject:put];
    [self waitForExpectationsWithTimeout:80000 handler:^(NSError * _Nullable error) {
    }];
    XCTAssertNotNil(result);
    
}
#endif


//- (void) testChineseFileNameBigfileUpload {
//    QCloudCOSXMLUploadObjectRequest* put = [QCloudCOSXMLUploadObjectRequest new];
//    int randomNumber = arc4random()%100;
//    NSURL* url = [NSURL fileURLWithPath:[QClouldCreateTempFile tempFileWithSize:randomNumber unit:QCLOUD_TEMP_FILE_UNIT_MB];
//    put.object = @"中文名大文件";
//    put.bucket = self.bucket;
//    put.body =  url;
//    [put setSendProcessBlock:^(int64_t bytesSent, int64_t totalBytesSent, int64_t totalBytesExpectedToSend) {
//        NSLog(@"upload %lld totalSend %lld aim %lld", bytesSent, totalBytesSent, totalBytesExpectedToSend);
//    }];
//    XCTestExpectation* exp = [self expectationWithDescription:@"delete33"];
//    __block id result;
//    [put setFinishBlock:^(id outputObject, NSError *error) {
//        XCTAssertNil(error);
//        result = outputObject;
//        [exp fulfill];
//    }];
//    [put setInitMultipleUploadFinishBlock:^(QCloudInitiateMultipartUploadResult* result,QCloudCOSXMLUploadObjectResumeData resumeData) {
//        NSString* uploadID = result.uploadId;
//        NSLog(@"UploadID%@",uploadID);
//    }];
//    [[QCloudCOSTransferMangerService defaultCOSTransferManager] UploadObject:put];
//    [self waitForExpectationsWithTimeout:18000 handler:^(NSError * _Nullable error) {
//    }];
//    XCTAssertNotNil(result);
//}



- (void)testSpecialCharacterFileNameBigFileUpoload {
    QCloudCOSXMLUploadObjectRequest* put = [QCloudCOSXMLUploadObjectRequest new];
      int randomNumber = (arc4random() % 20) + 30;
    NSURL* url = [NSURL fileURLWithPath:[QClouldCreateTempFile tempFileWithSize:randomNumber unit:QCLOUD_TEMP_FILE_UNIT_MB]];
    put.object = @"→↓←→↖↗↙↘! \"#$%&'()*+,-.0123456789:;<=>@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_`abcdefghijklmnopqrstuvwxyz{|}~";
    __block NSString *bucketName = [[QCloudCOSXMLTestUtility sharedInstance] createTestBucket];
    put.bucket = bucketName;
    put.body =  url;
    [put setSendProcessBlock:^(int64_t bytesSent, int64_t totalBytesSent, int64_t totalBytesExpectedToSend) {
        NSLog(@"upload %lld totalSend %lld aim %lld", bytesSent, totalBytesSent, totalBytesExpectedToSend);
    }];
    
    XCTestExpectation* exp = [self expectationWithDescription:@"delete33"];
    __block id result;
    [put setFinishBlock:^(id outputObject, NSError *error) {
        XCTAssertNil(error);
        result = outputObject;
        [[QCloudCOSXMLTestUtility sharedInstance] createTestBucket];
        [exp fulfill];
    }];
    [[QCloudCOSTransferMangerService defaultCOSTransferManager] UploadObject:put];
    [self waitForExpectationsWithTimeout:80000 handler:^(NSError * _Nullable error) {
    }];
    XCTAssertNotNil(result);
}


- (void)testSpecialCharacterFileSmallFileUpload {
    QCloudCOSXMLUploadObjectRequest* put = [QCloudCOSXMLUploadObjectRequest new];
    int randomNumber = arc4random()%100;
    NSURL* url = [NSURL fileURLWithPath:[QClouldCreateTempFile tempFileWithSize:15+randomNumber unit:QCLOUD_TEMP_FILE_UNIT_KB]];
    put.object = @"→↓←→↖↗↙↘! \"#$%&'()*+,-.0123456789:;<=>@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_`abcdefghijklmnopqrstuvwxyz{|}~";
    __block NSString *bucketName = [[QCloudCOSXMLTestUtility sharedInstance] createTestBucket];
    put.bucket = bucketName;
    put.body =  url;
    [put setSendProcessBlock:^(int64_t bytesSent, int64_t totalBytesSent, int64_t totalBytesExpectedToSend) {
        NSLog(@"upload %lld totalSend %lld aim %lld", bytesSent, totalBytesSent, totalBytesExpectedToSend);
    }];
    XCTestExpectation* exp = [self expectationWithDescription:@"delete33"];
    __block id result;
    [put setFinishBlock:^(id outputObject, NSError *error) {
        XCTAssertNil(error);
        result = outputObject;
        [[QCloudCOSXMLTestUtility sharedInstance] deleteTestBucket:bucketName];
        [exp fulfill];
    }];
    [[QCloudCOSTransferMangerService defaultCOSTransferManager] UploadObject:put];
    [self waitForExpectationsWithTimeout:18000 handler:^(NSError * _Nullable error) {
    }];
    XCTAssertNotNil(result);
}






#pragma mark - abort part


#ifndef BUILD_FOR_TEST
//- (void) testPauseAndResume {
//
//    QCloudCOSXMLUploadObjectRequest* put = [QCloudCOSXMLUploadObjectRequest new];
//    NSURL* url = [NSURL fileURLWithPath[QClouldCreateTempFile tempFileWithSize:30 unit:QCLOUD_TEMP_FILE_UNIT_MB]];
//    put.object = [NSUUID UUID].UUIDString;
//    put.bucket = self.bucket;
//    put.body =  url;
//
//    __block QCloudUploadObjectResult* result;
//    [put setFinishBlock:^(id outputObject, NSError *error) {
//        result = outputObject;
//    }];
//
//    [put setSendProcessBlock:^(int64_t bytesSent, int64_t totalBytesSent, int64_t totalBytesExpectedToSend) {
//        NSLog(@"upload %lld totalSend %lld aim %lld", bytesSent, totalBytesSent, totalBytesExpectedToSend);
//    }];
//    [[QCloudCOSTransferMangerService defaultCOSTransferManager] UploadObject:put];
//
//
//    __block QCloudCOSXMLUploadObjectResumeData resumeData = nil;
//    XCTestExpectation* resumeExp = [self expectationWithDescription:@"delete2"];
//    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
//        NSError* error;
//        resumeData = [put cancelByProductingResumeData:&error];
//        if (resumeData) {
//            QCloudCOSXMLUploadObjectRequest* request = [QCloudCOSXMLUploadObjectRequest requestWithRequestData:resumeData];
//            [request setFinishBlock:^(QCloudUploadObjectResult* outputObject, NSError *error) {
//                result = outputObject;
//                [resumeExp fulfill];
//            }];
//
//            [request setSendProcessBlock:^(int64_t bytesSent, int64_t totalBytesSent, int64_t totalBytesExpectedToSend) {
//                NSLog(@"upload %lld totalSend %lld aim %lld", bytesSent, totalBytesSent, totalBytesExpectedToSend);
//            }];
//            [[QCloudCOSTransferMangerService defaultCOSTransferManager] UploadObject:request];
//        } else {
//            [resumeExp fulfill];
//        }
//    });
//
//
//    [self waitForExpectationsWithTimeout:80000 handler:nil];
//    XCTAssertNotNil(result);
//    XCTAssertNotNil(result.location);
//    XCTAssertNotNil(result.eTag);
//}
#endif


#pragma mark - bucket

- (void)testPutAndDeleteBucket {
    XCTestExpectation* exception = [self expectationWithDescription:@"Delete bucket exception"];
    __block NSError* responseError ;
    QCloudPutBucketRequest* putBucketRequest = [[QCloudPutBucketRequest alloc] init];
    NSString* bucketName = [NSString stringWithFormat:@"bucketshouldbedelete%i",arc4random()%10000];
    putBucketRequest.bucket = bucketName;
    [putBucketRequest setFinishBlock:^(id outputObject, NSError* error) {
        XCTAssertNil(error);
        if (!error) {
            QCloudDeleteBucketRequest* request = [[QCloudDeleteBucketRequest alloc ] init];
            request.bucket = bucketName;
            [request setFinishBlock:^(id outputObject,NSError*error) {
                responseError = error;
                [exception fulfill];
            }];
            [[QCloudCOSXMLService defaultCOSXML] DeleteBucket:request];
        } else {
            [exception fulfill];
        }
    }];
    [[QCloudCOSXMLService defaultCOSXML] PutBucket:putBucketRequest];
    [self waitForExpectationsWithTimeout:100 handler:nil];
    XCTAssertNil(responseError);
}



- (void)testaPut_Get_Delete_BucketLifeCycle {
    QCloudPutBucketLifecycleRequest* request = [QCloudPutBucketLifecycleRequest new];
    __block NSString *bucketName =  [[QCloudCOSXMLTestUtility sharedInstance]createTestBucket];
    request.bucket = bucketName;
    __block QCloudLifecycleConfiguration* configuration = [[QCloudLifecycleConfiguration alloc] init];
    QCloudLifecycleRule* rule = [[QCloudLifecycleRule alloc] init];
    rule.identifier = @"id1";
    rule.status = QCloudLifecycleStatueEnabled;
    QCloudLifecycleRuleFilter* filter = [[QCloudLifecycleRuleFilter alloc] init];
    filter.prefix = @"0";
    rule.filter = filter;
    
    QCloudLifecycleTransition* transition = [[QCloudLifecycleTransition alloc] init];
    transition.days = 100;
    transition.storageClass = QCloudCOSStorageNearline;
    rule.transition = transition;
    request.lifeCycle = configuration;
    request.lifeCycle.rules = @[rule];
    XCTestExpectation* exception = [self expectationWithDescription:@"Put Bucket Life cycle exception"];
    [request setFinishBlock:^(id outputObject, NSError* putLifecycleError) {
        XCTAssertNil(putLifecycleError);
        //Get Configuration
        XCTAssertNil(putLifecycleError);
        QCloudGetBucketLifecycleRequest* request = [QCloudGetBucketLifecycleRequest new];
        request.bucket = bucketName;
        [request setFinishBlock:^(QCloudLifecycleConfiguration* getLifecycleReuslt,NSError* getLifeCycleError) {
            XCTAssertNil(getLifeCycleError);
            XCTAssertNotNil(getLifecycleReuslt);
            XCTAssert(getLifecycleReuslt.rules.count==configuration.rules.count);
            XCTAssert([getLifecycleReuslt.rules.firstObject.identifier isEqualToString:configuration.rules.firstObject.identifier]);
            XCTAssert(getLifecycleReuslt.rules.firstObject.status==configuration.rules.firstObject.status);
            
            //delete configuration
            QCloudDeleteBucketLifeCycleRequest* request = [[QCloudDeleteBucketLifeCycleRequest alloc ] init];
            request.bucket = bucketName;
            [request setFinishBlock:^(QCloudLifecycleConfiguration* deleteResult, NSError* deleteError) {
                XCTAssert(deleteResult);
                XCTAssertNil(deleteError);
                [[QCloudCOSXMLTestUtility sharedInstance]deleteTestBucket:bucketName];
                [exception fulfill];
            }];
            [[QCloudCOSXMLService defaultCOSXML] DeleteBucketLifeCycle:request];
            //delete configuration end
            
        }];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(8 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [[QCloudCOSXMLService defaultCOSXML] GetBucketLifecycle:request];
        });
        //Get configuration end
    }];
    [[QCloudCOSXMLService defaultCOSXML] PutBucketLifecycle:request];
    [self waitForExpectationsWithTimeout:100 handler:nil];
}





#pragma mark - karis
#pragma mark - bucketLifeCycle
//put bucket lifecycle，请求body中不指定filter
- (void)testPutBucketLifeCycleWithNoFilter {
    QCloudPutBucketLifecycleRequest* request = [QCloudPutBucketLifecycleRequest new];
    __block NSString *bucketName = [[QCloudCOSXMLTestUtility sharedInstance] createTestBucket];
    request.bucket = bucketName;
    __block QCloudLifecycleConfiguration* configuration = [[QCloudLifecycleConfiguration alloc] init];
    QCloudLifecycleRule* rule = [[QCloudLifecycleRule alloc] init];
    rule.identifier = @"identifier";
    rule.status = QCloudLifecycleStatueEnabled;
    QCloudLifecycleTransition* transition = [[QCloudLifecycleTransition alloc] init];
    transition.days = 100;
    transition.storageClass = QCloudCOSStorageNearline;
    rule.transition = transition;
    request.lifeCycle = configuration;
    request.lifeCycle.rules = @[rule];
    XCTestExpectation* exception = [self expectationWithDescription:@"Put Bucket Life cycle exception"];
    [request setFinishBlock:^(id outputObject, NSError* putLifecycleError) {
        XCTAssertNil(putLifecycleError);
        [[QCloudCOSXMLTestUtility sharedInstance] deleteTestBucket:bucketName];
        [exception fulfill];
    }];
    [[QCloudCOSXMLService defaultCOSXML] PutBucketLifecycle:request];
    [self waitForExpectationsWithTimeout:100 handler:nil];
}



#pragma mark - bucket

//put bucket,bucket名称带有-
- (void)testCreteBucketNameWithOne {
    QCloudPutBucketRequest* request = [QCloudPutBucketRequest new];
    __block NSString* bucketName = [NSString stringWithFormat:@"bucketcanbedelete%i-1",arc4random()%1000];
    request.bucket = bucketName;
    XCTestExpectation* exception = [self expectationWithDescription:@"Put new bucket with ont - exception"];
    __block NSError* responseError ;
    __weak typeof(self) weakSelf = self;
    [request setFinishBlock:^(id outputObject, NSError* error) {
        XCTAssertNil(error);
        XCTAssertNotNil(outputObject);
        [[QCloudCOSXMLTestUtility sharedInstance]deleteTestBucket: bucketName];
        [exception fulfill];
    }];
    [[QCloudCOSXMLService defaultCOSXML] PutBucket:request];
    [self waitForExpectationsWithTimeout:100 handler:nil];
    
    
}
//put bucket,bucket名称带有两个-
- (void)testCreteWithBucketNameWithTwo {
    QCloudPutBucketRequest* request = [QCloudPutBucketRequest new];
    __block NSString* bucketName = [NSString stringWithFormat:@"bucketcanbedelete%i--pp",arc4random()%1000];
    request.bucket = bucketName;
    XCTestExpectation* exception = [self expectationWithDescription:@"Put new bucket with two - exception"];
    __block NSError* responseError ;
    __weak typeof(self) weakSelf = self;
    [request setFinishBlock:^(id outputObject, NSError* error) {
        XCTAssertNil(error);
        XCTAssertNotNil(outputObject);
        [[QCloudCOSXMLTestUtility sharedInstance]deleteTestBucket: bucketName];
        [exception fulfill];
    }];
    [[QCloudCOSXMLService defaultCOSXML] PutBucket:request];
    [self waitForExpectationsWithTimeout:100 handler:nil];
    
    
    
}
//put bucket，bucket名称以-开头
- (void)testCreteIllegelBucketName {
    QCloudPutBucketRequest* putRequest = [QCloudPutBucketRequest new];
    NSString *testBucket = @"-karis-123";
    putRequest.bucket = testBucket;
    XCTestExpectation* exception = [self expectationWithDescription:@"Put new bucket with prefix is - exception"];
    __block NSError* responseError ;
    __weak typeof(self) weakSelf = self;
    [putRequest setFinishBlock:^(id outputObject, NSError* error) {
        XCTAssertNotNil(error,@"put Bucket fail! error detail is %@",error);
        [exception fulfill];
    }];
    [[QCloudCOSXMLService defaultCOSXML] PutBucket:putRequest];
    [self waitForExpectationsWithTimeout:100 handler:nil];
    
}

//测试创建已经存在的bucke名
- (void)testCreateExistBucketName {
    QCloudPutBucketRequest* request = [QCloudPutBucketRequest new];
    __block NSString *bucketName = [[QCloudCOSXMLTestUtility sharedInstance] createTestBucket];
    request.bucket = bucketName;
    XCTestExpectation* exception = [self expectationWithDescription:@"Put new bucket exception"];
    __block NSError* responseError ;
    __weak typeof(self) weakSelf = self;
    [request setFinishBlock:^(id outputObject, NSError* error) {
        XCTAssertNotNil(error);
        [[QCloudCOSXMLTestUtility sharedInstance] deleteTestBucket:bucketName];
        [exception fulfill];
    }];
    [[QCloudCOSXMLService defaultCOSXML] PutBucket:request];
    [self waitForExpectationsWithTimeout:100 handler:nil];
}

//get bucket,bucket为空
- (void)testGetEmptyBucket{
    QCloudGetBucketRequest *getBucket = [QCloudGetBucketRequest new];
    getBucket.bucket = [[QCloudCOSXMLTestUtility sharedInstance] createTestBucket];
    XCTestExpectation* exception = [self expectationWithDescription:@"get empty bucket exception"];
    __block NSError* responseError ;
    [getBucket setFinishBlock:^(id outputObject, NSError *error) {
        //error occucs if error != nil
        XCTAssertNil(error);
        responseError = error;
        [exception fulfill];
    }];
    [[QCloudCOSXMLService defaultCOSXML]GetBucket:getBucket];
    [self waitForExpectationsWithTimeout:100 handler:nil];
}



//delete bucket,bucket不存在
- (void)testDeleteNotExistBucket{
    QCloudDeleteBucketRequest* deleteBucket = [QCloudDeleteBucketRequest new];
    deleteBucket.bucket = @"buncunzai123";
    XCTestExpectation* exception = [self expectationWithDescription:@"delte not exist bucket exception"];
    __block NSError* responseError ;
    [deleteBucket setFinishBlock:^(id outputObject, NSError *error) {
        //error occucs if error != nil
        XCTAssertNotNil(error);
        XCTAssert(error.code == 404,@"error code is not equal to 404,it is %lu",error.code);
        responseError = error;
        [exception fulfill];
    }];
    [[QCloudCOSXMLService defaultCOSXML] DeleteBucket:deleteBucket];
    [self waitForExpectationsWithTimeout:100 handler:nil];
}



#pragma mark - bucket acl test


//put bucket acl，bucket不存在
- (void)testPutACLForNotExistBucket{
    QCloudPutBucketACLRequest* putACL = [QCloudPutBucketACLRequest new];
    NSString* appID = kAppID;
    NSString *ownerIdentifier = [NSString stringWithFormat:@"qcs::cam::uin/%@:uin/%@", appID, appID];
    NSString *grantString = [NSString stringWithFormat:@"id=\"%@\"",ownerIdentifier];
    putACL.grantFullControl = grantString;
    putACL.bucket = @"bucaunzaiios-karis-333";
    XCTestExpectation* exception = [self expectationWithDescription:@"Put bucket acl exception"];
    __block NSError* responseError ;
    [putACL setFinishBlock:^(id outputObject, NSError *error) {
        //error occucs if error != nil
        XCTAssertNotNil(error);
        XCTAssert(error.code == 404,@"error code is not equal to 404,it is %lu",error.code);
        responseError = error;
        [exception fulfill];
    }];
    [[QCloudCOSXMLService defaultCOSXML] PutBucketACL:putACL];
    [self waitForExpectationsWithTimeout:100 handler:nil];
}
//put bucket，设置bucket公公权限为private
-(void)testPutBucketAndSetACLIsPrivate{
    QCloudPutBucketRequest* putbucket = [QCloudPutBucketRequest new];
    putbucket.accessControlList = @"private";
    __block NSString *bucketName = [NSString stringWithFormat:@"bucketcanbedelete%ild",arc4random()%2000];
    putbucket.bucket = bucketName;
    XCTestExpectation* exception = [self expectationWithDescription:@"put bucket and set bucket acl is private exception"];
    __block NSError* responseError ;
    [putbucket setFinishBlock:^(id outputObject, NSError *error) {
        //error occucs if error != nil
        XCTAssertNil(error);
        responseError = error;
        [[QCloudCOSXMLTestUtility sharedInstance]deleteTestBucket: bucketName];
        [exception fulfill];
    }];
    [[QCloudCOSXMLService defaultCOSXML] PutBucket:putbucket];
    [self waitForExpectationsWithTimeout:100 handler:nil];
}
//put bucket，设置bucket公公权限为public-read
-(void)testPutBucketAndSetACLIsPublicRead{
    QCloudPutBucketRequest* putbucket = [QCloudPutBucketRequest new];
    putbucket.accessControlList = @"public-read";
    __block NSString *bucketName =  [NSString stringWithFormat:@"bucketcanbedelete%ikk",arc4random()%2000];
    putbucket.bucket = bucketName;
    XCTestExpectation* exception = [self expectationWithDescription:@"put bucket and set bucket acl is public-read exception"];
    __block NSError* responseError ;
    [putbucket setFinishBlock:^(id outputObject, NSError *error) {
        //error occucs if error != nil
        XCTAssertNil(error);
        responseError = error;
        [[QCloudCOSXMLTestUtility sharedInstance]deleteTestBucket: bucketName];
        [exception fulfill];
    }];
    [[QCloudCOSXMLService defaultCOSXML] PutBucket:putbucket];
    [self waitForExpectationsWithTimeout:100 handler:nil];
}
//put bucket，公共权限非法
-(void)testPutBucketAndSetACLIsInvalid{
    QCloudPutBucketRequest* putbucket = [QCloudPutBucketRequest new];
    putbucket.accessControlList = @"public-write";
    putbucket.bucket = [NSString stringWithFormat:@"bucketcanbedelete%io",arc4random()%2000];
    XCTestExpectation* exception = [self expectationWithDescription:@"put bucket and set bucket acl is  invalid exception"];
    __block NSError* responseError ;
    [putbucket setFinishBlock:^(id outputObject, NSError *error) {
        //error occucs if error != nil
        XCTAssertNotNil(error);
        XCTAssert(error.code == 400,@"error.code not equal to 400, it is %lu",error.code);
        responseError = error;
        [exception fulfill];
    }];
    [[QCloudCOSXMLService defaultCOSXML] PutBucket:putbucket];
    [self waitForExpectationsWithTimeout:100 handler:nil];
}

//put bucket，设置bucket账号权限为grant-read
-(void)testPutBucketAndSetGrantIsRead{
    if (!kEnableACLTest) {
        return ;
    }
    QCloudPutBucketRequest* putbucket = [QCloudPutBucketRequest new];
    NSString *ownerIdentifier = [NSString stringWithFormat:@"qcs::cam::uin/%@:uin/%@", kAuthorizedUIN, kAuthorizedUIN];
    NSString *grantString = [NSString stringWithFormat:@"id=\"%@\"",ownerIdentifier];
    putbucket.grantRead= grantString;
    __block NSString *bucketName = [NSString stringWithFormat:@"bucketcanbedelete%ip",arc4random()%2000];
    putbucket.bucket = bucketName;
    XCTestExpectation* exception = [self expectationWithDescription:@"put bucket and set bucket grant is  read exception"];
    __block NSError* responseError ;
    [putbucket setFinishBlock:^(id outputObject, NSError *error) {
        //error occucs if error != nil
        XCTAssertNil(error);
        responseError = error;
        [[QCloudCOSXMLTestUtility sharedInstance]deleteTestBucket: bucketName];
        [exception fulfill];
    }];
    [[QCloudCOSXMLService defaultCOSXML] PutBucket:putbucket];
    [self waitForExpectationsWithTimeout:100 handler:nil];
}

//put bucket，设置bucket账号权限为grant-write
-(void)testPutBucketAndSetGrantIsWrite{
    if (!kEnableACLTest) {
        return ;
    }
    QCloudPutBucketRequest* putbucket = [QCloudPutBucketRequest new];
    NSString *ownerIdentifier = [NSString stringWithFormat:@"qcs::cam::uin/%@:uin/%@", kAuthorizedUIN, kAuthorizedUIN];
    NSString *grantString = [NSString stringWithFormat:@"id=\"%@\"",ownerIdentifier];
    putbucket.grantWrite= grantString;
    __block NSString *bucketName = [NSString stringWithFormat:@"bucketcanbedelete%iq",arc4random()%2000];
    putbucket.bucket = bucketName;
    XCTestExpectation* exception = [self expectationWithDescription:@"put bucket and set grand acl is write  exception"];
    __block NSError* responseError ;
    [putbucket setFinishBlock:^(id outputObject, NSError *error) {
        //error occucs if error != nil
        XCTAssertNil(error);
        XCTAssertNotNil(outputObject);
        [[QCloudCOSXMLTestUtility sharedInstance]deleteTestBucket: bucketName];
        [exception fulfill];
    }];
    [[QCloudCOSXMLService defaultCOSXML] PutBucket:putbucket];
    [self waitForExpectationsWithTimeout:100 handler:nil];
}

//put bucket，设置bucket账号权限为grant-full-control
-(void)testPutBucketAndSetGrantIsfullControl{
    if (!kEnableACLTest) {
        return ;
    }
    QCloudPutBucketRequest* putbucket = [QCloudPutBucketRequest new];
    NSString *ownerIdentifier = [NSString stringWithFormat:@"qcs::cam::uin/%@:uin/%@", kAuthorizedUIN, kAuthorizedUIN];
    NSString *grantString = [NSString stringWithFormat:@"id=\"%@\"",ownerIdentifier];
    putbucket.grantFullControl = grantString;
    __block NSString *bucketName = [NSString stringWithFormat:@"bucketcanbedelete%ipo",arc4random()%2000];
    putbucket.bucket = bucketName;
    XCTestExpectation* exception = [self expectationWithDescription:@"put bucket and set bucket grant is  full control exception"];
    __block NSError* responseError ;
    [putbucket setFinishBlock:^(id outputObject, NSError *error) {
        //error occucs if error != nil
        XCTAssertNil(error);
        XCTAssertNotNil(outputObject);
        [[QCloudCOSXMLTestUtility sharedInstance]deleteTestBucket: bucketName];
        [exception fulfill];
    }];
    [[QCloudCOSXMLService defaultCOSXML] PutBucket:putbucket];
    [self waitForExpectationsWithTimeout:100 handler:nil];
}

//put bucket，设置bucket账号权限，同时指定read、write和fullcontrol
-(void)testPutBucketAndSetGrantareReadAndWriteAndfullControl{
    if (!kEnableACLTest) {
        return ;
    }
    QCloudPutBucketRequest* putbucket = [QCloudPutBucketRequest new];
    NSString *ownerIdentifier = [NSString stringWithFormat:@"qcs::cam::uin/%@:uin/%@", kAuthorizedUIN, kAuthorizedUIN];
    NSString *grantString = [NSString stringWithFormat:@"id=\"%@\"",ownerIdentifier];
    putbucket.grantFullControl = grantString;
    putbucket.grantWrite= grantString;
    putbucket.grantRead = grantString;
    __block NSString *bucketName = [NSString stringWithFormat:@"bucketcanbedelete%iww",arc4random()%2000];
    putbucket.bucket = bucketName;
    XCTestExpectation* exception = [self expectationWithDescription:@"put bucket and set bucket grant are read and write and  full control exception"];
    __block NSError* responseError ;
    [putbucket setFinishBlock:^(id outputObject, NSError *error) {
        //error occucs if error != nil
        XCTAssertNil(error);
        XCTAssertNotNil(outputObject);
        [[QCloudCOSXMLTestUtility sharedInstance]deleteTestBucket: bucketName];
        [exception fulfill];
    }];
    [[QCloudCOSXMLService defaultCOSXML] PutBucket:putbucket];
    [self waitForExpectationsWithTimeout:100 handler:nil];
}
//put bucket，设置bucket账号权限，grant值非法
-(void)testPutBucketAndSetInvalidGrant{
    QCloudPutBucketRequest* putbucket = [QCloudPutBucketRequest new];
    NSString *ownerIdentifier = [NSString stringWithFormat:@"illegel%@%@", kAppID, kAppID];
    NSString *grantString = [NSString stringWithFormat:@"id=\"%@\"",ownerIdentifier];
    putbucket.grantFullControl = grantString;
    putbucket.grantWrite= grantString;
    putbucket.grantRead = grantString;
    putbucket.bucket = [NSString stringWithFormat:@"bucketcanbedelete%ih",arc4random()%2000];
    XCTestExpectation* exception = [self expectationWithDescription:@"put bucket and set bucket invalid grant exception"];
    __block NSError* responseError ;
    [putbucket setFinishBlock:^(id outputObject, NSError *error) {
        //error occucs if error != nil
        XCTAssertNotNil(error);
        //        XCTAssert(error.code == 400,@"error.code != 400,it is %lu",error.code);
        [exception fulfill];
    }];
    [[QCloudCOSXMLService defaultCOSXML] PutBucket:putbucket];
    [self waitForExpectationsWithTimeout:100 handler:nil];
}
////put bucket，设置bucket账号权限，同时授权给多个账户
//-(void)testPutBucketAndSetGrantToMannyAccounts{
//    QCloudPutBucketRequest* putbucket = [QCloudPutBucketRequest new];
//    NSString *ownerIdentifier = [NSString stringWithFormat:@"qcs::cam::uin/%@:uin/%@", @"3210232098", @"3210232098"];
//    NSString *grantString = [NSString stringWithFormat:@"id=\"%@\"",ownerIdentifier];
//    NSString *ownerIdentifier1 = [NSString stringWithFormat:@"qcs::cam::uin/%@:uin/%@", @"1030872851", @"1030872851"];
//    NSString *grantString1 = [NSString stringWithFormat:@"id=\"%@\"",ownerIdentifier1];
//    putbucket.grantRead = grantString;
//    putbucket.grantWrite = grantString1;
//    putbucket.bucket = [NSString stringWithFormat:@"bucketcanbedelete1%u",arc4random()%2000];
//    XCTestExpectation* exception = [self expectationWithDescription:@"put bucket and set bucket grant are read and write and  full control exception"];
//    __block NSError* responseError ;
//    [putbucket setFinishBlock:^(id outputObject, NSError *error) {
//        //error occucs if error != nil
//        XCTAssertNil(error);
//        XCTAssertNotNil(outputObject);
//        [exception fulfill];
//    }];
//    [[QCloudCOSXMLService defaultCOSXML] PutBucket:putbucket];
//    [self waitForExpectationsWithTimeout:100 handler:nil];
//}

//put bucket，设置bucket账号权限，授权给子账号
-(void)testPutBucketAndSetGrantToSubAccounts{
    if (!kEnableACLTest) {
        return ;
    }
    QCloudPutBucketRequest* putbucket = [QCloudPutBucketRequest new];
    NSString *ownerIdentifier = [NSString stringWithFormat:@"qcs::cam::uin/%@:uin/%@", kAuthorizedUIN, kAuthorizedUIN];
    NSString *grantString = [NSString stringWithFormat:@"id=\"%@\"",ownerIdentifier];
    putbucket.grantRead = grantString;
    
    NSString *ownerIdentifier1 = [NSString stringWithFormat:@"qcs::cam::uin/%@:uin/%@", kAppID, kAppID];
    NSString *grantString1 = [NSString stringWithFormat:@"id=\"%@\"",ownerIdentifier1];
    putbucket.grantWrite = grantString1;
    __block NSString *bucketName = [NSString stringWithFormat:@"bucketcanbedelete%il",arc4random()%2000];
    putbucket.bucket = bucketName;
    
    XCTestExpectation* exception = [self expectationWithDescription:@"put bucket and set bucket grant are read and write and  full control exception"];
    __block NSError* responseError ;
    [putbucket setFinishBlock:^(id outputObject, NSError *error) {
        //error occucs if error != nil
        XCTAssertNil(error);
        XCTAssertNotNil(outputObject);
        [[QCloudCOSXMLTestUtility sharedInstance]deleteTestBucket: bucketName];
        [exception fulfill];
    }];
    [[QCloudCOSXMLService defaultCOSXML] PutBucket:putbucket];
    [self waitForExpectationsWithTimeout:100 handler:nil];
}


//put bucket acl，设置bucket公公权限为private
-(void)testPutBucketACLWithPrivate{
    if (!kEnableACLTest) {
        return ;
    }
    QCloudPutBucketACLRequest  *bucketRequest = [QCloudPutBucketACLRequest new];
    bucketRequest.accessControlList = @"private";
    __block NSString *bucketName = [[QCloudCOSXMLTestUtility sharedInstance] createTestBucket];
    bucketRequest.bucket = bucketName;
    XCTestExpectation* exp = [self expectationWithDescription:@"put bucket acl with private exception"];
    [bucketRequest setFinishBlock:^(id outputObject, NSError *error) {
        XCTAssertNil(error);
        XCTAssertNotNil(outputObject);
        [[QCloudCOSXMLTestUtility sharedInstance] deleteTestBucket:bucketName];
        [exp fulfill];
    }];
    [[QCloudCOSXMLService defaultCOSXML]PutBucketACL:bucketRequest];
    [self waitForExpectationsWithTimeout:100 handler:nil];
}

//put bucket acl，公共权限非法
-(void)testPutBucketACLWithInvalid{
    if (!kEnableACLTest) {
        return ;
    }
    QCloudPutBucketACLRequest  *bucketRequest = [QCloudPutBucketACLRequest new];
    bucketRequest.accessControlList = @"public-write";
    __block NSString *bucketName = [[QCloudCOSXMLTestUtility sharedInstance] createTestBucket];
    bucketRequest.bucket = bucketName;
    XCTestExpectation* exp = [self expectationWithDescription:@"put bucket acl with Invalid exception"];
    [bucketRequest setFinishBlock:^(id outputObject, NSError *error) {
        XCTAssertNotNil(error);
        XCTAssert(error.code==400,@"error code is not equal to 400,it is %lu",error.code);
        [[QCloudCOSXMLTestUtility sharedInstance] deleteTestBucket:bucketName];
        [exp fulfill];
    }];
    [[QCloudCOSXMLService defaultCOSXML]PutBucketACL:bucketRequest];
    [self waitForExpectationsWithTimeout:100 handler:nil];
}
//put bucket acl，设置bucket账号权限为grant-read
-(void)testPutBucketGrantWithRead{
    if (!kEnableACLTest) {
        return ;
    }
    QCloudPutBucketACLRequest *putACLRequst = [QCloudPutBucketACLRequest new];
    __block NSString *bucketName = [[QCloudCOSXMLTestUtility sharedInstance] createTestBucket];
    putACLRequst.bucket = bucketName;
    NSString *ownerIdentifier = [NSString stringWithFormat:@"qcs::cam::uin/%@:uin/%@", kAuthorizedUIN, kAuthorizedUIN];
    NSString *grantString = [NSString stringWithFormat:@"id=\"%@\"",ownerIdentifier];
    putACLRequst.grantRead= grantString;
    XCTestExpectation* exp = [self expectationWithDescription:@"puta bucket grant is grand-read expectation"];
    [putACLRequst setFinishBlock:^(id outputObject, NSError *error) {
        XCTAssertNil(error);
        XCTAssertNotNil(outputObject);
        [[QCloudCOSXMLTestUtility sharedInstance]deleteTestBucket:bucketName];
        [exp fulfill];
    }];
    [[QCloudCOSXMLService defaultCOSXML] PutBucketACL:putACLRequst];
    [self waitForExpectationsWithTimeout:100 handler:nil];
    
}

//put bucket acl，设置bucket账号权限为grant-write
-(void)testPutBucketGrantWithWrite{
    if (!kEnableACLTest) {
        return ;
    }
    QCloudPutBucketACLRequest *putACLRequst = [QCloudPutBucketACLRequest new];
    __block NSString *bucketName = [[QCloudCOSXMLTestUtility sharedInstance] createTestBucket];
    putACLRequst.bucket = bucketName;
    NSString *ownerIdentifier = [NSString stringWithFormat:@"qcs::cam::uin/%@:uin/%@", kAuthorizedUIN, kAuthorizedUIN];
    NSString *grantString = [NSString stringWithFormat:@"id=\"%@\"",ownerIdentifier];
    putACLRequst.grantWrite= grantString;
    XCTestExpectation* exp = [self expectationWithDescription:@"puta bucket grant is grand-write expectation"];
    [putACLRequst setFinishBlock:^(id outputObject, NSError *error) {
        XCTAssertNil(error);
        XCTAssertNotNil(outputObject);
        [[QCloudCOSXMLTestUtility sharedInstance] deleteTestBucket:bucketName];
        [exp fulfill];
    }];
    [[QCloudCOSXMLService defaultCOSXML] PutBucketACL:putACLRequst];
    [self waitForExpectationsWithTimeout:100 handler:nil];
    
}

//put bucket acl，设置bucket账号权限为grant-full-control
-(void)testPutBucketGrantWithfullControl{
    if (!kEnableACLTest) {
        return ;
    }
    QCloudPutBucketACLRequest *putACLRequst = [QCloudPutBucketACLRequest new];
    __block NSString *bucketName = [[QCloudCOSXMLTestUtility sharedInstance] createTestBucket];
    putACLRequst.bucket = bucketName;
    NSString *ownerIdentifier = [NSString stringWithFormat:@"qcs::cam::uin/%@:uin/%@", kAuthorizedUIN, kAuthorizedUIN];
    NSString *grantString = [NSString stringWithFormat:@"id=\"%@\"",ownerIdentifier];
    putACLRequst.grantFullControl= grantString;
    XCTestExpectation* exp = [self expectationWithDescription:@"puta bucket grant is grantFullControl expectation"];
    [putACLRequst setFinishBlock:^(id outputObject, NSError *error) {
        XCTAssertNil(error);
        XCTAssertNotNil(outputObject);
        [[QCloudCOSXMLTestUtility sharedInstance] deleteTestBucket:bucketName];
        [exp fulfill];
    }];
    [[QCloudCOSXMLService defaultCOSXML] PutBucketACL:putACLRequst];
    [self waitForExpectationsWithTimeout:100 handler:nil];
    
}
// put bucket acl，设置bucket账号权限，同时指定read、write和fullcontrol
-(void)testPutBucketGrantWithreadAndWriteandfullControl{
    if (!kEnableACLTest) {
        return ;
    }
    QCloudPutBucketACLRequest *putACLRequst = [QCloudPutBucketACLRequest new];
    __block NSString *bucketName = [[QCloudCOSXMLTestUtility sharedInstance] createTestBucket];
    putACLRequst.bucket = bucketName;
    NSString *ownerIdentifier = [NSString stringWithFormat:@"qcs::cam::uin/%@:uin/%@", kAuthorizedUIN, kAuthorizedUIN];
    NSString *grantString = [NSString stringWithFormat:@"id=\"%@\"",ownerIdentifier];
    putACLRequst.grantFullControl= grantString;
    putACLRequst.grantWrite = grantString;
    putACLRequst.grantRead = grantString;
    XCTestExpectation* exp = [self expectationWithDescription:@"puta bucket grant are read ang wirte and grantFullControl expectation"];
    [putACLRequst setFinishBlock:^(id outputObject, NSError *error) {
        XCTAssertNil(error);
        XCTAssertNotNil(outputObject);
        [[QCloudCOSXMLTestUtility sharedInstance] deleteTestBucket:bucketName];
        [exp fulfill];
    }];
    [[QCloudCOSXMLService defaultCOSXML] PutBucketACL:putACLRequst];
    [self waitForExpectationsWithTimeout:100 handler:nil];
    
}

//put bucket acl，设置bucket账号权限，grant值非法
-(void)testPutBucketGrantWithInvalid{
    QCloudPutBucketACLRequest *putACLRequst = [QCloudPutBucketACLRequest new];
    __block NSString *bucketName = [[QCloudCOSXMLTestUtility sharedInstance] createTestBucket];
    putACLRequst.bucket = bucketName;
    NSString *ownerIdentifier = [NSString stringWithFormat:@"hhh%@:/%@", kAppID, kAppID];
    NSString *grantString = [NSString stringWithFormat:@"id=\"%@\"",ownerIdentifier];
    putACLRequst.grantRead = grantString;
    XCTestExpectation* exp = [self expectationWithDescription:@"puta bucket grant is Invalid expectation"];
    [putACLRequst setFinishBlock:^(id outputObject, NSError *error) {
        XCTAssertNotNil(error);
        XCTAssert(error.code == 400,@"srror.code != 400,it is %lu",error.code);
        [exp fulfill];
    }];
    [[QCloudCOSXMLService defaultCOSXML] PutBucketACL:putACLRequst];
    [self waitForExpectationsWithTimeout:100 handler:nil];
    
}
//put bucket acl，设置bucket公公权限为public-read
-(void)testPutBucketACLWithPublicRead{
    QCloudPutBucketACLRequest  *bucketRequest = [QCloudPutBucketACLRequest new];
    bucketRequest.accessControlList = @"public-read";
    __block NSString *bucketName = [[QCloudCOSXMLTestUtility sharedInstance] createTestBucket];
    bucketRequest.bucket = bucketName;
    XCTestExpectation* exp = [self expectationWithDescription:@"put bucket acl with public-read exception"];
    [bucketRequest setFinishBlock:^(id outputObject, NSError *error) {
        XCTAssertNil(error);
        XCTAssertNotNil(outputObject);
        [[QCloudCOSXMLTestUtility sharedInstance] deleteTestBucket:bucketName];
        [exp fulfill];
    }];
    [[QCloudCOSXMLService defaultCOSXML]PutBucketACL:bucketRequest];
    [self waitForExpectationsWithTimeout:100 handler:nil];
}
////put bucket acl，设置bucket账号权限，同时授权给多个账户
//-(void)testPutBucketGrantToMannyAccounts{
//    QCloudPutBucketACLRequest* putbucketACl = [QCloudPutBucketACLRequest new];
//    NSString *ownerIdentifier = [NSString stringWithFormat:@"qcs::cam::uin/%@:uin/%@", @"2832742109", @"2832742109"];
//    NSString *grantString = [NSString stringWithFormat:@"id=\"%@\"",ownerIdentifier];
//    NSString *ownerIdentifier1 = [NSString stringWithFormat:@"qcs::cam::uin/%@:uin/%@", @"1030872851", @"1030872851"];
//    NSString *grantString1 = [NSString stringWithFormat:@"id=\"%@\"",ownerIdentifier1];
//    putbucketACl.grantRead = grantString;
//    putbucketACl.grantRead = grantString1;
//    putbucketACl.bucket = self.bucket;
//    XCTestExpectation* exception = [self expectationWithDescription:@"put bucket and set bucket grant are read and write and  full control exception"];
//    __block NSError* responseError ;
//    [putbucketACl setFinishBlock:^(id outputObject, NSError *error) {
//        //error occucs if error != nil
//        XCTAssertNil(error);
//        XCTAssertNotNil(outputObject);
//        [exception fulfill];
//    }];
//    [[QCloudCOSXMLService defaultCOSXML] PutBucketACL:putbucketACl];
//    [self waitForExpectationsWithTimeout:100 handler:nil];
//}

// put bucket acl，设置bucket账号权限，授权给子账号
-(void)testPutBucketGrantToSubAccount{
    if (!kEnableACLTest) {
        return ;
    }
    QCloudPutBucketACLRequest* putbucketACl = [QCloudPutBucketACLRequest new];
    NSString *ownerIdentifier = [NSString stringWithFormat:@"qcs::cam::uin/%@:uin/%@",kAuthorizedUIN,kAuthorizedUIN];
    NSString *grantString = [NSString stringWithFormat:@"id=\"%@\"",ownerIdentifier];
    putbucketACl.grantFullControl = grantString;
    __block NSString *bucketName = [[QCloudCOSXMLTestUtility sharedInstance] createTestBucket];
    putbucketACl.bucket = bucketName;
    XCTestExpectation* exception = [self expectationWithDescription:@"put bucket and set bucket grant are read and write and  full control exception"];
    __block NSError* responseError ;
    [putbucketACl setFinishBlock:^(id outputObject, NSError *error) {
        //error occucs if error != nil
        XCTAssertNil(error);
        XCTAssertNotNil(outputObject);
       [[QCloudCOSXMLTestUtility sharedInstance] deleteTestBucket:bucketName];
        [exception fulfill];
    }];
    [[QCloudCOSXMLService defaultCOSXML] PutBucketACL:putbucketACl];
    [self waitForExpectationsWithTimeout:100 handler:nil];
}

//get bucket acl,bucket未设置acl信息
- (void) testGetBucketWithNotSetAcl {
    QCloudGetBucketRequest* getRequest = [QCloudGetBucketRequest new];
    getRequest.bucket = [[QCloudCOSXMLTestUtility sharedInstance]createTestBucket];
    XCTestExpectation* exception = [self expectationWithDescription:@"get bucket acl and not bucket didn’t set acl exception"];
    __block NSError* responseError ;
    __weak typeof(self) weakSelf = self;
    [getRequest setFinishBlock:^(id outputObject, NSError* error) {
        XCTAssertNil(error);
        [exception fulfill];
    }];
    [[QCloudCOSXMLService defaultCOSXML] GetBucket:getRequest];
    [self waitForExpectationsWithTimeout:100 handler:nil];
}


#pragma mark - cors


//bucket未设置cors规则，发送get bucket cors
-(void)testGetBucketWithNotSetcors{
    
    XCTestExpectation* exp = [self expectationWithDescription:@"get cors ang the bucket didn't set cors "];
    QCloudGetBucketLocationRequest* locationReq = [QCloudGetBucketLocationRequest new];
    locationReq.bucket = [[QCloudCOSXMLTestUtility sharedInstance] createTestBucket];
    __block QCloudBucketLocationConstraint* location;
    [locationReq setFinishBlock:^(QCloudBucketLocationConstraint * _Nonnull result, NSError * _Nonnull error) {
        XCTAssertNil(error);
        [exp fulfill];
    }];
    [[QCloudCOSXMLService defaultCOSXML] GetBucketLocation:locationReq];
    [self waitForExpectationsWithTimeout:100 handler:nil];
}

#pragma mark - list parts

- (void)testListMultipartUploadWithMoreInfo {
    
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    QCloudCOSXMLUploadObjectRequest* uploadObjectRequest = [[QCloudCOSXMLUploadObjectRequest alloc] init];
    __block NSString *bucketName = [[QCloudCOSXMLTestUtility sharedInstance] createTestBucket];
    uploadObjectRequest.bucket = bucketName;
    uploadObjectRequest.object = [[QCloudCOSXMLTestUtility sharedInstance]createCanbeDeleteTestObject];
    uploadObjectRequest.body = [NSURL fileURLWithPath:[QClouldCreateTempFile tempFileWithSize:5 unit:QCLOUD_TEMP_FILE_UNIT_MB]];
    __weak QCloudCOSXMLUploadObjectRequest* weakRequest = uploadObjectRequest;
    __block NSString* uploadID ;
    [uploadObjectRequest setSendProcessBlock:^(int64_t bytesSent, int64_t totalBytesSent, int64_t totalBytesExpectedToSend) {
        if (totalBytesSent > totalBytesExpectedToSend*0.5 ) {
            [weakRequest cancel];
        }
    }];
    uploadObjectRequest.initMultipleUploadFinishBlock = ^(QCloudInitiateMultipartUploadResult *multipleUploadInitResult, QCloudCOSXMLUploadObjectResumeData resumeData) {
        uploadID = multipleUploadInitResult.uploadId;
    };
    [uploadObjectRequest setFinishBlock:^(QCloudUploadObjectResult *result, NSError *error) {
        dispatch_semaphore_signal(semaphore);
    }];
    [[QCloudCOSTransferMangerService defaultCOSTransferManager] UploadObject:uploadObjectRequest];
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    
    
    
    QCloudListMultipartRequest* request = [[QCloudListMultipartRequest alloc] init];
    request.bucket = bucketName;
    request.object = uploadObjectRequest.object;
    request.uploadId = uploadID;
    
    XCTestExpectation* expectation = [self expectationWithDescription:@"test" ];
    [request setFinishBlock:^(QCloudListPartsResult * _Nonnull result, NSError * _Nonnull error) {
        XCTAssertNil(error);
        XCTAssert(result);
        [[QCloudCOSXMLTestUtility sharedInstance] deleteTestBucket:bucketName];
        [expectation fulfill];
    }];
    [[QCloudCOSXMLService defaultCOSXML] ListMultipart:request];
    [self waitForExpectationsWithTimeout:80 handler:nil];
}


#pragma mark - demo


- (void)testPutObjectCopy {

    __block NSString *bucket = [[QCloudCOSXMLTestUtility sharedInstance] createTestBucket];
    __block NSString* copyObjectSourceName = [NSUUID UUID].UUIDString;
    QCloudPutObjectRequest* put = [QCloudPutObjectRequest new];
    put.object = copyObjectSourceName;
    put.bucket = bucket;
//    NSString *ownerIdentifier = [NSString stringWithFormat:@"qcs::cam::uin/%@:uin/%@", kAppID,kAppID];
//    NSString *grantString = [NSString stringWithFormat:@"id=\"%@\"",ownerIdentifier];
//    put.grantFullControl = grantString;
    put.body =  [@"4324ewr325" dataUsingEncoding:NSUTF8StringEncoding];
    __block XCTestExpectation* exception = [self expectationWithDescription:@"Put Object Copy Exception"];
    __block NSError* putObjectCopyError;
    __block NSError* resultError;
    __block QCloudCopyObjectResult* copyObjectResult;
    [put setFinishBlock:^(id outputObject, NSError *error) {
            NSURL* serviceURL = [[QCloudCOSXMLService defaultCOSXML].configuration.endpoint serverURLWithBucket:bucket appID:kAppID];
            NSMutableString* objectCopySource = [serviceURL.absoluteString mutableCopy] ;
            [objectCopySource appendFormat:@"/%@",copyObjectSourceName];
            objectCopySource = [[objectCopySource substringFromIndex:7] mutableCopy];
            QCloudPutObjectCopyRequest* request = [[QCloudPutObjectCopyRequest alloc] init];
            request.bucket = bucket;
            request.object = copyObjectSourceName;
            request.metadataDirective = @"Replaced";
            request.objectCopySource = objectCopySource;
            [request setFinishBlock:^(QCloudCopyObjectResult* result, NSError* error) {
                putObjectCopyError = result;
                resultError = error;
                [[QCloudCOSXMLTestUtility sharedInstance] deleteTestBucket:bucket];
                [exception fulfill];
            }];
            [[QCloudCOSXMLService defaultCOSXML] PutObjectCopy:request];
        }];
    [[QCloudCOSXMLService defaultCOSXML] PutObject:put];
    [self waitForExpectationsWithTimeout:100 handler:nil];
    XCTAssertNil(resultError);
    
}


//- (void)testMultiplePutObjectCopy {
//    QCloudCOSXMLCopyObjectRequest* request = [[QCloudCOSXMLCopyObjectRequest alloc] init];
//    request.bucket = self.bucket;
//    request.object = @"copy-result-test";
//    request.sourceBucket = @"xy3";
//    request.sourceObject = @"Frameworks.zip";
//    request.sourceAPPID = [QCloudCOSXMLService defaultCOSXML].configuration.appID;
//    request.sourceRegion= @"ap-guangzhou";
//
//    XCTestExpectation* expectation = [self expectationWithDescription:@"Put Object Copy"];
//    [request setFinishBlock:^(QCloudCopyObjectResult* result, NSError* error) {
//        XCTAssertNil(error);
//        [expectation fulfill];
//    }];
//    [[QCloudCOSTransferMangerService defaultCOSTRANSFERMANGER] CopyObject:request];
//    [self waitForExpectationsWithTimeout:10000 handler:nil];
//
//
//}


//- (void)testGetObjectURL {
//    NSString* objectDownloadURL = [[QCloudCOSXMLService defaultCOSXML] getURLWithBucket:@"ios-v2-test" object:@"005HSIzAjw1f9lpbftcy0j31hc0xct9m.jpg" withAuthorization:YES];
//    NSMutableURLRequest* request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:objectDownloadURL]];
//    request.cachePolicy = NSURLRequestReloadIgnoringCacheData;
//    XCTestExpectation* expectation = [self expectationWithDescription:@"get object url"];
//    [[[NSURLSession sharedSession] downloadTaskWithRequest:request completionHandler:^(NSURL * _Nullable location, NSURLResponse * _Nullable response, NSError * _Nullable error) {
//        XCTAssertNil(error);
//        NSInteger statusCode = [(NSHTTPURLResponse*)response statusCode];
//        XCTAssert(statusCode>199&&statusCode<300,@"StatusCode not equal to 2xx! statu code is %ld, response is %@",(long)statusCode,response);
//        XCTAssert(QCloudFileExist(location.path),@"File not exist!");
//        [expectation fulfill];
//    }] resume];
//    [self waitForExpectationsWithTimeout:80 handler:nil];
//}

//- (void)testGetPresignedURL {
//    QCloudGetPresignedURLRequest* getPresignedURLRequest = [[QCloudGetPresignedURLRequest alloc] init];
//    getPresignedURLRequest.bucket = @"ios-v2-test";
//    getPresignedURLRequest.object = @"005HSIzAjw1f9lpbftcy0j31hc0xct9m.jpg";
//    getPresignedURLRequest.HTTPMethod = @"GET";
//    XCTestExpectation* expectation = [self expectationWithDescription:@"GET PRESIGNED URL"];
//    [getPresignedURLRequest setFinishBlock:^(QCloudGetPresignedURLResult *result, NSError *error) {
//        XCTAssertNil(error,@"error occured in getting presigned URL ! details:%@",error);
//        XCTAssertNotNil(result.presienedURL,@"presigned url is nil!");
//        NSString* objectDownloadURL = result.presienedURL;
//        NSMutableURLRequest* request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:objectDownloadURL]];
//        [request setHTTPMethod:@"GET"];
//        [[[NSURLSession sharedSession] downloadTaskWithRequest:request completionHandler:^(NSURL * _Nullable location, NSURLResponse * _Nullable response, NSError * _Nullable error) {
//            XCTAssertNil(error);
//            NSInteger statusCode = [(NSHTTPURLResponse*)response statusCode];
//            XCTAssert(statusCode>199&&statusCode<300,@"StatusCode not equal to 2xx! statu code is %ld, response is %@",(long)statusCode,response);
//            XCTAssert(QCloudFileExist(location.path),@"File not exist!");
//            [expectation fulfill];
//        }] resume];
//    }];
//    [[QCloudCOSXMLService defaultCOSXML] getPresignedURL:getPresignedURLRequest];
//    [self waitForExpectationsWithTimeout:80 handler:nil];
//}
//



//- (void)testListObjectVersions {
//    QCloudPutBucketVersioningRequest* putBucketVersioningRequest = [[QCloudPutBucketVersioningRequest alloc] init];
//    putBucketVersioningRequest.bucket = self.bucket;
//    putBucketVersioningRequest.configuration = [[QCloudBucketVersioningConfiguration alloc] init];
//    putBucketVersioningRequest.configuration.status = QCloudCOSBucketVersioningStatusEnabled;
//    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
//    [putBucketVersioningRequest setFinishBlock:^(id outputObject, NSError *error) {
//        dispatch_semaphore_signal(semaphore);
//    }];
//    NSString* tempObject = [[QCloudCOSXMLTestUtility sharedInstance]uploadTempObjectInBucket:self.bucket];
//    NSString* tempObject2 = [[QCloudCOSXMLTestUtility sharedInstance]uploadTempObjectInBucket:self.bucket];
//    [[QCloudCOSXMLService defaultCOSXML] PutBucketVersioning:putBucketVersioningRequest];
//    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
//    XCTestExpectation* expectation = [self expectationWithDescription:@"haha"];
//
//
//    QCloudListObjectVersionsRequest* listObjectRequest = [[QCloudListObjectVersionsRequest alloc] init];
//    listObjectRequest.maxKeys = 100;
//    listObjectRequest.bucket = self.bucket;
//    [listObjectRequest setFinishBlock:^(QCloudListVersionsResult * _Nonnull result, NSError * _Nonnull error) {
//        XCTAssertNil(error);
//        XCTAssertNotNil(result);
//
//        [expectation fulfill];
//    }];
//    [[QCloudCOSXMLService defaultCOSXML] ListObjectVersions:listObjectRequest];
//    [self waitForExpectationsWithTimeout:80 handler:nil];
//    putBucketVersioningRequest.configuration.status = QCloudCOSBucketVersioningStatusSuspended;
//    [[QCloudCOSXMLService defaultCOSXML] PutBucketVersioning:putBucketVersioningRequest];
//}

#pragma mark - object copy
//put object copy，源文件不存在
- (void)testPutObjectCopyAndNoSource {
    NSString* copyObjectSourceName = @"bucnunzaiuo999";
    __block XCTestExpectation* exception = [self expectationWithDescription:@"Put Object Copy Exception"];
    __block NSError* putObjectCopyError;
    __block NSError* resultError;
    __block QCloudCopyObjectResult* copyObjectResult;
    __block NSString *bucketName = [[QCloudCOSXMLTestUtility sharedInstance] createTestBucket];
    NSURL* serviceURL = [[QCloudCOSXMLService defaultCOSXML].configuration.endpoint serverURLWithBucket:bucketName appID:kAppID];
    NSMutableString* objectCopySource = [serviceURL.absoluteString mutableCopy] ;
    [objectCopySource appendFormat:@"/%@",copyObjectSourceName];
    objectCopySource = [[objectCopySource substringFromIndex:7] mutableCopy];
    QCloudPutObjectCopyRequest* request = [[QCloudPutObjectCopyRequest alloc] init];
    request.bucket = bucketName;
    request.object = [NSUUID UUID].UUIDString;
    request.objectCopySource = objectCopySource;
    [request setFinishBlock:^(QCloudCopyObjectResult* result, NSError* error) {
        XCTAssertNotNil(error);
        XCTAssert(error.code == 404,@"error.code != 404,it is %lu",error.code);
        putObjectCopyError = result;
        resultError = error;
       [[QCloudCOSXMLTestUtility sharedInstance] deleteTestBucket:bucketName];
        [exception fulfill];
    }];
    [[QCloudCOSXMLService defaultCOSXML] PutObjectCopy:request];
    [self waitForExpectationsWithTimeout:100 handler:nil];
    
}

//- (void)testPutObjectCopyfromAnotherRegion {
//    __block XCTestExpectation* exception = [self expectationWithDescription:@"Put Object Copy Exception"];
//    QCloudPutObjectCopyRequest* request = [[QCloudPutObjectCopyRequest alloc] init];
//    request.bucket = self.bucket;
//    request.object = @"MTg0NDY3NDI1NTk0MzUwNDQ1OTg";
//    request.objectCopySource = @"lewzylu02-1252448703.cos.ap-guangzhou.myqcloud.com/test1G?versionId=MTg0NDY3NDI1NTk0MzUwNDQ1OTg";
//    [request setFinishBlock:^(QCloudCopyObjectResult* result, NSError* error) {
//        XCTAssertNil(error);
//        [exception fulfill];
//    }];
//    [[QCloudCOSXMLService defaultCOSXML] PutObjectCopy:request];
//    [self waitForExpectationsWithTimeout:100 handler:nil];
//
//}

+(void)tool{
    
}

@end
