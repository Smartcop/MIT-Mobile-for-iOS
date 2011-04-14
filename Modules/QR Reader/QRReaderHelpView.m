//
//  QRReaderHelpView.m
//  MIT Mobile
//
//  Created by Blake Skinner on 4/13/11.
//  Copyright 2011 MIT. All rights reserved.
//

#import "QRReaderHelpView.h"

@interface QRReaderHelpView ()
@property (nonatomic,retain) UIWebView *helpView;
@end

@implementation QRReaderHelpView
@synthesize helpView = _helpView;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        NSString *path = [[NSBundle mainBundle] pathForResource:@"qr-reader-help"
                                                         ofType:@"html"
                                                    inDirectory:@"qrreader"];
        self.helpView = [[UIWebView alloc] initWithFrame:self.bounds];
        [self.helpView loadHTMLString:[[[NSString alloc] initWithContentsOfFile:path
                                                                       encoding:NSUTF8StringEncoding
                                                                          error:NULL] autorelease]
                              baseURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] bundlePath]]];
        self.helpView.backgroundColor = [UIColor clearColor];
        self.helpView.opaque = NO;
        
        UIImageView *background = [[[UIImageView alloc] initWithFrame:frame] autorelease];
        background.image = [UIImage imageNamed:@"global/body-background"];
        [self addSubview:background];
        [self addSubview:self.helpView];
        self.userInteractionEnabled = NO;
    }
    return self;
}


- (void)dealloc
{
    self.helpView = nil;
    [super dealloc];
}

@end
