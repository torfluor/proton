//
//  RendererCommandExampleViewController.swift
//  ExampleApp
//
//  Created by Rajdeep Kwatra on 15/1/20.
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

import Proton
import ProtonExtensions

class TableExampleViewController: UITableViewController {
    let storage: [NSAttributedString]

    init() {
        storage = (0 ..< 20).map({ NSAttributedString.makeRandom($0) })
        super.init(style: .plain)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .secondarySystemBackground
        tableView.register(TableCell.self, forCellReuseIdentifier: TableCell.description())
    }
}

extension TableExampleViewController {
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        storage.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: TableCell.description()) as! TableCell
        cell.renderer.attributedText = self.storage[indexPath.row]
        cell.backgroundColor = .secondarySystemBackground
        return cell
    }

}

final class TableCell: UITableViewCell {
    let renderer = EditorView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        renderer.isEditable = false
        renderer.translatesAutoresizingMaskIntoConstraints = false
        renderer.backgroundColor = UIColor.systemBackground
        contentView.addSubview(renderer)

        NSLayoutConstraint.activate([
            renderer.topAnchor.constraint(equalTo: contentView.safeAreaLayoutGuide.topAnchor, constant: 10),
            renderer.bottomAnchor.constraint(equalTo: contentView.safeAreaLayoutGuide.bottomAnchor, constant: -10),
            renderer.leadingAnchor.constraint(equalTo: contentView.safeAreaLayoutGuide.leadingAnchor, constant: 10),
            renderer.trailingAnchor.constraint(equalTo: contentView.safeAreaLayoutGuide.trailingAnchor, constant: -10),
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        renderer.attributedText = NSAttributedString()
        renderer.setNeedsLayout()
    }
}

private extension NSAttributedString {
    static func makeRandom(_ index: Int) -> NSAttributedString {
        let count = Int.random(in: 1 ..< 5)

        let value = NSMutableAttributedString()
        (0 ..< count).forEach { i in
            let content = NSAttributedString(
                string: "#\(String(index)):\(String(i))\n" + NSString.makeRandom(),
                attributes: [
                    .font: UIFont.preferredFont(forTextStyle: .body),
                    .foregroundColor: UIColor.systemIndigo
            ]
            )

            let attachment = PanelAttachment(frame: .init(origin: .zero, size: .init(width: 320, height: 40)))
            attachment.backgroundColor = UIColor.systemTeal
            attachment.view.editor.attributedText = content
            value.append(attachment.string)
        }

        return value
    }
}


private extension NSString {
    static let loremIpsum: NSString = """
     Lorem ipsum dolor sit amet, consectetur adipiscing elit. Nulla suscipit dignissim tristique. Proin sagittis, orci a aliquet semper, mi lorem convallis sapien, ac faucibus odio neque sit amet tortor. Aenean sit amet lacus nec magna congue volutpat nec at nulla. Donec id orci nunc. In hac habitasse platea dictumst. Vestibulum a mauris mi. Nulla vel lectus luctus, tempus erat maximus, feugiat diam. Fusce bibendum libero quis sapien maximus, eu molestie ligula eleifend. Ut non arcu odio. Pellentesque ultrices et risus a aliquam. Donec nibh orci, vehicula in purus vitae, consequat bibendum enim. Aenean mollis eget urna id efficitur. Nullam dapibus libero at sollicitudin tristique. Aliquam quis magna sed enim aliquam facilisis.
    Curabitur molestie eleifend nisi, nec porttitor nibh feugiat id. Duis volutpat a erat quis pretium. Nunc eu iaculis mi. Proin ut orci sed tellus congue euismod sed nec elit. Nunc malesuada tristique ipsum, id mattis nibh placerat at. Nam suscipit gravida orci ut volutpat. Pellentesque vitae ante non massa elementum gravida. Duis convallis at augue a iaculis. Etiam quis ligula lobortis, maximus nibh at, vulputate purus. Integer sodales ex ac auctor hendrerit. Nunc laoreet convallis eros at imperdiet. Phasellus efficitur metus a auctor imperdiet. Nunc at odio gravida, bibendum augue at, ornare risus.
    Aenean mollis tortor lobortis, rutrum risus suscipit, pharetra nibh. Nulla hendrerit sit amet neque vitae pretium. Vivamus vitae felis pharetra, efficitur libero sit amet, maximus elit. Nullam eleifend urna at nisi aliquam ornare. Ut suscipit scelerisque fermentum. Proin ac accumsan tellus. Donec dictum, ex molestie aliquam elementum, eros est pulvinar turpis, vel elementum libero metus sit amet nisl. Vestibulum laoreet nec quam at aliquet. Proin ultricies ullamcorper neque, in mattis ex tincidunt pharetra. Integer ac lorem et lorem aliquam molestie at ullamcorper enim. Aliquam nunc velit, ullamcorper et lorem lobortis, aliquet varius mi. Morbi eget commodo sapien, non sagittis tellus. Donec eget feugiat quam, non interdum lorem. Morbi ac molestie purus, nec dignissim sem. Cras commodo tortor quis enim blandit maximus. Cras mattis volutpat condimentum.
    """

    static func makeRandom() -> String {
        let start = Int.random(in: 0 ..< (loremIpsum.length - 100))
        let length = Int.random(in: 50 ..< loremIpsum.length - start)
        return loremIpsum.substring(with: NSRange(location: start, length: length))
    }
}
