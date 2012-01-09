//
//  RDHTTPDemoRoot.m
//  RDHTTP
//
//  Created by Andrian Budantsov on 09.01.12.
//  Copyright (c) 2012 Readdle. All rights reserved.
//

#import "RDHTTPDemoRoot.h"
#import "RDHTTPImageLoadDemo.h"

@interface RDHTTPDemoRoot() {
@private
    NSArray *rows;
}
@end

@implementation RDHTTPDemoRoot

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        self.title = @"RDHTTP Demos";
        
        NSMutableArray *mutableRows = [NSMutableArray array];
        
        [mutableRows addObject:@"Load UIImage"];
        [mutableRows addObject:[NSValue valueWithPointer:@selector(uiImageLoad)]];

        rows = [[NSArray arrayWithArray:mutableRows] retain];
    }
    return self;
}

- (void)dealloc {
    [rows release];
    [super dealloc];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [rows count] / 2;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    }
    
    cell.textLabel.text = [rows objectAtIndex:indexPath.row * 2];
    return cell;
}
#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    SEL sel = (SEL)[(NSValue *)[rows objectAtIndex:indexPath.row * 2 + 1] pointerValue];
    [self performSelector:sel];
}

         
#pragma mark - demo methods
         
- (void)uiImageLoad {
    RDHTTPImageLoadDemo *demo = [RDHTTPImageLoadDemo new];
    [self.navigationController pushViewController:demo animated:YES];
    [demo release];
        
}

         
@end
