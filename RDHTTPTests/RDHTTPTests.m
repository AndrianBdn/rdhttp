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
    
    [request setHTTPAuthHandler:^(RDHTTPAuthorizer *httpAuthorizeResponse) {
        [httpAuthorizeResponse continueWithUsername:@"test" password:@"test"];
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

- (void)testBasicAuthHTTPGetNoBlock {
    
    RDHTTPRequest *request = [RDHTTPRequest getRequestWithURL:@"http://browserspy.dk/password-ok.php"];
    __block NSString *responseText = nil;

    [request tryBasicHTTPAuthorizationWithUsername:@"test" password:@"test"];
    
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
    

    [request setHTTPAuthHandler:^(RDHTTPAuthorizer *httpAuthorizer) {
        [httpAuthorizer continueWithUsername:@"test" password:@"crap"];
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
    
    [request setSSLCertificateTrustHandler:^(RDHTTPSSLServerTrust *sslTrustQuery) {
        [sslTrustQuery trust];
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

- (void)testSimpleHTTPPOSTFileUpload {
    RDHTTPRequest *request = [RDHTTPRequest postRequestWithURL:@"http://osric.readdle.com/tests/post-file.php"];
    
    NSString *path = [[NSBundle bundleForClass:[self class]] pathForResource:@"IMG_0045" ofType:@"jpg"];
    NSURL *url = [NSURL fileURLWithPath:path];
                  
    [[request formPost] setFile:url forKey:@"file"];
    
    __block NSString *responseText = nil;
    
    [request startWithCompletionHandler:^(RDHTTPResponse *response) {
        if (response.error == nil) {
            responseText = [response.responseText copy];
        }
        else 
            STFail(@"response error %@", response.error);
        
        operationComplete = YES;
        
    }];
    
    STAssertTrue([self waitWithTimeout:55.0], @"wait timeout");
    STAssertEqualObjects(responseText, @"size:33464\nmd5:c9894d80c2d05b826fabe24283031fe6", @"but it is not");
}


- (void)testCancelMethod {
    RDHTTPRequest *request = [RDHTTPRequest getRequestWithURL:@"http://www.ubuntu.com/start-download?distro=desktop&bits=32&release=latest"];
    
    __block BOOL isCancelled = NO;
    
    request.cancelCausesCompletion = YES;
    
    RDHTTPOperation *operation = [request startWithCompletionHandler:^(RDHTTPResponse *response) {
        NSLog(@"cancelled operation response %@", response);
    
        isCancelled = [response isCancelled];
        
        operationComplete = YES;
        
    }];
    
    double delayInSeconds = 10.0;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [operation cancel];
        NSLog(@"cancel operation");
    });
    
    STAssertTrue([self waitWithTimeout:25.0], @"wait timeout");
    STAssertTrue(isCancelled, @"RDHTTP should be cancelled", @"but it is not");
    
}


- (void)testMultipartPOSTFileUpload {
    RDHTTPRequest *request = [RDHTTPRequest postRequestWithURL:@"http://osric.readdle.com/tests/post-files-and-fields.php"];
    
    NSString *path = [[NSBundle bundleForClass:[self class]] pathForResource:@"IMG_0045" ofType:@"jpg"];
    NSURL *url2 = [NSURL fileURLWithPath:path];

    path = [[NSBundle bundleForClass:[self class]] pathForResource:@"Earphones_UG" ofType:@"pdf"];
    NSURL *url1 = [NSURL fileURLWithPath:path];

    path = [[NSBundle bundleForClass:[self class]] pathForResource:@"cakephp-cakephp-2.0.3-0-gde5a4ea" ofType:@"zip"];
    NSURL *url3 = [NSURL fileURLWithPath:path];

    
    [[request formPost] setFile:url1 forKey:@"file1"];
    [[request formPost] setFile:url2 forKey:@"file2"];
    [[request formPost] setFile:url3 forKey:@"file3"];    
    
    [[request formPost] setPostValue:@"zorro" forKey:@"text1"];
    [[request formPost] setPostValue:@"pegasus" forKey:@"text2"];
    
    __block NSString *responseText = nil;
    
    [request setProgressHandler:^(float progress, BOOL upload) {
        NSLog(@"%f UPLOAD=%d", progress, upload);
    }];
    
    [request startWithCompletionHandler:^(RDHTTPResponse *response) {
        if (response.error == nil) {
            responseText = [response.responseText copy];
        }
        else 
            STFail(@"response error %@", response.error);
        
        operationComplete = YES;
        
    }];
    
    NSMutableString *refString = [NSMutableString stringWithCapacity:1024];
    [refString appendString:@"877325/b0d1463be77d15f4e31c22169bda45e2\n"];
    [refString appendString:@"33464/c9894d80c2d05b826fabe24283031fe6\n"];
    [refString appendString:@"1646835/ecd5e85b41a6c33ecfcc93c0f2c5d421\n"];    
    [refString appendString:@"zorro/pegasus\n"];
    
    STAssertTrue([self waitWithTimeout:55.0], @"wait timeout");
    STAssertEqualObjects(responseText, refString, @"but it is not");
    
}


- (void)testHTTPGetRedirect {
    RDHTTPRequest *request = [RDHTTPRequest getRequestWithURL:@"http://osric.readdle.com/tests/redirect1.php"];
    __block NSString *responseText = nil;
    
    [request startWithCompletionHandler:^(RDHTTPResponse *response) {
        if (response.error == nil) {
            responseText = [response.responseText copy];
        }
        else 
            STFail(@"response error %@", response.error);
        
        operationComplete = YES;
        
    }];
    
    STAssertTrue([self waitWithTimeout:15.0], @"wait timeout");
    STAssertEqualObjects(responseText, @"RDHTTP Is Working OK", @"but it is not");
    
    [responseText release];
}

- (void)testHTTPGetRedirectNO {
    RDHTTPRequest *request = [RDHTTPRequest getRequestWithURL:@"http://osric.readdle.com/tests/redirect1.php"];
    request.shouldRedirect = NO;
    
    __block NSString *responseText = nil;    
    __block NSError *error = nil;
    
    [request startWithCompletionHandler:^(RDHTTPResponse *response) {
        responseText = [response.responseText copy];
        error = [response.httpError copy];
        operationComplete = YES;
        
    }];
    
    STAssertTrue([self waitWithTimeout:15.0], @"wait timeout");

    NSLog(@"%@", responseText);
    NSLog(@"redirect no = %@", error);

    
    STAssertTrue(error.code == 302, @"error code 302 redirect", @"but it is not");
    
    [responseText release];
    [error release];
}



- (void)testHTTPRedirectLoop {
    RDHTTPRequest *request = [RDHTTPRequest getRequestWithURL:@"http://osric.readdle.com/tests/redirect-loop1.php"];
   
    __block NSString *responseText = nil;    
    __block NSError *error = nil;
    
    [request startWithCompletionHandler:^(RDHTTPResponse *response) {
        responseText = [response.responseText copy];
        error = [response.error copy];
        operationComplete = YES;
        
    }];
    
    STAssertTrue([self waitWithTimeout:15.0], @"wait timeout");

    NSLog(@"redirect loop error: %@", error);
    
    STAssertTrue(error != nil, @"redirect loop error", @"but it is not");
    
    [responseText release];
}

- (void)testHTTPRedirectPost2616 {
    RDHTTPRequest *request = [RDHTTPRequest postRequestWithURL:@"http://osric.readdle.com/tests/redirect-post.php"];
    request.shouldUseRFC2616RedirectBehaviour = YES;
    
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



@end
