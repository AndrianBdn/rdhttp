//
//  RDHTTP.h
//  GetAdhoc
//
//  Created by Andrian Budantsov on 27.10.11.
//  Copyright (c) 2011 Readdle. All rights reserved.
//

#import <Foundation/Foundation.h>

// ------------- RDHTTP Error Domain: 
extern NSString *const RDHTTPResponseCodeErrorDomain;

@class RDHTTPFormPost;
@class RDHTTPConnection;
@class RDHTTPResponse;


// ------------- BLOCKS: regular response (errors inside RDHTTPResponse)
typedef void (^rdhttp_block_t)(RDHTTPResponse *response);
//                       progress response 
typedef void (^rdhttp_progress_block_t)(float progress, BOOL upload);
//
typedef void (^rdhttp_trustssl_result_block_t)(BOOL shouldConnect);
// 
typedef void (^rdhttp_trustssl_block_t)(NSURL *url, rdhttp_trustssl_result_block_t trustssl_result);
//
typedef void (^rdhttp_httpauth_result_block_t)(NSString *username, NSString *password, NSString *domain);
// 
typedef void (^rdhttp_httpauth_block_t)(rdhttp_httpauth_result_block_t auth_result);
//



// ------------- RDHTTPRequest 

@interface RDHTTPRequest : NSObject
@property(nonatomic, retain) NSDictionary       *userInfo;
@property(nonatomic, retain) RDHTTPFormPost     *formPost;
@property(nonatomic, assign) dispatch_queue_t   dispatchQueue;
@property(nonatomic, assign) BOOL               saveResponseToFile;

@property(nonatomic, copy)  rdhttp_httpauth_block_t HTTPAuthHandler;
@property(nonatomic, copy)  rdhttp_trustssl_block_t SSLCertificateTrustHandler;

+ (id)getRequestWithURL:(NSObject *)url;
+ (id)postRequestWithURL:(NSObject *)url;
+ (id)customRequest:(NSString *)method withURL:(NSObject *)url;

- (void)addValue:(NSString *)value forHTTPHeaderField:(NSString *)field;

- (void)setHTTPBodyData:(NSData *)data;
- (void)setHTTPBodyStream:(NSInputStream *)inputStream;
- (void)setHTTPBodyFilePath:(NSString *)filePath;

- (RDHTTPConnection *)startWithCompletionHandler:(rdhttp_block_t)aCompletionBlock;

- (RDHTTPConnection *)startWithCompletionHandler:(rdhttp_block_t)aCompletionBlock
                                 progressHandler:(rdhttp_progress_block_t)aProgressBlock;

- (RDHTTPConnection *)startWithCompletionHandler:(rdhttp_block_t)aCompletionBlock
                                 progressHandler:(rdhttp_progress_block_t)aProgressBlock
                                  headersHandler:(rdhttp_block_t)aHeadersBlock;

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



// ------------- RDHTTPConnection 
@interface RDHTTPConnection : NSObject
@property(nonatomic, readonly)  BOOL    completed;
@end


// ------------- RDHTTPFormPost 
@interface RDHTTPFormPost : NSObject<NSCopying> 
- (void)setPostValue:(NSString *)value forKey:(NSString *)key;
- (void)setFile:(NSString *)filePath forKey:(NSString *)key;
+ (NSString *)stringByAddingPercentEscapesToString:(NSString *)url;
@end

