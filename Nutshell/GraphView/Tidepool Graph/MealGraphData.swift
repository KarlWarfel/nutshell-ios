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

class MealGraphDataType: GraphDataType {
    
    var isMainEvent: Bool = false
    var id: String?
    var rectInGraph: CGRect = CGRectZero
    
    init(timeOffset: NSTimeInterval, isMain: Bool, event: Meal) {
        self.isMainEvent = isMain
        // id needed if user taps on this item...
        if let eventId = event.id as? String {
            self.id = eventId
        } else {
            // historically may be nil...
            self.id = nil
        }
        super.init(timeOffset: timeOffset)
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

    //
    // MARK: - Loading data
    //

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
                    
                    //kbw  filter out bgl values
                    if (mealEvent.title!.lowercaseString.rangeOfString("🧀") != nil)
                        ||
                        (mealEvent.title!.lowercaseString.rangeOfString("💉novalog fast insulin") != nil)
                    {
                    let deltaTime = eventTime.timeIntervalSinceDate(startTime)
                    var isMainEvent = false
                    isMainEvent = mealEvent.time == layout.mainEventTime
                    dataArray.append(MealGraphDataType(timeOffset: deltaTime, isMain: isMainEvent, event: mealEvent))
                    }
                }
            }
        } catch let error as NSError {
            NSLog("Error: \(error)")
        }
        //NSLog("loaded \(dataArray.count) meal events")
    }
 
    //
    // MARK: - Drawing data points
    //

    override func drawDataPointAtXOffset(xOffset: CGFloat, dataPoint: GraphDataType) {
        
        var isMain = false
        if let mealDataType = dataPoint as? MealGraphDataType {
            isMain = mealDataType.isMainEvent

            // eventLine Drawing
            let lineColor = isMain ? kMealLineColor : kOtherMealColor
            let triangleColor = isMain ? kMealTriangleColor : kOtherMealColor
            let lineHeight: CGFloat = isMain ? layout.yBottomOfMeal - layout.yTopOfMeal : layout.headerHeight
            let lineWidth: CGFloat = isMain ? 2.0 : 1.0
            
            let rect = CGRect(x: xOffset, y: layout.yTopOfMeal, width: lineWidth, height: lineHeight)
            let eventLinePath = UIBezierPath(rect: rect)
            lineColor.setFill()
            eventLinePath.fill()
            
            let trianglePath = UIBezierPath()
            let centerX = rect.origin.x + lineWidth/2.0
            let triangleSize: CGFloat = kMealTriangleTopWidth
            let triangleOrgX = centerX - triangleSize/2.0
            
            //kbw change direction of triangle 
            var triangleDirection: CGFloat = -1.0
            let tempEvent = DatabaseUtils.getNutEventItemWithId(mealDataType.id!)
            if tempEvent!.title!.lowercaseString.rangeOfString("💉novalog fast insulin") != nil {
                triangleDirection = 1.0
                //testSize = (viewPixelsPerSec)*2.5*60.0*60.0
            }
            
            //kbw build traingle
            var centerOfHeader: CGFloat = 16.5
            var centerOffset: CGFloat = 4*triangleDirection
            var baseOfTriangle = centerOfHeader + centerOffset
            //test new triangle creation
            //base center of triangle
            trianglePath.moveToPoint(CGPoint(x: triangleOrgX, y: baseOfTriangle))
            //base edge to the right
            
            //kbw add line
            trianglePath.addLineToPoint(CGPoint(x: triangleOrgX , y: baseOfTriangle))
            trianglePath.addLineToPoint(CGPoint(x: triangleOrgX , y: baseOfTriangle+1.0*triangleDirection))
            trianglePath.addLineToPoint(CGPoint(x: triangleOrgX, y: baseOfTriangle+1.0*triangleDirection))
            trianglePath.addLineToPoint(CGPoint(x: triangleOrgX, y: baseOfTriangle))
            
            trianglePath.addLineToPoint(CGPoint(x: triangleOrgX + triangleSize, y: baseOfTriangle))
            //apex other left edge
            trianglePath.addLineToPoint(CGPoint(x: triangleOrgX + triangleSize/2.0, y: baseOfTriangle+(baseOfTriangle-centerOffset)*CGFloat(triangleDirection)))
            //base edge
            trianglePath.addLineToPoint(CGPoint(x: triangleOrgX, y: baseOfTriangle))
            
            
            //old triangle 
/*
            trianglePath.moveToPoint(CGPointMake(triangleOrgX, 0.0))
            trianglePath.addLineToPoint(CGPointMake(triangleOrgX + triangleSize, 0.0))
            trianglePath.addLineToPoint(CGPointMake(triangleOrgX + triangleSize/2.0, 13.5))
            trianglePath.addLineToPoint(CGPointMake(triangleOrgX, 0))
*/
            
            
            trianglePath.closePath()
            trianglePath.miterLimit = 4;
            trianglePath.usesEvenOddFillRule = true;
            triangleColor.setFill()
            trianglePath.fill()
            
            if !isMain {
                let mealHitAreaWidth: CGFloat = max(triangleSize, 30.0)
                let mealRect = CGRect(x: centerX - mealHitAreaWidth/2.0, y: 0.0, width: mealHitAreaWidth, height: lineHeight)
                mealDataType.rectInGraph = mealRect
            }
        }
    }
    
    // override to handle taps - return true if tap has been handled
    override func tappedAtPoint(point: CGPoint) -> GraphDataType? {
        for dataPoint in dataArray {
            if let mealDataPoint = dataPoint as? MealGraphDataType {
                if mealDataPoint.rectInGraph.contains(point) {
                    return mealDataPoint
                }
            }
        }
        return nil
    }

}
