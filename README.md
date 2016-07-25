# x-document-source

The iCloud document picker introduced in iOS 8 lets applications access files outside its own sandbox, where these external files are made available by file provider and document picker extensions bundles with other applications. 

The app accessing external files has no immediate way to know which app provides these files. We describe a way to share such information with extended file attributes in a way that has minimal consequences for apps unaware of this mechanism. 

