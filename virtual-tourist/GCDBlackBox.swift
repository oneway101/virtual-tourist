//
//  GCDBlackBox.swift
//  virtual-tourist
//
//  Created by Ha Na Gill on 3/23/17.
//  Copyright © 2017 Ha Na Gill. All rights reserved.
//

import Foundation

func performUIUpdatesOnMain(_ updates: @escaping () -> Void) {
    DispatchQueue.main.async {
        updates()
    }
}
