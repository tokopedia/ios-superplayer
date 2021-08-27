//
//  CGSize+Extensions.swift
//  Source
//
//  Created by Andrey Yoshua on 04/08/21.
//

import Foundation
import UIKit

extension CGSize {
    internal init(squareWithSize size: CGFloat) {
        self.init(width: size, height: size)
    }
}
