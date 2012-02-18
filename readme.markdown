# RDHTTP 
RDHTTP is HTTP client library for iOS. It is based on Apple's NSURLConnection but much easier to use and 
ready for real world tasks. 

The library was designed as a simple, self-contained solution (just RDHTTP.h and RDHTTP.m). 
It is reasonably low-level and does not contain any features unrelated to HTTP (JSON, XML, SOAP, ...).

## TODO 
Currently the library is in development. Following tasks are active: 

* More unit tests 
* Actual usage examples
* <del>Tested and good 'cancel' method</del>
* <del>RFC 2616 redirect behaviour</del>
* <del>Generating basic authorizaion header</del>
* <del>better GCD / threading options</del>
* <del>NSOperation methods</del>
* <del>Submit any binary to App Store (private API test)</del>
* Use library in production code for 100000+ users
* Documentation

usage: php namespace.php PREFIX

	PREFIX would be added to all RDHTTP classes / global vars / types,
	to emulate namespaces in Objective-C.

	Usually two or three-letter prefixes are sufficient.
	Prefixes are always capitalized.

	PREFIXRDHTTP.h and PREFIXRDHTTP.m would be generated in scripts directory.
## Features

* Blocks-oriented API
* Easy access to HTTP request / response fields 
* HTTP errors detection
* Downloading data to memory or file 
* HTTP POST for key-value data (urlencoded)
* HTTP POST for files (multipart)
* Setting request body to data / file (HTTP PUT, PROPFIND, ...)
* All kinds of HTTP authorization (Basic, Digest, ...)
* Trust-callback for self-signed SSL certificates


## Requirements 

* iOS4+
* possibly OS X


## Installation 

1. Copy RDHTTP.h and RDHTTP.m from RDHTTP directory to your Xcode project. 
2. Add MobileCoreServices.framework


## Obj-C Namespaces 

namespace.php script is included with library. You may use it to produce prefixed versions of the library:

```
usage: php namespace.php PREFIX

PREFIX would be added to all RDHTTP classes / global vars / types,
to emulate namespaces in Objective-C.

Usually two or three-letter prefixes are sufficient.
Prefixes are always capitalized.

PREFIXRDHTTP.h and PREFIXRDHTTP.m would be generated in scripts directory.
```


## Usage Example

Simple HTTP GET:

```objective-c
RDHTTPRequest *request = [RDHTTPRequest getRequestWithURL:@"http://osric.readdle.com/tests/ok.html"];
[request startWithCompletionHandler:^(RDHTTPResponse *response) {
    if (response.error)
        NSLog(@"error: %@", response.error) 
    else
		NSLog(@"response text: %@", response.responseString);
}];
```

Form-data compatible HTTP POST:

```objective-c
RDHTTPRequest *request = [RDHTTPRequest postRequestWithURL:@"http://osric.readdle.com/tests/post-values.php"];

[[request formPost] setPostValue:@"value" forKey:@"fieldName"];
[[request formPost] setPostValue:@"anotherValue" forKey:@"anotherField"];

[request startWithCompletionHandler:^(RDHTTPResponse *response) {
    if (response.error)
        NSLog(@"error: %@", response.error) 
    else
		NSLog(@"response text: %@", response.responseString);
        
}];
```

Saving file: 

```objective-c
RDHTTPRequest *request = [RDHTTPRequest getRequestWithURL:@"http://www.ubuntu.com/start-download?distro=desktop&bits=32&release=latest"];

request.shouldSaveResponseToFile = YES;

RDHTTPOperation *operation = [request startWithCompletionHandler:^(RDHTTPResponse *response) {

    if (response.error) {
        NSLog(@"error: %@", response.error);
        return;
    }
        
    NSURL *dest = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory
                                                          inDomains:NSUserDomainMask] objectAtIndex:0];
    
    dest = [dest URLByAppendingPathComponent:@"latest-ubuntu.iso"];
    
    [response moveResponseFileToURL:dest
        withIntermediateDirectories:NO 
                              error:nil];
    
    NSLog(@"saved file to latest-ubuntu.iso");
    
}];
```

