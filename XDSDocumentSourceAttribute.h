//
//  XDSDocumentSourceAttribute.h
//  Textastic & Working Copy
//
//  Created by Alexander Blach & Anders Borum June & July 2016
//
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, XDSDocumentSourceAttributeIconType) {
    // 29x29 icon used for spotlight and settings
    AABDocumentSourceAttributeIconTypeSpotlight
};

@interface XDSDocumentSourceAttribute : NSObject

// Bundle identifier of the app: "com.appliedphasor.working-copy"
@property (nonatomic, copy) NSString *bundleIdentifier;
// Application name: "Working Copy"
@property (nonatomic, copy) NSString *applicationName;
// Path of the document in the source app: "libgit2/doc/README.md"
@property (nonatomic, copy) NSString *documentPath;
// URL pointing to a JSON file that countains icon urls and sizes:
// "http://workingcopyapp.com/icons.json"
@property (nonatomic, copy) NSURL *appInfoURL;

// tries to read the x-document-source extended attribute and returns
// an AABDocumentSourceAttribute instance on success
+ (instancetype)documentSourceAttributeWithURL:(NSURL * _Nonnull)url;

// write x-document-source extended attribute with contents of this
// XDSDocumentSourceAttribute returning whether this succeeded.
-(BOOL)writeToURL:(NSURL * _Nonnull)fileURL;

// load a matching icon using the JSON file pointed to by appInfoURL
// the completion handler might not be invoked on the calling queue
- (void)loadIcon:(XDSDocumentSourceAttributeIconType) iconType
    withCompletionHandler:(void (^)(UIImage *icon, NSError *error))completionHandler;


@end
