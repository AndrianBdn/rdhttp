//
//  RDHTTP.h
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


#import <Foundation/Foundation.h>

/** Error domain for non-200 HTTP response codes */
extern NSString *const RDHTTPResponseCodeErrorDomain;


@class RDHTTPFormPost;
@class RDHTTPOperation;
@class RDHTTPResponse;
@class RDHTTPAuthorizer;
@class RDHTTPSSLServerTrust;

/** Completion block type */
typedef void (^rdhttp_block_t)(RDHTTPResponse *response);

/** Response block type */
typedef void (^rdhttp_header_block_t)(RDHTTPResponse *response, RDHTTPOperation *connection);

/** Progress block type */
typedef void (^rdhttp_progress_block_t)(float progress);

/** SSL Trust block type */
typedef void (^rdhttp_trustssl_block_t)(RDHTTPSSLServerTrust *sslTrustResponse);

/** HTTP Auth block type */
typedef void (^rdhttp_httpauth_block_t)(RDHTTPAuthorizer *httpAuthorizeResponse);

/** HTTP BODY Input Stream */
typedef NSInputStream *(^rdhttp_httpbody_stream_block_t)();





/** RDHTTPRequest is a main RDHTTP class for library end-user. 
 * This class is used for creating/configuring HTTP request as well as getting an operation that executes it.
 */
@interface RDHTTPRequest : NSObject

/** @name Creating Requests */

/** Creates new RDHTTPRequest object with GET HTTP request method 
 *  @param url Either <NSURL> or <NSString> object that represents absolute URL with HTTP or HTTPS scheme.
 *  @returns New RDHTTPRequest object with GET HTTP request method  
 */
+ (id)getRequestWithURL:(NSObject *)url;

/** Creates new RDHTTPRequest object with POST HTTP request method 
 *  @param url Either <NSURL> or <NSString> object that represents absolute URL with HTTP or HTTPS scheme.
 *  @returns New RDHTTPRequest object with POST HTTP request method  
 */
+ (id)postRequestWithURL:(NSObject *)url;

/** Creates new RDHTTPRequest object with custom HTTP request method
 *  @param method HTTP request method (verb), for example "DELETE", "OPTIONS", "PROPFIND" 
 *  @param url Either <NSURL> or <NSString> object that represents absolute URL with HTTP or HTTPS scheme.
 *  @returns New RDHTTPRequest object with custom HTTP request method  
 */
+ (id)customRequest:(NSString *)method withURL:(NSObject *)url;

/** @name Configuring Request */

/** A dictionary for passing custom information from <RDHTTPRequest> to <RDHTTPResponse> */
@property(nonatomic, copy)   NSDictionary       *userInfo;

/** Returns request's <RDHTTPFormPost> object which is used to set POST form values (key-value strings or files)
 * @returns request's form POST configuration object 
 */
@property(nonatomic, retain) RDHTTPFormPost     *formPost;

/** Dispatch queue for executing event blocks. By default all callback blocks are executed on the main queue. */
@property(nonatomic, assign) dispatch_queue_t   dispatchQueue;

/** A Boolean that indicates if saving HTTP response directly to file is required. */
@property(nonatomic, assign) BOOL               shouldSaveResponseToFile;

/** String encoding which is used to encode request data (used by <RDHTTPFormPost>). */
@property(nonatomic, assign) NSStringEncoding   encoding;

/** A Boolean that indicates whether HTTP redirects should be handled transparently. */
@property(nonatomic, assign) BOOL               shouldRedirect;
@property(nonatomic, assign) BOOL               shouldUseRFC2616RedirectBehaviour;
@property(nonatomic, assign) BOOL               cancelCausesCompletion;
@property(nonatomic, copy)   NSString           *userAgent;
@property(nonatomic, assign) BOOL               useInternalThread;

/** Timeout time interval. Default is 20 sec. */
@property(nonatomic, assign) NSTimeInterval                 timeoutInterval;
@property(nonatomic, assign) NSURLRequestCachePolicy        cachePolicy;
@property(nonatomic, assign) NSURLRequestNetworkServiceType networkServiceType;
@property(nonatomic, assign) BOOL                           HTTPShouldUsePipelining;
@property(nonatomic, assign) BOOL                           HTTPShouldHandleCookies;
@property(nonatomic, assign) NSURL                          *URL;


@property(nonatomic, copy)  rdhttp_httpauth_block_t HTTPAuthHandler;
@property(nonatomic, copy)  rdhttp_trustssl_block_t SSLCertificateTrustHandler;
@property(nonatomic, copy)  rdhttp_header_block_t   headersHandler;
@property(nonatomic, copy)  rdhttp_progress_block_t downloadProgressHandler;
@property(nonatomic, copy)  rdhttp_progress_block_t uploadProgressHandler;
@property(nonatomic, copy)  rdhttp_httpbody_stream_block_t HTTPBodyStreamCreationBlock;

// additional difinition of setters make Xcode autocompletion better
- (void)setHTTPAuthHandler:(rdhttp_httpauth_block_t)HTTPAuthHandler;
- (void)setSSLCertificateTrustHandler:(rdhttp_trustssl_block_t)SSLCertificateTrustHandler;
- (void)setHeadersHandler:(rdhttp_header_block_t)headersHandler;
- (void)setDownloadProgressHandler:(rdhttp_progress_block_t)progressHandler;
- (void)setUploadProgressHandler:(rdhttp_progress_block_t)progressHandler;
- (void)setHTTPBodyStreamCreationBlock:(rdhttp_httpbody_stream_block_t)streamGenerator;

/** Sets HTTP Authorization header for Basic Authorization using supplied credentials. 
 *  
 *  This method passes authorization data without calling <HTTPAuthHandler> and re-sending initial request.
 *  @param username The username for the credential.
 *  @param password The password for _username_.
 */
- (void)tryBasicHTTPAuthorizationWithUsername:(NSString *)username password:(NSString *)password;

/** Sets the specified HTTP header field.
 *  @param value The new value for the header field. Any existing value for the field is replaced by the new value. 
 *  @param field The name of the header field to set. In keeping with the HTTP RFC, HTTP header field names are case-insensitive. 
 */
- (void)setValue:(NSString *)value forHTTPHeaderField:(NSString *)field;

- (void)setHTTPBodyData:(NSData *)data contentType:(NSString *)contentType;
- (void)setHTTPBodyStream:(NSInputStream *)inputStream contentType:(NSString *)contentType;
- (void)setHTTPBodyFilePath:(NSString *)filePath guessContentType:(BOOL)guess;

/** Creates and returns an initialized <RDHTTPOperation> that executes current request. 
 *  @param aCompletionBlock The handler to call when request execution is completed.
 */
- (RDHTTPOperation *)operationWithCompletionHandler:(rdhttp_block_t)aCompletionBlock;

/** Creates and returns an initialized <RDHTTPOperation>. New operation object is **automatically started** to execute current request.
 *  @param aCompletionBlock The handler to call when request execution is completed.
 */
- (RDHTTPOperation *)startWithCompletionHandler:(rdhttp_block_t)aCompletionBlock;

@end






/** RDHTTPResponse stores information about HTTP response, HTTP response data inself (as NSData or file) and 
 * provides useful helper methods 
 */
 
@interface RDHTTPResponse : NSObject
/** Retrieves value of HTTP response field 
 * @param field The name of the header field whose value is to be returned. Case-sensitive. 
 */
- (NSString *)valueForHTTPHeaderField:(NSString *)field;

/** Moves HTTP-response file to destination 
 *  @param destination The file URL that identifies the file for storing HTTP response data.
 *  The URL in this parameter must not be a file reference URL. This parameter must not be nil.
 *  @param createIntermediates If YES, this method creates any non-existent parent directories as part of saving file to destination. 
 *  If NO, this method fails if any of the intermediate parent directories does not exist.
 *  @param error On input, a pointer to an error object. If an error occurs, this pointer is
 *  set to an actual error object containing the error information. 
 *  You may specify nil for this parameter if you do not want the error information.
 *  @return YES if the operation was successful, otherwise NO.
 */
- (BOOL)  moveResponseFileToURL:(NSURL *)destination 
    withIntermediateDirectories:(BOOL)createIntermediates 
                          error:(NSError **)error;

/** A Boolean that indicates whether source RDHTTP requests was cancelled. You can recieve cancelled responses if someonce calls  <[RDHTTPOperation cancelWithCompletionHandler]> or <[RDHTTPRequest setCancelCausesCompletion:]> was set to YES. */
@property(nonatomic, readonly) BOOL         isCancelled;

/** A dictionary for passing custom information from RDHTTPRequest to RDHTTPResponse */
@property(nonatomic, readonly) NSDictionary *userInfo;

/** Describes the error that occurred if non-200 HTTP response was returned. */
@property(nonatomic, readonly) NSError      *httpError;

/** Describes generic network connection error. */
@property(nonatomic, readonly) NSError      *networkError;

/** Describes request error, either the one which is returned by httpError or the one returned by <error> */
@property(nonatomic, readonly) NSError      *error;

/** Returns the receiver’s HTTP status code. */
@property(nonatomic, readonly) NSUInteger   statusCode;

/** Returns HTTP response as string. Encoding specified in Content-Type is used, default encoding is UTF-8. */
@property(nonatomic, readonly) NSString     *responseString;

/** Returns HTTP response as data. If <shouldSaveResponseToFile> flag of <RDHTTPRequest> was set this property returns nil. */
@property(nonatomic, readonly) NSData       *responseData;

/** Returns file URL of HTTP response saved as a temporary file. 
    If <shouldSaveResponseToFile> flag of <RDHTTPRequest> was not set this property returns nil. */
@property(nonatomic, readonly) NSURL        *responseFileURL;

/** Returns all the HTTP header fields of the receiver. */
@property(nonatomic, readonly) NSDictionary *allHeaderFields;
@end


// Common parent of RDHTTPAuth and RDHTTPSSLServerTrust
@interface RDHTTPChallangeDecision : NSObject
@end


/** RDHTTPAuth */
@interface RDHTTPAuthorizer : RDHTTPChallangeDecision
- (void)continueWithUsername:(NSString *)username password:(NSString *)password;
- (void)cancelAuthorization;
@end


/** RDHTTPSSLServerTrust */
@interface RDHTTPSSLServerTrust : RDHTTPChallangeDecision
- (void)trust;
- (void)dontTrust;
@end


/** RDHTTPOperation */
@interface RDHTTPOperation : NSOperation
@property (readonly) BOOL isExecuting;
@property (readonly) BOOL isFinished;
@property (readonly) BOOL isCancelled;
- (void)cancelWithCompletionHandler;
@end




/** RDHTTPFormPost */
@interface RDHTTPFormPost : NSObject<NSCopying> 
- (void)setPostValue:(NSString *)value forKey:(NSString *)key;
- (void)setFile:(NSURL *)fileURL forKey:(NSString *)key;
+ (NSString *)stringByAddingPercentEscapesToString:(NSString *)url;
+ (NSString *)guessContentTypeForURL:(NSURL *)filePath defaultEncoding:(NSStringEncoding)encoding;
@end

