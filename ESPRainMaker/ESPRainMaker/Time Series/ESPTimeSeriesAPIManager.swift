// Copyright 2022 Espressif Systems
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
//  ESPTimeSeriesAPIManager.swift
//  ESPRainMaker
//

import Foundation

class ESPTimeSeriesAPIManager {
    
    var atleastOnce = true
    
    let tsDataURL = Configuration.shared.awsConfiguration.baseURL + "/" + Constants.apiVersion + "/user/nodes/tsdata"
    lazy var apiManager = ESPAPIManager()
    var dataSource: ESPTSDataList?
    
    /// Method to fetch time series data using API.
    ///
    /// - Parameters:
    ///   - nodeID: Node ID of device whose params data need to be fetched.
    ///   - paramName: Name of device parameter.
    ///   - dataType: Type of data (Integer & Float are currently supported.)
    ///   - aggregate: Aggregate for a certain time duration like avgerage, minimum, maximum , etc.
    ///   - timeInterval: Time interval aggregate like hour, day, week , etc.
    ///   - startTime: Timestamp for start of duration.
    ///   - endTime: Timestamp for end of duration.
    ///   - weekStart: Day of week that will be considered as start of the week.
    ///   - completionHandler: Callback method that is invoked in case request is succesfully processed or fails in between.
    func fetchTSDataFor(nodeID: String, paramName: String, dataType:String? = nil, aggregate: String? = nil, timeInterval: String? = nil, startTime: UInt? = nil, endTime: UInt? = nil, weekStart: String? = nil, completionHandler: @escaping (ESPTSData?, ESPNetworkError?) -> Void ) {
        
        var url = tsDataURL + "?node_id=\(nodeID)&param_name=\(paramName)"
        if let aggregate = aggregate {
            url.append("&aggregate=\(aggregate)")
        }
        if let timeInterval = timeInterval {
            url.append("&aggregation_interval=\(timeInterval)")
        }
        if let startTime = startTime {
            url.append("&start_time=\(startTime)")
        }
        if let endTime = endTime {
            url.append("&end_time=\(endTime)")
        }
        if let weekStart = weekStart {
            url.append("&week_start=\(weekStart)")
        }
        if let dataType = dataType {
            switch dataType {
            case "float","int":
                url.append("&type=\(dataType)")
            default:
                completionHandler(nil,.serverError("Data type not supported."))
                return
            }
        }
        url.append("&timezone=\(TimeZone.current.identifier)")
        
        let urlString = url.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
        
        apiManager.genericAuthorizedDataRequest(url: urlString ?? url, parameter: nil, method: .get) { response, error in
            guard let result = ESPTSData.decoder(data: response) else {
                completionHandler(nil, error)
                return
            }
            if let nextID = result.next_id {
                self.fetchNextRecordSet(url: urlString ?? url, nodeID: nodeID, paramName: paramName, startID: nextID, tsData: result, completionHandler: completionHandler)
            } else {
                completionHandler(result, nil)
            }
        }
    }
    
    
    private func fetchNextRecordSet(url: String, nodeID: String, paramName: String, startID: String, tsData: ESPTSData, completionHandler: @escaping (ESPTSData?, ESPNetworkError?) -> Void) {
        let urlString = url + "&start_id=\(startID)"
        apiManager.genericAuthorizedDataRequest(url: urlString, parameter: nil, method: .get) { response, error in
            guard let result = ESPTSData.decoder(data: response) else {
                completionHandler(tsData, nil)
                return
            }
            var joinedTSData = tsData
            joinedTSData.params?[0].values?.append(contentsOf: result.params?[0].values ?? [])
            if let nextID = result.next_id {
                self.fetchNextRecordSet(url: url, nodeID: nodeID, paramName: paramName, startID: nextID, tsData: joinedTSData, completionHandler: completionHandler)
            } else {
                completionHandler(joinedTSData, nil)
            }
        }
    }
}
