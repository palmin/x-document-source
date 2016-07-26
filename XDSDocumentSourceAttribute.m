//
//  XDSDocumentSourceAttribute.m
//  Textastic & Working Copy
//
//  Created by Alexander Blach & Anders Borum in June & July 2016
//

#import "XDSDocumentSourceAttribute.h"

#include <sys/xattr.h>

#if !__has_feature(objc_arc)
#error This file must be compiled with ARC enabled.
#endif


static NSString *const XDSDocumentSourceAttributeName = @"x-document-source";

@implementation XDSDocumentSourceAttribute

- (instancetype)initWithBundleIdentifier:(NSString *)bundleIdentifier
                         applicationName:(NSString *)applicationName
                            documentPath:(NSString *)documentPath
                              appInfoURL:(NSURL *)appInfoURL {
    if (self = [super init]) {
        self.bundleIdentifier = bundleIdentifier;
        self.applicationName = applicationName;
        self.documentPath = documentPath;
        self.appInfoURL = appInfoURL;
    }
    return self;
}

+ (instancetype)documentSourceAttributeWithBundleIdentifier:(NSString *)bundleIdentifier
                                            applicationName:(NSString *)applicationName
                                               documentPath:(NSString *)documentPath
                                                 appInfoURL:(NSURL *)appInfoURL {
    return [[self alloc] initWithBundleIdentifier:bundleIdentifier
                                  applicationName:applicationName
                                     documentPath:documentPath
                                       appInfoURL:appInfoURL];
}

+ (instancetype)readDocumentSourceAttributeAtURL:(NSURL *)fileURL {
    if (![fileURL isFileURL]) {
        // we need a file path for getxattr
        return nil;
    }

    const char *attributeName = [XDSDocumentSourceAttributeName UTF8String];
    const char *path = [[fileURL path] fileSystemRepresentation];

    // try to read the "x-document-source" extended attribute
    // get length of attribute data
    ssize_t size = getxattr(path, attributeName, NULL, 0, 0, 0);
    if (size == -1) {
        return nil;
    }

    // get attribute data
    NSMutableData *data = [NSMutableData dataWithLength:size];
    ssize_t size2 = getxattr(path, attributeName, [data mutableBytes], size, 0, 0);

    XDSDocumentSourceAttribute *attribute = nil;
    if (size2 == size) {
        NSDictionary *dict = [NSPropertyListSerialization propertyListWithData:data
                                                                       options:NSPropertyListImmutable
                                                                        format:nil
                                                                         error:nil];

        if (dict != nil && [dict isKindOfClass:[NSDictionary class]]) {
            attribute = [[XDSDocumentSourceAttribute alloc] init];

            Class stringClass = [NSString class];

            id identifier = [dict objectForKey:@"identifier"];
            if ([identifier isKindOfClass:stringClass]) {
                attribute.bundleIdentifier = identifier;
            }
            id name = [dict objectForKey:@"name"];
            if ([name isKindOfClass:stringClass]) {
                attribute.applicationName = name;
            }
            id path = [dict objectForKey:@"path"];
            if ([path isKindOfClass:stringClass]) {
                attribute.documentPath = path;
            }
            id appInfoURL = [dict objectForKey:@"appInfoURL"];
            if ([appInfoURL isKindOfClass:stringClass]) {
                attribute.appInfoURL = [NSURL URLWithString:appInfoURL];
            }
        }
    }

    return attribute;
}

// Takes a square application icon and applies the superellipse rounded rect.
// Also strokes the path to match the look of the icon in the document picker document provider list.
- (UIImage *)roundedImage:(UIImage *)image withSize:(CGSize)size scale:(CGFloat)scale {
    CGFloat cornerRadius = round(0.225 * size.width);
    CGRect rect = CGRectMake(0, 0, size.width, size.height);
    UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:rect cornerRadius:cornerRadius];

    UIImage *resultImage;

    UIGraphicsBeginImageContextWithOptions(size, NO, scale);
    {
        [path addClip];
        [image drawInRect:rect];

        [[UIColor colorWithWhite:0.0f alpha:0.1f] setStroke];
        [path stroke];
        resultImage = UIGraphicsGetImageFromCurrentImageContext();
    }
    UIGraphicsEndImageContext();

    return resultImage;
}

- (void)loadIcon:(XDSDocumentSourceAttributeIconType)iconType
    withCompletionHandler:(void (^)(UIImage *icon, NSError *error))completionHandler {
    NSURL *url = self.appInfoURL;

    if (url) {
        // try to load json
        NSURLSessionDataTask *task = [[NSURLSession sharedSession]
              dataTaskWithURL:url
            completionHandler:^(NSData *_Nullable data, NSURLResponse *_Nullable response, NSError *_Nullable error) {
                if (!error) {
                    NSError *jsonError = nil;

                    NSDictionary *dictionary = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
                    if (jsonError) {
                        completionHandler(nil, jsonError);
                    } else {
                        id object = dictionary[@"icons"];
                        if ([object isKindOfClass:[NSArray class]]) {
                            NSUInteger preferredWidth;
                            NSUInteger preferredHeight;
                            CGFloat scale = [UIScreen mainScreen].scale;

                            switch (iconType) {
                            case XDSDocumentSourceAttributeIconTypeSpotlight:
                            default:
                                preferredWidth = preferredHeight = 29;
                                break;
                            }

                            BOOL foundExactMatch = NO;
                            NSString *foundSrc = nil;
                            NSInteger foundHeight = NSIntegerMax;
                            NSInteger foundWidth = NSIntegerMax;

                            for (NSDictionary *dict in object) {
                                if ([dict isKindOfClass:[NSDictionary class]]) {
                                    NSNumber *width = dict[@"width"];
                                    NSNumber *height = dict[@"height"];
                                    NSString *src = dict[@"src"];

                                    if (width && height && src) {
                                        NSInteger w = [width integerValue];
                                        NSInteger h = [height integerValue];

                                        if (w == preferredWidth * scale && h == preferredHeight * scale) {
                                            // found exact match -> perfect!
                                            foundExactMatch = YES;
                                            foundSrc = src;
                                            foundWidth = w;
                                            foundHeight = h;
                                            break;
                                        } else if (w > preferredWidth * scale && h > preferredHeight * scale
                                            && w < foundWidth && h < foundWidth) {
                                            // found an icon that is larger than our preferred size but smaller than
                                            // our previously found icon
                                            foundSrc = src;
                                            foundWidth = w;
                                            foundHeight = h;
                                        }
                                    }
                                }
                            }
                            if (foundSrc) {
                                NSURL *imageURL = [[NSURL alloc] initWithString:foundSrc relativeToURL:url];
                                if (imageURL) {
                                    // load icon
                                    NSURLSessionDataTask *imageTask = [[NSURLSession sharedSession]
                                          dataTaskWithURL:imageURL
                                        completionHandler:^(NSData *_Nullable data, NSURLResponse *_Nullable response,
                                            NSError *_Nullable error) {
                                            if (error || [data length] == 0) {
                                                completionHandler(nil, error);
                                            } else {
                                                UIImage *image = [UIImage imageWithData:data];
                                                if (!image) {
                                                    // could not load image
                                                    completionHandler(nil, nil);
                                                } else {
                                                    image =
                                                        [self roundedImage:image
                                                                  withSize:CGSizeMake(preferredWidth, preferredHeight)
                                                                     scale:scale];
                                                    // finally we have our image!
                                                    completionHandler(image, nil);
                                                }
                                            }
                                        }];
                                    [imageTask resume];
                                } else {
                                    // could not parse relative url string
                                    completionHandler(nil, nil);
                                }
                            } else {
                                // no matching icon found
                                completionHandler(nil, nil);
                            }
                        } else {
                            // no "icon" key in appInfo.json file
                            completionHandler(nil, nil);
                        }
                    }
                } else {
                    // error parsing json file
                    completionHandler(nil, error);
                }
            }];
        [task resume];
    } else {
        // no "appInfoURL" key found
        completionHandler(nil, nil);
    }
}

- (BOOL)writeToURL:(NSURL *)fileURL {
    if (![fileURL isFileURL]) {
        // we need a file path for setxattr
        return NO;
    }

    NSDictionary *plist = @{
        @"identifier": self.bundleIdentifier,
        @"name": self.applicationName,
        @"path": self.documentPath,
        @"appInfoURL": self.appInfoURL.absoluteString
    };

    NSData *data = [NSPropertyListSerialization dataWithPropertyList:plist
                                                              format:NSPropertyListBinaryFormat_v1_0
                                                             options:0
                                                               error:NULL];

    const char *filePath = [fileURL.path fileSystemRepresentation];
    return setxattr(filePath, XDSDocumentSourceAttributeName.UTF8String, data.bytes, data.length, 0, 0) == 0;
}

@end
