//
//  File.swift
//  
//
//  Created by Nickolay Truhin on 10.03.2021.
//

import Foundation

extension Array {

    /**
     Returns a new array with the first elements up to specified distance being shifted to the end of the collection. If the distance is negative, returns a new array with the last elements up to the specified absolute distance being shifted to the beginning of the collection.

     If the absolute distance exceeds the number of elements in the array, the elements are not shifted.
     */
    func shift(withDistance distance: Int = 1) -> Array<Element> {
        let offsetIndex = distance >= 0 ?
            self.index(startIndex, offsetBy: distance, limitedBy: endIndex) :
            self.index(endIndex, offsetBy: distance, limitedBy: startIndex)

        guard let index = offsetIndex else { return self }
        return Array(self[index ..< endIndex] + self[startIndex ..< index])
    }
}
