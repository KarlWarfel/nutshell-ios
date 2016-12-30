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
import Darwin

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
        let averageBGLpoint = self.averageSMBGTOD(date, startDate: date.dateByAddingTimeInterval(-7.0*24*60*60.0), endDate: date)
        var directionString = "\u{2198}";
        if(beforeBGLpoint < afterBGLpoint) {directionString = "\u{2197}";}
        
        let addOnTextString = "\n\(directionString) " +
            (NSString(format: "%3d to \t%3d,%3d     \t%3.2fAvg\n",Int(beforeBGLpoint),Int(afterBGLpoint), Int(afterafterBGLpoint),averageBGLpoint) as String)
/*            +
            (NSString(format: "\n      %3.1f/%3.1f wk/mo avg at ToD ",
                        NutUtils.averageSMBGTOD(date.dateByAddingTimeInterval(+0.0*60.0*60.0), startDate: date.dateByAddingTimeInterval(-7.0*24.0*60.0*60.0), endDate: date.dateByAddingTimeInterval(1.0*24.0*60.0*60.0)),
                        NutUtils.averageSMBGTOD(date.dateByAddingTimeInterval(+2.0*60.0*60.0), startDate: date.dateByAddingTimeInterval(-30.0*24.0*60.0*60.0), endDate: date)) as String)
*/
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
        //kbw stream lines before and after functions
//        var convertedValue = CGFloat(85);
//        convertedValue = closestSMBG(date, startDate: earlyStartTime , endDate: lateEndTime);
  
        //return value and time?
        return Double(closestSMBG(date, startDate: earlyStartTime , endDate: lateEndTime))
    }
    
    //kbw find the SMBG after the time
    class func afterSMBG(date: NSDate) ->Double {
        //return value and time?
        //find smbg before date,
        
        let earlyStartTime = date.dateByAddingTimeInterval(0.1*60.0*60.0); //loadStartTime()
        let lateEndTime = date.dateByAddingTimeInterval(12.0*60.0*60.0);
        //kbw streamlines before and after functions  
//        var convertedValue = CGFloat(85);
//        convertedValue = closestSMBG(date, startDate: earlyStartTime , endDate: lateEndTime);
  
        //return value and time?
        return Double(closestSMBG(date, startDate: earlyStartTime , endDate: lateEndTime))
       
    }
    
    //build function to retunr the closed bGL to a date between two dates
    class func closestSMBG(centerDate: NSDate ,startDate: NSDate, endDate: NSDate)->CGFloat{
        
        var convertedValue = CGFloat(999.9);
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
        
        return averageSMBGTOD(centerDate, startDate: startDate, endDate: endDate, timeWindow: 24.0)
        
/*
        
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
*/
        
    }
    
    
    //build function to retunr the average BGL to a date between two dates
    //kbw refactor to use this method, add value to expand the window - error check window
    class func averageSMBGTOD(centerDate: NSDate ,startDate: NSDate, endDate: NSDate)->CGFloat{
        
        return averageSMBGTOD(centerDate, startDate: startDate, endDate: endDate, timeWindow: 2.0)
        
/*        /
        
        var convertedValue = CGFloat(0);
        var deltaTime = 99999999.0;
        var timeWindow = 2.0;
        var count = 0;
        var totalSMBG = CGFloat(0.0);
        var minSMBG = CGFloat(-999.0);
        var maxSMBG = CGFloat(0.0);
        var sdtDev  = CGFloat(0.0);
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
                                    //NSLog("\(convertedValue) \(eventTime) ")
                                    var differenceTimeDays=centerDate.timeIntervalSinceDate(smbgEvent.time!)/(24.0*60.0*60.0)
                                    var differenceTimeHours = differenceTimeDays-Double(Int(differenceTimeDays+0.5))
                                    if (abs(differenceTimeHours)<(timeWindow/24.0)){//only could measurement within 2 hours of centerdate
                                        NSLog("CvE\(centerDate) \(smbgEvent.time)   \(differenceTimeHours)")
                                           count = count+1;
                                           totalSMBG = totalSMBG+convertedValue
                                        if (convertedValue>maxSMBG) {maxSMBG=convertedValue}
                                        if (convertedValue<minSMBG) {minSMBG=convertedValue}
                                    //dataArray.append(CbgGraphDataType(value: convertedValue, timeOffset: timeOffset))
                                    }
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
 */
    }
    
    //build function to retunr the average BGL to a date between two dates
    //kbw refactor to use this method, add value to expand the window - error check window
    class func averageSMBGTOD(centerDate: NSDate ,startDate: NSDate, endDate: NSDate, timeWindow: Double)->CGFloat{
        
        var convertedValue = CGFloat(0);
        var deltaTime = 99999999.0;
 //       var timeWindow = 2.0;
        var count = 0;
        var totalSMBG = CGFloat(0.0);
        var minSMBG = CGFloat(-999.0);
        var maxSMBG = CGFloat(0.0);
        var sdtDev  = CGFloat(0.0);
        
      
        
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
                                    //NSLog("\(convertedValue) \(eventTime) ")
                                    var differenceTimeDays=centerDate.timeIntervalSinceDate(smbgEvent.time!)/(24.0*60.0*60.0)
                                    var differenceTimeHours = differenceTimeDays-Double(Int(differenceTimeDays+0.5))
                                    if (abs(differenceTimeHours)<(timeWindow/24.0)){//only could measurement within 2 hours of centerdate
                                        NSLog("CvE\(centerDate) \(smbgEvent.time)   \(differenceTimeHours)")
                                        count = count+1;
                                        totalSMBG = totalSMBG+convertedValue
                                        if (convertedValue>maxSMBG) {maxSMBG=convertedValue}
                                        if (convertedValue<minSMBG) {minSMBG=convertedValue}
                                        //dataArray.append(CbgGraphDataType(value: convertedValue, timeOffset: timeOffset))
                                    }
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

    
    class func varianceSMBG(centerDate: NSDate ,startDate: NSDate, endDate: NSDate)->CGFloat{
        
        return varianceSMBGTOD(centerDate, startDate: startDate, endDate: endDate, timeWindow: 24.0)
    }

    
    class func varianceSMBGTOD(centerDate: NSDate ,startDate: NSDate, endDate: NSDate)->CGFloat{
        
        return varianceSMBGTOD(centerDate, startDate: startDate, endDate: endDate, timeWindow: 2.0)
        
   /*
        
        var variance = CGFloat(0.0)
        var count = CGFloat(0.0)
        var sum   = CGFloat(0.0)
        var convertedValue = CGFloat(0);
        var deltaTime = 99999999.0;
        var timeWindow = 2.0;
        var average  = self.averageSMBGTOD(centerDate, startDate: startDate, endDate: endDate)
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
                                    //NSLog("\(convertedValue) \(eventTime) ")
                                    var differenceTimeDays=centerDate.timeIntervalSinceDate(smbgEvent.time!)/(24.0*60.0*60.0)
                                    var differenceTimeHours = differenceTimeDays-Double(Int(differenceTimeDays+0.5))
                                    if (abs(differenceTimeHours)<(timeWindow/24.0)){//only could measurement within 2 hours of centerdate
                                        NSLog("CvE\(centerDate) \(smbgEvent.time)   \(differenceTimeHours)")
                                        count = count+1;
                                        sum += (convertedValue-average)*(convertedValue-average)
                                    }
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
        return sum/count 
 */
    }
 
    
    class func varianceSMBGTOD(centerDate: NSDate ,startDate: NSDate, endDate: NSDate, timeWindow: Double)->CGFloat{
        var variance = CGFloat(0.0)
        var count = CGFloat(0.0)
        var sum   = CGFloat(0.0)
        var convertedValue = CGFloat(0);
        var deltaTime = 99999999.0;
    //    var timeWindow = 2.0;
        var average  = self.averageSMBGTOD(centerDate, startDate: startDate, endDate: endDate, timeWindow: timeWindow)
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
                                    //NSLog("\(convertedValue) \(eventTime) ")
                                    var differenceTimeDays=centerDate.timeIntervalSinceDate(smbgEvent.time!)/(24.0*60.0*60.0)
                                    var differenceTimeHours = differenceTimeDays-Double(Int(differenceTimeDays+0.5))
                                    if (abs(differenceTimeHours)<(timeWindow/24.0)){//only could measurement within 2 hours of centerdate
                                        NSLog("CvE\(centerDate) \(smbgEvent.time)   \(differenceTimeHours)")
                                        count = count+1;
                                        sum += (convertedValue-average)*(convertedValue-average)
                                    }
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
        return sum/count
    }
    

    
    class func standardDeviationSMBG(centerDate: NSDate ,startDate: NSDate, endDate: NSDate)->CGFloat{
        var stdDev = CGFloat(0.0)
        var variance  = self.varianceSMBG(centerDate, startDate: startDate, endDate: endDate)
        
        return (CGFloat(Darwin.sqrt(Double(variance))))
    }
    
    class func standardDeviationSMBGTOD(centerDate: NSDate ,startDate: NSDate, endDate: NSDate)->CGFloat{
        var stdDev = CGFloat(0.0)
        var variance  = self.varianceSMBGTOD(centerDate, startDate: startDate, endDate: endDate, timeWindow: 2.0)
        
        return (CGFloat(Darwin.sqrt(Double(variance))))
    }

    class func standardDeviationSMBGTOD(centerDate: NSDate ,startDate: NSDate, endDate: NSDate, timeWindow: Double)->CGFloat{
        var stdDev = CGFloat(0.0)
        var variance  = self.varianceSMBGTOD(centerDate, startDate: startDate, endDate: endDate, timeWindow: timeWindow)
        
        return (CGFloat(Darwin.sqrt(Double(variance))))
    }

    
    
    
    //kbw add fasing hour method that return a well forwatted string 
    class func fastingHoursText(date: NSDate) -> String{
        
        let fastingHoursTime = NutUtils.fastingHours(date)
        var fastingIcon = "🚫"
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
            return NSString(format: "↗️Digesting for %3.1f hrs",fastingHoursTime+4.0) as String
        }
    }//fastingHoursText
    
    
    
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
    
    
    //kbw add function to return hours - refactor and combine with fasting hours
    class func iobHours(date: NSDate) -> Double{
        //dataArray = []
        let maxIoB = -1.0*24.0*60.0*60.0
        //        let endTime = date  //.dateByAddingTimeInterval(timeIntervalForView)
        //        let timeExtensionForDataFetch = NSTimeInterval(kMealTriangleTopWidth/viewPixelsPerSec)
        let earlyStartTime = date.dateByAddingTimeInterval(maxIoB)
        let lateEndTime = date.dateByAddingTimeInterval(+0.0*60.0*60.0)  //endTime.dateByAddingTimeInterval(timeExtensionForDataFetch)
        var iobTime = maxIoB
        do {
            let events = try DatabaseUtils.getMealEvents(earlyStartTime, toTime: lateEndTime)
            for mealEvent in events {
                if let eventTime = mealEvent.time {
                    
                    //kbw  filter out bgl values
                    if (mealEvent.title!.lowercaseString.rangeOfString("💉novalog") != nil)
                    {
                        let deltaTime = eventTime.timeIntervalSinceDate(date)
                        if (deltaTime > iobTime) {iobTime=deltaTime}
                    }
                    NSLog("\(mealEvent.title) \(iobTime)")
                }
            }
        } catch let error as NSError {
            NSLog("Error: \(error)")
        }
        //NSLog("loaded \(dataArray.count) meal events")
        return -1.0*((iobTime)/(60.0*60.0))//+(4.0*60.0*60.0))/(60.0*60.0)
    }

    
    
    
    
    //kbw a
    class func iobText(date: NSDate) -> String{
        
        let iobTime = NutUtils.iobHours(date)
        var iobIcon = "👌"
        if (iobTime<2.5){
            if iobTime > 1.5 {
                iobIcon = "❗️💉" //
            }
            else
            {
                iobIcon = "‼️💉" //syrynge
            }
            return NSString(format: "%@ IoB for %3.1f hrs",iobIcon,iobTime) as String
        }
        else{
            return NSString(format: "%@ Insulin %3.1f hrs ago",iobIcon,iobTime) as String
        }
    }//iobText
    
    
    
    
    
    //kbw add function to return hours - refactor and combine with fasting hours
    class func bglHours(date: NSDate) -> Double{
        //dataArray = []
        let maxBGL = -1.0*24.0*60.0*60.0
        //        let endTime = date  //.dateByAddingTimeInterval(timeIntervalForView)
        //        let timeExtensionForDataFetch = NSTimeInterval(kMealTriangleTopWidth/viewPixelsPerSec)
        let earlyStartTime = date.dateByAddingTimeInterval(maxBGL)
        let lateEndTime = date.dateByAddingTimeInterval(+0.0*60.0*60.0)  //endTime.dateByAddingTimeInterval(timeExtensionForDataFetch)
        var bglTime = maxBGL
        do {
            let events = try DatabaseUtils.getMealEvents(earlyStartTime, toTime: lateEndTime)
            for mealEvent in events {
                if let eventTime = mealEvent.time {
                    
                    //kbw  filter out bgl values
                    if (mealEvent.title!.lowercaseString.rangeOfString("bgl") != nil)
                    {
                        let deltaTime = eventTime.timeIntervalSinceDate(date)
                        if (deltaTime > bglTime) {bglTime=deltaTime}
                    }
                    NSLog("\(mealEvent.title) \(bglTime)")
                }
            }
        } catch let error as NSError {
            NSLog("Error: \(error)")
        }
        //NSLog("loaded \(dataArray.count) meal events")
        return -1.0*((bglTime)/(60.0*60.0))//+(4.0*60.0*60.0))/(60.0*60.0)
    }
    
    
    
    
    
    //kbw a
    class func bglText(date: NSDate) -> String{
        
        let bglTime = NutUtils.bglHours(date)
        var bglIcon = "👌"
        if (bglTime > 1.5){
            if bglTime > 2.0 {
                bglIcon = "‼️" //
            }
            else
            {
                bglIcon = "⏰" //
            }
            return NSString(format: "%@ been %3.1f hrs \n    time to check BGL",bglIcon,bglTime) as String
        }
        else{
            return NSString(format: "%@ BGL checked %3.1f hrs ago",bglIcon,bglTime) as String
        }
    }//bglText
    
    
    
    
    //kbw add function to return hours - refactor and combine with fasting hours
    class func tdd24String(date: NSDate) -> String{
        //dataArray = []
        var tddString = "  "
        var tddCount = 0
        //        let endTime = date  //.dateByAddingTimeInterval(timeIntervalForView)
        //        let timeExtensionForDataFetch = NSTimeInterval(kMealTriangleTopWidth/viewPixelsPerSec)
        let earlyStartTime = date.dateByAddingTimeInterval(-1.0*24*60*60)
        let lateEndTime = date.dateByAddingTimeInterval(+0.0*60.0*60.0)  //endTime.dateByAddingTimeInterval(timeExtensionForDataFetch)
        //var iobTime = maxIoB
        tddString=""
        do {
            let events = try DatabaseUtils.getMealEvents(earlyStartTime, toTime: lateEndTime)
            for mealEvent in events {
                if let eventTime = mealEvent.time {
                    
                    //kbw  filter out bgl values
                    if (mealEvent.title!.lowercaseString.rangeOfString("💉novalog") != nil)
                    {
                        tddCount++
                        tddString = tddString + mealEvent.notes! + "\n"
                        
                    }
                }
            }
        } catch let error as NSError {
            NSLog("Error: \(error)")
        }
        //NSLog("loaded \(dataArray.count) meal events")
        return tddString + "-\(tddCount) shots in the last 24 hours"
    }
    
    class func weekTDDString(date: NSDate) -> String{
        //dataArray = []
        var weekString = "  "
        var weekCount = 0
        //        let endTime = date  //.dateByAddingTimeInterval(timeIntervalForView)
        //        let timeExtensionForDataFetch = NSTimeInterval(kMealTriangleTopWidth/viewPixelsPerSec)
        let earlyStartTime = date.dateByAddingTimeInterval(-7.0*24*60*60)
        let lateEndTime = date.dateByAddingTimeInterval(+0.0*60.0*60.0)  //endTime.dateByAddingTimeInterval(timeExtensionForDataFetch)
        //var iobTime = maxIoB
        weekString=""
        do {
            let events = try DatabaseUtils.getMealEvents(earlyStartTime, toTime: lateEndTime)
            for mealEvent in events {
                if let eventTime = mealEvent.time {
                    
                    //kbw  filter out bgl values
                    if (mealEvent.title!.lowercaseString.rangeOfString("💉tdd") != nil)
                    {
                        weekCount++
                        weekString = weekString +
                            (NSString(format:"aBGL %3.1f\t", self.averageSMBG(mealEvent.time!, startDate: mealEvent.time!.dateByAddingTimeInterval(-1.0*24*60*60.0), endDate: mealEvent.time!)) as String) as String
                            + mealEvent.notes! + "\n"
                        
                    }
                }
            }
        } catch let error as NSError {
            NSLog("Error: \(error)")
        }
        //NSLog("loaded \(dataArray.count) meal events")
        return weekString + "-\(weekCount) days with TDD "
    }// end weekTDD

    
    
    
    
    
    
    
    
    
    class func avgSMBGToDbyHour (date :NSDate) -> String{
        
        //kbw averge 7 and 30 day 
        var convertedValue = CGFloat(0);
        var deltaTime = 99999999.0;
        //       var timeWindow = 2.0;
        var count = 0;
        var totalSMBG = CGFloat(0.0);
        var minSMBG = CGFloat(-999.0);
        var maxSMBG = CGFloat(0.0);
        var sdtDev  = CGFloat(0.0);
        
        var countArray:     [Int] = [0,0,0,0,0 ,0,0,0,0,0 ,0,0,0,0,0 ,0,0,0,0,0 ,0,0,0,0,0];
        var totalSMBGArray: [CGFloat] = [0,0,0,0,0 ,0,0,0,0,0 ,0,0,0,0,0 ,0,0,0,0,0 ,0,0,0,0,0];
        var minSMBGArray :  [CGFloat] = [-999.0,-999.0,-999.0,-999.0,-999.0,-999.0,-999.0,-999.0,-999.0,-999.0,-999.0,-999.0,-999.0,-999.0,-999.0,-999.0,-999.0,-999.0,-999.0,-999.0,-999.0,-999.0,-999.0,-999.0,-999.0,];
        var maxSMBGArray :  [CGFloat] = [0,0,0,0,0 ,0,0,0,0,0 ,0,0,0,0,0 ,0,0,0,0,0 ,0,0,0,0,0];
        var sdtDevArray  :  [CGFloat] = [0,0,0,0,0 ,0,0,0,0,0 ,0,0,0,0,0 ,0,0,0,0,0 ,0,0,0,0,0];
        var count1Star = 0
        var count2Star = 0
        var count3Star = 0
        
        var countArray30:     [Int] = [0,0,0,0,0 ,0,0,0,0,0 ,0,0,0,0,0 ,0,0,0,0,0 ,0,0,0,0,0];
        var totalSMBGArray30: [CGFloat] = [0,0,0,0,0 ,0,0,0,0,0 ,0,0,0,0,0 ,0,0,0,0,0 ,0,0,0,0,0];
        var minSMBGArray30 :  [CGFloat] = [-999.0,-999.0,-999.0,-999.0,-999.0,-999.0,-999.0,-999.0,-999.0,-999.0,-999.0,-999.0,-999.0,-999.0,-999.0,-999.0,-999.0,-999.0,-999.0,-999.0,-999.0,-999.0,-999.0,-999.0,-999.0,];
        var maxSMBGArray30 :  [CGFloat] = [0,0,0,0,0 ,0,0,0,0,0 ,0,0,0,0,0 ,0,0,0,0,0 ,0,0,0,0,0];
        var sdtDevArray30  :  [CGFloat] = [0,0,0,0,0 ,0,0,0,0,0 ,0,0,0,0,0 ,0,0,0,0,0 ,0,0,0,0,0];
        var count1Star30 = 0
        var count2Star30 = 0
        var count3Star30 = 0
        
        var countArray7:     [Int] = [0,0,0,0,0 ,0,0,0,0,0 ,0,0,0,0,0 ,0,0,0,0,0 ,0,0,0,0,0];
        var totalSMBGArray7: [CGFloat] = [0,0,0,0,0 ,0,0,0,0,0 ,0,0,0,0,0 ,0,0,0,0,0 ,0,0,0,0,0];
        var minSMBGArray7 :  [CGFloat] = [-999.0,-999.0,-999.0,-999.0,-999.0,-999.0,-999.0,-999.0,-999.0,-999.0,-999.0,-999.0,-999.0,-999.0,-999.0,-999.0,-999.0,-999.0,-999.0,-999.0,-999.0,-999.0,-999.0,-999.0,-999.0,];
        var maxSMBGArray7 :  [CGFloat] = [0,0,0,0,0 ,0,0,0,0,0 ,0,0,0,0,0 ,0,0,0,0,0 ,0,0,0,0,0];
        var sdtDevArray7  :  [CGFloat] = [0,0,0,0,0 ,0,0,0,0,0 ,0,0,0,0,0 ,0,0,0,0,0 ,0,0,0,0,0];
        var count1Star7 = 0
        var count2Star7 = 0
        var count3Star7 = 0
        
        var resultsString = ""
        let targetBGL = 83.0
        
        let presentHour = NSCalendar.currentCalendar().component(.Hour, fromDate: NSDate())
        
        
        
        do {
            let events = try DatabaseUtils.getTidepoolEvents(date.dateByAddingTimeInterval(-90.0*24.0*60.0*60), thruTime: date, objectTypes: ["smbg"])//[typeString()])
            
            for event in events {
                if let event = event as? CommonData {
                    if let eventTime = event.time {
                        if (true) //(abs(eventTime.timeIntervalSinceDate(date))<deltaTime)
                        {
                            deltaTime=abs(eventTime.timeIntervalSinceDate(date))
                            
                            if let smbgEvent = event as? SelfMonitoringGlucose {
                                //NSLog("Adding smbg event: \(event)")
                                if let value = smbgEvent.value {
                                    let kGlucoseConversionToMgDl = CGFloat(18.0)
                                    convertedValue = round(CGFloat(value) * kGlucoseConversionToMgDl)
                                    
                                    
                                    count = count+1;
                                    totalSMBG = totalSMBG+convertedValue
                                    if (convertedValue>maxSMBG) {maxSMBG=convertedValue}
                                    if (convertedValue<minSMBG) {minSMBG=convertedValue}
                                    // calc integer value of the hour
                                    let hour = NSCalendar.currentCalendar().component(.Hour, fromDate: eventTime)
                                    // use that for an array based version of the above statements
                                    countArray[hour]=countArray[hour]+1
                                    totalSMBGArray[hour] = totalSMBGArray[hour]+convertedValue
                                    
                                    if(eventTime.timeIntervalSinceNow > -30.0*24.0*60*60.0 )
                                    {
                                        countArray30[hour]=countArray30[hour]+1
                                        totalSMBGArray30[hour] = totalSMBGArray30[hour]+convertedValue
                                        if(eventTime.timeIntervalSinceNow > -7.0*24.0*60*60.0 )
                                        {
                                            countArray7[hour]=countArray7[hour]+1
                                            totalSMBGArray7[hour] = totalSMBGArray7[hour]+convertedValue
                                        }//7 day
                                    }//30 day
                                    
                                    
                                    //NSLog("\(convertedValue) \(eventTime) ")
                                    var differenceTimeDays=date.timeIntervalSinceDate(smbgEvent.time!)/(24.0*60.0*60.0)
                                    var differenceTimeHours = differenceTimeDays-Double(Int(differenceTimeDays+0.5))
                                    if (abs(differenceTimeHours)<(1.0/24.0)){//only could measurement within 2 hours of centerdate
                         //               NSLog("CvE\(centerDate) \(smbgEvent.time)   \(differenceTimeHours)")
                         //               count = count+1;
                         //               totalSMBG = totalSMBG+convertedValue
                         //               if (convertedValue>maxSMBG) {maxSMBG=convertedValue}
                         //               if (convertedValue<minSMBG) {minSMBG=convertedValue}
                                        //dataArray.append(CbgGraphDataType(value: convertedValue, timeOffset: timeOffset))
                                    }
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
        
        for (var i=0;i<24;i++){
            resultsString = resultsString + (NSString(format:"\n%dhr:",i) as String)
            if presentHour == i {
                resultsString = resultsString + "*"
            }
            
            if countArray7[i]==0 {
                resultsString = resultsString + (NSString(format:"\t%d \t\t",countArray7[i]) as String)
            }
            else
            {
                var tempCount = NSString(format: "%d",countArray7[i])
                if countArray7[i] < 3 {tempCount = (tempCount as String) + "*"}
                resultsString = resultsString + (NSString(format:"\t%@ \t%3.1f",tempCount,Double(totalSMBGArray7[i])/Double(countArray7[i])) as String)
                
                var tempBGLDelta = abs((Double(totalSMBGArray7[i])/Double(countArray7[i]))-targetBGL)
                if (tempBGLDelta<20)
                {
                    resultsString = resultsString + ""
                    if (tempBGLDelta<12)
                    {
                        resultsString = resultsString + "*"
                        count1Star7 = count1Star7+1
                        if (tempBGLDelta<6)
                        {
                            resultsString = resultsString + "*"
                            count2Star7 = count2Star7+1
                            if (tempBGLDelta<3.5)
                            {
                                resultsString = resultsString + "*"
                                count3Star7 = count3Star7+1
                            }
                            else{ // not in tightest group
                                if ((Double(totalSMBGArray7[i])/Double(countArray7[i]))-targetBGL)<0 {
                                    resultsString = resultsString + ".."
                                }
                            }
                        }
                        else{// not in 2nd tightest group
                            if ((Double(totalSMBGArray7[i])/Double(countArray7[i]))-targetBGL)<0 {
                                resultsString = resultsString + "...."
                            }
                            
                        }
                    }
                    else{// not in 3nd tightest group
                        if ((Double(totalSMBGArray7[i])/Double(countArray7[i]))-targetBGL)<0 {
                            resultsString = resultsString + "......"
                        }
                    }
                }
            }
            
            if countArray30[i]==0 {
                resultsString = resultsString + (NSString(format:"\t%d\t\t",countArray30[i]) as String)
            }
            else
            {
                resultsString = resultsString + (NSString(format:"\t|\t%3.1f",Double(totalSMBGArray30[i])/Double(countArray30[i])) as String)
                
                var tempBGLDelta = abs((Double(totalSMBGArray30[i])/Double(countArray30[i]))-targetBGL)
                if (tempBGLDelta<20)
                {
                    resultsString = resultsString + ""
                    if (tempBGLDelta<12)
                    {
                        resultsString = resultsString + "*"
                        count1Star30 += 1
                        if (tempBGLDelta<6)
                        {
                            resultsString = resultsString + "*"
                            count2Star30 += 1
                            if (tempBGLDelta<3.5)
                            {
                                resultsString = resultsString + "*"
                                count3Star30 += 1
                            }
                        }
                    }
                }
            }
            
            
            resultsString = resultsString + (NSString(format:"\t|\t%3.1f",Double(totalSMBGArray[i])/Double(countArray[i])) as String)
            
            var tempBGLDelta = abs((Double(totalSMBGArray[i])/Double(countArray[i]))-targetBGL)
            if (tempBGLDelta<20)
            {
                resultsString = resultsString + "'"
                if (tempBGLDelta<12)
                {
                    resultsString = resultsString + "'"
                    count1Star += 1
                    if (tempBGLDelta<6)
                    {
                        resultsString = resultsString + "'"
                        count2Star = count2Star+1
                        if (tempBGLDelta<3.5)
                        {
                            resultsString = resultsString + "'"
                            count3Star = count3Star+1
                        }
                    }
                }
            }


        }
    
        resultsString = resultsString + "\n" + (NSString(format: "*** \t\t%d \t\t\t%d \t\t\t%d", count3Star7,count3Star30,count3Star) as String)
        resultsString = resultsString + "\n" + (NSString(format: "**  \t\t\t%d \t\t\t%d \t\t\t%d", count2Star7,count2Star30,count2Star) as String)
        resultsString = resultsString + "\n" + (NSString(format: "*   \t\t\t%d \t\t\t%d \t\t\t%d", count1Star7,count1Star30,count1Star) as String)
        
        return resultsString
            //"\n30d: \(count) \(Double(totalSMBG)/Double(count))"+resultsString
        
 //       \nmidnight \n1am \n2am \n3am \n4am \n5am \n6am \n7am \n8am \n9am \n10am \n11am \nNoon \n1pm \n2pm \n3pm \n4pm \n5pm \n6pm \n7pm \n8pm \n9pm \n10pm \n11pm "
    }
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    class func generateCSV() -> String{
        let csvString = nutEventCSVString
        return csvString()
    }
    
    class func nutEventCSVString() -> String{
        var nutString = ""
        let date = NSDate()
        let maxFast = -356.0*24.0*60.0*60.0
        
        let earlyStartTime = date.dateByAddingTimeInterval(maxFast)
        let lateEndTime = date.dateByAddingTimeInterval(-1.0)  //
        
        do {
            let events = try DatabaseUtils.getMealEvents(earlyStartTime, toTime: lateEndTime)
            for mealEvent in events {
                if let eventTime = mealEvent.time {
                    
                    //kbw  filter out bgl values
                    //NSLog(" \(mealEvent.title!) \(mealEvent.notes!)")
                    nutString = (NSString(format: "nut event scan: %@,%@,",mealEvent.time!,mealEvent.title!,mealEvent.notes!) as String) as String
                    NSLog("\(nutString)")
                }
            }
        } catch let error as NSError {
            NSLog("Error: \(error)")
        }
        
        
        return nutString
    }
    
    
    class func  nutEventIsDue(nutEvent: NutEvent) -> Bool
    {
        var addOnText = ""
        var addOnTextExpire = ""
        var timeSinceNow=nutEvent.itemArray[nutEvent.itemArray.count-1].time.timeIntervalSinceNow
        var timeActive = 0.0
        var timeExpire = -365.0*24.0*60*60
        
        for item in nutEvent.itemArray {
            //KBW is there an activity tag?
            if item.notes.rangeOfString("#A(") != nil {
                var minInTextArr = item.notes.characters.split("(")
                var minInText = String(minInTextArr[1])
                var minInTextArr2 = minInText.characters.split(")")
                var minInTextNum = String(minInTextArr2[0])
                //[item.notes.rangeOfString("#A(")!]
                //let tempString = minInTextArr
                NSLog("**Active tag found in %@  with note \(item.notes) ",item.title)
                NSLog("  number string ")//\(String(minInTextNum))")
                ///addOnText="****Active****"
                
                //parse out time
                timeActive = -4.0 * 60.0 * 60.0
                
                //minInTextNum = "10"
                
                timeActive = -60.0*Double(minInTextNum)!
                addOnText="****Active****"
                var addOnTextArr = item.notes.characters.split("\"")
                if (addOnTextArr.count > 1) {
                    addOnText = String(addOnTextArr[1])
                }
                else
                {
                    //addOnText = String("****Active****")
                }
                //and copy add on text
                //titleLabel.textColor = UIColor.redColor()
            }//End activity tag
            
            if item.notes.rangeOfString("#D(") != nil {
                var minInTextArr = item.notes.characters.split("(")
                var minInText = String(minInTextArr[1])
                var minInTextArr2 = minInText.characters.split(")")
                var minInTextNum = String(minInTextArr2[0])
                //[item.notes.rangeOfString("#A(")!]
                //let tempString = minInTextArr
                NSLog("***DUE tag found in %@  with note \(item.notes) ",item.title)
                NSLog("  number string ")//\(String(minInTextNum))")
                ///addOnText="****Active****"
                
                //parse out time
                timeExpire = -24.0 * 60.0 * 60.0
                timeExpire = -60.0*Double(minInTextNum)!
                addOnText="****Active****"
                var addOnTextArr = item.notes.characters.split("\"")
                if (addOnTextArr.count > 1) {
                    addOnTextExpire = String(addOnTextArr[1])
                }
                else
                {
                    //addOnText = String("****Active****")
                }
                //and copy add on text
                //titleLabel.textColor = UIColor.redColor()
            }//End Due tag
            
            
            if item.notes.lowercaseString.rangeOfString("#daily") != nil {
                timeExpire = -23.5*60.0*60
                addOnTextExpire = ""
                
            }
            if item.notes.lowercaseString.rangeOfString("#weekly") != nil {
                timeExpire = -6.75*24.0*60.0*60
                addOnTextExpire = ""
            }
            
            
            //KBW Find the most recent time
            if timeSinceNow < item.time.timeIntervalSinceNow {
                timeSinceNow = item.time.timeIntervalSinceNow
                NSLog("**** found better time****")
            }
        }// loop through nut array
        
        
        
        
        NSLog(" Is the event DUE \(timeSinceNow) \(timeExpire)")
        return (timeSinceNow < (timeExpire))
    } //end of nutEventIsDue
    
}
