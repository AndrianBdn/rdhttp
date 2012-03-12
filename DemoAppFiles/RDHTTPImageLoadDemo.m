//
//  RDHTTPImageLoadDemo.m
//  RDHTTP
//
//  Created by Andrian Budantsov on 09.01.12.
//  Copyright (c) 2012 Readdle. All rights reserved.
//

#import "RDHTTPImageLoadDemo.h"
#import "RDHTTP.h"

static NSString *const ImageLoadDemoURL = @"http://www.pictures-of-cats.org/images/large-maine-coon-cat-1s.jpg";

@interface RDHTTPImageLoadDemo() {
@private
    UILabel *label;
    UIImageView *imageView;
    RDHTTPOperation *operation;
    UIImage *image;
}
- (void)updateImage;
@end

@implementation RDHTTPImageLoadDemo

- (void)dealloc {
    [operation release];
    [image release];
    [super dealloc];
}


#pragma mark - View lifecycle


// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView
{
    [super loadView];
    self.title = @"Simple Image Load";
    
    label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 30)];
    label.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [self.view addSubview:label];
    [label release];
    label.text = [NSString stringWithFormat:@"Loading %@...", ImageLoadDemoURL];
    
    imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 30, 100, 100)];
    [self.view addSubview:imageView];
    [imageView release];
    
}

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self updateImage];

    if (operation) return;
    
    RDHTTPRequest *request = [RDHTTPRequest getRequestWithURLString:ImageLoadDemoURL];
    [request setDownloadProgressHandler:^(float progress) {
        NSString *progressString = [NSString stringWithFormat:@"%@ %f", ImageLoadDemoURL, progress];
        label.text = progressString;
        NSLog(@"%@", progressString);
        
    }];
    
    operation = [request startWithCompletionHandler:^(RDHTTPResponse *response) {
        if (response.error == nil) {
            label.text = @"done downloading";
            image = [[UIImage imageWithData:response.responseData] retain];
            if (image == nil)
                label.text = @"unable to create image from response";
            
            [self updateImage];
        }
        else {
            label.text = [response.error description];
        }
    }];
    
    [operation retain];
}

- (void)viewWillDisappear:(BOOL)animated {
    [operation cancel];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    label = nil;
    imageView = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
	return YES;
}

- (void)updateImage {
    if (image) {
        imageView.image = image;
        imageView.frame = CGRectMake(0, 30, image.size.width, image.size.height);
    }
}




@end
