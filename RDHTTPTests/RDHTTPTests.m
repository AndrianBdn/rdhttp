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


- (void)testBasicAuthHTTPGet {
    
    RDHTTPRequest *request = [RDHTTPRequest getRequestWithURL:@"http://browserspy.dk/password-ok.php"];
    __block NSString *responseText = nil;
    
    [request setHTTPAuthHandler:^(rdhttp_httpauth_result_block_t auth_result) {
        auth_result(@"test", @"test", nil);
    }];
    
    [request startWithCompletionHandler:^(RDHTTPResponse *response) {
        if (response.error == nil) {
            responseText = [response.responseText copy];
        }
        else 
            NSLog(@"response error %@", response.error);
        
        operationComplete = YES;
        
    }];
    

    STAssertTrue([self waitWithTimeout:5.0], @"wait timeout");
    BOOL ok = responseText && [responseText rangeOfString:@"HTTP Password Information - Success"].location != NSNotFound;
    STAssertTrue(ok, @"No success indicator in password test");
    
}

- (void)testBasicAuthHTTPGetFAIL {
    
    RDHTTPRequest *request = [RDHTTPRequest getRequestWithURL:@"http://browserspy.dk/password-ok.php"];
    __block NSString *responseText = nil;
    
    [request setHTTPAuthHandler:^(rdhttp_httpauth_result_block_t auth_result) {
        auth_result(@"test", @"crap", nil);
    }];
    
    [request startWithCompletionHandler:^(RDHTTPResponse *response) {
        if (response.error == nil) {
            responseText = [response.responseText copy];
        }
        else 
            NSLog(@"response error %@", response.error);
        
        operationComplete = YES;
        
    }];
    
    
    STAssertTrue([self waitWithTimeout:10.0], @"wait timeout");
    BOOL ok = responseText && [responseText rangeOfString:@"HTTP Password Information - Success"].location != NSNotFound;
    STAssertFalse(ok, @"Success indicator in FAIL password test");
    
}

- (void)testSelfSignedHTTPSGet {
    
    RDHTTPRequest *request = [RDHTTPRequest getRequestWithURL:@"https://www.pcwebshop.co.uk/"];
    __block NSString *responseText = nil;
    
    [request setSSLCertificateTrustHandler:^(NSURL *url, rdhttp_trustssl_result_block_t trust_result) {
        trust_result(YES);
    }];     
     
    [request startWithCompletionHandler:^(RDHTTPResponse *response) {
        if (response.error == nil) {
            responseText = [response.responseText copy];
        }
        else 
            NSLog(@"response error %@", response.error);
        
        operationComplete = YES;
    }];
    
    
    STAssertTrue([self waitWithTimeout:5.0], @"wait timeout");
    BOOL ok = [responseText rangeOfString:@"You see this page because there is no Web site at this address."].location != NSNotFound;
    STAssertTrue(ok, @"No success indicator in password test");
    
}



@end
