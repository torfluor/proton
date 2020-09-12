//
//  TextStorage.swift
//  Proton
//
//  Created by Robert Chatfield on 13/9/20.
//  Copyright © 2020 Rajdeep Kwatra. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#import "EditorContentName.h"

@implementation EditorContentName

- (instancetype)initWithRawValue:(NSString *)rawValue {
    self = [super init];
    if (self) {
        _rawValue = rawValue;
    }
    return self;
}

+ (EditorContentName *)paragraphName { return [[EditorContentName alloc] initWithRawValue:@"_paragraph"]; }
+ (EditorContentName *)viewOnlyName { return [[EditorContentName alloc] initWithRawValue:@"_viewOnly"]; }
+ (EditorContentName *)newlineName { return [[EditorContentName alloc] initWithRawValue:@"_newline"]; }
+ (EditorContentName *)textName { return [[EditorContentName alloc] initWithRawValue:@"_text"]; }
+ (EditorContentName *)unknownName { return [[EditorContentName alloc] initWithRawValue:@"_unknown"]; }

@end
