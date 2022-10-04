//
//  CMGridViewController.swift
//  Crossword_iOS
//
//  Created by Natália Struharová on 13/08/2018.
//  Copyright © 2018 Natalia Struharova. All rights reserved.
//

import Foundation
import UIKit

class CMGridViewController: UIViewController, UIScrollViewDelegate {
    
    @IBOutlet var scrollView: UIScrollView!
    @IBOutlet var myView: UIView!
    
    public var width = 10
    public var height = 10
    var documentView: UIView?
    var crosswordGrid: [[CMGridCellView]] = []
    var crosswordDictionary: Dictionary = [String: String]()
    var secretDictionary: Dictionary = [Int: Bool]() // true = vertical, false = horizontal
    var secretString: String?
    var secretWordsArray: [String]?
    var secretArrayForGen: [[Int]]?
    var allWords: [[String]] = [];
    var shortestWord = 100;
    var longestWord = 0;
    var currentWord = 0;
    var currentIndex = 0;
    let cellSize: CGFloat = 60.0;
    let cellPadding: CGFloat = 2.0;
    
    //----------------THE EXTENSION SECTION------------------------------------------
    
    func randomBool() -> Bool {
        return arc4random_uniform(2) == 0
    }
    
    //--------------------------------------------------------------------------------
    
    func clearLetters(){
        for y in 0...height-1{
            for x in 0...width-1{
                if (crosswordGrid[y][x].type == CellType.letter || crosswordGrid[y][x].type == CellType.secret) {
                    crosswordGrid[y][x].value = ""
                }
            }
        }
        self.view.setNeedsDisplay()
    }
    
    func secretToElements(secretString: String) -> Array<String> {
        return secretString.components(separatedBy: " ")
    }
    
    func createCW(cellSize: CGFloat, cellPadding: CGFloat, x: Int, y: Int) {
        for y1 in 0...height-1 {
            var row : [CMGridCellView] = []
            for x1 in 0...width-1 {
                let rect1 = CGRect(x: CGFloat(x1)*(cellSize+cellPadding), y: CGFloat(height-y1-1)*(cellSize+cellPadding), width: cellSize, height: cellSize)
                let newView = CMGridCellView(frame: rect1)
                newView.controller = self
                newView.row = y1
                newView.column = x1
                row.append(newView)
                if (x1 == 0 || y1 == 0) {
                    newView.type = CellType.description
                }
                documentView?.addSubview(newView)
                newView.secretWords.removeAll()
            }
            crosswordGrid.append(row);
        }
    }
    
    @IBAction func generateCrossword(_ sender: Any) {
        //function fixInvalidSlots() must be used twice to check if any one-letter slots were created, and if so, fill them
        fixInvalidSlots();
        fixInvalidSlots()
        var slot: CMSlot? = findLongestSlot() as? CMSlot;
        if (slot == nil) {
            infoAlert(headline: "NEPLATNE ZADANÁ KRÍŽOVKA", text: "Po úprave invalidných jednopísmenkových políčok nie sú v krížovke žiadne slová. Zmeňte kompozíciu krížovky.");
        } else {
            while (slot != nil){
                let result = tryWords(slot: slot!);
                if (!result) {
                    infoAlert(headline: "NEMÁM RIEŠENIE", text: "Pre danú krížovku neexistuje riešenie.");
                    return;
                }
                slot = findEmptySlot() as? CMSlot;
            }
            printDescriptions();
            
            self.view.setNeedsDisplay();
            
        }
    }
    
    func infoAlert(headline: String, text: String) {
        let alert = UIAlertController(title: headline, message: text, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
    }
    
    func crosswordToString() -> String {
        var crosswordString : String = "";
        crosswordString.append("\(width),\(height)");
        for y in 0...crosswordGrid.count - 1{
            crosswordString.append("\n");
            for x in 0...crosswordGrid[y].count - 1{
                let cell: CMGridCellView = crosswordGrid[y][x];
                
                switch cell.type {
                case .letter:
                    crosswordString.append("_");
                case .description:
                    crosswordString.append("*");
                case .secretDescription:
                    crosswordString.append("*");
                case .empty:
                    crosswordString.append("x");
                case .secret:
                    crosswordString.append("?");
                case .help:
                    crosswordString.append("H")
                }
            }
        }
        return crosswordString;
    }
    
    func stringToCrossword(stringArray: [String], width: Int, height: Int){
        crosswordGrid.removeAll();
        self.width = width;
        self.height = height;
        documentView = UIView.init(frame: CGRect(x: 0, y: 0, width: CGFloat(width)*(cellSize+cellPadding), height: CGFloat(height)*(cellSize+cellPadding)))
        myView.addSubview(documentView!)
        scrollView.addSubview(myView!);
        var gridLineCount = 0;
        for y in 0...height-1 {
            var row : [CMGridCellView] = [];
            for x in 0...width-1 {
                let newView = CMGridCellView(frame: CGRect(x: CGFloat(x)*(cellSize+cellPadding), y: CGFloat(height-y-1)*(cellSize+cellPadding), width: cellSize, height: cellSize));
                newView.secretWords.removeAll();
                currentIndex = 0;
                currentWord = 0;
                newView.controller = self;
                row.append(newView);
                let c: Character = stringArray[gridLineCount][x];
                switch c{
                case "_":
                    newView.type = CellType.letter
                case "*":
                    newView.type = CellType.description;
                case "?":
                    newView.type = CellType.letter;
                default:
                    newView.type = CellType.letter;
                }
                documentView?.addSubview(newView);
            }
            crosswordGrid.append(row);
            gridLineCount = gridLineCount + 1;
        }
    }
    
    func printDescriptions(){
        //Horizontal
        var x = 0;
        var y = 0;
        while (y < crosswordGrid.count){
            let cell = crosswordGrid[y][x];
            if (cell.type == CellType.letter || cell.type == CellType.secret){
                let slot = CMSlot.init(x: x, y: y, vertical: false, crosswordArr: crosswordGrid);
                if (slot.allSecret) {
                    for i in 0...cell.secretWords.count-1{
                        if (slot.word == cell.secretWords[i]){
                            crosswordGrid[slot.startY][slot.startX-1].type = CellType.secretDescription;
                            crosswordGrid[slot.startY][slot.startX-1].value = String(i+1);
                            break;
                        }
                    }
                } else {
                    let words = findMatchingDictionary(slot: slot, dictionary: crosswordDictionary)
                    if (words == nil) {
                        print("zle slovo: ", slot.word);
                    } else {
                        let key = words?.keys.first;
                        print(key!, words![key!]!)
                        crosswordGrid[slot.startY][slot.startX-1].value = words![key!]!;
                    }
                }
                x = x + slot.word.count;
            } else {
                x = x + 1;
            }
            if (x >= crosswordGrid[y].count){
                x = 0;
                y = y + 1;
            }
        }
        //Vertical
        x = 0;
        y = 0;
        while (x < crosswordGrid[y].count){
            let cell = crosswordGrid[y][x];
            if (cell.type == CellType.letter || cell.type == CellType.secret){
                let slot = CMSlot.init(x: x, y: y, vertical: true, crosswordArr: crosswordGrid);
                if (slot.allSecret) {
                    for i in 0...cell.secretWords.count-1{
                        if (slot.word == cell.secretWords[i]){
                            crosswordGrid[slot.startY-1][slot.startX].type = CellType.secretDescription;
                            crosswordGrid[slot.startY-1][slot.startX].value = String(i+1);
                            break;
                        }
                    }
                } else {
                    let words = findMatchingDictionary(slot: slot, dictionary: self.crosswordDictionary);
                    if (words == nil) {
                        print("zle slovo: %s", slot.word);
                    } else {
                        let key = words?.keys.first;
                        print(key!, words![key!]!);
                        if (crosswordGrid[slot.startY-1][slot.startX].value == " ") {
                            crosswordGrid[slot.startY-1][slot.startX].value = words![key!]!;
                        }
                        else {
                            crosswordGrid[slot.startY-1][slot.startX].value2 = words![key!]!;
                        }
                    }
                }
                y = y + slot.word.count;
            } else {
                y = y + 1;
            }
            if (y >= crosswordGrid.count){
                y = 0;
                x = x + 1;
            }
        }
    }
    
    func findLongestSlot() -> Any? {
        //Horizontal
        var maxLength: Int = 0;
        var maxSlot: CMSlot? = nil;
        var x = 0;
        var y = 0;
        while (y < crosswordGrid.count){
            let cell = crosswordGrid[y][x];
            if (cell.type == CellType.letter){
                let slot = CMSlot.init(x: x, y: y, vertical: false, crosswordArr: crosswordGrid);
                let length = slot.word.count;
                if (length > maxLength) {
                    maxLength = length;
                    maxSlot = slot;
                }
                x = x + slot.word.count;
            } else {
                x = x + 1;
            }
            if (x >= crosswordGrid[y].count){
                x = 0;
                y = y + 1;
            }
        }
        //Vertical
        x = 0;
        y = 0;
        while (x < crosswordGrid[y].count){
            let cell = crosswordGrid[y][x];
            if (cell.type == CellType.letter){
                let slot = CMSlot.init(x: x, y: y, vertical: true, crosswordArr: crosswordGrid);
                let length = slot.word.count;
                if (length > maxLength) {
                    maxLength = length;
                    maxSlot = slot;
                }
                y = y + slot.word.count;
            } else {
                y = y + 1;
            }
            if (y >= crosswordGrid.count){
                y = 0;
                x = x + 1;
            }
        }
        return maxSlot;
    }
    
    func fixInvalidSlots(){
        //Horizontal
        var x = 0;
        var y = 0;
        while (y < crosswordGrid.count){
            let cell = crosswordGrid[y][x];
            if (cell.type == CellType.letter){
                let slot = CMSlot.init(x: x, y: y, vertical: false, crosswordArr: crosswordGrid);
                let length = slot.word.count;
                if (length == 1) {
                    slot.type = CellType.description
                    crosswordGrid[slot.startY][slot.startX].type = CellType.description
                    crosswordGrid[slot.startY][slot.startX].backgroundColor = UIColor.gray
                }
                x = x + slot.word.count;
            } else {
                x = x + 1;
            }
            if (x >= crosswordGrid[y].count){
                x = 0;
                y = y + 1;
            }
        }
        //Vertical
        x = 0;
        y = 0;
        var c = crosswordGrid[x].count
        while (x < c){
            let cell = crosswordGrid[y][x];
            if (cell.type == CellType.letter){
                let slot = CMSlot.init(x: x, y: y, vertical: true, crosswordArr: crosswordGrid);
                let length = slot.word.count;
                if (length == 1) {
                    slot.type = CellType.description;
                    crosswordGrid[slot.startY][slot.startX].type = CellType.description;
                    crosswordGrid[slot.startY][slot.startX].type = CellType.description;
                }
                y = y + slot.word.count;
            } else {
                y = y + 1;
            }
            if (y >= crosswordGrid.count){
                y = 0;
                x = x + 1;
            }
        }
        //Horizontal
        x = 0;
        y = 0;
        while (y < crosswordGrid.count){
            let cell = crosswordGrid[y][x];
            if (cell.type == CellType.letter){
                let slot = CMSlot.init(x: x, y: y, vertical: false, crosswordArr: crosswordGrid);
                let length = slot.word.count;
                if (length == 1) {
                    slot.type = CellType.description
                    crosswordGrid[slot.startY][slot.startX].type = CellType.description
                    crosswordGrid[slot.startY][slot.startX].backgroundColor = UIColor.gray
                }
                x = x + slot.word.count;
            } else {
                x = x + 1;
            }
            if (x >= crosswordGrid[y].count){
                x = 0;
                y = y + 1;
            }
        }
        //Vertical
        x = 0;
        y = 0;
        c = crosswordGrid[x].count
        while (x < c){
            let cell = crosswordGrid[y][x];
            if (cell.type == CellType.letter){
                let slot = CMSlot.init(x: x, y: y, vertical: true, crosswordArr: crosswordGrid);
                let length = slot.word.count;
                if (length == 1) {
                    slot.type = CellType.description;
                    crosswordGrid[slot.startY][slot.startX].type = CellType.description;
                    crosswordGrid[slot.startY][slot.startX].type = CellType.description;
                }
                y = y + slot.word.count;
            } else {
                y = y + 1;
            }
            if (y >= crosswordGrid.count){
                y = 0;
                x = x + 1;
            }
        }
    }
    
    func storeWord(word: String, slot: CMSlot) {
        var x1 = slot.startX;
        var y1 = slot.startY;
        let len = slot.word.count;
        
        if (len == 0){
            return;
        }
        for i in 0...len - 1{
            let si : String.Index = word.index(word.startIndex, offsetBy: i);
            crosswordGrid[y1][x1].value = String(word[si]);
            if (slot.vertical){
                y1 = y1 + 1;
            } else {
                x1 = x1 + 1;
            }
        }
    }
    
    func smartStoreWord(word: String, slot: CMSlot) -> Bool{
        var x1 = slot.startX;
        var y1 = slot.startY;
        let len = slot.word.count;
        
        if (len == 0){
            return false;
        }
        for i in 0...len - 1{
            let si : String.Index = word.index(word.startIndex, offsetBy: i);
            let cell : CMGridCellView = crosswordGrid[y1][x1];
            cell.value = String(word[si]);
            if (slot.vertical){
                if (cell.type == CellType.letter){
                    let slot2 = CMSlot.init(x: x1, y: y1, vertical: false, crosswordArr: crosswordGrid);
                    let matches = findMatchingWords(slot: slot2);
                    if (matches?.count == 0) {
                        storeWord(word: word, slot: slot);
                        return false;
                    }
                }
                y1 = y1 + 1;
            } else {
                if (cell.type == CellType.letter){
                    let slot2 = CMSlot.init(x: x1, y: y1, vertical: true, crosswordArr: crosswordGrid)
                    let matches = findMatchingWords(slot: slot2)
                    if (matches?.count == 0) {
                        storeWord(word: slot.word, slot: slot);
                        return false;
                    }
                }
                x1 = x1 + 1;
            }
        }
        return true;
    }
    func findMatchingDictionary(slot: CMSlot, dictionary: Dictionary<String, String>) -> Dictionary<String, String>? {
        let key = slot.word;
        let description = dictionary[key]
        if (description == nil){
            return nil;
        }
        return [key : (description as String?)!]; // IDK
    }
    
    //function for tracking the tryWords algorithm
    /*func printLog(){
     for y in 0...crosswordGrid.count - 1{
     var line: String = "";
     for x in 0...crosswordGrid[y].count - 1{
     let cell: CMGridCellView = crosswordGrid[y][x];
     line = line.appending(cell.value);
     }
     print(line);
     }
     }*/
    
    func findMatchingWords(slot: CMSlot) -> Array<String>? {
        let wordLength = slot.word.count;
        var matchingWords: [String] = [];
        let words = allWords[wordLength - shortestWord];
        let searchString: String = slot.word.uppercased();
        let spaceString : String = " ";
        let spaceLetter : Character = spaceString[spaceString.startIndex];
        for word in words{
            var result = true;
            for i in 0...searchString.count - 1 {
                let ssi = searchString.index(searchString.startIndex, offsetBy: i)
                let searchLetter : Character = searchString[ssi];
                if (searchLetter != spaceLetter) {
                    let wsi = word.index(word.startIndex, offsetBy: i);
                    let wordLetter : Character = word[wsi];
                    
                    if (searchLetter != wordLetter) {
                        result = false;
                        break;
                    }
                }
            }
            if (result == true){
                matchingWords.append(word);
            }
        }
        
        return matchingWords;
    }
    
    func findShortestWord(dictionary: Dictionary<String, String>) -> Int{
        var shortest: Int = 100;
        let keys = Array(dictionary.keys);
        for key in keys{
            if (key.count < shortest){
                shortest = key.count;
            }
        }
        return shortest;
    }
    
    func findLongestWord(dictionary: Dictionary<String, String>) -> Int{
        var longest: Int = 0;
        let keys = Array(dictionary.keys);
        for key in keys{
            if (key.count > longest){
                longest = key.count;
            }
        }
        return longest;
    }
    
    func extractWords(length: Int, dictionary: Dictionary<String, String>) -> Array<String>?{
        let keys = Array(dictionary.keys)
        var arr = [String]();
        for key in keys{
            if (key.count == length){
                arr.append(key);
            }
        }
        return arr;
    }
    
    func loadDictionary() -> Dictionary<String, String> {
        
        var dictionaryText: String;
        var dictionary: Dictionary = [String: String]();
        if let filepath = Bundle.main.path(forResource: "vyrazy", ofType: "csv") {
            do {
                dictionaryText = try String(contentsOfFile: filepath);
            } catch {
                return dictionary;
            }
        } else {
            return dictionary; //may be a problem
        }
        let lines = dictionaryText.components(separatedBy: CharacterSet.newlines);
        for line in lines{
            if (line.count > 2){
                let lineParts = line.components(separatedBy: "#");
                dictionary.updateValue(lineParts[1], forKey: lineParts[0])
            }
        }
        return dictionary;
    }
    
    func findEmptySlot() -> Any? {
        for y in 0...crosswordGrid.count - 1{
            for x in 0...crosswordGrid[y].count - 1{
                let cell: CMGridCellView = crosswordGrid[y][x];
                if (cell.type == CellType.letter && cell.value == " "){
                    let slot = CMSlot.init(x: x, y: y, vertical: false, crosswordArr: crosswordGrid);
                    return slot;
                }
            }
        }
        return nil;
    }
    
    func createMyCrossword() {
        height = 10
        width = 10
        secretString = "HELLO WORLD"
        
        secretWordsArray = secretToElements(secretString: secretString!)
        for i in 0...(secretWordsArray?.count)! - 1 {
            secretDictionary.updateValue(randomBool(), forKey: i)
            if (secretDictionary[i] == true) {
                let x = arc4random_uniform(UInt32(width - 2)) + 1
                let y = arc4random_uniform(UInt32((height-1)-(secretWordsArray![i].count))) + 1
                secretArrayForGen?.append([Int(x), Int(y)])
            } else {
                let x = arc4random_uniform(UInt32((width-1)-(secretWordsArray![i].count))) + 1
                let y = arc4random_uniform(UInt32(width - 2)) + 1
                secretArrayForGen?.append([Int(x), Int(y)])
            }
        }
        
        documentView = UIView.init(frame: CGRect(x: 0, y: 0, width: CGFloat(width)*(cellSize+cellPadding), height: CGFloat(height)*(cellSize+cellPadding)))
        documentView?.backgroundColor = UIColor.black
        myView.addSubview(documentView!)
        scrollView.addSubview(myView!)
        scrollView.contentSize = (documentView?.bounds.size)!
        self.view.setNeedsDisplay()
        documentView?.setNeedsDisplay()
        
        var wordLength = arc4random_uniform(UInt32(width)) + 1
        
        for y1 in 0...height-1 {
            var row : [CMGridCellView] = [];
            for x1 in 0...width-1 {
                let rect1 = CGRect(x: (CGFloat(x1))*(cellSize+cellPadding), y: CGFloat(y1)*(cellSize+cellPadding), width: cellSize, height: cellSize)
                let newView = CMGridCellView(frame: rect1)
                newView.controller = self
                newView.row = y1
                newView.column = x1
                row.append(newView)
                if (x1 == 0 && y1 == 0) {
                    newView.type = CellType.help
                    newView.backgroundColor = UIColor.red
                    newView.setNeedsDisplay()
                } else if ((x1 == 0 && y1 > 0) || (y1 == 0 && x1 > 0)) {
                    newView.type = CellType.description
                    newView.backgroundColor = UIColor.gray
                    newView.setNeedsDisplay()
                } else if (x1 == wordLength && y1 != 0) {
                    newView.type = CellType.description
                    newView.backgroundColor = UIColor.gray
                    newView.setNeedsDisplay()
                    wordLength = arc4random_uniform(UInt32(width)) + 1
                } else {
                    newView.type = CellType.letter
                    newView.backgroundColor = UIColor.white
                    newView.setNeedsDisplay()
                }
                documentView?.addSubview(newView);
                //newView.secretWords.removeAll()
            }
            crosswordGrid.append(row);
        }
        //Vertical secondary modification
        wordLength = arc4random_uniform(UInt32(height)) + 1
        for x1 in 1...width-1 {
            for y1 in 1...height-1{
                if (y1 == wordLength){
                    let rect1 = CGRect(x: (CGFloat(x1))*(cellSize+cellPadding), y: CGFloat(y1)*(cellSize+cellPadding), width: cellSize, height: cellSize)
                    let newView = CMGridCellView(frame: rect1)
                    crosswordGrid[y1][x1] = newView
                    newView.controller = self
                    newView.row = y1
                    newView.column = x1
                    newView.type = CellType.description
                    newView.backgroundColor = UIColor.gray
                    newView.setNeedsDisplay()
                    documentView?.addSubview(newView)
                    wordLength = arc4random_uniform(UInt32(height)) + 1
                }
            }
        }
        fixInvalidSlots()
        self.documentView?.setNeedsDisplay()
        self.view.setNeedsDisplay()
    }
    
    func tryWords(slot: CMSlot) -> Bool {
        if ((findEmptySlot()) == nil) {
            return true
        }
        let words = findMatchingWords(slot: slot);
        if ((words?.count)==0) {
            return false
        }
        for word in words! {
            let wordString: String = word
            let cond = smartStoreWord(word: wordString, slot: slot)
            if (cond) {
                var wordIsGood: Bool = true
                //printLog(); //can be used to track the tryWords algorithm
                if (slot.vertical == true){
                    for i in 0...slot.word.count - 1{
                        let slot2 = CMSlot.init(x: slot.startX, y: slot.startY+i, vertical: false, crosswordArr: crosswordGrid)
                        if (!slot2.isFull()) {
                            if (tryWords(slot: slot2) == false) {
                                wordIsGood = false;
                                break;
                            }
                        } else if (slot2.type != CellType.secret) {
                            let matches = findMatchingWords(slot: slot2)
                            if matches?.count==0 {
                                wordIsGood = false;
                                break;
                            }
                        }
                    }
                } else {
                    for i in 0...slot.word.count - 1{
                        let slot2 = CMSlot.init(x: slot.startX+i, y: slot.startY, vertical: true, crosswordArr: crosswordGrid)
                        if (!slot2.isFull()) {
                            if (tryWords(slot: slot2) == false) {
                                wordIsGood = false;
                                break;
                            }
                        }
                        else if (slot2.type != CellType.secret) {
                            let matches = findMatchingWords(slot: slot2)
                            if matches?.count==0 {
                                wordIsGood = false;
                                break;
                            }
                        }
                    }
                }
                if (wordIsGood) {
                    return true;
                }
            }
        }
        storeWord(word: slot.word, slot: slot);
        return false;
    }
    
    override func viewDidLoad() {
        super.viewDidLoad();
        self.view.backgroundColor = UIColor.white
    
        self.scrollView.delegate = self
        self.scrollView.minimumZoomScale = 0.2
        self.scrollView.maximumZoomScale = 2
        view.addSubview(scrollView)
        
        self.crosswordDictionary = loadDictionary();
        self.shortestWord = findShortestWord(dictionary: self.crosswordDictionary);
        self.longestWord = findLongestWord(dictionary: self.crosswordDictionary);
        
        for i in self.shortestWord...self.longestWord{
            allWords.append(extractWords(length: i, dictionary: self.crosswordDictionary)!);
        }

        createMyCrossword()
        print(crosswordToString())
    }
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return documentView
    }
    
}
