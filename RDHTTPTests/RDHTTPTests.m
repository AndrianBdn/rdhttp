//
//  RDHTTPTests.m
//  RDHTTPTests
//
//  Created by Andrian Budantsov on 26.11.11.
//  Copyright (c) 2011 Readdle. All rights reserved.
//

#import "RDHTTPTests.h"
#import "RDHTTP.h"

static const NSTimeInterval runloopTimerResolution = 0.05;

@interface RDHTTPTests() {
    BOOL operationComplete;
}
@end


@implementation RDHTTPTests

- (void)setUp
{
    [super setUp];
    
    // Set-up code here.
}

- (void)tearDown
{
    // Tear-down code here.
    
    [super tearDown];
}

- (BOOL)waitWithTimeout:(NSTimeInterval)timeout 
{
    NSTimeInterval start = [NSDate timeIntervalSinceReferenceDate];

    while (!operationComplete && 
           [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:.05]])
    {
        if ([NSDate timeIntervalSinceReferenceDate] - start > timeout) {
            return NO;
        }
    }
    return YES;
}

- (void)testSimpleHTTPGet {
    RDHTTPRequest *request = [RDHTTPRequest getRequestWithURL:@"http://osric.readdle.com/tests/ok.html"];
    __block NSString *responseText = nil;
    
    [request startWithCompletionHandler:^(RDHTTPResponse *response) {
        if (response.error == nil) {
            responseText = [response.responseText copy];
        }
        else 
            STFail(@"response error %@", response.error);
        
        operationComplete = YES;
    
    }];
    
    STAssertTrue([self waitWithTimeout:5.0], @"wait timeout");
    STAssertEqualObjects(responseText, @"RDHTTP Is Working OK", @"but it is not");
}

- (void)testSimpleHTTPPost {
    RDHTTPRequest *request = [RDHTTPRequest postRequestWithURL:@"http://osric.readdle.com/tests/post-values.php"];
    [[request formPost] setPostValue:@"1" forKey:@"a"];
    [[request formPost] setPostValue:@"2" forKey:@"b"];
    
    __block NSString *responseText = nil;
    
    [request startWithCompletionHandler:^(RDHTTPResponse *response) {
        if (response.error == nil) {
            responseText = [response.responseText copy];
        }
        else 
            STFail(@"response error %@", response.error);
        
        operationComplete = YES;
        
    }];
    
    STAssertTrue([self waitWithTimeout:5.0], @"wait timeout");
    STAssertEqualObjects(responseText, @"a=>1\nb=>2\n", @"but it is not");
}

//- (void)testExample
//{
//    //STFail(@"Unit tests are not implemented yet in RDHTTPTests");
//}

@end
