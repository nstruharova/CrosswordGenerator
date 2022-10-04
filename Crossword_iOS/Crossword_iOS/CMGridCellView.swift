//
//  CMGridCellView.swift
//  Crossword_iOS
//
//  Created by Natália Struharová on 13/08/2018.
//  Copyright © 2018 Natalia Struharova. All rights reserved.
//

import Foundation
import UIKit

public enum CellType {
    
    case empty;
    case letter;
    case description;
    case secretDescription;
    case secret;
    case help;
    
}

extension String {
    
    subscript (i: Int) -> Character {
        return self[index(startIndex, offsetBy: i)]
    }
    
    subscript (i: Int) -> String {
        return String(self[i] as Character)
    }
    
    subscript (r: Range<Int>) -> String {
        let start = index(startIndex, offsetBy: r.lowerBound)
        let end = index(startIndex, offsetBy: r.upperBound)
        return String(self[Range(start ..< end)])
    }
}

class CMGridCellView: UIView {
    
    var row = 0;
    var column = 0;
    var controller: CMGridViewController?
    var type = CellType.letter
    var value: String = " "
    var value2: String = " "
    var secretWords: [String] = []
    var mySlot: CMSlot?
    
    override func draw(_ dirtyRect: CGRect) {
        super.draw(dirtyRect)
        let rect = dirtyRect;
        var color: UIColor;
        switch type {
        case .empty:
            color = UIColor.white;
        case .letter:
            color = UIColor.white;
        case .description:
            color = UIColor.init(red: 0.9, green: 0.9, blue: 0.9, alpha: 1.0);
        case .secretDescription:
            color = UIColor.init(red: 0.9, green: 0.9, blue: 0.9, alpha: 1.0);
        case .secret:
            color = UIColor.init(red: 1.0, green: 0.8, blue: 0.8, alpha: 1.0);
        case.help:
            color = UIColor.lightGray
        }
        color.set();
        //rect.fill(); idk what to do with dis
        /*if (self.type != CellType.empty){
            let path = UIBezierPath.init(rect: rect);
            UIColor.black.setStroke();
            path.lineWidth = 2.0;
            path.stroke();
        } */
        if (self.value != " ") {
            let paragraphStyle = NSMutableParagraphStyle.init();
            if (self.type == CellType.letter || self.type == CellType.secret || self.type == CellType.secretDescription) {
                paragraphStyle.alignment = NSTextAlignment.center;
            } else {
                paragraphStyle.alignment = NSTextAlignment.left;
            }
            var textAttrs: [NSAttributedStringKey : Any]?;
            var rect2 = rect.insetBy(dx: 3, dy: 3);
            
            if (self.type == CellType.description || self.type == CellType.help){
                //paragraphStyle.lineBreakMode nejako doplnit wordByWrapping
                textAttrs = [
                    NSAttributedStringKey.font: UIFont.init(name: "Arial", size: 7.0)!,
                    NSAttributedStringKey.paragraphStyle: paragraphStyle,
                ]
            } else {
                textAttrs = [
                    NSAttributedStringKey.font: UIFont.init(name: "Arial", size: 20.0)!,
                    NSAttributedStringKey.paragraphStyle: paragraphStyle,
                ]
            }
            
            let stringSize : CGSize = value.size(withAttributes: textAttrs);
            
            if (self.type != CellType.description){
                rect2.size.height = stringSize.height;
                rect2.origin.y = (CGFloat(rect.size.height)-CGFloat(rect2.size.height))/2.0;
            }
            
            self.value.draw(in: rect2, withAttributes: textAttrs);
            
            if (self.type == CellType.description && self.value2 != " ") {
                let path = UIBezierPath.init()
                path.move(to: CGPoint(x: rect.origin.x, y: rect.origin.y + rect.size.height*0.5))
                path.addLine(to: CGPoint(x: rect.origin.x + rect.size.width, y: rect.origin.y + rect.size.height*0.5))
                path.close();
                path.stroke();
                
                var rect3 = rect;
                rect3.size.height *= 0.5;
                rect3 = rect3.insetBy(dx: 3, dy: 3);
                self.value2.draw(in: rect3, withAttributes: textAttrs);
            }
        }
        
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let touch = touches.first!
        if (touch.view == self && self.type == CellType.description) {
            let boundsRelToDocumentView = self.convert(self.bounds, to: controller?.scrollView.subviews[0].subviews[0])
            controller?.scrollView.zoom(to: boundsRelToDocumentView, animated: true)
            self.mySlot?.isSelected = true
        }
    }
    
    func modifyCell() {
        //var secretText : String = (controller?.secretField.text)!;
        //secretText = secretText.uppercased();
        //secretWords = secretText.components(separatedBy: " ");
        //will deal with when dictionary is present
        
        /*switch controller?.segmentedButton.selectedSegment as Int!{
        case 0:
            type = CellType.empty;
        case 1:
            type = CellType.letter;
            value = " ";
        case 2:
            type = CellType.description;
        case 3:
            if (type == CellType.secret){
                controller?.infoAlert(headline: "NEPLATNÉ ZADANIE TAJNIČKY", text: "Písmenká tajničky sa nesmú prekrývať!");
            } else if ((controller?.currentIndex)! + 1 <= secretWords[(controller?.currentWord)!].count) {
                value = secretWords[(controller?.currentWord)!][(controller?.currentIndex)!];
                controller?.currentIndex = (controller?.currentIndex)! + 1;
                type = CellType.secret;
            } else if ((controller?.currentIndex)! + 1 > secretWords[(controller?.currentWord)!].count && (controller?.currentWord)! + 1 < secretWords.count) {
                controller?.currentIndex = 0;
                controller?.currentWord = (controller?.currentWord)! + 1;
                value = secretWords[(controller?.currentWord)!][(controller?.currentIndex)!];
                type = CellType.secret;
                controller?.currentIndex = (controller?.currentIndex)! + 1;
            } else if (controller?.currentIndex == 1) {
                
            }
        default:
            type = CellType.letter;
        }*/
        
        self.setNeedsDisplay()
    }
    
    func changeCellBack(){
        if (self.type == CellType.secret){
            controller?.currentIndex = (controller?.currentIndex)! - 1;
            if (controller?.currentIndex == 0 && (controller?.currentWord)! > 0) {
                controller?.currentWord = (controller?.currentWord)! - 1;
                controller?.currentIndex = secretWords[(controller?.currentWord)!].count;
            } else if (controller?.currentIndex == 0 && controller?.currentWord == 0){
                
            }
            self.type = CellType.letter;
            self.value = " ";
        }
        self.setNeedsDisplay()
    }
}
