//
//  RDHTTP.m
//  GetAdhoc
//
//  Created by Andrian Budantsov on 27.10.11.
//  Copyright (c) 2011 Readdle. All rights reserved.
//

#import "RDHTTP.h"

NSString *const RDHTTPResponseCodeErrorDomain = @"RDHTTPResponseCodeErrorDomain";


#pragma mark - RDHTTP Private API 

@interface RDHTTPRequest(RDHTTPPrivate)
- (NSURLRequest *)_nsurlrequest;
@end

@interface RDHTTPFormPost(RDHTTPPrivate) 
- (void)buildPostBodyForRequest:(RDHTTPRequest *)request;
@end

@interface RDHTTPConnection(RDHTTPRequestInterface)

- (id)initWithRequest:(RDHTTPRequest *)aRequest
    completionHandler:(rdhttp_block_t)aCompletionBlock 
      progressHandler:(rdhttp_progress_block_t)aProgressBlock
       headersHandler:(rdhttp_block_t)aHeadersBlock;

- (void)start;

@end





#pragma mark - RDHTTPResponse


@interface RDHTTPResponse() {
    NSHTTPURLResponse *response;
    RDHTTPRequest     *request; // this object is mutable, we agreed to use it only for non-mutable tasks here
    
    NSError           *error;
    NSError           *httpError;
    NSString          *tempFilePath;
    NSData            *responseData;
    NSString          *responseTextCached;
    NSDictionary      *responseHeaders;
}

- (id)initWithResponse:(NSHTTPURLResponse *)response 
               request:(RDHTTPRequest *)request
                 error:(NSError *)error
          tempFilePath:(NSString *)tempFilePath
                  data:(NSData *)responseData;


@end

@implementation RDHTTPResponse
@synthesize error;
@synthesize userInfo;
@synthesize responseData;

- (id)initWithResponse:(NSHTTPURLResponse *)aResponse 
               request:(RDHTTPRequest *)aRequest
                 error:(NSError *)anError
          tempFilePath:(NSString *)aTempFilePath
                  data:(NSData *)aResponseData 
{
    self = [super init];
    if (self) {
        request = [aRequest retain];
        response = [aResponse retain];
        error = [anError retain];
        tempFilePath = [aTempFilePath retain];
        responseData = [aResponseData retain];
    }
    return self;
}

- (void)dealloc {
    [request release];
    [response release];
    
    [error release];
    [tempFilePath release];
    [responseData release];
    
    [httpError release];
    [responseTextCached release];
    [responseHeaders release];
    [super dealloc];
}

- (NSError *)httpError {
    if (httpError) 
        return httpError;
    
    NSInteger statusCode = [response statusCode];
    
    if (statusCode >= 200 && statusCode < 300)
        return nil;
    
    httpError = [[NSError errorWithDomain:RDHTTPResponseCodeErrorDomain code:statusCode userInfo:nil] retain];
    return httpError;
}

- (NSError *)networkError {
    return error;
}

- (NSError *)error {
    if (error) 
        return error;
    
    if (self.httpError)
        return self.httpError;
    
    return nil;
}

- (NSString *)valueForHTTPHeaderField:(NSString *)field {
    if (responseHeaders == nil) {
        responseHeaders = [[response allHeaderFields] retain];
    }
    return (NSString *)[responseHeaders objectForKey:field];
}

- (NSString *)responseText {
    if (responseTextCached == nil && responseData)
        responseTextCached = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
    return responseTextCached;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<RDHTTPResponse: URL %@ code %d length: %d>", 
            [request _nsurlrequest].URL,
            response.statusCode, 
            [responseData length]];
}

@end








#pragma mark - RDHTTPRequest -

@interface RDHTTPRequest() {
    NSMutableURLRequest *urlRequest;
    rdhttp_trustssl_block_t trustBlock;
    rdhttp_httpauth_block_t authBlock;
}
- (id)initWithMethod:(NSString *)aMethod resource:(NSObject *)urlObject;
- (void)prepare;

@end


@implementation RDHTTPRequest
@synthesize userInfo;
@synthesize dispatchQueue;
@synthesize formPost;
@synthesize saveResponseToFile;

- (id)initWithMethod:(NSString *)aMethod resource:(NSObject *)urlObject {
    self = [super init];
    if (self) {
        NSURL *url = nil;
        if ([urlObject isKindOfClass:[NSURL class]])
            url = (NSURL *)urlObject;
        else if ([urlObject isKindOfClass:[NSString class]]) {
            url = [NSURL URLWithString:(NSString *)urlObject];
        }
        else {
            if (url == nil) 
                NSLog(@"RDHTTP: nil object passed as an URL");
            else
                NSLog(@"RDHTTP: unknown object passed as an URL, should be NSURL or NSString");
            return nil;
        }
        
        urlRequest = [[NSMutableURLRequest requestWithURL:url] retain];
        if (aMethod)
            [urlRequest setHTTPMethod:aMethod];

        self.dispatchQueue = dispatch_get_main_queue();
    }
    return self;
}

- (void)dealloc {
    [urlRequest release];
    self.dispatchQueue = nil;
    [super dealloc];
}

- (id)copyWithZone:(NSZone *)zone {
    RDHTTPRequest *request = [[RDHTTPRequest alloc] init];
    
    request->urlRequest = [urlRequest copyWithZone:zone];
    request.dispatchQueue = self.dispatchQueue;

    // don't use self.formPost here, because it will just create new formPost
    RDHTTPFormPost *formPostCopy = [formPost copyWithZone:zone];
    request.formPost = formPostCopy;
    [formPostCopy release];
    
    NSDictionary *userInfoCopy = [userInfo copyWithZone:zone];
    request.userInfo = userInfoCopy;
    [userInfoCopy release];
    request.saveResponseToFile = saveResponseToFile;
    
    [request setSSLCertificateTrustHandler:trustBlock];
    [request setHTTPAuthHandler:authBlock];
    
    return request;
}

- (NSURLRequest *)_nsurlrequest {
    return urlRequest;
}

+ (id)customRequest:(NSString *)method withURL:(NSObject *)url {
    return [[[self alloc] initWithMethod:method resource:url] autorelease];
}

+ (id)getRequestWithURL:(NSObject *)url {
    return [self customRequest:@"GET" withURL:url];
}

+ (id)postRequestWithURL:(NSObject *)url {
    return [self customRequest:@"POST" withURL:url];
}

- (void)addValue:(NSString *)value forHTTPHeaderField:(NSString *)field {
    [urlRequest addValue:value forHTTPHeaderField:field];
}

- (void)setHTTPBodyStream:(NSInputStream *)inputStream {
    if ([urlRequest.HTTPMethod isEqualToString:@"GET"]) {
        NSLog(@"RDHTTP: trying to set post body for GET request");
    }
    
    if (self.formPost) {
        NSLog(@"RDHTTP: trying to assign postBody with postFiles / multipartPostFiles set");
        NSLog(@"RDHTTP: postFields / multipartPostFiles reset");
        self.formPost = nil;
    }
    
    [urlRequest setHTTPBodyStream:inputStream];
}

- (void)setHTTPBodyData:(NSData *)data {
    [self setHTTPBodyStream:[NSInputStream inputStreamWithData:data]];
    [self addValue:[NSString stringWithFormat:@"%u", [data length]] forHTTPHeaderField:@"Content-Length"];
}

- (void)setHTTPBodyFilePath:(NSString *)filePath {
    if ([[NSFileManager defaultManager] fileExistsAtPath:filePath] == NO) {
        NSLog(@"RDHTTP: not-existing file %@ in setHTTPBodyFilePath", filePath);
        return;
    }
    [self setHTTPBodyStream:[NSInputStream inputStreamWithFileAtPath:filePath]];
}


- (rdhttp_trustssl_block_t)SSLCertificateTrustHandler {
    return trustBlock;
}

- (void)setSSLCertificateTrustHandler:(rdhttp_trustssl_block_t)aTrustBlock {
    if (trustBlock)
        Block_release(trustBlock);
    if (aTrustBlock)
        trustBlock = Block_copy(aTrustBlock);
}


- (rdhttp_httpauth_block_t)HTTPAuthHandler {
    return authBlock;
}

- (void)setHTTPAuthHandler:(rdhttp_httpauth_block_t)anAuthBlock {
    if (authBlock) 
        Block_release(authBlock);
    
    if (anAuthBlock)
        authBlock = Block_copy(anAuthBlock);
}


- (RDHTTPFormPost *)formPost {
    if ([urlRequest.HTTPMethod isEqualToString:@"GET"]) {
        NSLog(@"RDHTTP: warning using formPost with GET HTTP request");
    }
    if (formPost == nil) {
        formPost = [RDHTTPFormPost new];
    }
    return formPost;
}

- (void)setDispatchQueue:(dispatch_queue_t)aDispatchQueue {
    if (dispatchQueue == aDispatchQueue)
        return;
    
    if (dispatchQueue) 
        dispatch_release(dispatchQueue);
    
    if (aDispatchQueue == nil)
        return;
    
    dispatch_retain(aDispatchQueue);
    dispatchQueue = aDispatchQueue;
}


- (RDHTTPConnection *)startWithCompletionHandler:(rdhttp_block_t)aCompletionBlock
                                 progressHandler:(rdhttp_progress_block_t)aProgressBlock
                                  headersHandler:(rdhttp_block_t)aHeadersBlock 
{
    RDHTTPConnection *conn = [[RDHTTPConnection alloc] initWithRequest:self
                                                     completionHandler:aCompletionBlock
                                                       progressHandler:aProgressBlock
                                                        headersHandler:aHeadersBlock];
    [conn start];
    return [conn autorelease];
}


- (RDHTTPConnection *)startWithCompletionHandler:(rdhttp_block_t)aCompletionBlock
                                 progressHandler:(rdhttp_progress_block_t)aProgressBlock 
{
    return [self startWithCompletionHandler:aCompletionBlock 
                            progressHandler:aProgressBlock
                             headersHandler:nil];    
}

- (RDHTTPConnection *)startWithCompletionHandler:(rdhttp_block_t)aCompletionBlock {
    return [self startWithCompletionHandler:aCompletionBlock 
                            progressHandler:nil
                             headersHandler:nil];
    
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<RDHTTPRequest: %@ %@>", urlRequest.HTTPMethod, urlRequest.URL];
}

#pragma mark - internal

- (void)prepare {
    [formPost buildPostBodyForRequest:self];
}

@end





#pragma mark - RDHTTPFormPost -

@interface RDHTTPFormPost() {
    NSMutableDictionary *postFields;
    NSMutableDictionary *multipartPostFiles;   
}
@end

@implementation RDHTTPFormPost

- (id)copyWithZone:(NSZone *)zone {
    RDHTTPFormPost *copy = [RDHTTPFormPost new];
    copy->postFields = [postFields copyWithZone:zone];
    copy->multipartPostFiles = [multipartPostFiles copyWithZone:zone];    
    return copy;
}

- (void)setPostValue:(NSString *)value forKey:(NSString *)key {
    if (postFields == nil)
        postFields = [NSMutableDictionary new];
    
    [postFields setObject:value forKey:key];
}

- (void)setFile:(NSString *)filePath forKey:(NSString *)key {
    if ([[NSFileManager defaultManager] fileExistsAtPath:filePath] == NO) {
        NSLog(@"RDHTTP: not-existing file %@ in RDHTTPFormPost setFile", filePath);
        return;
    }
    
    if (multipartPostFiles == nil) 
        multipartPostFiles = [NSMutableDictionary new];
    
    [multipartPostFiles setObject:filePath forKey:key];
}
#pragma mark - internal

- (NSData *)dataByAddingPercentEscapesToString:(NSString *)string usingEncoding:(CFStringEncoding)encoding {
    CFStringRef retval;
    
    retval = CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault, 
                                                     (CFStringRef)string,
                                                     NULL,
                                                     CFSTR(":/?#[]@!$ &'()*+,;=\"<>%{}|\\^~`"),
                                                     encoding);
    if (retval == nil) {
        return [NSData data];
    }
    
    CFDataRef data = CFStringCreateExternalRepresentation(kCFAllocatorDefault, retval, encoding, '?');
    CFRelease(retval);
    
    return [(__bridge_transfer NSData *)data autorelease];
}

- (void)buildPostBodyForRequest:(RDHTTPRequest *)request {
    if (postFields == nil)
        return;
    
    [request addValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    
    NSMutableData *data = [NSMutableData data];
    
    BOOL first = YES;
    for (NSString *key in postFields) {
        if (first == NO)
            [data appendBytes:"&" length:1];
        
        [data appendData:[self dataByAddingPercentEscapesToString:key usingEncoding:kCFStringEncodingUTF8]];
        [data appendBytes:"=" length:1];
        [data appendData:[self dataByAddingPercentEscapesToString:[postFields objectForKey:key]
                                                    usingEncoding:kCFStringEncodingUTF8]];
        first = NO;
    }
    
    [request setHTTPBodyData:data];
}

#pragma mark - utilities 

+ (NSString*)stringByAddingPercentEscapesToString:(NSString *)string
{
    CFStringRef retval;
    
    retval = CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault, 
                                                     (CFStringRef)string,
                                                     NULL,
                                                     CFSTR(":/?#[]@!$ &'()*+,;=\"<>%{}|\\^~`"),
                                                     CFStringConvertNSStringEncodingToEncoding(NSUTF8StringEncoding));
    
    return [(__bridge_transfer NSString *)retval autorelease];
}

@end








#pragma mark - RDHTTP -

@interface RDHTTPConnection()<NSURLConnectionDataDelegate, NSURLConnectionDelegate> {
    RDHTTPRequest       *request; // this object is mutable, we agreed to use our copy for non-mutable tasks only
    
    rdhttp_block_t              completionBlock;
    rdhttp_progress_block_t     progressBlock;
    rdhttp_block_t              headersBlock;
    
    NSURLConnection     *connection;
    long long           httpExpectedContentLength;
    long long           httpSavedDataLength;
    NSHTTPURLResponse   *httpResponse;
    NSMutableData       *httpResponseData;    
}

@end

@implementation RDHTTPConnection
@synthesize completed;

- (id)initWithRequest:(RDHTTPRequest *)aRequest
    completionHandler:(rdhttp_block_t)aCompletionBlock 
      progressHandler:(rdhttp_progress_block_t)aProgressBlock
       headersHandler:(rdhttp_block_t)aHeadersBlock
{
    self = [super init];
    if (self) {
        request = [aRequest copy];
        completionBlock = [aCompletionBlock copy];
        progressBlock = [aProgressBlock copy];
        headersBlock = [aHeadersBlock copy];
    }
    return self;
}

- (void)dealloc {
    [request release];
    [completionBlock release];
    [progressBlock release];
    [headersBlock release];    
    
    [httpResponse release];
    [httpResponseData release];
    
    [connection release];
    [super dealloc];
}

- (void)start {
    NSAssert(connection == nil, @"RDHTTPConnection: someone called -(void)start twice");
    [request prepare];
    
    connection = [[NSURLConnection alloc] initWithRequest:[request _nsurlrequest]
                                                 delegate:self
                                         startImmediately:YES];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    RDHTTPResponse *response = [[[RDHTTPResponse alloc] initWithResponse:nil
                                                                 request:request
                                                                   error:error
                                                            tempFilePath:nil
                                                                    data:nil] autorelease];
    
    dispatch_async(request.dispatchQueue, ^{
        completionBlock(response);
    });
    
    [self willChangeValueForKey:@"completed"];
    completed = YES;
    [self didChangeValueForKey:@"completed"];
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)aResponse {
    if ([aResponse isKindOfClass:[NSHTTPURLResponse class]] == NO) {
        // TODO: fail
    }

    httpResponse = [(NSHTTPURLResponse *)aResponse retain];
    httpExpectedContentLength = [httpResponse expectedContentLength];
    
    if (request.saveResponseToFile) {
        // TODO: save Response To File        
    }
    else {
        NSUInteger dataCapacity = 8192;
        if (httpExpectedContentLength != NSURLResponseUnknownLength)
            dataCapacity = httpExpectedContentLength;
        
        httpResponseData = [[NSMutableData alloc] initWithCapacity:dataCapacity];
    }
    
    if (headersBlock) {
        RDHTTPResponse *response = [[[RDHTTPResponse alloc] initWithResponse:httpResponse
                                                                     request:request
                                                                       error:nil
                                                                tempFilePath:nil
                                                                        data:nil] autorelease];
        
        dispatch_async(request.dispatchQueue, ^{
            headersBlock(response);
        });
    }
    
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    if (httpResponseData) {
        [httpResponseData appendData:data];
    }
    else {
        // TODO: file downloads 
    }
    
    httpSavedDataLength += [data length];
    
    if (progressBlock) {
        if (httpExpectedContentLength > 0) {
            float progress = (float)httpSavedDataLength  / (float)httpExpectedContentLength;
            dispatch_async(dispatch_get_main_queue(), ^{ progressBlock(progress, NO); });
        }
        else {
            dispatch_async(dispatch_get_main_queue(), ^{ progressBlock(-1.0f, NO); });
            [progressBlock release];
            progressBlock = nil;
        }
    }
}

- (void)        connection:(NSURLConnection *)connection 
           didSendBodyData:(NSInteger)bytesWritten 
         totalBytesWritten:(NSInteger)totalBytesWritten 
 totalBytesExpectedToWrite:(NSInteger)totalBytesExpectedToWrite 
{
    if (progressBlock) {
        if (totalBytesExpectedToWrite > 0) {
            float progress = (float)totalBytesWritten  / (float)totalBytesExpectedToWrite;
            dispatch_async(dispatch_get_main_queue(), ^{ progressBlock(progress, YES); });
        }
    }
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    if (completionBlock == nil)
        return;
    
    RDHTTPResponse *response = [[RDHTTPResponse alloc] initWithResponse:httpResponse
                                                                request:request
                                                                  error:nil
                                                           tempFilePath:nil
                                                                   data:httpResponseData];
    [response autorelease];
    
    dispatch_async(request.dispatchQueue, ^{
        completionBlock(response);
    });
    
    [self willChangeValueForKey:@"completed"];
    completed = YES;
    [self didChangeValueForKey:@"completed"];
}


- (BOOL)connection:(NSURLConnection *)connection canAuthenticateAgainstProtectionSpace:(NSURLProtectionSpace *)protectionSpace {	
	return YES;
}


- (BOOL)connectionShouldUseCredentialStorage:(NSURLConnection *)connection {
	return YES;
}

- (void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {
    
    if ([challenge.protectionSpace.authenticationMethod isEqualToString:@"NSURLAuthenticationMethodServerTrust"]) {
        // certificate trust
        rdhttp_trustssl_block_t trust = [request SSLCertificateTrustHandler];
        if (trust == nil) {
            [[challenge sender] continueWithoutCredentialForAuthenticationChallenge:challenge];
            return;
        }
        
        rdhttp_trustssl_result_block_t trustResult = ^(BOOL shouldConnect) {
            if (shouldConnect) {
                [[challenge sender] useCredential:[NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust] 
                     forAuthenticationChallenge:challenge];
            }
            else {
                [[challenge sender] continueWithoutCredentialForAuthenticationChallenge:challenge];
            }
        };
        
        trust([request _nsurlrequest].URL, trustResult);
        return;
    }
    
    // normal login-password auth: 
    
    const int kAllowedLoginFailures = 1;
    rdhttp_httpauth_block_t auth = [request HTTPAuthHandler];
    if ((auth == nil)||([challenge previousFailureCount] >= kAllowedLoginFailures)) {
        [[challenge sender] cancelAuthenticationChallenge:challenge];
        return;
    }
    
    rdhttp_httpauth_result_block_t authResult = ^(NSString *username, NSString *password, NSString *domain) {
        
        [[challenge sender] useCredential:[NSURLCredential credentialWithUser:username
                                                                     password:password
                                                                  persistence:NSURLCredentialPersistenceNone]

               forAuthenticationChallenge:challenge];
    
        
    };
    
    dispatch_async(dispatch_get_main_queue(), ^{
        auth(authResult);
    });
    
}







@end

