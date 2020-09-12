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

#import "RKTextStorage.h"
#import "EditorContentName.h"
#import <UIKit/UIKit.h>

@implementation RKTextStorage

- (NSRange)textEndRange {
    return NSMakeRange(self.length, 0);
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _storage = [NSTextStorage init];
        _defaultParagraphStyle = [NSParagraphStyle init];
        _defaultFont = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
        if (@available(iOS 13, *)) {
            _defaultTextColor = [UIColor labelColor];
        } else {
            _defaultTextColor = [UIColor blackColor];
        }
    }
    return self;
}

- (NSString *)string {
    return _storage.string;
}

- (NSDictionary<NSAttributedStringKey,id> *)attributesAtIndex:(NSUInteger)location effectiveRange:(NSRangePointer)range {
    if (!(_storage.length > location)) {
        return [NSDictionary init];
    }
    return [_storage attributesAtIndex:location effectiveRange:range];
}

- (void)replaceCharactersInRange:(NSRange)range withAttributedString:(NSAttributedString *)attrString {
    // TODO: Add undo behavior
    NSMutableAttributedString *replacementString = [attrString mutableCopy];
    // Fix any missing attribute that is in the location being replaced, but not in the text that
    // is coming in.
    if (range.length > 0 && attrString.length > 0) {
        id outgoingAttrs = [_storage attributesAtIndex:(range.location + range.length - 1) effectiveRange:nil];
        id incomingAttrs = [attrString attributesAtIndex:0 effectiveRange:nil];
        // We do not want to fix the underline since it can be added by the input method for
        // characters accepting diacritical marks (eg. in vietnamese or spanish) and should be transient.
        
        NSDictionary<NSAttributedStringKey,id> *diff = [NSDictionary init];
        
        for (id outgoingKey in outgoingAttrs) {
            if ([incomingAttrs containsValueForKey:outgoingKey] && outgoingKey != NSUnderlineStyleAttributeName) {
                [diff setValue:outgoingAttrs[outgoingKey] forKey:outgoingKey];
            }
        }
        
        [replacementString addAttributes:diff range:NSMakeRange(0, replacementString.length)];
    }
    
    id deletedText = [_storage attributedSubstringFromRange:range];
    [_textStorageDelegate textStorage:self willDeleteText: deletedText insertedText: replacementString range: range];
    [super replaceCharactersInRange:range withAttributedString:replacementString];
}

- (void)replaceCharactersInRange:(NSRange)range withString:(NSString *)str {
    [self beginEditing];
    unsigned long delta = str.length - range.length;
    
    SEL removeFromSuperViewSel = NSSelectorFromString(@"removeFromSuperView");
    [_storage enumerateAttribute:@"attachment" // NSAttributedString.Key.attachment
                         inRange:range
                         options:NSAttributedStringEnumerationLongestEffectiveRangeNotRequired
                      usingBlock:^(id  _Nullable value, NSRange range, BOOL * _Nonnull stop) {
        if ([value respondsToSelector:removeFromSuperViewSel]) {
            // TODO: FIX: "PerformSelector may cause a leak because its selector is unknown"
            [value performSelector:removeFromSuperViewSel];
        }
    }];
    
    [_storage replaceCharactersInRange:range withString:str];
    [_storage fixAttributesInRange:NSMakeRange(0, _storage.length)];
    [self edited:NSTextStorageEditedAttributes & NSTextStorageEditedCharacters range:range changeInLength:delta];
    
    [self endEditing];
}

- (void)setAttributes:(NSDictionary<NSAttributedStringKey,id> *)attrs range:(NSRange)range {
    [self beginEditing];
    
    id updatedAttributes = [self applyingDefaultFormattingIfRequiredtoAttributes:attrs];
    [_storage setAttributes:updatedAttributes range:range];
    
    NSRange newlineRange = [_storage.string rangeOfCharacterFromSet:[NSCharacterSet newlineCharacterSet]];
    while(newlineRange .location != NSNotFound) {
        [_storage addAttribute:@"blockContentType" value:[EditorContentName newlineName] range:range];
        newlineRange = [_storage.string rangeOfCharacterFromSet:[NSCharacterSet newlineCharacterSet]
                                                        options:0
                                                          range:NSMakeRange(newlineRange.location + newlineRange.length, _storage.length)];
    }
    
    [_storage fixAttributesInRange:NSMakeRange(0, _storage.length)];
    [self edited:NSTextStorageEditedAttributes range:range changeInLength:0];
    [self endEditing];
}

- (NSDictionary<NSAttributedStringKey,id> *)applyingDefaultFormattingIfRequiredtoAttributes:(NSDictionary<NSAttributedStringKey,id> *)attributes {
    NSMutableDictionary<NSAttributedStringKey,id> * updatedAttributes = attributes.mutableCopy;
    if (!updatedAttributes) {
        updatedAttributes = [NSMutableDictionary init];
    }
    
    if (![attributes objectForKey:NSParagraphStyleAttributeName]) {
        id value = [_defaultTextFormattingProvider getParagraphStyle];
        if (!value) {
            value = _defaultParagraphStyle;
        }
        [updatedAttributes setValue:value forKey:NSParagraphStyleAttributeName];
    }

    if (![attributes objectForKey:NSFontAttributeName]) {
        id value = [_defaultTextFormattingProvider getFont];
        if (!value) {
            value = [self defaultFont];
        }
        [updatedAttributes setValue:value forKey:NSFontAttributeName];
    }

    if (![attributes objectForKey:NSForegroundColorAttributeName]) {
        id value = [_defaultTextFormattingProvider getTextColor];
        if (!value) {
            value = [self defaultTextColor];
        }
        [updatedAttributes setValue:value forKey:NSForegroundColorAttributeName];
    }

    return updatedAttributes;
}

- (void)addAttributes:(NSDictionary<NSAttributedStringKey,id> *)attrs range:(NSRange)range {
    [self beginEditing];
    [_storage addAttributes:attrs range:range];
    [_storage fixAttributesInRange:NSMakeRange(0, _storage.length)];
    [self edited:NSTextStorageEditedAttributes range:range changeInLength:0];
    [self endEditing];
}

- (void)removeAttributes:(NSArray<NSAttributedStringKey> *)attrs range:(NSRange)range {
    [self beginEditing];
    for (id attr in attrs) {
        [_storage removeAttribute:attr range:range];
    }
    [self fixMissingAttributesForDeletedAttributes: attrs range: range];
    [_storage fixAttributesInRange:NSMakeRange(0, _storage.length)];
    [self edited:NSTextStorageEditedAttributes range:range changeInLength:0];
    [self endEditing];

}

- (void)fixMissingAttributesForDeletedAttributes:(NSArray<NSAttributedStringKey> *)attrs range:(NSRange)range {
    if ([attrs containsObject:NSForegroundColorAttributeName]) {
        [_storage addAttribute:NSForegroundColorAttributeName value:[self defaultTextColor] range:range];
    }
    
    if ([attrs containsObject:NSParagraphStyleAttributeName]) {
        [_storage addAttribute:NSParagraphStyleAttributeName value:[self defaultParagraphStyle] range:range];
    }
    
    if ([attrs containsObject:NSFontAttributeName]) {
        [_storage addAttribute:NSFontAttributeName value:[self defaultFont] range:range];
    }
}

- (void)removeAttribute:(NSAttributedStringKey)name range:(NSRange)range {
    [_storage removeAttribute:name range:range];
}

- (void) insertAttachmentInRange:(NSRange)range attachment:(Attachment *)attachment {
    
    // TODO: Expose `Attachment` API from Swift
    
//    let spacer = attachment.spacer.string
    id spacer = [[NSAttributedString alloc] initWithString: @"todo"]; // attachment.spacer.string
    bool hasPrevSpacer = false;
    if (range.length + range.location > 0) {
        hasPrevSpacer = [self attributedSubstringFromRange: NSMakeRange(MAX(range.location - 1, 0), 1)].string == spacer;
    }
    bool hasNextSpacer = false;
    if ((range.location + range.length + 1) <= self.length) {
        hasNextSpacer = [self attributedSubstringFromRange: NSMakeRange(range.location, 1)].string == spacer;
    }
    
//    let attachmentString = attachment.stringWithSpacers(appendPrev: !hasPrevSpacer, appendNext: !hasNextSpacer)
    NSAttributedString *attachmentString = [NSAttributedString init]; //[attachment stringWithSpacers(appendPrev: !hasPrevSpacer, appendNext: !hasNextSpacer)
    [self replaceCharactersInRange:range withAttributedString: attachmentString];
}

@end
