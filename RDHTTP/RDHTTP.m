//
//  RDHTTP.m
//
//  Copyright (c) 2011, Andrian Budantsov. All rights reserved.
//
//  Redistribution and use in source and binary forms, with or without 
//  modification, are permitted provided that the following conditions are met:
//
//  * Redistributions of source code must retain the above copyright notice, this 
//  list of conditions and the following disclaimer.
//
//  * Redistributions in binary form must reproduce the above copyright notice, 
//  this list of conditions and the following disclaimer in the documentation 
//  and/or other materials provided with the distribution.
//
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND 
//  ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED 
//  WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE 
//  DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE 
//  FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL 
//  DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR 
//           SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER 
//  CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, 
//  OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE 
//  OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


#import "RDHTTP.h"
#if TARGET_OS_IPHONE
#import <MobileCoreServices/MobileCoreServices.h>
#endif

NSString *const RDHTTPResponseCodeErrorDomain = @"RDHTTPResponseCodeErrorDomain";

#pragma mark - RDHTTP Private API 

@interface RDHTTPRequest(RDHTTPPrivate)
- (NSURLRequest *)_nsurlrequest;
@end

@interface RDHTTPFormPost(RDHTTPPrivate) 
- (NSInputStream *)setupPostFormRequest:(NSMutableURLRequest *)request encoding:(NSStringEncoding)encoding;
@end

@interface RDHTTPOperation(RDHTTPPrivate)
- (id)initWithRequest:(RDHTTPRequest *)aRequest;
@end





#pragma mark - RDHTTPResponse


@interface RDHTTPResponse() {
    NSHTTPURLResponse *response;
    RDHTTPRequest     *request; // this object is mutable, we agreed to use it only for non-mutable tasks here
    
    NSError           *error;
    NSError           *httpError;
    NSURL             *responseFileURL;
    NSData            *responseData;
    NSString          *responseTextCached;
}

- (id)initWithResponse:(NSHTTPURLResponse *)response 
               request:(RDHTTPRequest *)request
                 error:(NSError *)error
           isCancelled:(BOOL)anIsCancelledFlag
          tempFilePath:(NSString *)tempFilePath
                  data:(NSData *)responseData;


@end

@implementation RDHTTPResponse
@synthesize error;
@synthesize userInfo;
@synthesize responseData;
@synthesize isCancelled;
@synthesize responseFileURL;

- (id)initWithResponse:(NSHTTPURLResponse *)aResponse 
               request:(RDHTTPRequest *)aRequest
                 error:(NSError *)anError
           isCancelled:(BOOL)anIsCancelledFlag
          tempFilePath:(NSString *)aTempFilePath
                  data:(NSData *)aResponseData 
{
    self = [super init];
    if (self) {
        request = [aRequest retain];
        response = [aResponse retain];
        error = [anError retain];
        if (aTempFilePath) 
            responseFileURL = [[NSURL fileURLWithPath:aTempFilePath] retain];
        responseData = [aResponseData retain];
        isCancelled = anIsCancelledFlag;
    }
    return self;
}

- (void)dealloc {
    
    [request release];
    [response release];
    
    [error release];
    [responseFileURL release];
    [responseData release];
    
    [httpError release];
    [responseTextCached release];
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

- (NSUInteger)statusCode {
    return response.statusCode;
}

- (NSDictionary *)allHeaderFields {
    return [response allHeaderFields];
}

- (NSString *)valueForHTTPHeaderField:(NSString *)field {
    return (NSString *)[[response allHeaderFields] objectForKey:field];
}

- (NSData *)responseData {
    if (responseData == nil && responseFileURL) {
        NSLog(@"RDHTTP: attempt to access responseData with saveResponseToFile=YES set in request. return nil");
        return nil;
    }
    return responseData;
}

- (NSString *)responseString {
    if (responseData == nil && responseFileURL) {
        NSLog(@"RDHTTP: attempt to access responseText with saveResponseToFile=YES set in request. return nil");
        return nil;
    }
    
    NSStringEncoding encoding = NSUTF8StringEncoding; // default 
    if (response.textEncodingName) {
        encoding = CFStringConvertEncodingToNSStringEncoding(CFStringConvertIANACharSetNameToEncoding((CFStringRef)response.textEncodingName));
    }
    
    if (responseTextCached == nil && responseData)
        responseTextCached = [[NSString alloc] initWithData:responseData encoding:encoding];
    
    if (responseTextCached == nil && responseData) {
        if (encoding != NSUTF8StringEncoding) 
            NSLog(@"RDHTTP: warning, unable to create string with %@ encoding. Use responseData.", response.textEncodingName);
        else
            NSLog(@"RDHTTP: warning, unable to create string with UTF-8 encoding. Use responseData.");
    }
    
    return responseTextCached;
}

- (NSDictionary *)userInfo {
    return request.userInfo;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<RDHTTPResponse: URL %@ code %d length: %d>", 
            response.URL,
            response.statusCode, 
            [responseData length]];
}

- (BOOL)  moveResponseFileToURL:(NSURL *)destination 
    withIntermediateDirectories:(BOOL)createIntermediates 
                          error:(NSError **)anError
{
    if (createIntermediates) {
        if ([[NSFileManager defaultManager] createDirectoryAtPath:[[destination path] stringByDeletingLastPathComponent]
                                      withIntermediateDirectories:YES
                                                       attributes:nil
                                                            error:anError] == NO)
            return NO;
    }
    return [[NSFileManager defaultManager] moveItemAtURL:responseFileURL 
                                                   toURL:destination
                                                   error:anError];
}



@end

#pragma mark - RDHTTPRequest

@interface RDHTTPRequest() {
    NSMutableURLRequest *urlRequest;
    rdhttp_block_t      completionBlock;
    NSString            *postBodyFilePath;
    
}
- (id)initWithMethod:(NSString *)aMethod resource:(NSObject *)urlObject;
- (void)prepare;
- (rdhttp_block_t)completionBlock;
- (NSString *)base64encodeString:(NSString *)string;
- (NSInputStream *)regenerateBodyStream;

@property(nonatomic, retain) NSString *postBodyFilePath;
@end


@implementation RDHTTPRequest
@synthesize userInfo;
@synthesize dispatchQueue;
@synthesize formPost;
@synthesize shouldSaveResponseToFile;
@synthesize encoding;
@synthesize shouldRedirect;
@synthesize shouldUseRFC2616RedirectBehaviour;
@synthesize cancelCausesCompletion;
@synthesize useInternalThread;
@synthesize postBodyFilePath;

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
        encoding = NSUTF8StringEncoding;
        shouldRedirect = YES;
        urlRequest.timeoutInterval = 20;
        useInternalThread = YES;
    }
    return self;
}

- (void)dealloc {
    [urlRequest release];
    self.postBodyFilePath = nil;
    self.dispatchQueue = nil;
    [super dealloc];
}

- (id)copyWithZone:(NSZone *)zone {
    RDHTTPRequest *request = [[RDHTTPRequest alloc] init];
    
    request->urlRequest = [urlRequest copyWithZone:zone];
    if (completionBlock)
        request->completionBlock = Block_copy(completionBlock);
    
    request.encoding = self.encoding;
    request.dispatchQueue = self.dispatchQueue;

    // don't use self.formPost here, because it will just create new formPost
    // in case we don't have any 
    RDHTTPFormPost *formPostCopy = [formPost copyWithZone:zone];
    request.formPost = formPostCopy;
    [formPostCopy release];
    
    NSDictionary *userInfoCopy = [userInfo copyWithZone:zone];
    request.userInfo = userInfoCopy;
    [userInfoCopy release];
    request.shouldSaveResponseToFile = shouldSaveResponseToFile;
    request.cancelCausesCompletion = cancelCausesCompletion;
    request.shouldRedirect = shouldRedirect;
    request.shouldUseRFC2616RedirectBehaviour = shouldUseRFC2616RedirectBehaviour;
    request.useInternalThread = useInternalThread;
    
    [request setSSLCertificateTrustHandler:self.SSLCertificateTrustHandler];
    [request setHTTPAuthHandler:self.HTTPAuthHandler];
    [request setDownloadProgressHandler:self.downloadProgressHandler];
    [request setUploadProgressHandler:self.uploadProgressHandler];
    [request setHeadersHandler:self.headersHandler];
    
    return request;
}

- (NSURLRequest *)_nsurlrequest {
    return urlRequest;
}

+ (id)getRequestWithURL:(NSURL *)url {
    return [self customRequest:@"GET" withURL:url];
}

+ (id)getRequestWithURLString:(NSString *)urlString {
    return [self customRequest:@"GET" withURLString:urlString];
}

+ (id)postRequestWithURL:(NSURL *)url {
    return [self customRequest:@"POST" withURL:url];
}

+ (id)postRequestWithURLString:(NSString *)urlString {
    return [self customRequest:@"POST" withURLString:urlString];
}

+ (id)customRequest:(NSString *)method withURL:(NSURL *)url {
    return [[[self alloc] initWithMethod:method resource:url] autorelease];
}

+ (id)customRequest:(NSString *)method withURLString:(NSString *)urlString {
    return [[[self alloc] initWithMethod:method resource:urlString] autorelease];
}



- (void)setValue:(NSString *)value forHTTPHeaderField:(NSString *)field {
    [urlRequest setValue:value forHTTPHeaderField:field];
}

- (void)tryBasicHTTPAuthorizationWithUsername:(NSString *)username password:(NSString *)password {
    NSString *authString = [NSString stringWithFormat:@"%@:%@", username, password];
    NSString *headerValue = [NSString stringWithFormat:@"Basic %@", [self base64encodeString:authString]];
    [self setValue:headerValue forHTTPHeaderField:@"Authorization"];
}

- (void)postBodyCheckAndSetContentType:(NSString *)contentType {
    if ([urlRequest.HTTPMethod isEqualToString:@"GET"]) {
        NSLog(@"RDHTTP: trying to set post body for GET request");
    }
    
    if (formPost) {
        NSLog(@"RDHTTP: trying to assign postBody with postFiles / multipartPostFiles set");
        NSLog(@"RDHTTP: postFields / multipartPostFiles reset");
        self.formPost = nil;
    }   
    
    if (contentType) {
        [urlRequest setValue:contentType forHTTPHeaderField:@"Content-Type"];
    }
}

- (void)setHTTPBodyStream:(NSInputStream *)inputStream contentType:(NSString *)contentType {
    [self postBodyCheckAndSetContentType:contentType];
    [urlRequest setHTTPBodyStream:inputStream];
}

- (void)setHTTPBodyData:(NSData *)data contentType:(NSString *)contentType {
    [self postBodyCheckAndSetContentType:contentType];
    [urlRequest setValue:[NSString stringWithFormat:@"%u", [data length]] forHTTPHeaderField:@"Content-Length"];
    [urlRequest setHTTPBody:data];
}

- (void)setHTTPBodyFilePath:(NSString *)filePath guessContentType:(BOOL)guess {
    if ([[NSFileManager defaultManager] fileExistsAtPath:filePath] == NO) {
        NSLog(@"RDHTTP: not-existing file %@ in setHTTPBodyFilePath", filePath);
        return;
    }

    NSString *contentType = nil;
    if (guess) {
        contentType = [RDHTTPFormPost guessContentTypeForURL:[NSURL fileURLWithPath:filePath] 
                                             defaultEncoding:encoding];
    }

    
    NSDictionary *fileAttrs = [[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:nil];
    unsigned long long size = [fileAttrs fileSize];
    [self setValue:[NSString stringWithFormat:@"%llu", size] forHTTPHeaderField:@"Content-Length"];
    [self setHTTPBodyStream:[NSInputStream inputStreamWithFileAtPath:filePath] contentType:contentType];
    
    self.postBodyFilePath = filePath;
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

- (rdhttp_block_t)completionBlock {
    return completionBlock;
}

- (RDHTTPOperation *)operationWithCompletionHandler:(rdhttp_block_t)aCompletionBlock {
    if (aCompletionBlock)
        completionBlock = Block_copy(aCompletionBlock);
    
    RDHTTPOperation *conn = [[RDHTTPOperation alloc] initWithRequest:self];
    return [conn autorelease];
    
}


- (RDHTTPOperation *)startWithCompletionHandler:(rdhttp_block_t)aCompletionBlock {
    RDHTTPOperation *conn = [self operationWithCompletionHandler:aCompletionBlock];
    [conn start];
    return conn;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<RDHTTPRequest: %@ %@>", urlRequest.HTTPMethod, urlRequest.URL];
}

#pragma mark - properties 
@synthesize headersHandler;
@synthesize downloadProgressHandler;
@synthesize uploadProgressHandler;
@synthesize SSLCertificateTrustHandler;
@synthesize HTTPAuthHandler;
@synthesize HTTPBodyStreamCreationBlock;

- (void)setURL:(NSURL *)URL {
    [urlRequest setURL:URL];
}

- (NSURL *)URL {
    return [urlRequest URL];
}

- (void)setCachePolicy:(NSURLRequestCachePolicy)cachePolicy {
    [urlRequest setCachePolicy:cachePolicy];
}

- (NSURLRequestCachePolicy)cachePolicy {
    return [urlRequest cachePolicy];
}

- (void)setNetworkServiceType:(NSURLRequestNetworkServiceType)networkServiceType {
    [urlRequest setNetworkServiceType:networkServiceType];
}

- (NSURLRequestNetworkServiceType)networkServiceType {
    return [urlRequest networkServiceType];
}

- (void)setHTTPShouldHandleCookies:(BOOL)HTTPShouldHandleCookies {
    [urlRequest setHTTPShouldHandleCookies:HTTPShouldHandleCookies];
}

- (BOOL)HTTPShouldHandleCookies {
    return [urlRequest HTTPShouldHandleCookies];
}

- (void)setHTTPShouldUsePipelining:(BOOL)HTTPShouldUsePipelining {
    [urlRequest setHTTPShouldUsePipelining:HTTPShouldUsePipelining];
}

- (BOOL)HTTPShouldUsePipelining {
    return [urlRequest HTTPShouldUsePipelining];
}


- (void)setTimeoutInterval:(NSTimeInterval)timeoutInterval {
    [urlRequest setTimeoutInterval:timeoutInterval];
}

- (NSTimeInterval)timeoutInterval {
    return urlRequest.timeoutInterval;
}


- (void)setUserAgent:(NSString *)userAgent {
    [urlRequest setValue:userAgent forHTTPHeaderField:@"User-Agent"];
}

- (NSString *)userAgent {
    return [urlRequest valueForHTTPHeaderField:@"User-Agent"];
}

#pragma mark - internal

+ (NSString *)base64encodeData:(NSData *)data {
    static const char cb64[]="ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
    const char *dataptr = [data bytes];
    const NSUInteger input_length = [data length];
    NSMutableString *response = [NSMutableString stringWithCapacity:input_length*2];
    
    for(NSUInteger i=0; i<input_length;) {
        uint32_t octet_a = i < input_length ? dataptr[i++] : 0;
        uint32_t octet_b = i < input_length ? dataptr[i++] : 0;
        uint32_t octet_c = i < input_length ? dataptr[i++] : 0;
        uint32_t triple = (octet_a << 0x10) + (octet_b << 0x08) + octet_c;
        [response appendFormat:@"%c", cb64[(triple >> 3 * 6) & 0x3F]];
        [response appendFormat:@"%c", cb64[(triple >> 2 * 6) & 0x3F]];
        [response appendFormat:@"%c", cb64[(triple >> 1 * 6) & 0x3F]];
        [response appendFormat:@"%c", cb64[(triple >> 0 * 6) & 0x3F]];        
    }
    
    static const int mod_table[] = {0, 2, 1};
    for (int i = 0; i < mod_table[input_length % 3]; i++)
        [response appendString:@"="];
    
    return response;
}

- (NSString *)base64encodeString:(NSString *)string {
    return [[self class] base64encodeData:[string dataUsingEncoding:encoding]];
}

- (void)prepare {
    [formPost setupPostFormRequest:urlRequest encoding:encoding];

    // generate input stream using Creation Block 
    if (urlRequest.HTTPBodyStream == nil && HTTPBodyStreamCreationBlock) {
        NSInputStream *inputStream = HTTPBodyStreamCreationBlock();
        [self setHTTPBodyStream:inputStream contentType:nil];
    }
    
}

- (NSInputStream *)regenerateBodyStream {
    if (formPost) {
        NSInputStream *newStream = [formPost setupPostFormRequest:nil encoding:encoding];
        if (newStream == nil) {
            NSLog(@"RDHTTP: we have tried to re-generate form post input stream, but failed");
        }
    }
    
    if (postBodyFilePath) {
        return [NSInputStream inputStreamWithFileAtPath:self.postBodyFilePath];
    }
    
    if (HTTPBodyStreamCreationBlock) {
        NSInputStream *inputStream = HTTPBodyStreamCreationBlock();
        if (inputStream) 
            return inputStream;
    }
    
    NSLog(@"RDHTTP: regenerateBodyStream was called, but we returned nil");
    NSLog(@"Examine how post body stream was set. Check HTTPBodyInputStreamCreationBlock");
    return nil;
}

@end



#pragma mark - RDHTTPFormPost

@interface RDHTTPMultipartPostStream : NSInputStream {
    NSString            *contentBoundary;
    NSUInteger          multipartBodyLength;
    NSMutableArray      *multipartDataArray;
    
    NSUInteger          currentBufferIndex;
    NSUInteger          currentBufferPosition;
    NSData              *currentFileData;
    NSURL               *currentFileDataURL;
    
    NSStreamStatus      streamStatus;
}

- (id)initWithPostFields:(NSDictionary *)postFields
     multipartPostFields:(NSDictionary *)multipartPostFields
                encoding:(NSStringEncoding)encoding;

@property(nonatomic, readonly) NSUInteger multipartBodyLength;
@property(nonatomic, readonly) NSString   *contentBoundary;

@end


@interface RDHTTPFormPost() {
    // user storage
    NSMutableDictionary *postFields;
    NSMutableDictionary *multipartPostFiles;
}

- (NSData *)formURLEncodedBodyWithEncoding:(NSStringEncoding)encoding;
@end

@implementation RDHTTPFormPost

- (void)dealloc
{
    [postFields release];
    [multipartPostFiles release];    
    [super dealloc];
}

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

- (void)setFile:(NSURL *)fileURL forKey:(NSString *)key {
    if ([fileURL isFileURL] == NO) {
        NSLog(@"RDHTTP: setFile accepts only file URLs");
        return;
    }
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:[fileURL path]] == NO) {
        NSLog(@"RDHTTP: not-existing file %@ in RDHTTPFormPost setFile", fileURL);
        return;
    }
    
    if (multipartPostFiles == nil) 
        multipartPostFiles = [NSMutableDictionary new];
    
    [multipartPostFiles setObject:fileURL forKey:key];
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

- (NSInputStream *)setupPostFormRequest:(NSMutableURLRequest *)request encoding:(NSStringEncoding)encoding {
    NSString *charset = (__bridge_transfer NSString *)CFStringConvertEncodingToIANACharSetName(CFStringConvertNSStringEncodingToEncoding(encoding));

    if (multipartPostFiles) {
        // multipart/form-data, stream
        
        RDHTTPMultipartPostStream *postStream;
        
        postStream = [[RDHTTPMultipartPostStream alloc] initWithPostFields:postFields
                                                       multipartPostFields:multipartPostFiles
                                                                  encoding:encoding];
        
        [request        addValue:[NSString stringWithFormat:@"%u", postStream.multipartBodyLength]
              forHTTPHeaderField:@"Content-Length"];
        
        NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; charset=%@; boundary=%@", charset, postStream.contentBoundary];
        [request addValue:contentType forHTTPHeaderField:@"Content-Type"];

        [request setHTTPBodyStream:postStream];
        
        return [postStream autorelease];
    }
    else {
        // x-www-form-urlencoded body, in memory 
        if (postFields == nil)
            return nil;

        NSString *contentType = [NSString stringWithFormat:@"application/x-www-form-urlencoded; charset=%@", charset];
        [request addValue:contentType forHTTPHeaderField:@"Content-Type"];
        [request setHTTPBody:[self formURLEncodedBodyWithEncoding:NSUTF8StringEncoding]];
    }
    
    return nil;
}

- (NSData *)formURLEncodedBodyWithEncoding:(NSStringEncoding)encoding {
    
    NSMutableData *data = [NSMutableData data];
    
    BOOL first = YES;
    CFStringEncoding enc = CFStringConvertNSStringEncodingToEncoding(encoding);
    
    for (NSString *key in postFields) {
        if (first == NO)
            [data appendBytes:"&" length:1];
        
        [data appendData:[self dataByAddingPercentEscapesToString:key usingEncoding:enc]];
        [data appendBytes:"=" length:1];
        [data appendData:[self dataByAddingPercentEscapesToString:[postFields objectForKey:key]
                                                    usingEncoding:enc]];
        first = NO;
    }
    
    return data;
}

#pragma mark - utilities 

+ (NSString *)guessContentTypeForURL:(NSURL *)fileURL defaultEncoding:(NSStringEncoding)encoding {
    // no charset ; charset=... is currently added, encoding is unused

    // Borrowed from http://stackoverflow.com/questions/2439020/wheres-the-iphone-mime-type-database
    CFStringRef UTI = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (CFStringRef)[fileURL pathExtension], NULL);
    CFStringRef MIMEType = UTTypeCopyPreferredTagWithClass (UTI, kUTTagClassMIMEType);
    CFRelease(UTI);
    if (!MIMEType) {
        return @"application/octet-stream";
    }
    return [(__bridge_transfer NSString *)MIMEType autorelease];
}


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


@implementation RDHTTPMultipartPostStream
@synthesize multipartBodyLength;
@synthesize contentBoundary;

- (id)initWithPostFields:(NSDictionary *)postFields
     multipartPostFields:(NSDictionary *)multipartPostFiles
                encoding:(NSStringEncoding)encoding 
{
    self = [super init];
    if (self) {
        streamStatus = NSStreamStatusNotOpen;
        multipartDataArray = [NSMutableArray new];
        
        CFUUIDRef theUUID = CFUUIDCreate(NULL);
        contentBoundary = (__bridge_transfer NSString *)CFUUIDCreateString(NULL, theUUID);
        CFRelease(theUUID);
        
        NSMutableData *simpleFieldsData = [NSMutableData dataWithCapacity:1024];
        
        NSString *boundaryBegin = [NSString stringWithFormat:@"--%@\r\n", contentBoundary];
        [simpleFieldsData appendData:[boundaryBegin dataUsingEncoding:encoding]];
        
        NSData *boundaryMiddle = [[NSString stringWithFormat:@"\r\n--%@\r\n", contentBoundary] dataUsingEncoding:encoding];
        
        BOOL first = YES;
        for (NSString *key in postFields) {
            if (first == NO) {
                [simpleFieldsData appendData:boundaryMiddle];
            }
            
            NSString *formData;
            formData = [NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"\r\n\r\n%@", key, [postFields objectForKey:key]];
            [simpleFieldsData appendData:[formData dataUsingEncoding:encoding]];
            
            first = NO;
        }
        
        [multipartDataArray addObject:simpleFieldsData];
        
        for(NSString *key in multipartPostFiles) {
            NSURL *fileURL = [multipartPostFiles objectForKey:key];
            
            if ([[NSFileManager defaultManager] fileExistsAtPath:[fileURL path]] == NO) {
                NSLog(@"RDHTTP: no file %@ exists", fileURL);
                continue;
            }
            
            if (first == NO) {
                [multipartDataArray addObject:boundaryMiddle];
            }
            
            NSString *fileName = [fileURL lastPathComponent];
            
            NSMutableString *fileHeaders = [NSMutableString stringWithCapacity:256];
            NSString *contentType = [RDHTTPFormPost guessContentTypeForURL:fileURL defaultEncoding:encoding];
            
            [fileHeaders appendFormat:@"Content-Disposition: form-data; name=\"%@\"; filename=\"%@\"\r\n", key, fileName];
            [fileHeaders appendFormat:@"Content-Type: %@\r\n\r\n", contentType];
            
            [multipartDataArray addObject:[fileHeaders dataUsingEncoding:encoding]];
            [multipartDataArray addObject:fileURL];
            first = NO;
        }
        
        
        NSString *boundaryEnd = [NSString stringWithFormat:@"\r\n--%@--\r\n", contentBoundary];
        [multipartDataArray addObject:[boundaryEnd dataUsingEncoding:encoding]];
        
        
        // calculate length
        multipartBodyLength = 0;
        for (NSObject *part in multipartDataArray) {
            if ([part isKindOfClass:[NSData class]]) {
                multipartBodyLength += [(NSData *)part length];
                //NSLog(@"\n%@", [[[NSString alloc] initWithData:(NSData *)part encoding:NSUTF8StringEncoding] autorelease]);
            }
            else if ([part isKindOfClass:[NSURL class]]) {
                //NSLog(@"\n%@", part);
                
                NSError *error = nil;
                NSDictionary *dict = [[NSFileManager defaultManager] attributesOfItemAtPath:[(NSURL *)part path]
                                                                                      error:&error];
                
                unsigned long long fileSize = [dict fileSize];
                multipartBodyLength += (NSUInteger)fileSize;
            }
        }
        
    }
    return self;
}

- (void)dealloc {
    [multipartDataArray release];
    [contentBoundary release];
    [currentFileDataURL release];
    [currentFileData release];

    [super dealloc];
}

#pragma mark - input stream methods 

- (NSInteger)read:(uint8_t *)buffer maxLength:(NSUInteger)len {
    //NSLog(@"%s = %d", __func__, len);
    
    if ([self hasBytesAvailable] == NO)
        return 0;
    
    streamStatus = NSStreamStatusReading;
    
    NSObject *currentPart = [multipartDataArray objectAtIndex:currentBufferIndex];
    
    NSData *data = nil;
    if ([currentPart isKindOfClass:[NSData class]]) {
        data = (NSData *)currentPart;
    }
    else if ([currentPart isKindOfClass:[NSURL class]]) {
        NSURL *url = (NSURL *)currentPart;
        
        if ([url isEqual:currentFileDataURL] == NO) {
            [currentFileDataURL release];
            [currentFileData release];
            
            currentFileData = [[NSData alloc] initWithContentsOfMappedFile:[url path]];
            currentFileDataURL = [url copy];
        }
        
        data = currentFileData;
    }
    
    if (len >= [data length] - currentBufferPosition) {
        len = [data length] - currentBufferPosition;
        
        [data getBytes:buffer range:NSMakeRange(currentBufferPosition, len)];
        currentBufferIndex++;
        currentBufferPosition = 0;
    }
    else {
        [data getBytes:buffer range:NSMakeRange(currentBufferPosition, len)];
        currentBufferPosition += len;
    }
    
    streamStatus = NSStreamStatusOpen;
    return len;
}

- (BOOL)hasBytesAvailable {
    return currentBufferIndex < [multipartDataArray count];
}

- (BOOL)getBuffer:(uint8_t **)buffer length:(NSUInteger *)len {
    return NO;
}

- (void)open {
    streamStatus = NSStreamStatusOpen;
}

- (void)close {
    [multipartDataArray release];
    multipartDataArray = nil;
    streamStatus = NSStreamStatusClosed;
}

- (NSStreamStatus)streamStatus {
    if (multipartDataArray && [self hasBytesAvailable] == NO)
        return NSStreamStatusAtEnd;
    
    return streamStatus;
}

- (NSError *)streamError {
    return nil;
}

- (void)scheduleInRunLoop:(NSRunLoop *)aRunLoop forMode:(NSString *)mode {
    // Nothing to do here, because this stream does not implement a run loop to produce its data.
    // Should we bother to implement this method? Contact andrian@readdle.com if you know positive answer
}

- (void)removeFromRunLoop:(NSRunLoop *)aRunLoop forMode:(NSString *)mode {
    // Nothing to do here, because this stream does not implement a run loop to produce its data.
    // Should we bother to implement this method? Contact andrian@readdle.com if you know positive answer
}

- (void) _scheduleInCFRunLoop: (CFRunLoopRef) inRunLoop forMode: (CFStringRef) inMode {
    // Nothing to do here, because this stream does not implement a run loop to produce its data.
    // Should we bother to implement this method? Contact andrian@readdle.com if you know positive answer
}

- (void) _unscheduleFromCFRunLoop:(CFRunLoopRef)inRunLoop forMode:(CFStringRef)inMode {
    // Nothing to do here, because this stream does not implement a run loop to produce its data.
    // Should we bother to implement this method? Contact andrian@readdle.com if you know positive answer
}

- (BOOL) _setCFClientFlags: (CFOptionFlags)inFlags
                  callback: (CFReadStreamClientCallBack) inCallback
                   context: (CFStreamClientContext *) inContext
{
    // Nothing to do here, because this stream does not implement a run loop to produce its data.
    // Should we bother to implement this method? Contact andrian@readdle.com if you know positive answer
    return NO;
}

@end










#pragma mark - Challenge Decision Helper Objects

@interface RDHTTPChallangeDecision() {
@protected
    NSURLAuthenticationChallenge *challenge;
    NSString *host;
}
- (id)initWithChallenge:(NSURLAuthenticationChallenge *)aChallenge host:(NSString *)aHost;
@end

@implementation RDHTTPChallangeDecision
@synthesize host;
- (id)initWithChallenge:(NSURLAuthenticationChallenge *)aChallenge host:(NSString *)aHost {
    self = [super init];
    if (self) {
        challenge = [aChallenge retain];
        host = [aHost retain];
    }
    return self;
}

- (void)cancel {
    [[challenge sender] continueWithoutCredentialForAuthenticationChallenge:challenge];
}

- (void)dealloc {
    [host release];
    [challenge release];
    [super dealloc];
}
@end


@implementation RDHTTPAuthorizer
@dynamic host;

- (void)continueWithUsername:(NSString *)username password:(NSString *)password {
    
    NSURLCredential *credential = [NSURLCredential credentialWithUser:username
                                                             password:password
                                                          persistence:NSURLCredentialPersistenceNone];

    [[challenge sender] useCredential:credential
           forAuthenticationChallenge:challenge];
     
}

- (void)cancelAuthorization {
    [[challenge sender] continueWithoutCredentialForAuthenticationChallenge:challenge];
}

@end

@implementation RDHTTPSSLServerTrust
@dynamic host;

- (void)trust {
    [[challenge sender] useCredential:[NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust] 
           forAuthenticationChallenge:challenge];
}
- (void)dontTrust {
    [[challenge sender] continueWithoutCredentialForAuthenticationChallenge:challenge];
}

@end


#pragma mark - RDHTTPThread

static RDHTTPThread *_rdhttpThread;

@implementation RDHTTPThread

+ (RDHTTPThread *)defaultThread {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (_rdhttpThread == nil) {
            _rdhttpThread = [[RDHTTPThread alloc] init];
            [_rdhttpThread start];
        }            
    });
    
    return _rdhttpThread;
}

- (void)main {
    @autoreleasepool {
        self.name = @"RDHTTPConnectionThread";
        pthread_setname_np("RDHTTPConnectionThread");
        [NSTimer scheduledTimerWithTimeInterval:1000000 target:nil selector:nil userInfo:nil repeats:YES];
        NSRunLoop *loop = [NSRunLoop currentRunLoop];
        while(!self.isCancelled && [loop runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:10.0]]);
    }
}

@end





#pragma mark - RDHTTPOperation

@interface RDHTTPOperation()<NSURLConnectionDataDelegate, NSURLConnectionDelegate> {
    RDHTTPRequest       *request; // this object is mutable, we agreed to use our copy for non-mutable tasks only
    
    NSString            *tempFilePath;
    NSFileHandle        *tempFileHandle;
    
    BOOL                sendProgressUpdates;
    
    NSURLConnection     *connection;
    long long           httpExpectedContentLength;
    long long           httpSavedDataLength;
    NSHTTPURLResponse   *httpResponse;
    NSMutableData       *httpResponseData;
    
    
    BOOL                isCancelled;
    BOOL                isExecuting;
    BOOL                isFinished;
}

- (void)_start;

@end

@implementation RDHTTPOperation

- (id)initWithRequest:(RDHTTPRequest *)aRequest {
    self = [super init];
    if (self) {
        request = [aRequest copy];
        sendProgressUpdates = YES;
    }
    return self;
}

- (void)dealloc {
    [request release];
    
    [httpResponse release];
    [httpResponseData release];
    
    [super dealloc];
}

#pragma mark - Operation methods 
@synthesize isExecuting;
@synthesize isCancelled;
@synthesize isFinished;

- (BOOL)isConcurrent {
    return YES;
}

- (void)start {
    if (self.isCancelled || self.isExecuting) {
        return;
    }
    
    [self willChangeValueForKey:@"isExecuting"];
    isExecuting = YES;
    [self didChangeValueForKey:@"isExecuting"];
    
    NSAssert(isExecuting && isFinished == NO, @"RDHTTPConnection: someone called -(void)start twice");
    
    if (request.useInternalThread) {
        
        if (_rdhttpThread == nil) {
            
#ifdef TARGET_OS_IPHONE
            NSObject<UIApplicationDelegate> *appDelegate = [UIApplication sharedApplication].delegate;
            if ([appDelegate respondsToSelector:@selector(rdhttpThread)]) {
                _rdhttpThread = [appDelegate performSelector:@selector(rdhttpThread)];
            }
#endif
            if (_rdhttpThread == nil) {
                _rdhttpThread = [RDHTTPThread defaultThread];
            }
            
        }
        
        [self performSelector:@selector(_start) onThread:_rdhttpThread withObject:nil waitUntilDone:NO];
    }
    else 
        [self _start];
}

- (void)_start {
    [request prepare];
    connection = [[[NSURLConnection alloc] initWithRequest:[request _nsurlrequest]
                                                  delegate:self
                                          startImmediately:NO] autorelease];

    [connection scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
    [connection start];
}
             


- (void)_cancel:(BOOL)shouldCallCompletion {
    if (self.isCancelled || self.isFinished) 
        return;
    
    [self retain];
    
    [connection cancel];
    connection = nil;
    
    [self willChangeValueForKey:@"isCancelled"];
    isCancelled = YES;
    [self didChangeValueForKey:@"isCancelled"];
    
    if ((request.completionBlock == nil) || (shouldCallCompletion == NO)) {
        [self release];
        return;
    }

    
    rdhttp_block_t completionBlock = request.completionBlock;
    
    RDHTTPResponse *response = [[RDHTTPResponse alloc] initWithResponse:nil
                                                                request:request
                                                                  error:nil
                                                            isCancelled:YES
                                                           tempFilePath:nil
                                                                   data:nil];
    [response autorelease];
    
    dispatch_async(request.dispatchQueue, ^{
        completionBlock(response);
        [self release];
    });
}

- (void)cancelWithCompletionHandler {
    [self _cancel:YES];
}

- (void)cancel {
    [self _cancel:request.cancelCausesCompletion];
}

- (void)prepareTempFile {
    
    CFUUIDRef theUUID = CFUUIDCreate(NULL);
    NSString *tempUUID = (__bridge_transfer NSString *)CFUUIDCreateString(NULL, theUUID);
    NSString *tempName = [NSString stringWithFormat:@"RDHTTP-%@", tempUUID];
    [tempUUID release];
    CFRelease(theUUID);

    tempFilePath = [[NSTemporaryDirectory() stringByAppendingPathComponent:tempName] retain];
    [[NSFileManager defaultManager] createFileAtPath:tempFilePath contents:[NSData data] attributes:nil];
    tempFileHandle = [[NSFileHandle fileHandleForWritingAtPath:tempFilePath] retain];
}

#pragma mark - NSURLConnection delegate / dataSource

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    [tempFileHandle closeFile];
    
    rdhttp_block_t completionBlock = request.completionBlock;
    
    if (completionBlock && [self isCancelled] == NO) {    
        RDHTTPResponse *response = [[[RDHTTPResponse alloc] initWithResponse:nil
                                                                     request:request
                                                                       error:error
                                                                 isCancelled:NO
                                                                tempFilePath:tempFilePath
                                                                        data:nil] autorelease];
        
        dispatch_async(request.dispatchQueue, ^{
            completionBlock(response);
            if (tempFilePath)
                [[NSFileManager defaultManager] removeItemAtPath:tempFilePath error:nil];
        });
    }
    else {
        if (tempFilePath)
            [[NSFileManager defaultManager] removeItemAtPath:tempFilePath error:nil];
    }
    
    [self willChangeValueForKey:@"isExecuting"];
    [self willChangeValueForKey:@"isFinished"];
    isExecuting = NO;
    isFinished = YES;
    [self didChangeValueForKey:@"isExecuting"];
    [self didChangeValueForKey:@"isFinished"];
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)aResponse {
    NSAssert([aResponse isKindOfClass:[NSHTTPURLResponse class]], @"NSURLConnection did not return NSHTTPURLResponse");

    [httpResponse release];
    httpResponse = [(NSHTTPURLResponse *)aResponse retain];
    httpExpectedContentLength = [httpResponse expectedContentLength];
    
    if (request.shouldSaveResponseToFile) {
        [self prepareTempFile];    
    }
    else {
        NSUInteger dataCapacity = 8192;
        if (httpExpectedContentLength != NSURLResponseUnknownLength)
            dataCapacity = httpExpectedContentLength;
        
        [httpResponseData release];
        httpResponseData = [[NSMutableData alloc] initWithCapacity:dataCapacity];
    }
    
    if (request.headersHandler && [self isCancelled] == NO) {
        RDHTTPResponse *response = [[[RDHTTPResponse alloc] initWithResponse:httpResponse
                                                                     request:request
                                                                       error:nil
                                                                 isCancelled:NO
                                                                tempFilePath:nil // too early to pass tempFilePath, it is empty
                                                                        data:nil] autorelease];
        
        dispatch_async(request.dispatchQueue, ^{
            request.headersHandler(response, self);
        });
    }
    
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    if (httpResponseData) {
        [httpResponseData appendData:data];
    }
    else {
        [tempFileHandle writeData:data];
    }
    
    httpSavedDataLength += [data length];
    
    if (request.downloadProgressHandler && sendProgressUpdates) {
        rdhttp_progress_block_t progressBlock = request.downloadProgressHandler;
        
        if (httpExpectedContentLength > 0) {
            float progress = (float)httpSavedDataLength  / (float)httpExpectedContentLength;
            dispatch_async(dispatch_get_main_queue(), ^{ progressBlock(progress); });
        }
        else {
            dispatch_async(dispatch_get_main_queue(), ^{ progressBlock(-1.0f); });
            sendProgressUpdates = NO;
        }
    }
}

- (void)        connection:(NSURLConnection *)connection 
           didSendBodyData:(NSInteger)bytesWritten 
         totalBytesWritten:(NSInteger)totalBytesWritten 
 totalBytesExpectedToWrite:(NSInteger)totalBytesExpectedToWrite 
{
    if (request.uploadProgressHandler) {
        rdhttp_progress_block_t progressBlock = request.uploadProgressHandler;
        
        if (totalBytesExpectedToWrite > 0) {
            float progress = (float)totalBytesWritten  / (float)totalBytesExpectedToWrite;
            dispatch_async(dispatch_get_main_queue(), ^{ progressBlock(progress); });
        }
    }
}

- (void)connectionDidFinishLoading:(NSURLConnection *)aConnection {
    connection = nil;
    [tempFileHandle closeFile];
    rdhttp_block_t completionBlock = request.completionBlock;
    
    if (completionBlock == nil || [self isCancelled]) {
        if (tempFilePath)
            [[NSFileManager defaultManager] removeItemAtPath:tempFilePath error:nil];
        return;
    }
    
    RDHTTPResponse *response = [[RDHTTPResponse alloc] initWithResponse:httpResponse
                                                                request:request
                                                                  error:nil
                                                            isCancelled:NO
                                                           tempFilePath:tempFilePath
                                                                   data:httpResponseData];
    [response autorelease];
    
    [httpResponseData release]; // response retains this
    httpResponseData = nil;

    
    dispatch_async(request.dispatchQueue, ^{
        completionBlock(response);
        if (tempFilePath)
            [[NSFileManager defaultManager] removeItemAtPath:tempFilePath error:nil];
    });
    
    [self willChangeValueForKey:@"isExecuting"];
    [self willChangeValueForKey:@"isFinished"];
    isExecuting = NO;
    isFinished = YES;
    [self didChangeValueForKey:@"isExecuting"];
    [self didChangeValueForKey:@"isFinished"];
}

- (NSURLRequest *)connection:(NSURLConnection *)connection
             willSendRequest:(NSURLRequest *)newURLRequest
            redirectResponse:(NSURLResponse *)redirectResponse 
{
    if (redirectResponse == nil) // transforming to canonical form
        return newURLRequest;
    
    if (request.shouldRedirect) {
        if (request.shouldUseRFC2616RedirectBehaviour) {
            NSMutableURLRequest *new2616request = [[[request _nsurlrequest] copy] autorelease];
            [new2616request setURL:newURLRequest.URL];
            return new2616request;
        }
        
        return newURLRequest;
    }
    
    return nil;
}

- (BOOL)connection:(NSURLConnection *)connection canAuthenticateAgainstProtectionSpace:(NSURLProtectionSpace *)protectionSpace {	
	return YES;
}


- (BOOL)connectionShouldUseCredentialStorage:(NSURLConnection *)connection {
	return YES;
}

- (NSInputStream *) connection:(NSURLConnection *)connection needNewBodyStream:(NSURLRequest *)resentRequest {
    return [request regenerateBodyStream];
}

- (void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {
    NSString *host = [[request _nsurlrequest].URL host];
    
    if ([challenge.protectionSpace.authenticationMethod isEqualToString:@"NSURLAuthenticationMethodServerTrust"]) {
        // certificate trust
        RDHTTPSSLServerTrust *serverTrust = [[RDHTTPSSLServerTrust alloc] initWithChallenge:challenge host:host];
        
        rdhttp_trustssl_block_t trust = [request SSLCertificateTrustHandler];
        if (trust == nil) {
            [serverTrust dontTrust];
            [serverTrust release];
            return;
        }

        dispatch_async(request.dispatchQueue, ^{ 
            trust(serverTrust);
        });
        [serverTrust release];

    }
    else {
        // normal login-password auth: 
        const int kAllowedLoginFailures = 1;
        RDHTTPAuthorizer *httpAuthorizer = [[RDHTTPAuthorizer alloc] initWithChallenge:challenge host:host];
        
        rdhttp_httpauth_block_t auth = [request HTTPAuthHandler];
        
        if ((auth == nil)||([challenge previousFailureCount] >= kAllowedLoginFailures)) {
            [httpAuthorizer cancelAuthorization];
            [httpAuthorizer release];
            return;
        }
            
        dispatch_async(request.dispatchQueue, ^{
            auth(httpAuthorizer);
        });
        
        [httpAuthorizer release];
    }
}

@end

