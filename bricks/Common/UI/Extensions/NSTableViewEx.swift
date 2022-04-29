//
//  NSTableViewEx.swift
//  Bricks
//
//  Created by Ido on 06/04/2022.
//

import AppKit

/*
protocol NSTableViewClickableDelegate: NSTableViewDelegate {
    func tableView(_ tableView: NSTableView, didClickRow row: Int, didClickColumn: Int)
}

extension NSTableView {
    open override func mouseDown(with event: NSEvent) {
        let localLocation = self.convert(event.locationInWindow, to: nil)
        let clickedRow = self.row(at: localLocation)
        let clickedColumn = self.column(at: localLocation)

        super.mouseDown(with: event)

        guard clickedRow >= 0, clickedColumn >= 0, let delegate = self.delegate as? NSTableViewClickableDelegate else {
            return
        }

        delegate.tableView(self, didClickRow: clickedRow, didClickColumn: clickedColumn)
    }
}
*/
