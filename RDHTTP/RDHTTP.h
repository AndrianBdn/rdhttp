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

// ------------- RDHTTP Error Domain: 
extern NSString *const RDHTTPResponseCodeErrorDomain;

@class RDHTTPFormPost;
@class RDHTTPConnection;
@class RDHTTPResponse;
@class RDHTTPAuthorizer;
@class RDHTTPSSLServerTrust;

// ------------- BLOCKS: regular response (errors inside RDHTTPResponse)
typedef void (^rdhttp_block_t)(RDHTTPResponse *response);
//                       progress response 
typedef void (^rdhttp_header_block_t)(RDHTTPResponse *response, RDHTTPConnection *connection);
//
typedef void (^rdhttp_progress_block_t)(float progress, BOOL upload);
//
typedef void (^rdhttp_trustssl_block_t)(RDHTTPSSLServerTrust *sslTrustResponse);
//
typedef void (^rdhttp_httpauth_block_t)(RDHTTPAuthorizer *httpAuthorizeResponse);
//



// ------------- RDHTTPRequest 

@interface RDHTTPRequest : NSObject

@property(nonatomic, retain) NSDictionary       *userInfo;
@property(nonatomic, retain) RDHTTPFormPost     *formPost;
@property(nonatomic, assign) dispatch_queue_t   dispatchQueue;
@property(nonatomic, assign) BOOL               saveResponseToFile;
@property(nonatomic, assign) NSStringEncoding   encoding;

@property(nonatomic, copy)  rdhttp_httpauth_block_t HTTPAuthHandler;
@property(nonatomic, copy)  rdhttp_trustssl_block_t SSLCertificateTrustHandler;
@property(nonatomic, copy)  rdhttp_header_block_t   headersHandler;
@property(nonatomic, copy)  rdhttp_progress_block_t progressHandler;

- (void)setHTTPAuthHandler:(rdhttp_httpauth_block_t)HTTPAuthHandler;
- (void)setSSLCertificateTrustHandler:(rdhttp_trustssl_block_t)SSLCertificateTrustHandler;
- (void)setHeadersHandler:(rdhttp_header_block_t)headersHandler;
- (void)setProgressHandler:(rdhttp_progress_block_t)progressHandler;

+ (id)getRequestWithURL:(NSObject *)url;
+ (id)postRequestWithURL:(NSObject *)url;
+ (id)customRequest:(NSString *)method withURL:(NSObject *)url;

- (void)addValue:(NSString *)value forHTTPHeaderField:(NSString *)field;

- (void)setHTTPBodyData:(NSData *)data;
- (void)setHTTPBodyStream:(NSInputStream *)inputStream;
- (void)setHTTPBodyFilePath:(NSString *)filePath;

- (RDHTTPConnection *)startWithCompletionHandler:(rdhttp_block_t)aCompletionBlock;

@end






// -------------  RDHTTPResponse
@interface RDHTTPResponse : NSObject
- (NSString *)valueForHTTPHeaderField:(NSString *)field;
@property(nonatomic, readonly) NSDictionary *userInfo;
@property(nonatomic, readonly) NSError  *httpError;
@property(nonatomic, readonly) NSError  *networkError;
@property(nonatomic, readonly) NSError  *error;
@property(nonatomic, readonly) NSString *responseText;
@property(nonatomic, readonly) NSData   *responseData;
@end



// ------------- base class for RDHTTPAuth and RDHTTPSSLServerTrust
@interface RDHTTPChallangeDecision : NSObject
@end


// ------------- RDHTTPAuth
@interface RDHTTPAuthorizer : RDHTTPChallangeDecision
- (void)continueWithUsername:(NSString *)username password:(NSString *)password;
- (void)cancelAuthorization;
@end


// ------------- RDHTTPSSLServerTrust
@interface RDHTTPSSLServerTrust : RDHTTPChallangeDecision
- (void)trust;
- (void)dontTrust;
@end



// ------------- RDHTTPConnection 
@interface RDHTTPConnection : NSObject
@property(nonatomic, readonly)  BOOL    completed;
- (void)cancel;
@end




// ------------- RDHTTPFormPost 
@interface RDHTTPFormPost : NSObject<NSCopying> 
- (void)setPostValue:(NSString *)value forKey:(NSString *)key;
- (void)setFile:(NSURL *)fileURL forKey:(NSString *)key;
+ (NSString *)stringByAddingPercentEscapesToString:(NSString *)url;
+ (NSString *)guessContentTypeForURL:(NSURL *)filePath defaultEncoding:(NSStringEncoding)encoding;
@end

