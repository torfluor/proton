//
//  ListTextProcessor.swift
//  Proton
//
//  Created by Rajdeep Kwatra on 28/5/20.
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

import Foundation
import UIKit

public class ListTextProcessor: TextProcessing {
    public let name = "listProcessor"

    // Zero width space - used for laying out the list bullet/number in an empty line.
    // This is required when using tab on a blank bullet line. Without this, layout calculations are not performed.
    private let blankLineFiller = "\u{200B}"

    public init() { }
    public let priority = TextProcessingPriority.medium

    var executeOnDidProcess: ((EditorView)->Void)?

    public func shouldProcess(_ editorView: EditorView, shouldProcessTextIn range: NSRange, replacementText text: String) -> Bool {
        let rangeToCheck = max(0, range.endLocation - 1)
        if editorView.contentLength > 0,
            editorView.attributedText.attribute(.listItem, at: rangeToCheck, effectiveRange: nil) != nil,
        (editorView.attributedText.attribute(.paragraphStyle, at: rangeToCheck, effectiveRange: nil) as? NSParagraphStyle)?.firstLineHeadIndent ?? 0 > 0 {
            if let currentLine = editorView.currentLine {
                if currentLine.startsWith(blankLineFiller), currentLine.text.length > 1 {
                    editorView.replaceCharacters(in: currentLine.range, with: "")
                }
            }
            editorView.typingAttributes[.listItem] = 1
        }
        return true
    }

    public func processInterrupted(editor: EditorView, at range: NSRange) { }

    public func process(editor: EditorView, range editedRange: NSRange, changeInLength delta: Int) -> Processed {
        return false
    }

    public func handleKeyWithModifiers(editor: EditorView, key: EditorKey, modifierFlags: UIKeyModifierFlags, range editedRange: NSRange)  {
        switch key {
        case .tab:
            let indentMode: Indentation  = (modifierFlags == .shift) ? .outdent : .indent
            updateListItemIfRequired(editor: editor, editedRange: editedRange, indentMode: indentMode)
        case .enter:
            exitListsIfRequired(editor: editor, editedRange: editedRange)
        default:
            break
        }
    }

    private func exitListsIfRequired(editor: EditorView, editedRange: NSRange) {
        guard let currentLine = editor.contentLinesInRange(editedRange).first,
            let previousLine = editor.previousContentLine(from: currentLine.range.location) else { return }

        let isInList = previousLine.text.attribute(.listItem, at: 0, effectiveRange: nil) != nil

        if currentLine.text.length == 0, isInList {
            executeOnDidProcess = { [blankLineFiller] editor in
                editor.typingAttributes[.listItem] = nil
                editor.typingAttributes[.paragraphStyle] = editor.paragraphStyle

                let newLineRange = NSRange(location: previousLine.range.endLocation + 1, length: 1)
                let filler = NSAttributedString(string: blankLineFiller, attributes: [.paragraphStyle: editor.paragraphStyle])
                editor.replaceCharacters(in: newLineRange, with: filler)
            }
        }
    }

    public func didProcess(editor: EditorView) {
        executeOnDidProcess?(editor)
        executeOnDidProcess = nil
    }

    private func updateListItemIfRequired(editor: EditorView, editedRange: NSRange, indentMode: Indentation) {
        guard editedRange.length == 0 else {
            // if any content is selected
            editor.attributedText.enumerateAttribute(.paragraphStyle, in: editedRange, options: []) { (value, range, _) in
                if editor.attributedText.attribute(.listItem, at: range.location, effectiveRange: nil) != nil {
                    let paraStyle = value as? NSParagraphStyle
                    let mutableStyle = ListStyles.updatedParagraphStyle(paraStyle: paraStyle, indentMode: indentMode)

                    let prevLine = editor.previousContentLine(from: editedRange.location)

                    let prevParaStyle = prevLine?.text.attribute(.paragraphStyle, at: 0, effectiveRange: nil) as? NSParagraphStyle ?? editor.paragraphStyle

                    guard mutableStyle?.firstLineHeadIndent ?? 0 <= prevParaStyle.firstLineHeadIndent + ListStyles.indentPoints else {
                        return
                    }

                    editor.addAttribute(.paragraphStyle, value: mutableStyle ?? editor.paragraphStyle, at: range)
                }
            }

            let paraStyle = editor.attributedText.attribute(.paragraphStyle, at: editedRange.location, effectiveRange: nil) as? NSParagraphStyle

            // if content has been moved all the way to 0 indent level, remove listItem attribute if present
            if paraStyle?.firstLineHeadIndent == 0,
                editor.attributedText.attribute(.listItem, at: editedRange.location, effectiveRange: nil) != nil {
                var effectiveRange = NSRange()
                let paraStyle = editor.attributedText.attribute(.paragraphStyle, at: editedRange.location, effectiveRange: &effectiveRange) as? NSParagraphStyle
                let mutablePara = (paraStyle ?? editor.paragraphStyle).mutableParagraphStyle
                mutablePara.paragraphSpacingBefore = editor.paragraphStyle.paragraphSpacingBefore
                editor.addAttribute(.paragraphStyle, value: mutablePara, at: editedRange)
                editor.removeAttribute(.listItem, at: editedRange)
            }

            return
        }

        // if current line is empty
        if editor.contentLinesInRange(editedRange).first?.text.length == 0 {
            createListItemInANewLine(editor: editor, editedRange: editedRange, indentMode: indentMode)
        } else if editor.attributedText.attribute(.listItem, at: editedRange.location - 1, effectiveRange: nil) != nil {
            let paraStyle = editor.attributedText.attribute(.paragraphStyle, at: editedRange.location - 1, effectiveRange: nil) as? NSParagraphStyle
            let mutableStyle = ListStyles.updatedParagraphStyle(paraStyle: paraStyle, indentMode: indentMode)

            let prevLine = editor.previousContentLine(from: editedRange.location)

            let prevParaStyle = prevLine?.text.attribute(.paragraphStyle, at: 0, effectiveRange: nil) as? NSParagraphStyle ?? editor.paragraphStyle

            guard mutableStyle?.firstLineHeadIndent ?? 0 <= prevParaStyle.firstLineHeadIndent + ListStyles.indentPoints else {
                return
            }

            if let line = editor.contentLinesInRange(editedRange).first {
                editor.addAttribute(.paragraphStyle, value: mutableStyle ?? editor.paragraphStyle, at: line.range)
            }
        }
    }

    private func createListItemInANewLine(editor: EditorView, editedRange: NSRange, indentMode: Indentation) {
        guard editedRange != .zero,
            editor.attributedText.attribute(.listItem, at: editedRange.endLocation - 1, effectiveRange: nil) != nil else {
                editor.typingAttributes[.listItem] = nil
                return
        }
        var attrs = editor.typingAttributes
        let paraStyle = attrs[.paragraphStyle] as? NSParagraphStyle
        let updatedStyle = ListStyles.updatedParagraphStyle(paraStyle: paraStyle, indentMode: indentMode)
        attrs[.paragraphStyle] = updatedStyle
        attrs[.listItem] = updatedStyle?.firstLineHeadIndent ?? 0 > 0.0 ? 1 : nil
        let marker = NSAttributedString(string: blankLineFiller, attributes: attrs)
        editor.replaceCharacters(in: editedRange, with: marker)
        editor.selectedRange = editedRange.nextPosition
    }
}
