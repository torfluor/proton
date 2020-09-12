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

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class Attachment; /// Defined in Attachment.swift

// MARK: -

@protocol DefaultTextFormattingProviding;
@protocol TextStorageDelegate;

// MARK: -

@interface RKTextStorage : NSTextStorage

@property (readonly, copy) NSTextStorage *storage;
@property (readonly, copy) NSParagraphStyle *defaultParagraphStyle;
@property (readonly, copy) UIFont *defaultFont;
@property (readonly, copy) UIColor *defaultTextColor;
@property (nullable, weak, NS_NONATOMIC_IOSONLY) id <DefaultTextFormattingProviding> defaultTextFormattingProvider;
@property (nullable, weak, NS_NONATOMIC_IOSONLY) id <TextStorageDelegate> textStorageDelegate;

- (NSRange)textEndRange;
- (void)removeAttributes:(NSArray<NSAttributedStringKey> *)attrs range:(NSRange)range;
- (void) insertAttachmentInRange:(NSRange)range attachment:(Attachment *)attachment;

@end

// MARK: -

@protocol DefaultTextFormattingProviding <NSObject>

- (UIFont *)getFont;
- (NSMutableParagraphStyle *)getParagraphStyle;
- (UIColor *)getTextColor;

@end

// MARK: -

@protocol TextStorageDelegate <NSObject>

- (void)textStorage:(RKTextStorage *)textStorage willDeleteText:(NSAttributedString *)deletedText insertedText:(NSAttributedString *)insertedText range:(NSRange)range;

@end

NS_ASSUME_NONNULL_END
