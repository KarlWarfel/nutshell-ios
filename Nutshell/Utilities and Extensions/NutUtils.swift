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
import CoreData
import Photos

class NutUtils {

    class func onIPad() -> Bool {
        return UIDevice.currentDevice().userInterfaceIdiom == .Pad
    }

    class func dispatchBoolToVoidAfterSecs(secs: Float, result: Bool, boolToVoid: (Bool) -> (Void)) {
        let time = dispatch_time(DISPATCH_TIME_NOW, Int64(secs * Float(NSEC_PER_SEC)))
        dispatch_after(time, dispatch_get_main_queue()){
            boolToVoid(result)
        }
    }
    
    class func delay(delay:Double, closure:()->()) {
        dispatch_after(
            dispatch_time(
                DISPATCH_TIME_NOW,
                Int64(delay * Double(NSEC_PER_SEC))
            ),
            dispatch_get_main_queue(), closure)
    }
    
    class func compressImage(image: UIImage) -> UIImage {
        var actualHeight : CGFloat = image.size.height
        var actualWidth : CGFloat = image.size.width
        let maxHeight : CGFloat = 600.0
        let maxWidth : CGFloat = 800.0
        var imgRatio : CGFloat = actualWidth/actualHeight
        let maxRatio : CGFloat = maxWidth/maxHeight
        let compressionQuality : CGFloat = 0.5 //50 percent compression
        
        if ((actualHeight > maxHeight) || (actualWidth > maxWidth)){
            if(imgRatio < maxRatio){
                //adjust height according to maxWidth
                imgRatio = maxWidth / actualWidth;
                actualHeight = imgRatio * actualHeight;
                actualWidth = maxWidth;
            }
            else{
                actualHeight = maxHeight;
                actualWidth = maxWidth;
            }
        }
        
        let rect = CGRectMake(0.0, 0.0, actualWidth, actualHeight)
        UIGraphicsBeginImageContext(rect.size)
        image.drawInRect(rect)
        let img : UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        let imageData = UIImageJPEGRepresentation(img, compressionQuality)
        UIGraphicsEndImageContext()
        NSLog("Compressed length: \(imageData!.length)")
        return UIImage(data: imageData!)!
    }
    
    class func photosDirectoryPath() -> String? {
        let path = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0]
        var photoDirPath: String? = path + "/photos/" + NutDataController.controller().currentUserId! + "/"
        
        let fm = NSFileManager.defaultManager()
        var dirExists = false
        do {
            _ = try fm.contentsOfDirectoryAtPath(photoDirPath!)
            //NSLog("Photos dir: \(dirContents)")
            dirExists = true
        } catch let error as NSError {
            NSLog("Need to create dir at \(photoDirPath), error: \(error)")
        }
        
        if !dirExists {
            do {
                try fm.createDirectoryAtPath(photoDirPath!, withIntermediateDirectories: true, attributes: nil)
            } catch let error as NSError {
                NSLog("Failed to create dir at \(photoDirPath), error: \(error)")
                photoDirPath = nil
            }
        }
        return photoDirPath
    }
    
    class func urlForNewPhoto() -> String {
        let baseFilename = "file_" + NSUUID().UUIDString + ".jpg"
        return baseFilename
    }

    class func filePathForPhoto(photoUrl: String) -> String? {
        if let dirPath = NutUtils.photosDirectoryPath() {
            return dirPath + photoUrl
        }
        return nil
    }
    
    class func deleteLocalPhoto(url: String) {
        if url.hasPrefix("file_") {
            if let filePath = filePathForPhoto(url) {
                let fm = NSFileManager.defaultManager()
                do {
                    try fm.removeItemAtPath(filePath)
                    NSLog("Deleted photo: \(url)")
                } catch let error as NSError {
                    NSLog("Failed to delete photo at \(filePath), error: \(error)")
                }
            }
        }
    }

    class func photoInfo(url: String) -> String {
        var result = "url: " + url
        if url.hasPrefix("file_") {
            if let filePath = filePathForPhoto(url) {
                let fm = NSFileManager.defaultManager()
                do {
                    let fileAttributes = try fm.attributesOfItemAtPath(filePath)
                    result += "size: " + String(fileAttributes[NSFileSize])
                    result += "created: " + String(fileAttributes[NSFileCreationDate])
                } catch let error as NSError {
                    NSLog("Failed to get attributes for file \(filePath), error: \(error)")
                }
            }
        }
        return result
    }
    
    class func loadImage(url: String, imageView: UIImageView) {
        if let image = UIImage(named: url) {
            imageView.image = image
            imageView.hidden = false
        } else if url.hasPrefix("file_") {
            if let filePath = filePathForPhoto(url) {
                let image = UIImage(contentsOfFile: filePath)
                if let image = image {
                    imageView.hidden = false
                    imageView.image = image
                } else {
                    NSLog("Failed to load photo from local file: \(url)!")
                }
            }
        } else {
            if let nsurl = NSURL(string:url) {
                let fetchResult = PHAsset.fetchAssetsWithALAssetURLs([nsurl], options: nil)
                if let asset = fetchResult.firstObject as? PHAsset {
                    // TODO: move this to file system! Would need current event to update it as well!
                    var targetSize = imageView.frame.size
                    // bump up resolution...
                    targetSize.height *= 2.0
                    targetSize.width *= 2.0
                    let options = PHImageRequestOptions()
                    PHImageManager.defaultManager().requestImageForAsset(asset, targetSize: targetSize, contentMode: PHImageContentMode.AspectFit, options: options) {
                        (result, info) in
                        if let result = result {
                            imageView.hidden = false
                            imageView.image = result
                        }
                    }
                }
            }
        }
    }

    class func dateFromJSON(json: String?) -> NSDate? {
        if let json = json {
            var result = jsonDateFormatter.dateFromString(json)
            if result == nil {
                result = jsonAltDateFormatter.dateFromString(json)
            }
            return result
        }
        return nil
    }
    
    class func dateToJSON(date: NSDate) -> String {
        return jsonDateFormatter.stringFromDate(date)
    }

    class func decimalFromJSON(json: String?) -> NSDecimalNumber? {
        if let json = json {
            return NSDecimalNumber(string: json)
        }
        return nil
    }

    /** Date formatter for JSON date strings */
    class var jsonDateFormatter : NSDateFormatter {
        struct Static {
            static let instance: NSDateFormatter = {
                let dateFormatter = NSDateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
                dateFormatter.timeZone = NSTimeZone(name: "GMT")
                return dateFormatter
                }()
        }
        return Static.instance
    }
    
    class var jsonAltDateFormatter : NSDateFormatter {
        struct Static {
            static let instance: NSDateFormatter = {
                let dateFormatter = NSDateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
                dateFormatter.timeZone = NSTimeZone(name: "GMT")
                return dateFormatter
            }()
        }
        return Static.instance
    }

    
    /** Date formatter for date strings in the UI */
    private class var dateFormatter : NSDateFormatter {
        struct Static {
            static let instance: NSDateFormatter = {
                let df = NSDateFormatter()
                df.dateFormat = Styles.uniformDateFormat
                return df
            }()
        }
        return Static.instance
    }

    // NOTE: these date routines are not localized, and do not take into account user preferences for date display.

    /// Call setFormatterTimezone to set time zone before calling standardUIDayString or standardUIDateString
    class func setFormatterTimezone(timezoneOffsetSecs: Int) {
        let df = NutUtils.dateFormatter
        df.timeZone = NSTimeZone(forSecondsFromGMT:timezoneOffsetSecs)
    }
    
    /// Returns delta time different due to a different daylight savings time setting for a date different from the current time, assuming the location-based time zone is the same as the current default.
    class func dayLightSavingsAdjust(dateInPast: NSDate) -> Int {
        let thisTimeZone = NSTimeZone.localTimeZone()
        let dstOffsetForThisDate = thisTimeZone.daylightSavingTimeOffsetForDate(NSDate())
        let dstOffsetForPickerDate = thisTimeZone.daylightSavingTimeOffsetForDate(dateInPast)
        let dstAdjust = dstOffsetForPickerDate - dstOffsetForThisDate
        return Int(dstAdjust)
    }
    
    /// Returns strings like "Mar 17, 2016", "Today", "Yesterday"
    /// Note: call setFormatterTimezone before this!
    class func standardUIDayString(date: NSDate) -> String {
        let df = NutUtils.dateFormatter
        df.dateFormat = "MMM d, yyyy"
        var dayString = df.stringFromDate(date)
        // If this year, remove year.
        df.dateFormat = ", yyyy"
        let thisYearString = df.stringFromDate(NSDate())
        dayString = dayString.stringByReplacingOccurrencesOfString(thisYearString, withString: "")
        // Replace with today, yesterday if appropriate: only check if it's in the last 48 hours
        // TODO: look at using NSCalendar.startOfDayForDate and then time intervals to determine today, yesterday, Saturday, etc., back a week.
        if (date.timeIntervalSinceNow > -48 * 60 * 60) {
            if NSCalendar.currentCalendar().isDateInToday(date) {
                dayString = "Today"
            } else if NSCalendar.currentCalendar().isDateInYesterday(date) {
                dayString = "Yesterday"
            }
        }
        return dayString
    }
    
    /// Returns strings like "Yesterday at 9:17 am"
    /// Note: call setFormatterTimezone before this!
    class func standardUIDateString(date: NSDate) -> String {
        let df = NutUtils.dateFormatter
        let dayString = NutUtils.standardUIDayString(date)
        // Figure the hour/minute part...
        df.dateFormat = "h:mm a"
        var hourString = df.stringFromDate(date)
        // Replace uppercase PM and AM with lowercase versions
        hourString = hourString.stringByReplacingOccurrencesOfString("PM", withString: "pm", options: NSStringCompareOptions.LiteralSearch, range: nil)
        hourString = hourString.stringByReplacingOccurrencesOfString("AM", withString: "am", options: NSStringCompareOptions.LiteralSearch, range: nil)
        //kbw add delta hours 
        var hoursAgo = Float(trunc(Float(date.timeIntervalSinceNow/(60.0*60.0))*10.0)/10.0)
        if (hoursAgo < -24.0) {
            //hoursAgo = hoursAgo/24.0
           // hoursAgo = Double(Int(hoursAgo*10)/10.0)
            hourString += "    \(Float(trunc(Float(hoursAgo/24.0 )*10.0)/10.0)) days ago "
        }
        else
        {
            hourString += "    \(Float(trunc(Float(hoursAgo)*10.0)/10.0)) hours ago "
        }
        return dayString + " at " + hourString
    }
    
    
    //kbw to add text to a cell - for extra information
    class func addOnText() -> String{
        // use cases
        // new food - fast or digesting state?
        // new bgl - avg 7, 30 day, avg tod 7, 30 std dev 7, 30
        // existing nut event - food insulin exercise BGL before and after, (slope delta BGL per hour
        // existing nut event - bgl iob? timesincenow  
        
        return "test"
    }
    //kbw add function to add on text for bgl measurements
    class func addOnTextBGL(date: NSDate) -> String {
        let beforeBGLpoint = self.beforeSMBG(date);
        let afterBGLpoint  = self.afterSMBG(date.dateByAddingTimeInterval(1.0*60.0*60.0));
        let afterafterBGLpoint = self.afterSMBG(date.dateByAddingTimeInterval(2.5*60*60.0));
        let averageBGLpoint = self.averageSMBG(date, startDate: date.dateByAddingTimeInterval(-7.0*24*60*60.0), endDate: date)
        var directionString = "\u{2198}";
        if(beforeBGLpoint < afterBGLpoint) {directionString = "\u{2197}";}
        
        let addOnTextString = "\n\(directionString) " + (NSString(format: "%3d to \t%3d,%3d     \t%3.2fAvg ",Int(beforeBGLpoint),Int(afterBGLpoint), Int(afterafterBGLpoint),averageBGLpoint) as String)
        //future:  add in delta and del / hour as well as flaging if it is moveing in the right direction and too much or too little insulin / correction.  
        //future: advanced display averae and STDev for the past 7, 30 days as well as abg and stddev TOD for the past 7,30 days
        
        return addOnTextString
    }
    
    
    
    //kbw todo refactor to just find a bgl at the closest of an interval?
    //kbw find the SMBG before the time
    class func beforeSMBG(date: NSDate) ->Double {
        //find smbg before date,
        
        let earlyStartTime = date.dateByAddingTimeInterval(-12.0*60.0*60.0); //loadStartTime()
        let lateEndTime = date.dateByAddingTimeInterval(-0.0);//0.1*60.0*60.0);
        var convertedValue = CGFloat(85);
        convertedValue = closestSMBG(date, startDate: earlyStartTime , endDate: lateEndTime);
  
        //return value and time?
        return Double(convertedValue)
    }
    
    //kbw find the SMBG after the time
    class func afterSMBG(date: NSDate) ->Double {
        //return value and time?
        //find smbg before date,
        
        let earlyStartTime = date.dateByAddingTimeInterval(0.1*60.0*60.0); //loadStartTime()
        let lateEndTime = date.dateByAddingTimeInterval(12.0*60.0*60.0);
        var convertedValue = CGFloat(85);
        convertedValue = closestSMBG(date, startDate: earlyStartTime , endDate: lateEndTime);
  
        //return value and time?
        return Double(convertedValue)
       
    }
    
    //build function to retunr the closed bGL to a date between two dates
    class func closestSMBG(centerDate: NSDate ,startDate: NSDate, endDate: NSDate)->CGFloat{
        
        var convertedValue = CGFloat(85);
        var deltaTime = 99999999.0
        do {
            let events = try DatabaseUtils.getTidepoolEvents(startDate, thruTime: endDate, objectTypes: ["smbg"])//[typeString()])
            
            for event in events {
                if let event = event as? CommonData {
                    if let eventTime = event.time {
                        if (abs(eventTime.timeIntervalSinceDate(centerDate))<deltaTime){
                            deltaTime=abs(eventTime.timeIntervalSinceDate(centerDate))
                            
                            if let smbgEvent = event as? SelfMonitoringGlucose {
                                //NSLog("Adding smbg event: \(event)")
                                if let value = smbgEvent.value {
                                    let kGlucoseConversionToMgDl = CGFloat(18.0)
                                    convertedValue = round(CGFloat(value) * kGlucoseConversionToMgDl)
                                    NSLog("\(convertedValue) \(eventTime) ")
                                    //dataArray.append(CbgGraphDataType(value: convertedValue, timeOffset: timeOffset))
                                } else {
                                    NSLog("ignoring smbg event with nil value")
                                }
                            }
                        }
                    }
                }
            }
        } catch let error as NSError {
            NSLog("Error: \(error)")
        }
        
        //return value and time?
        return convertedValue
        
        
    }
    
    
    //build function to retunr the average BGL to a date between two dates
    class func averageSMBG(centerDate: NSDate ,startDate: NSDate, endDate: NSDate)->CGFloat{
        
        var convertedValue = CGFloat(85);
        var deltaTime = 99999999.0
        var count = 0;
        var totalSMBG = CGFloat(0.0);
        do {
            let events = try DatabaseUtils.getTidepoolEvents(startDate, thruTime: endDate, objectTypes: ["smbg"])//[typeString()])
            
            for event in events {
                if let event = event as? CommonData {
                    if let eventTime = event.time {
                        if (abs(eventTime.timeIntervalSinceDate(centerDate))<deltaTime){
                            deltaTime=abs(eventTime.timeIntervalSinceDate(centerDate))
                            
                            if let smbgEvent = event as? SelfMonitoringGlucose {
                                //NSLog("Adding smbg event: \(event)")
                                if let value = smbgEvent.value {
                                    let kGlucoseConversionToMgDl = CGFloat(18.0)
                                    convertedValue = round(CGFloat(value) * kGlucoseConversionToMgDl)
                                    NSLog("\(convertedValue) \(eventTime) ")
                                    count = count+1;
                                    totalSMBG = totalSMBG+convertedValue
                                    //dataArray.append(CbgGraphDataType(value: convertedValue, timeOffset: timeOffset))
                                } else {
                                    NSLog("ignoring smbg event with nil value")
                                }
                            }
                        }
                    }
                }
            }
        } catch let error as NSError {
            NSLog("Error: \(error)")
        }
        
        //return value and time?
        return totalSMBG/CGFloat(count) //convertedValue
        
        
    }
    
    
    //kbw add fasing hour method that return a well forwatted string 
    class func fastingHoursText(date: NSDate) -> String{
        
        let fastingHoursTime = NutUtils.fastingHours(date)
        var fastingIcon = ""
        if (fastingHoursTime>0){
            if fastingHoursTime > 10.0 {
                fastingIcon = "\u{1F374} " //fork and knife
            }
            if fastingHoursTime > 24.0 {
                fastingIcon = "\u{1F37D} " //fork and knife and plate
            }
            return NSString(format: "%@Fasting hours: %3.1f",fastingIcon,fastingHoursTime) as String
        }
        else{
            return NSString(format: "Digesting food %3.1f hours ago",fastingHoursTime) as String
        }
        
        
        
    }
    
    //kbw add function to return hours fasting
    class func fastingHours(date: NSDate) -> Double{
        //dataArray = []
        let maxFast = -7.0*24.0*60.0*60.0
//        let endTime = date  //.dateByAddingTimeInterval(timeIntervalForView)
//        let timeExtensionForDataFetch = NSTimeInterval(kMealTriangleTopWidth/viewPixelsPerSec)
        let earlyStartTime = date.dateByAddingTimeInterval(maxFast)
        let lateEndTime = date.dateByAddingTimeInterval(-1.0)  //endTime.dateByAddingTimeInterval(timeExtensionForDataFetch)
        var fastingTime = maxFast
        do {
            let events = try DatabaseUtils.getMealEvents(earlyStartTime, toTime: lateEndTime)
            for mealEvent in events {
                if let eventTime = mealEvent.time {
                    
                    //kbw  filter out bgl values
                    if (mealEvent.title!.lowercaseString.rangeOfString("🧀") != nil)
                    {
                        let deltaTime = eventTime.timeIntervalSinceDate(date)
                        if (deltaTime > fastingTime) {fastingTime=deltaTime}
                    }
                    NSLog("\(mealEvent.title) \(fastingTime)")
                }
            }
        } catch let error as NSError {
            NSLog("Error: \(error)")
        }
        //NSLog("loaded \(dataArray.count) meal events")
       return -1.0*(fastingTime+(4.0*60.0*60.0))/(60.0*60.0)
    }
    
    
}
