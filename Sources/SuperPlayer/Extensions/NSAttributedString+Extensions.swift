//
//  NSAttributedString+Extensions.swift
//  Source
//
//  Created by Andrey Yoshua on 04/08/21.
//

import UIKit

extension NSAttributedString {
    internal class func setFont(font: UIFont, kerning: Double = 0, color: UIColor, lineSpacing: CGFloat? = nil, alignment: NSTextAlignment, strikethrough: Bool) -> [NSAttributedString.Key: Any] {
        let paragraphStyle = NSMutableParagraphStyle()
        if let lineSpacing = lineSpacing {
            paragraphStyle.lineSpacing = lineSpacing
        }
        paragraphStyle.alignment = alignment

        var attribute = [.font: font,
                         .kern: kerning,
                         .foregroundColor: color,
                         .paragraphStyle: paragraphStyle] as [NSAttributedString.Key: Any]

        if strikethrough {
            attribute[.strikethroughStyle] = NSUnderlineStyle.single.rawValue
        }
        return attribute
    }
    
    internal class func body3(_ string: String,
                            color: UIColor = #colorLiteral(red: 0.1921568627, green: 0.2078431373, blue: 0.231372549, alpha: 1).withAlphaComponent(0.96),
                            isBold: Bool = false,
                            alignment: NSTextAlignment = .left,
                            strikethrough: Bool = false) -> NSAttributedString {
        let attribute = NSAttributedString.setFont(
            font: .systemFont(
                ofSize: 12,
                weight: isBold ? .bold : .regular
            ),
            color: color,
            lineSpacing: 3.7,
            alignment: alignment,
            strikethrough: strikethrough
        )
        let attributeString = NSMutableAttributedString(string: string, attributes: attribute)
        return attributeString
    }
}
