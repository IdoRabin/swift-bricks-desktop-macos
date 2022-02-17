//
//  FileLogView+NSTableView.swift
//  Bricks
//
//  Created by Ido on 29/01/2022.
//

import AppKit

fileprivate let dlog : DSLogger? = DLog.forClass("FileLogView+TV")


extension FileLogView : NSTableViewDataSource {
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        // dlog?.info("numberOfRows (lines): \((self.fileLog?.count).descOrNil)")
        return self.fileLog?.count ?? 0
    }
     
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        
        // TODO: Recycle view? enqueue / dequeue?
        let digitSpacer = String.FIGURE_SPACE // ":"
        let cell = tableView.makeView(withIdentifier: (tableColumn!.identifier), owner: self) as? NSTableCellView
        guard row >= 0 else {
            return cell
        }
        
        let chunkIndex = self.chunkIndex(for: UInt(row))
        guard let lines = self.lines[chunkIndex], row >= lines.minRow && row <= lines.maxRow else {
            cell?.textField?.stringValue = "?"
            return cell
        }
        let line : Line? = lines.rows[UInt(row)]
        switch tableColumn?.identifier.rawValue ?? "" {
        case "rowNumberColumnID":
            let str = String(format: self.lineNrFormatStr, (line?.row ?? UInt(row)) + 1).appending(digitSpacer).replacingOccurrences(ofFromTo: [" ": digitSpacer, String.NBSP: digitSpacer])
            cell?.textField?.font = self.cellFont.withSize(12)
            cell?.textField?.textColor = NSColor.secondaryLabelColor
            if let attrs = cell?.textField?.attributedStringValue.attributes(at: 0, effectiveRange: nil) {
                let attr = NSMutableAttributedString(string: str, attributes: attrs)
                let paragraph = (NSParagraphStyle.default.mutableCopy() as? NSMutableParagraphStyle)!
                paragraph.alignment = .inverseNatural
                attr.setAtttibutesForStrings(matching: str, attributes: [.baselineOffset:NSNumber(integerLiteral: -2),
                                                                         .paragraphStyle : paragraph])
                cell?.textField?.attributedStringValue = attr
            } else {
                cell?.textField?.stringValue = str
            }

        case "stringValueColumnID":
            cell?.textField?.font = self.cellFont
            cell?.textField?.textColor = NSColor.labelColor
            
            cell?.textField?.stringValue = line?.stringValue ?? "?"

        default:
            cell?.textField?.stringValue = ""
        }
        
        return cell
    }
}

fileprivate let REQUIRE_CONSECUTIVE_SELECTION = true

extension FileLogView : NSTableViewDelegate {
    
    func tableViewSelectionDidChange(_ notification: Notification) {
        
        // Force consecutive selection if needed
        if REQUIRE_CONSECUTIVE_SELECTION {
            let sortedArr =  self.selectedRowIndexes.sorted()
            if self.selectedRowIndexes.count >= 2, let minRow = sortedArr.first, let maxRow = sortedArr.last {
                var rows : IndexSet = []
                for index in minRow...maxRow {
                    rows.update(with: index)
                }
                if rows != self.selectedRowIndexes {
                    self.selectRowIndexes(rows, byExtendingSelection: true)
                    return
                }
            }
        }
        
        // Notify obsrvers
        observers.enumerateOnMainThread { observer in
            observer.fileLogView(self, didSelectRows: self.selectedRowIndexes)
        }
    }
}
