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





/** RDHTTPRequest is a main RDHTTP class. 
 * This class is used for configuring HTTP request and starting request operation.
 */
@interface RDHTTPRequest : NSObject

/** @name Creating Requests */

/** Creates new RDHTTPRequest object with GET HTTP request method 
 *  @param URL <NSURL> that represents absolute URL with HTTP or HTTPS scheme.
 *  @returns New RDHTTPRequest object with GET HTTP request method  
 */
+ (id)getRequestWithURL:(NSURL *)URL;

/** Creates new RDHTTPRequest object with GET HTTP request method 
 *  @param URLString <NSString> that represents absolute URL with HTTP or HTTPS scheme
 *  @returns New RDHTTPRequest object with GET HTTP request method  
 */
+ (id)getRequestWithURLString:(NSString *)URLString;


/** Creates new RDHTTPRequest object with POST HTTP request method 
 *  @param URL <NSURL> that represents absolute URL with HTTP or HTTPS scheme.
 *  @returns New RDHTTPRequest object with POST HTTP request method  
 */
+ (id)postRequestWithURL:(NSURL *)URL;


/** Creates new RDHTTPRequest object with POST HTTP request method 
 *  @param URLString <NSString> that represents absolute URL with HTTP or HTTPS scheme
 *  @returns New RDHTTPRequest object with POST HTTP request method  
 */
+ (id)postRequestWithURLString:(NSString *)URLString;

/** Creates new RDHTTPRequest object with custom HTTP request method
 *  @param method HTTP request method (verb), for example "DELETE", "OPTIONS", "PROPFIND" 
 *  @param URL <NSURL> that represents absolute URL with HTTP or HTTPS scheme.
 *  @returns New RDHTTPRequest object with custom HTTP request method  
 */
+ (id)customRequest:(NSString *)method withURL:(NSURL *)URL;


/** Creates new RDHTTPRequest object with custom HTTP request method
 *  @param method HTTP request method (verb), for example "DELETE", "OPTIONS", "PROPFIND" 
 *  @param URLString <NSString> that represents absolute URL with HTTP or HTTPS scheme
 *  @returns New RDHTTPRequest object with custom HTTP request method  
 */
+ (id)customRequest:(NSString *)method withURLString:(NSString *)URLString;





/** @name Request block handlers */

/** A rdhttp_httpauth_block_t block which is
 *   void (^rdhttp_httpauth_block_t)(RDHTTPAuthorizer *httpAuthorizeResponse)
 *
 *  This block would be called if the server requeres authorization.
 *  To proceed with request execution call one of <RDHTTPAuthorizer> methods. 
 */ 
@property(nonatomic, copy)  rdhttp_httpauth_block_t HTTPAuthHandler;


/** A rdhttp_trustssl_block_t block which is 
 *   void (^rdhttp_trustssl_block_t)(RDHTTPSSLServerTrust *sslTrustResponse)
 *
 *  You may need to use this block for servers with self-signed sertificates.  
 *  To proceed with request execution call one of <RDHTTPSSLServerTrust> methods. 
 */ 
@property(nonatomic, copy)  rdhttp_trustssl_block_t SSLCertificateTrustHandler;


/** A rdhttp_header_block_t block which is
 *   void (^rdhttp_header_block_t)(RDHTTPResponse *response, RDHTTPOperation *connection)
 *
 *  This block would be called after HTTP server has returned headers. 
 *  It is possible to examine headers here (see <RDHTTPResponse>) 
 *  and/or cancel connection. 
 */ 
@property(nonatomic, copy)  rdhttp_header_block_t   headersHandler;


/** A rdhttp_progress_block_t block which is
 *   void (^rdhttp_progress_block_t)(float progress);
 *
 *  This block would be called periodically when receiving request response from the server.
 */ 
@property(nonatomic, copy)  rdhttp_progress_block_t downloadProgressHandler;


/** A rdhttp_progress_block_t block which is
 *   void (^rdhttp_progress_block_t)(float progress);
 *
 *  This block would be called periodically when sending request body to the server.
 */ 
@property(nonatomic, copy)  rdhttp_progress_block_t uploadProgressHandler;


/** A rdhttp_httpbody_stream_block_t block which is 
 *   NSInputStream *(^rdhttp_httpbody_stream_block_t)();
 *
 *  RDHTTP may need to get new NSInputStream for request body in case the server
 *  has client asked to reconnect. This usually happens when you send requests with 
 *  HTTP body stream (set using <setHTTPBodyStream:contentType:>
 *  to servers with HTTP Digest authorization. 
 */ 
@property(nonatomic, copy)  rdhttp_httpbody_stream_block_t HTTPBodyStreamCreationBlock;


// additional difinition of setters make Xcode autocompletion better
- (void)setHTTPAuthHandler:(rdhttp_httpauth_block_t)HTTPAuthHandler;
- (void)setSSLCertificateTrustHandler:(rdhttp_trustssl_block_t)SSLCertificateTrustHandler;
- (void)setHeadersHandler:(rdhttp_header_block_t)headersHandler;
- (void)setDownloadProgressHandler:(rdhttp_progress_block_t)progressHandler;
- (void)setUploadProgressHandler:(rdhttp_progress_block_t)progressHandler;
- (void)setHTTPBodyStreamCreationBlock:(rdhttp_httpbody_stream_block_t)streamGenerator;



/** @name Additional request configuration */

/** A dictionary for passing custom information from <RDHTTPRequest> to <RDHTTPResponse> */
@property(nonatomic, copy)   NSDictionary       *userInfo;

/** Returns request's <RDHTTPFormPost> object which is used to set POST form values (key-value strings or files)
 *  @returns request's form POST configuration object 
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


/** A Boolean that indicates whether 301 and 302 automatic redirects will use the original
 *  method and and body, according to the HTTP 1.1 standard.
 *  Default is NO to follow the behaviour of most browsers.
 */
@property(nonatomic, assign) BOOL               shouldUseRFC2616RedirectBehaviour;


/** A String which would be used as a value for User-Agent: HTTP request header. */
@property(nonatomic, copy)   NSString           *userAgent;

/** A Boolean that indicates that RDHTTP will create its own thread that will be used for HTTP requests processing.
 * Internal thread is shared among all RDHTTP instances. It can also be returned from application delegate,
 * in case it confirms to <RDHTTPThreadProviderAppDelegate> protocol.
 */
@property(nonatomic, assign) BOOL               useInternalThread;

/** Timeout time interval. Default is 20 sec. */
@property(nonatomic, assign) NSTimeInterval                 timeoutInterval;


/** A <NSURLRequestCachePolicy> that will be associated with this request. */
@property(nonatomic, assign) NSURLRequestCachePolicy        cachePolicy;


/** A <NSURLRequestNetworkServiceType> that will be associated with this request */
@property(nonatomic, assign) NSURLRequestNetworkServiceType networkServiceType;


/** A Boolean that indicates whether the request should not wait for the previous response 
 * before transmitting. Set to YES if the receiver should transmit before the previous response is
 * received.  NO to wait for the previous response before transmitting. 
 */
@property(nonatomic, assign) BOOL                           HTTPShouldUsePipelining;


/** A Boolean which determines whether default cookie handling will happen for 
 * this request. Set to YES if cookies should be sent with and set for this request; 
 * otherwise NO.
 * The default is YES - in other words, cookies are sent from and 
 * stored to the cookie manager by default.
 */
@property(nonatomic, assign) BOOL                           HTTPShouldHandleCookies;

/** An URL for HTTP request */
@property(nonatomic, assign) NSURL                          *URL;


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

/** Sets the request body of the receiver to the specified data.
 *  @param data The new request body for the receiver. 
 *  @param contentType  The value of Content-Type HTTP header that would be transmitted with request. 
 *  Set to nil, if you don't need to set Content-Type header here. 
 */ 
- (void)setHTTPBodyData:(NSData *)data contentType:(NSString *)contentType;


/** Sets the request body of the receiver to data from specified input stream. 
 *  @param inputStream A <NSInputStream> object that will provide request body.
 *  @param contentType  The value of Content-Type HTTP header that would be transmitted with request. 
 *  Set to nil, if you don't need to set Content-Type header here. 
 */
- (void)setHTTPBodyStream:(NSInputStream *)inputStream contentType:(NSString *)contentType;


/** Sets the request body of the receiver to data from specified file. 
 *  @param filePath A path to file that contents would be used as a request body. 
 *  @param guess    A boolean that indicates if HTTP Content-Type header should be set based on file extension.
 */
- (void)setHTTPBodyFilePath:(NSString *)filePath guessContentType:(BOOL)guess;


/** Creates and returns an initialized <RDHTTPOperation> that executes current request. 
 *  @param aCompletionBlock A block to call when request execution is completed. This block type is 
 *         void (^rdhttp_block_t)(RDHTTPResponse *response);
 */
- (RDHTTPOperation *)operationWithCompletionHandler:(rdhttp_block_t)aCompletionBlock;

/** Creates and returns an initialized <RDHTTPOperation>. New operation object is **automatically started** 
 *  to execute current request.
 *  @param aCompletionBlock A block to call when request execution is completed. This block type is 
 *         void (^rdhttp_block_t)(RDHTTPResponse *response);
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
 *  The URL in this parameter must be a file reference URL. This parameter must not be nil.
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

/** A dictionary for passing custom information from RDHTTPRequest to RDHTTPResponse */
@property(nonatomic, readonly) NSDictionary *userInfo;

/** An URL of the resourse that returned the response */
@property(nonatomic, readonly) NSURL        *URL;


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




/** RDHTTPChallangeDecision is a parent class for <RDHTTPAuthorizer> and <RDHTTPSSLServerTrust>.
 */
@interface RDHTTPChallangeDecision : NSObject
/** Returns HTTP server hostname for this decision. */
@property(nonatomic, readonly) NSString *host;
@end





/** RDHTTPAuth */
@interface RDHTTPAuthorizer : RDHTTPChallangeDecision

/** Returns HTTP server hostname for this decision. */
@property(nonatomic, readonly) NSString *host;

/** Continue to process HTTP request with supplied _username_ and _password_
 *  @param username HTTP authorization user name
 *  @param password HTTP authorization password
 */
- (void)continueWithUsername:(NSString *)username password:(NSString *)password;

/** Cancel HTTP authorization and fail request with authorization error */
- (void)cancelAuthorization;
@end





/** RDHTTPSSLServerTrust */
@interface RDHTTPSSLServerTrust : RDHTTPChallangeDecision

/** Returns HTTP server hostname for this decision. */
@property(nonatomic, readonly) NSString *host;

/** Continue to process HTTP request trusting to SSL server specified in <host> property.
 */
- (void)trust;
/** Stop processing HTTP request without trust to SSL server specified in <host> property.
 */
- (void)dontTrust;
@end






/** RDHTTPOperation. This is <NSOperation> subclass that is actually responsible for HTTP request completion. */
@interface RDHTTPOperation : NSOperation
@property (readonly) BOOL isExecuting;
@property (readonly) BOOL isFinished;
@property (readonly) BOOL isCancelled;
@end





/** RDHTTPFormPost is an object that is returned by <RDHTTPRequest> <formPost> method. Use it to set POST form string values 
 *  and/or transmit files using _multipart/form-data_.
 */
@interface RDHTTPFormPost : NSObject<NSCopying> 

/** Adds string key-value pair to POST form. 
 *  The data would be encoded as __x-www-form-urlencoded__ if <setFile:forKey:> was not called or as __multipart/form-data__ otherwise.
 *  @param value The value for POST form field identified by _key_.
 *  @param key The name of one of the POST form fields 
 */
- (void)setPostValue:(NSString *)value forKey:(NSString *)key;

/** Adds file-based key-value pair for POST form. POST request would be encoded as __multipart/form-data__ 
 *  @param fileURL The path to file containing data for POST form field identified by _key_.
 *  @param key The name of one of the POST form fields. 
 */
- (void)setFile:(NSURL *)fileURL forKey:(NSString *)key;

/** Utility method that add percents escapes to a string 
 *  @param url Source string that would be part of URL later. All characters that need percent escape encoding would be escaped. 
 */
+ (NSString *)stringByAddingPercentEscapesToString:(NSString *)url;

/** Utility method for getting content-type string based on a file type. 
 *  @param filePath NSURL object that represents local file URL. Only URL path extension would be used.  
 *  @param encoding Default encoding that would be specified with some MIME types. 
 */
+ (NSString *)guessContentTypeForURL:(NSURL *)filePath defaultEncoding:(NSStringEncoding)encoding;
@end



/** RDHTTPThread is a basic runloop-enabled NSThread that will work for HTTP request processing.
 * 
 *  You may need to use this object in case your iOS application delegate conforms to <RDHTTPThreadProviderAppDelegate> protocol. 
 */
@interface RDHTTPThread : NSThread {
}

/** Returns default instance of RDHTTPThread */ 
+ (RDHTTPThread *)defaultThread;
@end



/** The RDHTTPThreadProviderAppDelegate protocol declares methods that may be implemented
 *  by the application delegate on the iOS.
 */
@protocol RDHTTPThreadProviderAppDelegate <NSObject>

/** Returns <NSThread> object that will be used for HTTP request processing. 
 * This <NSThread> should have working runloop, like <RDHTTPThread> provides. 
 *
 * You may provide your own runloop-enabled NSThread here.
 * 
 * Another reason for implementnig this method is using of several 
 * renamed RDHTTP classes that differs by prefix. 
 *
 * This object is expected to live until app termination.
 */
- (NSThread *)rdhttpThread;
@end
