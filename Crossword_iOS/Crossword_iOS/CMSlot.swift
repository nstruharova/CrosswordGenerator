//
//  CMSlot.swift
//  Crossword_iOS
//
//  Created by Natália Struharová on 13/08/2018.
//  Copyright © 2018 Natalia Struharova. All rights reserved.
//

import Foundation
import UIKit

class CMSlot: UIView {
    
    var vertical: Bool = true
    var startX: Int = 0
    var startY: Int = 0
    var word: String = ""
    var type: CellType = CellType.empty
    var allSecret: Bool = true
    var isSelected: Bool = false
    
    init(x: Int, y: Int, vertical: Bool, crosswordArr: Any?){
        super.init(frame: CGRect(x: 1, y: 1, width: 1, height: 1)) // IDK if correct? May cause problems
        
        self.vertical = vertical
        
        let array : [[CMGridCellView]] = crosswordArr as! [[CMGridCellView]]
        var cell = array[y][x] as CMGridCellView
        
        var x1 = x
        var y1 = y
        startX = x
        startY = y
        if (cell.type == CellType.letter || cell.type == CellType.secret){
            while (cell.type == CellType.letter || cell.type == CellType.secret){
                if (vertical){
                    startY = y1
                    y1 = y1 - 1
                    if (y1 < 0) {
                        break
                    }
                } else {
                    startX = x1
                    x1 = x1 - 1
                    if (x1 < 0) {
                        break
                    }
                }
                cell = array[y1][x1] as CMGridCellView
            }
        } else {
            while (cell.type != CellType.letter && cell.type != CellType.secret){
                if (vertical){
                    y1 = y1 + 1
                    if (y1 >= array.count) {
                        break
                    }
                } else {
                    x1 = x1 + 1
                    if (x1 >= array[y1].count) {
                        break
                    }
                }
                cell = array[y1][x1] as CMGridCellView
            }
            startX = x1
            startY = y1
        }
        x1 = startX
        y1 = startY
        cell = array[y1][x1] as CMGridCellView
        cell.mySlot = self
        while (cell.type == CellType.letter || cell.type == CellType.secret){
            let s : String = cell.value
            self.word = self.word.appending(s)
            if (cell.type != CellType.secret) {
                allSecret = false
            }
            if (vertical){
                y1 = y1 + 1
                if (y1 >= array.count) {
                    break
                }
            } else {
                x1 = x1 + 1
                if (x1 >= array[y1].count) {
                    break
                }
            }
            cell = array[y1][x1] as CMGridCellView
        }
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func isFull() -> Bool{
        let firstSpace = self.word.index(of: " ") ?? self.word.endIndex
        return (firstSpace == self.word.endIndex)
    }
    
}
