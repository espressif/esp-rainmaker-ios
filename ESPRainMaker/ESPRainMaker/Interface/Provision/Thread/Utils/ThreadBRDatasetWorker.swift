// Copyright 2024 Espressif Systems
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
//  ThreadBRDatasetWorker.swift
//  ESPRainMaker
//

class ThreadBRDatasetWorker {
    
    static let shared = ThreadBRDatasetWorker()
    
    let activeTimestampTag: UInt8 = 14
    let delayTimerTag: UInt8 = 52
    
    private init() {}
    
    /// Extract TLV value for a given tag
    /// - Parameters:
    ///   - tag: tag
    ///   - data: dataset
    /// - Returns: TLV value for tag
    func extractTLVValue(byTag tag: UInt8, from data: Data) -> Data? {
        var index = 0
        while index < data.count {
            guard index + 2 < data.count else { return nil }
            let currentTag = data[index]
            let length = Int(data[index + 1])
            let valueStartIndex = index + 2
            
            if currentTag == tag {
                let valueRange = valueStartIndex..<valueStartIndex + length
                guard data.count >= valueRange.upperBound else { return nil }
                return data.subdata(in: valueRange)
            }
            
            index = valueStartIndex + length
        }
        return nil
    }
    
    /// Get active timestamp
    /// - Parameter dataset: dataset
    /// - Returns: timestamp
    func getActiveTimestamp(fromThreadDataset dataset: Data) -> UInt64? {
        guard let timestampData = extractTLVValue(byTag: activeTimestampTag, from: dataset) else {
            return nil
        }
        return timestampData.withUnsafeBytes { $0.load(as: UInt64.self).bigEndian }
    }
    
    /// Should the homepod active dataset be update before merge
    /// - Parameters:
    ///   - homepodDataset: homepod dataset
    ///   - espDataset: esp thread BR dataset
    /// - Returns: should update
    func shouldUpdateHomepodDataset(homepodDataset: Data, espDataset: Data) -> (shouldUpdate: Bool, timestampDifference: UInt64) {
        if let homepodActiveTimestamp = getActiveTimestamp(fromThreadDataset: homepodDataset), let espActiveTimestamp = getActiveTimestamp(fromThreadDataset: espDataset) {
            if homepodActiveTimestamp > espActiveTimestamp {
                return (true, 0)
            } else {
                return (false, espActiveTimestamp - homepodActiveTimestamp)
            }
        }
        return (false, 0)
    }
    
    /// Add delay timer
    /// - Parameters:
    ///   - data: active dataset
    ///   - delay: delay
    func addDelayTimer(to data: inout Data, delay: UInt32) {
        var delayBigEndian = delay.bigEndian
        data.append(delayTimerTag) // Append the Delay Timer tag
        data.append(4) // Length of Delay Timer (4 bytes for UInt32)
        withUnsafeBytes(of: &delayBigEndian) { bytes in
            data.append(contentsOf: bytes)
        }
    }
    
    /// Increase homepod timestamp
    /// - Parameters:
    ///   - data: active dataset
    ///   - value: value to be added to homepod active dataset
    func increaseHomepodActiveTimestamp(in data: inout Data, byValue value: UInt64) {
        // Extract the current timestamp data
        guard let timestampData = extractTLVValue(byTag: activeTimestampTag, from: data) else {
            return
        }
        
        // Convert the extracted timestamp data to UInt64
        var currentTimestamp: UInt64 = timestampData.withUnsafeBytes { $0.load(as: UInt64.self).bigEndian }
        
        // Increase the timestamp by the given value
        currentTimestamp += value
        
        // Prepare the updated timestamp data
        var updatedTimestampData = Data()
        updatedTimestampData.append(contentsOf: withUnsafeBytes(of: currentTimestamp.bigEndian) { Data($0) })
        
        // Find the range of the old timestamp in the dataset
        guard let range = findTLVRange(byTag: activeTimestampTag, in: data) else {
            return
        }
        
        // Replace the old timestamp data with the updated timestamp data
        data.replaceSubrange(range, with: updatedTimestampData)
    }
    
    // Helper method to find the range of the TLV data for a specific tag
    private func findTLVRange(byTag tag: UInt8, in data: Data) -> Range<Data.Index>? {
        var index = 0
        while index < data.count {
            guard index + 2 < data.count else { return nil }
            let currentTag = data[index]
            let length = Int(data[index + 1])
            let valueStartIndex = index + 2
            
            if currentTag == tag {
                let valueRange = valueStartIndex..<valueStartIndex + length
                guard data.count >= valueRange.upperBound else { return nil }
                return index..<valueStartIndex + length
            }
            
            index = valueStartIndex + length
        }
        return nil
    }
}
