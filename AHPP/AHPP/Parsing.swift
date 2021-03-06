//
//  Parsing.swift
//  AHPP
//
//  Created by Ben Neely on 3/15/15.
//  Copyright (c) 2015 boisestate. All rights reserved.
//

import Foundation

public class Parsing {
    class func parse(path: NSURL) -> Bool {
        var processing: Bool = true, table_gen = LookupTableGenerator(path: path), lookUpTable: LookUpTable, table1: Array2D, table2: Array2D
        
        lookUpTable = table_gen.loadMetaData()
        saveDataCells(table_gen.nextTable(), lookUpTable: lookUpTable, isHige: true, isHoge: false)
        saveDataCells(table_gen.nextTable(), lookUpTable: lookUpTable, isHige: false, isHoge: true)
        saveDataCells(table_gen.nextTable(), lookUpTable: lookUpTable, isHige: false, isHoge: false)

        return true
    }

    private class func saveDataCells(table: Array2D, lookUpTable: LookUpTable, isHige: Bool, isHoge: Bool) {
        if(table.colCount() > 0 && table.rowCount() > 0) {
            for col in 1..<table.colCount() {
                for row in 1..<table.rowCount() {
                    if(table[col,row] != nil && table[col,row] >= 0) {
                        ViewController.saveDataCell(
                            table[0,row-1]!,
                            temperature: table[col, 0]!,
                            weight: table[col,row]!,
                            lookUpTable: lookUpTable,
                            isHige: isHige,
                            isHoge: isHoge)
                    }
                }
            }
        }
    }
}

public class LookupTableGenerator {
    var company_name: String = "", contact_number: String = "", designated_base: String = "", fixed_weight_reduduction: NSNumber = 0, flight_crew_weight: NSNumber = 0, gross_weight_limitation_hige: NSNumber = 0, gross_weight_limitation_hoge: NSNumber = 0, gross_weight_limitation_hoge_j: NSNumber = 0, helicopter_equipped_weight: NSNumber = 0, is_hoge: NSNumber = 0, make_model: String = "", n_number: String = "", performance_reference_hige: String = "", performance_reference_hoge: String = "", pilot_name: String = "", has_wat: Bool = false, table_num: Int = 0, path: NSURL, atTable: Bool = false, aStreamReader: StreamReader
    
    init(path: NSURL) {
        self.path = path
        self.aStreamReader = StreamReader(path: self.path.path!)!
    }

    
    func loadMetaData() -> LookUpTable {
        var processing: Bool = true, strings: [String]
        
        strings = getMetaStrings()
        for var i = 0; i<strings.count; i++ {
            var temp = strings[i]
            switch temp {
                case "Designated Base":
                    self.designated_base = strings[i+1]
                    i++
                case "Contract #":
                    self.contact_number = strings[i+1]
                    i++
                case "Company Name":
                    self.company_name = strings[i+1]
                    i++
                case "Fixed Weight Reduction":
                    self.fixed_weight_reduduction = strings[i+1].toInt()!
                    i++
                case "Make/Model":
                    self.make_model = strings[i+1]
                    i++
                case "Performance Reference HIGE":
                    self.performance_reference_hige = strings[i+1]
                    i++
                case "N#":
                    self.n_number = strings[i+1]
                    i++
                case "Gross Weight Limitation HIGE":
                    self.gross_weight_limitation_hige = strings[i+1].toInt()!
                    i++
                case "Helicopter Equipped Weight":
                    self.helicopter_equipped_weight = strings[i+1].toInt()!
                    i++
                case "Performance Reference HOGE":
                    self.performance_reference_hoge = strings[i+1]
                    i++
                case "Pilot Name":
                    self.pilot_name = strings[i+1]
                    i++
                case "Gross Weight Limitation HOGE":
                    self.gross_weight_limitation_hoge = strings[i+1].toInt()!
                    i++
                case "Flight Crew Weight":
                    self.flight_crew_weight = strings[i+1].toInt()!
                    i++
                case "Gross Weight Limitation HOGE-J":
                    self.gross_weight_limitation_hoge_j = strings[i+1].toInt()!
                    i++
                default:
                    println()
            }
        }
        
        return ViewController.saveLookUpTable(self.company_name, contact_number: self.contact_number, designated_base: self.designated_base, fixed_weight_reduduction: self.fixed_weight_reduduction, flight_crew_weight: self.flight_crew_weight, gross_weight_limitation_hige: self.gross_weight_limitation_hige,gross_weight_limitation_hoge: self.gross_weight_limitation_hoge, gross_weight_limitation_hoge_j: self.gross_weight_limitation_hoge_j, helicopter_equipped_weight: self.helicopter_equipped_weight, is_hoge: self.is_hoge, make_model: self.make_model, n_number: self.n_number, performance_reference_hige: self.performance_reference_hige, performance_reference_hoge: self.performance_reference_hoge, pilot_name: self.pilot_name, has_wat: hasWatTable())
    }
    
    func nextTable() -> Array2D {
        var line: String, table: Array2D = Array2D(cols: 0, rows: 0), dim: [Int]
        
        if(findTable()) {
            self.table_num++
            dim = getTableDimensions()
            table = Array2D(cols: dim[0], rows: dim[1])
            for i in 0..<table.colCount() {
                let parsedline = getNextLine()
                for (j, cell) in enumerate(parsedline) {
                    table[i,j] = cell
                }
            }
            self.atTable = false
        }
        return table
    }
    
    func hasWatTable() -> Bool {
        var has_wat = false, i = 0;
        
        while(findTable()) { i++ }
        if i == 3 {
            has_wat = true
        }
        self.aStreamReader.rewind()
        return has_wat
    }
    
    private func findTable() -> Bool {
        var table_found = false
        while let line = aStreamReader.nextLine() {
            if line.rangeOfString("Lookup Table") != nil {
                table_found = true
            }
            if(table_found) {
                self.atTable = true
                break
            }
        }
        return table_found
    }
    
    private func getTableDimensions() ->[Int] {
        var processing: Bool = true, colsrows: [Int] = [0,0]
        
        if(!self.atTable) { findTable() }
        while(processing) {
            let parsedLine = getNextLine()
            if(!parsedLine.isEmpty) {
                if(parsedLine[0]<(0)) {
                    processing = false
                } else {
                    colsrows[0]++
                }
                if(colsrows[1] < parsedLine.count) {
                    colsrows[1]=parsedLine.count
                }
            } else {
                processing = false;
            }
        }
        
        //return back to beginning of the table you were at
        aStreamReader.rewind()
        for i in 0..<self.table_num {
            findTable()
        }
        return colsrows
    }
    
    private func getMetaStrings() -> [String] {
        var processing: Bool = true, line: String, cells: [String] = Array<String>()
        
        while(processing) {
            line = aStreamReader.nextLine()!
            for cell in line.componentsSeparatedByString(",") {
                if (!cell.isEmpty) { cells.append(cell) }
            }
            if line.rangeOfString("Flight Crew Weight") != nil {
                //found last line of meta data stop consuming more
                processing = false
            }
        }
        return cells
    }
    
    private func getNextLine() -> [Int] {
        var line: String, cells: [String] = Array<String>(), parsed_cells: [Int] = Array<Int>(), atEnd: Bool = false, processing = true
        
        while(processing) {
            line = (aStreamReader.nextLine()!).stringByTrimmingCharactersInSet(NSCharacterSet.newlineCharacterSet())
            //split line up and remove empty elements
            for cell in line.componentsSeparatedByString(",") {
                if (!cell.isEmpty) {
                    cells.append(cell)
                }
            }
            let x = line.componentsSeparatedByString(",").count
            
            //if all cells is empty we have reached the end of our table
            if(cells.isEmpty) {
                atEnd = true
            } else {
                for cell in cells {
                    if((cell.toInt()) != nil){
                        parsed_cells.append(cell.toInt()!)
                    }
                }
            }
            
            /*
            * if parsed_cells is empty but were not at the end of the table.
            * This would happend because the row and col titles take up their
            * own line with no Integer elements on the line, causing a false empty
            */
            if(parsed_cells.isEmpty && atEnd) {
                parsed_cells.append(-1)
                processing = false
            } else if(!parsed_cells.isEmpty) {
                processing = false
            }
        }
        return parsed_cells
    }
}

class Array2D {
    var cols:Int, rows:Int, matrix: [Int?]

    init(cols:Int, rows:Int) {
        self.cols = cols
        self.rows = rows
        matrix = Array(count:cols*rows, repeatedValue:nil)
    }
    
    subscript(col:Int, row:Int) -> Int? {
        get {
            return matrix[cols * row + col]
        }
        set {
            matrix[cols*row+col] = newValue
        }
    }
    
    func colCount() -> Int {
        return self.cols
    }
    
    func rowCount() -> Int {
        return self.rows
    }
}

class StreamReader  {
    let encoding : UInt
    let chunkSize : Int
    
    var fileHandle : NSFileHandle!, buffer : NSMutableData!, delimData : NSData!, atEof : Bool = false
    
    init?(path: String, delimiter: String = "\n", encoding : UInt = NSUTF8StringEncoding, chunkSize : Int = 4096) {
        self.chunkSize = chunkSize
        self.encoding = encoding
        self.buffer = nil
        self.delimData = nil
        
        if let fileHandle = NSFileHandle(forReadingAtPath: path) {
            self.fileHandle = fileHandle
        } else {
            return nil
        }
        // Create NSData object containing the line delimiter:
        if let delimData = delimiter.dataUsingEncoding(NSUTF8StringEncoding) {
            self.delimData = delimData
        } else {
            return nil
        }
        if let buffer = NSMutableData(capacity: chunkSize) {
            self.buffer = buffer
        } else {
            return nil
        }
    }
    
    deinit { self.close() }
    
    /// Return next line, or nil on EOF.
    func nextLine() -> String? {
        
        if atEof { return nil }
        
        // Read data chunks from file until a line delimiter is found:
        var range = buffer.rangeOfData(delimData, options: nil, range: NSMakeRange(0, buffer.length))
        while range.location == NSNotFound {
            var tmpData = fileHandle.readDataOfLength(chunkSize)
            if tmpData.length == 0 {
                // EOF or read error.
                atEof = true
                if buffer.length > 0 {
                    // Buffer contains last line in file (not terminated by delimiter).
                    let line = NSString(data: buffer, encoding: encoding);
                    buffer.length = 0
                    return (line as! String)
                }
                // No more lines.
                return nil
            }
            buffer.appendData(tmpData)
            range = buffer.rangeOfData(delimData, options: nil, range: NSMakeRange(0, buffer.length))
        }
        
        // Convert complete line (excluding the delimiter) to a string:
        let line = NSString(data: buffer.subdataWithRange(NSMakeRange(0, range.location)),
            encoding: encoding)
        // Remove line (and the delimiter) from the buffer:
        buffer.replaceBytesInRange(NSMakeRange(0, range.location + range.length), withBytes: nil, length: 0)
        
        return (line as! String)
    }
    
    /// Start reading from the beginning of file.
    func rewind() -> Void {
        fileHandle.seekToFileOffset(0)
        buffer.length = 0
        atEof = false
    }
    
    /// Close the underlying file. No reading must be done after calling this method.
    func close() -> Void {
        if fileHandle != nil {
            fileHandle.closeFile()
            fileHandle = nil
        }
    }
}
