/*
* Copyright (c) 2015, Tidepool Project
*
* This program is free software; you can redistribute it and/or modify it under
* the terms of the associated License, which is identical to the BSD 2-Clause
* License as published by the Open Source Initiative at opensource.org.
*
* This program is distributed in the hope that it will be useful, but WITHOUT
* ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
* FOR A PARTICULAR PURPOSE. See the License for more details.
*
* You should have received a copy of the License along with this program; if
* not, you can obtain one from Tidepool Project at tidepool.org.
*/

import UIKit

/// Continuous Blood Glucose readings vary between sub-100 to over 340 (we clip them there).
/// CbgGraphDataType is a single-value type, so no additional data is needed.

class MealGraphDataType: GraphDataType {
    
    var isMainEvent: Bool = false
    
    convenience init(timeOffset: NSTimeInterval, isMain: Bool) {
        self.init(timeOffset: timeOffset)
        isMainEvent = isMain
    }
    
    override func typeString() -> String {
        return "meal"
    }

}

class MealGraphDataLayer: GraphDataLayer {

    var layout: TidepoolGraphLayout

    init(viewSize: CGSize, timeIntervalForView: NSTimeInterval, startTime: NSDate, layout: TidepoolGraphLayout) {
        self.layout = layout
        super.init(viewSize: viewSize, timeIntervalForView: timeIntervalForView, startTime: startTime)
    }

    // Meal config constants
    let kMealLineColor = Styles.blackColor
    let kMealTriangleColor = Styles.darkPurpleColor
    let kOtherMealColor = UIColor(hex: 0x948ca3)
    let kMealTriangleTopWidth: CGFloat = 15.5
    
    override func loadDataItems() {
        dataArray = []
        let endTime = startTime.dateByAddingTimeInterval(timeIntervalForView)
        let timeExtensionForDataFetch = NSTimeInterval(kMealTriangleTopWidth/viewPixelsPerSec)
        let earlyStartTime = startTime.dateByAddingTimeInterval(-timeExtensionForDataFetch)
        let lateEndTime = endTime.dateByAddingTimeInterval(timeExtensionForDataFetch)
        do {
            let events = try DatabaseUtils.getMealEvents(earlyStartTime, toTime: lateEndTime)
            for mealEvent in events {
                if let eventTime = mealEvent.time {
                    let deltaTime = eventTime.timeIntervalSinceDate(startTime)
                    var isMainEvent = false
                    isMainEvent = mealEvent.time == layout.mainEventTime
                    dataArray.append(MealGraphDataType(timeOffset: deltaTime, isMain: isMainEvent))
                }
            }
        } catch let error as NSError {
            NSLog("Error: \(error)")
        }
        NSLog("loaded \(dataArray.count) meal events")
    }
    
    // override!
    override func drawDataPointAtXOffset(xOffset: CGFloat, dataPoint: GraphDataType, graphDraw: GraphingUtils) {
        
        var isMain = false
        if let mealDataType = dataPoint as? MealGraphDataType {
            isMain = mealDataType.isMainEvent
        }

        // eventLine Drawing
        let lineColor = isMain ? kMealLineColor : kOtherMealColor
        let triangleColor = isMain ? kMealTriangleColor : kOtherMealColor
        let lineHeight: CGFloat = isMain ? cellViewSize.height : layout.headerHeight
        let lineWidth: CGFloat = isMain ? 2.0 : 1.0
        
        let rect = CGRect(x: xOffset, y: 0.0, width: lineWidth, height: lineHeight)
        let eventLinePath = UIBezierPath(rect: rect)
        lineColor.setFill()
        eventLinePath.fill()
        
        let trianglePath = UIBezierPath()
        let centerX = rect.origin.x + lineWidth/2.0
        let triangleSize: CGFloat = kMealTriangleTopWidth
        let triangleOrgX = centerX - triangleSize/2.0
        trianglePath.moveToPoint(CGPointMake(triangleOrgX, 0.0))
        trianglePath.addLineToPoint(CGPointMake(triangleOrgX + triangleSize, 0.0))
        trianglePath.addLineToPoint(CGPointMake(triangleOrgX + triangleSize/2.0, 13.5))
        trianglePath.addLineToPoint(CGPointMake(triangleOrgX, 0))
        trianglePath.closePath()
        trianglePath.miterLimit = 4;
        trianglePath.usesEvenOddFillRule = true;
        triangleColor.setFill()
        trianglePath.fill()
    }
}