//
//  MenuAccountSettingsViewController.swift
//  Nutshell
//
//  Created by Larry Kenyon on 9/14/15.
//  Copyright © 2015 Tidepool. All rights reserved.
//

import UIKit
import CocoaLumberjack

class MenuAccountSettingsViewController: UIViewController, UITextViewDelegate {

    @IBOutlet weak var loginAccount: UILabel!
    @IBOutlet weak var versionString: NutshellUILabel!
    @IBOutlet weak var usernameLabel: NutshellUILabel!
    @IBOutlet weak var sidebarView: UIView!
    @IBOutlet weak var healthKitSwitch: UISwitch!
    @IBOutlet weak var healthKitLabel: NutshellUILabel!
    @IBOutlet weak var healthStatusContainerView: UIStackView!
    @IBOutlet weak var healthStatusLine1: UILabel!
    @IBOutlet weak var healthStatusLine2: UILabel!
    @IBOutlet weak var healthStatusLine3: UILabel!
    
    @IBOutlet weak var privacyTextField: UITextView!
    var hkTimeRefreshTimer: NSTimer?
    private let kHKTimeRefreshInterval: NSTimeInterval = 300.0

    //
    // MARK: - Base Methods
    //

    override func viewDidLoad() {
        super.viewDidLoad()
        let curService = APIConnector.connector().currentService!
        if curService == "Production" {
            versionString.text = "V" + UIApplication.appVersion()
        } else{
            versionString.text = "V" + UIApplication.appVersion() + " on " + curService
        }
        loginAccount.text = NutDataController.controller().currentUserName
        //let attributes = [NSUnderlineStyleAttributeName: NSUnderlineStyle.StyleSingle.rawValue]
 
        let str = "Privacy and Terms of Use"
        let paragraphStyle = NSParagraphStyle.defaultParagraphStyle().mutableCopy() as! NSMutableParagraphStyle
        paragraphStyle.alignment = .Center
        let attributedString = NSMutableAttributedString(string:str, attributes:[NSFontAttributeName: Styles.mediumVerySmallSemiboldFont, NSForegroundColorAttributeName: Styles.blackColor, NSParagraphStyleAttributeName: paragraphStyle])
        attributedString.addAttribute(NSLinkAttributeName, value: NSURL(string: "http://developer.tidepool.io/privacy-policy/")!, range: NSRange(location: 0, length: 7))
        attributedString.addAttribute(NSLinkAttributeName, value: NSURL(string: "http://developer.tidepool.io/terms-of-use/")!, range: NSRange(location: attributedString.length - 12, length: 12))
        privacyTextField.attributedText = attributedString
        privacyTextField.delegate = self

        let notificationCenter = NSNotificationCenter.defaultCenter()
        notificationCenter.addObserver(self, selector: #selector(MenuAccountSettingsViewController.handleUploaderNotification(_:)), name: HealthKitDataUploader.Notifications.Updated, object: nil)
        
        //kbw test 
        //NutUtils.generateCSV()
    }

    deinit {
        let nc = NSNotificationCenter.defaultCenter()
        nc.removeObserver(self, name: nil, object: nil)
        hkTimeRefreshTimer?.invalidate()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func menuWillOpen() {
        // Late binding here because profile fetch occurs after login complete!
        // Treat this like viewWillAppear...
        usernameLabel.text = NutDataController.controller().userFullName
        
        configureHKInterface()
    }
    
    //
    // MARK: - Navigation
    //

    @IBAction func done(segue: UIStoryboardSegue) {
        print("unwind segue to menuaccount done!")
    }

    //
    // MARK: - Button/switch handling
    //
    
    @IBAction func supportButtonHandler(sender: AnyObject) {
        APIConnector.connector().trackMetric("Clicked Tidepool Support (Hamburger)")
        let email = "support@tidepool.org"
        let url = NSURL(string: "mailto:\(email)")
        UIApplication.sharedApplication().openURL(url!)
    }
    
    
    @IBAction func logOutTapped(sender: AnyObject) {
        APIConnector.connector().trackMetric("Clicked Log Out (Hamburger)")
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        appDelegate.logout()
    }
    
    //
    // MARK: - Healthkit Methods
    //
    
    @IBAction func enableHealthData(sender: AnyObject) {
        if let enableSwitch = sender as? UISwitch {
            if enableSwitch.on {
                enableHealthKitInterfaceForCurrentUser()
            } else {
                NutDataController.controller().disableHealthKitInterface()
            }
            configureHKInterface()
        }
    }

    private func startHKTimeRefreshTimer() {
        if hkTimeRefreshTimer == nil {
            hkTimeRefreshTimer = NSTimer.scheduledTimerWithTimeInterval(kHKTimeRefreshInterval, target: self, selector: #selector(MenuAccountSettingsViewController.nextHKTimeRefresh), userInfo: nil, repeats: true)
        }
    }

    func stopHKTimeRefreshTimer() {
        hkTimeRefreshTimer?.invalidate()
        hkTimeRefreshTimer = nil
    }

    func nextHKTimeRefresh() {
        DDLogInfo("nextHKTimeRefresh")
        configureHKInterface()
    }
    
    internal func handleUploaderNotification(notification: NSNotification) {
        DDLogInfo("handleUploaderNotification: \(notification.name)")
        configureHKInterface()
    }

    private func configureHKInterface() {
        // Late binding here because profile fetch occurs after login complete!
        usernameLabel.text = NutDataController.controller().userFullName
        let hkCurrentEnable = appHealthKitConfiguration.healthKitInterfaceEnabledForCurrentUser()
        healthKitSwitch.on = hkCurrentEnable
        if hkCurrentEnable {
            self.configureHealthStatusLines()
            // make sure timer is turned on to prevent a stale interface...
            startHKTimeRefreshTimer()
        } else {
            stopHKTimeRefreshTimer()
        }
        
        var hideHealthKitUI = false
        // Note: Right now this is hard-wired true
        if !AppDelegate.healthKitUIEnabled {
            hideHealthKitUI = true
        }
        // The isDSAUser variable only becomes valid after user profile fetch, so if it is not set, assume true. Otherwise use it as main control of whether we show the HealthKit UI.
        if let isDSAUser = NutDataController.controller().isDSAUser {
            if !isDSAUser {
                hideHealthKitUI = true
            }
        }
        healthKitSwitch.hidden = hideHealthKitUI
        healthKitLabel.hidden = hideHealthKitUI
        healthStatusContainerView.hidden = hideHealthKitUI || !hkCurrentEnable
    }
    
    private func enableHealthKitInterfaceForCurrentUser() {
        if appHealthKitConfiguration.healthKitInterfaceConfiguredForOtherUser() {
            // use dialog to confirm delete with user!
            let curHKUserName = appHealthKitConfiguration.healthKitUserTidepoolUsername() ?? "Unknown"
            //let curUserName = usernameLabel.text!
            let titleString = "Are you sure?"
            let messageString = "A different account (" + curHKUserName + ") is currently associated with Health Data on this device"
            let alert = UIAlertController(title: titleString, message: messageString, preferredStyle: .Alert)
            alert.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: { Void in
                self.healthKitSwitch.on = false
                return
            }))
            alert.addAction(UIAlertAction(title: "Change Account", style: .Default, handler: { Void in
                NutDataController.controller().enableHealthKitInterface()
            }))
            self.presentViewController(alert, animated: true, completion: nil)
        } else {
            NutDataController.controller().enableHealthKitInterface()
        }
    }
    
    let healthKitUploadStatusMostRecentSamples: String = "Uploading last 14 days of Dexcom data\u{2026}"
    let healthKitUploadStatusUploadPausesWhenPhoneIsLocked: String = "FYI upload pauses when phone is locked"
    let healthKitUploadStatusDaysUploaded: String = "%d of %d days"
    let healthKitUploadStatusUploadingCompleteHistory: String = "Uploading complete history of Dexcom data"
    let healthKitUploadStatusLastUploadTime: String = "Last reading %@"
    let healthKitUploadStatusNoDataAvailableToUpload: String = "No data available to upload"
    let healthKitUploadStatusDexcomDataDelayed3Hours: String = "Dexcom data from Health is delayed 3 hours"

    private func configureHealthStatusLines() {
        let hkDataUploader = HealthKitDataUploader.sharedInstance
        var phase = hkDataUploader.uploadPhaseBloodGlucoseSamples
        
        // if we haven't actually uploaded a first historical sample, act like we're still doing most recent samples...
        if phase == .HistoricalSamples && hkDataUploader.totalDaysHistoricalBloodGlucoseSamples == 0 {
            phase = .MostRecentSamples
        }

        switch phase {
        case .MostRecentSamples:
            healthStatusLine1.text = healthKitUploadStatusMostRecentSamples
            healthStatusLine2.text = healthKitUploadStatusUploadPausesWhenPhoneIsLocked
            healthStatusLine3.text = ""
        case .HistoricalSamples:
            healthStatusLine1.text = healthKitUploadStatusUploadingCompleteHistory
            var healthKitUploadStatusDaysUploadedText = ""
            if hkDataUploader.totalDaysHistoricalBloodGlucoseSamples > 0 {
                healthKitUploadStatusDaysUploadedText = String(format: healthKitUploadStatusDaysUploaded, hkDataUploader.currentDayHistoricalBloodGlucoseSamples, hkDataUploader.totalDaysHistoricalBloodGlucoseSamples)
            }
            healthStatusLine2.text = healthKitUploadStatusDaysUploadedText
            healthStatusLine3.text = healthKitUploadStatusUploadPausesWhenPhoneIsLocked
        case .CurrentSamples:
            if hkDataUploader.totalUploadCountBloodGlucoseSamples > 0 {
                let lastUploadTimeAgoInWords = hkDataUploader.lastUploadTimeBloodGlucoseSamples.timeAgoInWords(NSDate())
                healthStatusLine1.text = String(format: healthKitUploadStatusLastUploadTime, lastUploadTimeAgoInWords)
            } else {
                healthStatusLine1.text = healthKitUploadStatusNoDataAvailableToUpload
            }
            healthStatusLine2.text = healthKitUploadStatusDexcomDataDelayed3Hours
            healthStatusLine3.text = ""
        }
        //kbw over ride text for reporting
        healthStatusLine1.text = NSString(format: "\u{00B5} BGL:\t%3.1f/ %3.2f/ %3.2f\n\u{03C3} BGL:\t%3.1f/ %3.2f/ %3.2f",
                                          NutUtils.averageSMBG(NSDate(), startDate: NSDate().dateByAddingTimeInterval(-7.0*24.0*60.0*60.0), endDate: NSDate()),
                                          NutUtils.averageSMBG(NSDate(), startDate: NSDate().dateByAddingTimeInterval(-30.0*24.0*60.0*60.0), endDate: NSDate()),
                                          NutUtils.averageSMBG(NSDate(), startDate: NSDate().dateByAddingTimeInterval(-90.0*24.0*60.0*60.0), endDate: NSDate()),
                                          NutUtils.standardDeviationSMBG(NSDate(), startDate: NSDate().dateByAddingTimeInterval(-7.0*24.0*60.0*60.0), endDate: NSDate().dateByAddingTimeInterval(1.0*24.0*60.0*60.0)),
                                          NutUtils.standardDeviationSMBG(NSDate(), startDate: NSDate().dateByAddingTimeInterval(-30.0*24.0*60.0*60.0), endDate: NSDate()),
                                          NutUtils.standardDeviationSMBG(NSDate(), startDate: NSDate().dateByAddingTimeInterval(-90.0*24.0*60.0*60.0), endDate: NSDate())
            ) as String
        
        let cal = NSCalendar(calendarIdentifier: NSCalendarIdentifierGregorian )!
        let newCal = cal.startOfDayForDate(NSDate())
        let newDate = newCal.dateByAddingTimeInterval(0)
        //kbw add dynamic seperators so it is easy to see what time bin we are in
        var ts1 = "|"
        var ts2 = "|"
        var ts3 = "|"
        var ts4 = "|"
        var ts5 = "|"
        
        let date = NSDate()
        var hour = 0
        let calendar = NSCalendar.currentCalendar()
        if #available(iOS 8.0, *) {
            calendar.getHour(&hour, minute: nil, second: nil, nanosecond: nil, fromDate: date)
        }
        
        
        switch hour {
        case 2,3,4,5:
            ts1 = "▪️ "
        case 6,7,8,9:
            ts1 = " ▪️"
            ts2 = "▪️ "
        case 10,11,12,13:
            ts2 = " ▪️"
            ts3 = "▪️ "
        case 14,15,16,17:
            ts3 = " ▪️"
            ts4 = "▪️ "
        case 18,19,20,21:
            ts4 = " ▪️"
            ts5 = "▪️ "
        case 22,23,0,1:
            ts5 = " ▪️"
           
            
        default:
            
                ts1 = "|"
                ts2 = "|"
                ts3 = "|"
                ts4 = "|"
                ts5 = "|"
            
        }// switch statements
 // copy to a func and reduce to onepass
        healthStatusLine2.text =  NSString(format: "\n%3.1f\(ts1)%3.1f\(ts2)%3.1f\(ts3)%3.1f\(ts4)%3.1f\(ts5)%3.1f\n%3.1f\(ts1)%3.1f\(ts2)%3.1f\(ts3)%3.1f\(ts4)%3.1f\(ts5)%3.1f\n",
                                           NutUtils.averageSMBGTOD(newCal.dateByAddingTimeInterval(+4.0*60.0*60.0), startDate: NSDate().dateByAddingTimeInterval(-30.0*24.0*60.0*60.0), endDate: NSDate().dateByAddingTimeInterval(1.0*24.0*60.0*60.0)),
                                           NutUtils.averageSMBGTOD(newCal.dateByAddingTimeInterval(+8.0*60.0*60.0), startDate: NSDate().dateByAddingTimeInterval(-30.0*24.0*60.0*60.0), endDate: NSDate().dateByAddingTimeInterval(1.0*24.0*60.0*60.0)),
                                           NutUtils.averageSMBGTOD(newCal.dateByAddingTimeInterval(+12.0*60.0*60.0), startDate: NSDate().dateByAddingTimeInterval(-30.0*24.0*60.0*60.0), endDate: NSDate().dateByAddingTimeInterval(1.0*24.0*60.0*60.0)),
                                           NutUtils.averageSMBGTOD(newCal.dateByAddingTimeInterval(+16.0*60.0*60.0), startDate: NSDate().dateByAddingTimeInterval(-30.0*24.0*60.0*60.0), endDate: NSDate().dateByAddingTimeInterval(1.0*24.0*60.0*60.0)),
                                           NutUtils.averageSMBGTOD(newCal.dateByAddingTimeInterval(+20.0*60.0*60.0), startDate: NSDate().dateByAddingTimeInterval(-30.0*24.0*60.0*60.0), endDate: NSDate().dateByAddingTimeInterval(1.0*24.0*60.0*60.0)),
                                           NutUtils.averageSMBGTOD(newCal.dateByAddingTimeInterval(+24.0*60.0*60.0), startDate: NSDate().dateByAddingTimeInterval(-30.0*24.0*60.0*60.0), endDate: NSDate().dateByAddingTimeInterval(1.0*24.0*60.0*60.0)),
                                           
                                           NutUtils.standardDeviationSMBGTOD(newCal.dateByAddingTimeInterval(+4.0*60.0*60.0), startDate: NSDate().dateByAddingTimeInterval(-30.0*24.0*60.0*60.0), endDate: NSDate().dateByAddingTimeInterval(1.0*24.0*60.0*60.0)),
                                           NutUtils.standardDeviationSMBGTOD(newCal.dateByAddingTimeInterval(+8.0*60.0*60.0), startDate: NSDate().dateByAddingTimeInterval(-30.0*24.0*60.0*60.0), endDate: NSDate().dateByAddingTimeInterval(1.0*24.0*60.0*60.0)),
                                           NutUtils.standardDeviationSMBGTOD(newCal.dateByAddingTimeInterval(+12.0*60.0*60.0), startDate: NSDate().dateByAddingTimeInterval(-30.0*24.0*60.0*60.0), endDate: NSDate().dateByAddingTimeInterval(1.0*24.0*60.0*60.0)),
                                           NutUtils.standardDeviationSMBGTOD(newCal.dateByAddingTimeInterval(+16.0*60.0*60.0), startDate: NSDate().dateByAddingTimeInterval(-30.0*24.0*60.0*60.0), endDate: NSDate().dateByAddingTimeInterval(1.0*24.0*60.0*60.0)),
                                           NutUtils.standardDeviationSMBGTOD(newCal.dateByAddingTimeInterval(+20.0*60.0*60.0), startDate: NSDate().dateByAddingTimeInterval(-30.0*24.0*60.0*60.0), endDate: NSDate().dateByAddingTimeInterval(1.0*24.0*60.0*60.0)),
                                           NutUtils.standardDeviationSMBGTOD(newCal.dateByAddingTimeInterval(+24.0*60.0*60.0), startDate: NSDate().dateByAddingTimeInterval(-30.0*24.0*60.0*60.0), endDate: NSDate().dateByAddingTimeInterval(1.0*24.0*60.0*60.0))
            )as String
 
 /*
            
            NSString(format: "Average ToD BGL: \t%3.1f/ %3.2f\nStdDev ToD BGL:  \t%3.1f/ %3.2f\n%3.1f\(ts1)%3.1f\(ts2)%3.1f\(ts3)%3.1f\(ts4)%3.1f\(ts5)%3.1f\n%3.1f\(ts1)%3.1f\(ts2)%3.1f\(ts3)%3.1f\(ts4)%3.1f\(ts5)%3.1f\n",
                                          NutUtils.averageSMBGTOD(NSDate().dateByAddingTimeInterval(+2.0*60.0*60.0), startDate: NSDate().dateByAddingTimeInterval(-7.0*24.0*60.0*60.0), endDate: NSDate().dateByAddingTimeInterval(1.0*24.0*60.0*60.0)),
                                          NutUtils.averageSMBGTOD(NSDate().dateByAddingTimeInterval(+2.0*60.0*60.0), startDate: NSDate().dateByAddingTimeInterval(-30.0*24.0*60.0*60.0), endDate: NSDate().dateByAddingTimeInterval(1.0*24.0*60.0*60.0)),
                                          NutUtils.standardDeviationSMBGTOD(NSDate().dateByAddingTimeInterval(+2.0*60.0*60.0), startDate: NSDate().dateByAddingTimeInterval(-7.0*24.0*60.0*60.0), endDate: NSDate().dateByAddingTimeInterval(1.0*24.0*60.0*60.0)),
                                          NutUtils.standardDeviationSMBGTOD(NSDate().dateByAddingTimeInterval(+2.0*60.0*60.0), startDate: NSDate().dateByAddingTimeInterval(-30.0*24.0*60.0*60.0), endDate: NSDate().dateByAddingTimeInterval(1.0*24.0*60.0*60.0)),
                                          
                                          NutUtils.averageSMBGTOD(newCal.dateByAddingTimeInterval(+4.0*60.0*60.0), startDate: NSDate().dateByAddingTimeInterval(-30.0*24.0*60.0*60.0), endDate: NSDate().dateByAddingTimeInterval(1.0*24.0*60.0*60.0)),
                                          NutUtils.averageSMBGTOD(newCal.dateByAddingTimeInterval(+8.0*60.0*60.0), startDate: NSDate().dateByAddingTimeInterval(-30.0*24.0*60.0*60.0), endDate: NSDate().dateByAddingTimeInterval(1.0*24.0*60.0*60.0)),
                                          NutUtils.averageSMBGTOD(newCal.dateByAddingTimeInterval(+12.0*60.0*60.0), startDate: NSDate().dateByAddingTimeInterval(-30.0*24.0*60.0*60.0), endDate: NSDate().dateByAddingTimeInterval(1.0*24.0*60.0*60.0)),
                                          NutUtils.averageSMBGTOD(newCal.dateByAddingTimeInterval(+16.0*60.0*60.0), startDate: NSDate().dateByAddingTimeInterval(-30.0*24.0*60.0*60.0), endDate: NSDate().dateByAddingTimeInterval(1.0*24.0*60.0*60.0)),
                                          NutUtils.averageSMBGTOD(newCal.dateByAddingTimeInterval(+20.0*60.0*60.0), startDate: NSDate().dateByAddingTimeInterval(-30.0*24.0*60.0*60.0), endDate: NSDate().dateByAddingTimeInterval(1.0*24.0*60.0*60.0)),
                                          NutUtils.averageSMBGTOD(newCal.dateByAddingTimeInterval(+24.0*60.0*60.0), startDate: NSDate().dateByAddingTimeInterval(-30.0*24.0*60.0*60.0), endDate: NSDate().dateByAddingTimeInterval(1.0*24.0*60.0*60.0)),
                                          
                                          NutUtils.standardDeviationSMBGTOD(newCal.dateByAddingTimeInterval(+4.0*60.0*60.0), startDate: NSDate().dateByAddingTimeInterval(-30.0*24.0*60.0*60.0), endDate: NSDate().dateByAddingTimeInterval(1.0*24.0*60.0*60.0)),
                                          NutUtils.standardDeviationSMBGTOD(newCal.dateByAddingTimeInterval(+8.0*60.0*60.0), startDate: NSDate().dateByAddingTimeInterval(-30.0*24.0*60.0*60.0), endDate: NSDate().dateByAddingTimeInterval(1.0*24.0*60.0*60.0)),
                                          NutUtils.standardDeviationSMBGTOD(newCal.dateByAddingTimeInterval(+12.0*60.0*60.0), startDate: NSDate().dateByAddingTimeInterval(-30.0*24.0*60.0*60.0), endDate: NSDate().dateByAddingTimeInterval(1.0*24.0*60.0*60.0)),
                                          NutUtils.standardDeviationSMBGTOD(newCal.dateByAddingTimeInterval(+16.0*60.0*60.0), startDate: NSDate().dateByAddingTimeInterval(-30.0*24.0*60.0*60.0), endDate: NSDate().dateByAddingTimeInterval(1.0*24.0*60.0*60.0)),
                                          NutUtils.standardDeviationSMBGTOD(newCal.dateByAddingTimeInterval(+20.0*60.0*60.0), startDate: NSDate().dateByAddingTimeInterval(-30.0*24.0*60.0*60.0), endDate: NSDate().dateByAddingTimeInterval(1.0*24.0*60.0*60.0)),
                                          NutUtils.standardDeviationSMBGTOD(newCal.dateByAddingTimeInterval(+24.0*60.0*60.0), startDate: NSDate().dateByAddingTimeInterval(-30.0*24.0*60.0*60.0), endDate: NSDate().dateByAddingTimeInterval(1.0*24.0*60.0*60.0))
            )as String
 
 */
        
         healthStatusLine3.text = "" //NutUtils.fastingHoursText(NSDate())//NSString(format: "Fasting hours: %3.1f",NutUtils.fastingHours(NSDate())) as String
        //kbw moved fasting time to quick status
    }
    
    //
    // MARK: - UITextView delegate
    //
    
    // Intercept links in order to track metrics...
    func textView(textView: UITextView, shouldInteractWithURL URL: NSURL, inRange characterRange: NSRange) -> Bool {
        if URL.absoluteString!.containsString("privacy-policy") {
            APIConnector.connector().trackMetric("Clicked privacy (Hamburger)")
        } else {
            APIConnector.connector().trackMetric("Clicked Terms of Use (Hamburger)")
        }
        return true
    }
    
}
