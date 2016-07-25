# x-document-source

The iOS [document picker](https://developer.apple.com/library/ios/documentation/FileManagement/Conceptual/DocumentPickerProgrammingGuide/Introduction/Introduction.html#//apple_ref/doc/uid/TP40014451-CH1-SW5) lets applications access files outside its own sandbox, where these external files are made available by file provider and document picker extensions bundles with other applications. 

The app accessing external files has no immediate way to know which app provides these files. We describe a way to share such information with [extended file attributes](https://en.m.wikipedia.org/wiki/Extended_file_attributes) in a way that has minimal consequences for apps unaware of this mechanism. 

When files or directories are picked, the app extension should write a extended file attribute named x-document-source containing a binary encoded property list containing

```
 {"name":       "Working Copy",
  "identifier": "com.appliedphasor.working-copy",
  "path":       "directory/filename.ext",
  "appInfoURL": "https://raw.githubusercontent.com/palmin/x-document-source/master/appInfo.json"
  };
```

Image resources can be retrieved by accessing the JSON file pointed to by appInfoURL
This file will itself reference icons at different resolutions and image src can be either fully qualified
or relative to the JSON file itself.

You should serve the files from secure websites to comply with App Transport Security.

```
{"icons":
[{"width": 29, "height": 29, "src": "/img/icon.png"},
 {"width": 58, "height": 58, "src": "/img/icon@2x.png"},
 {"width": 87, "height": 87, "src": "/img/icon@3x.png"},
 {"width": 1024, "height": 1024, "src": "/img/icon-1024.png"}
]}
```

It is the responsibility of the app reading these images to mask the image to the superellipse shape expected for app icons. This repository contains code for this. 
