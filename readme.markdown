# RDHTTP 
RDHTTP is HTTP client library for iOS. It is based on Apple's NSURLConnection but much easier to use and 
ready for real world tasks. 

The library was designed as a simple, self-contained solution (just RDHTTP.h and RDHTTP.m). 
It is reasonably low-level and does not contain any features unrelated to HTTP (JSON, XML, SOAP, ...).

## TODO 
Currently the library is in development. Following tasks are active: 

* More unit tests 
* <del>Tested and good 'cancel' method</del>
* <del>RFC 2616 redirect behaviour</del>
* <del>Generating basic authorizaion header</del>
* <del>better GCD / threading options</del>
* <del>NSOperation methods</del>
* Use library in production code for 100000+ users
* Documentation


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

* RDHTTP is targeted for iOS4+
* Most likely it will be compatible with Mac OS X 10.6+


## Usage Example

Simple HTTP GET:

```objective-c
RDHTTPRequest *request = [RDHTTPRequest getRequestWithURL:@"http://osric.readdle.com/tests/ok.html"];
[request startWithCompletionHandler:^(RDHTTPResponse *response) {
    if (response.error == nil) {
		NSLog(@"response text: %@", response.responseText);
    }
    else 
        NSLog(@"error: %@", response.error) 
}];
```

Form-data compatible HTTP POST:

```objective-c
RDHTTPRequest *request = [RDHTTPRequest postRequestWithURL:@"http://osric.readdle.com/tests/post-values.php"];

[[request formPost] setPostValue:@"value" forKey:@"fieldName"];
[[request formPost] setPostValue:@"anotherValue" forKey:@"fieldName"];

[request startWithCompletionHandler:^(RDHTTPResponse *response) {
    if (response.error == nil) {
		NSLog(@"response text: %@", response.responseText);
    }
    else 
        NSLog(@"error: %@", response.error) 
}];
```




