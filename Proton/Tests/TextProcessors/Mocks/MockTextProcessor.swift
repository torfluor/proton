//
//  MockTextProcessor.swift
//  ProtonTests
//
//  Created by Rajdeep Kwatra on 11/1/20.
//  Copyright © 2020 Rajdeep Kwatra. All rights reserved.
//

import Foundation
import UIKit

import Proton

class MockTextProcessor: TextProcessing {
    let name: String
    var priority: TextProcessingPriority = .medium

    var onWillProcess: ((NSAttributedString, String) -> Void)?
    var onProcess: ((EditorView, NSRange, Int) -> Void)?
    var onKeyWithModifier: ((EditorView, EditorKey, UIKeyModifierFlags, NSRange) -> Void)?
    var onProcessInterrupted: ((EditorView, NSRange) -> Void)?
    var onSelectedRangeChanged: ((EditorView, NSRange?, NSRange?) -> Void)?

    var processorCondition: (EditorView, NSRange) -> Bool

    init(name: String = "MockTextProcessor", processorCondition: @escaping (EditorView, NSRange) -> Bool = { _, _ in true }) {
        self.name = name
        self.processorCondition = processorCondition
    }

    func willProcess(deletedText: NSAttributedString, insertedText: String) {
        onWillProcess?(deletedText, insertedText)
    }

    func process(editor: EditorView, range editedRange: NSRange, changeInLength delta: Int) -> Processed {
        guard processorCondition(editor, editedRange) else {
            return false
        }
        onProcess?(editor, editedRange, delta)
        return true
    }

    func handleKeyWithModifiers(editor: EditorView, key: EditorKey, modifierFlags: UIKeyModifierFlags, range editedRange: NSRange) {
        guard processorCondition(editor, editedRange) else { return }

        onKeyWithModifier?(editor, key, modifierFlags, editedRange)
    }

    func processInterrupted(editor: EditorView, at range: NSRange) {
        onProcessInterrupted?(editor, range)
    }

    func selectedRangeChanged(editor: EditorView, oldRange: NSRange?, newRange: NSRange?) {
        onSelectedRangeChanged?(editor, oldRange, newRange)
    }
}
