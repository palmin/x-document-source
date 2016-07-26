//
//  XDSDocumentSourceAttribute.h
//  Textastic & Working Copy
//
//  Created by Alexander Blach & Anders Borum in June & July 2016
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, XDSDocumentSourceAttributeIconType) {
    // 29x29 icon used for spotlight and settings
    XDSDocumentSourceAttributeIconTypeSpotlight
};


NS_ASSUME_NONNULL_BEGIN

@interface XDSDocumentSourceAttribute : NSObject
// Bundle identifier of the app: e.g. "com.appliedphasor.working-copy"
@property (nonatomic, copy, nullable) NSString *bundleIdentifier;
// Application name: e.g. "Working Copy"
@property (nonatomic, copy, nullable) NSString *applicationName;
// Path of the document in the source app: e.g. "libgit2/doc/README.md"
@property (nonatomic, copy, nullable) NSString *documentPath;
// URL pointing to a JSON file that countains icon urls and sizes:
// "https://workingcopyapp.com/appInfo.json"
@property (nonatomic, copy, nullable) NSURL *appInfoURL;

// Create an instance for writing.
- (instancetype)initWithBundleIdentifier:(NSString *)bundleIdentifier
                         applicationName:(NSString *)applicationName
                            documentPath:(NSString *)documentPath
                              appInfoURL:(NSURL *)appInfoURL;

+ (instancetype)documentSourceAttributeWithBundleIdentifier:(NSString *)bundleIdentifier
                                            applicationName:(NSString *)applicationName
                                               documentPath:(NSString *)documentPath
                                                 appInfoURL:(NSURL *)appInfoURL;

// Tries to read the "x-document-source" extended attribute and returns
// an XDSDocumentSourceAttribute instance on success.
+ (nullable instancetype)readDocumentSourceAttributeAtURL:(NSURL *)fileURL;

// Write x-document-source extended attribute with contents of this
// XDSDocumentSourceAttribute returning whether this succeeded.
- (BOOL)writeToURL:(NSURL *)fileURL;

// Load a matching icon using the JSON file pointed to by appInfoURL.
// The completion handler is most likely not going to be invoked on the calling queue, so you probably
// want to dispatch it to the main queue if you want to update your UI in response to the icon load.
// In order to limit the number of server requests, the icon should be cached between app launches!
- (void)loadIcon:(XDSDocumentSourceAttributeIconType)iconType
    withCompletionHandler:(void (^)(UIImage *icon, NSError *error))completionHandler;

@end

NS_ASSUME_NONNULL_END
