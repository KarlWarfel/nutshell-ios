//
//  MenuAccountSettingsViewController.swift
//  Nutshell
//
//  Created by Larry Kenyon on 9/14/15.
//  Copyright © 2015 Tidepool. All rights reserved.
//

import UIKit

class MenuAccountSettingsViewController: UIViewController, UITextViewDelegate {

    @IBOutlet weak var loginAccount: UILabel!
    @IBOutlet weak var versionString: NutshellUILabel!
    @IBOutlet weak var usernameLabel: NutshellUILabel!
    @IBOutlet weak var sidebarView: UIView!
    @IBOutlet weak var healthKitSwitch: UISwitch!
    @IBOutlet weak var healthKitLabel: NutshellUILabel!
    
    @IBOutlet weak var privacyTextField: UITextView!
    
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
    }
    
    @IBAction func supportButtonHandler(sender: AnyObject) {
        let email = "support@tidepool.org"
        let url = NSURL(string: "mailto:\(email)")
        UIApplication.sharedApplication().openURL(url!)
    }

    func menuWillOpen() {
        // Late binding here because profile fetch occurs after login complete!
        usernameLabel.text = NutDataController.controller().userFullName
        healthKitSwitch.on = HealthKitManager.sharedInstance.authorizationRequestedForWorkoutSamples()
        healthKitSwitch.hidden = !AppDelegate.workoutInterfaceEnabled
        healthKitLabel.hidden = !AppDelegate.workoutInterfaceEnabled
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func logOutTapped(sender: AnyObject) {
        APIConnector.connector().trackMetric("Clicked Log Out (Hamburger)")
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        appDelegate.logout()
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

    @IBAction func done(segue: UIStoryboardSegue) {
        print("unwind segue to menuaccount done!")
    }

    @IBAction func enableHealthData(sender: AnyObject) {
        if let enableSwitch = sender as? UISwitch {
            if enableSwitch.on {
                observeHealthData(true)
            } else {
                observeHealthData(false)
            }
        }
    }
    
    private func observeHealthData(observe: Bool) {
        if (HealthKitManager.sharedInstance.isHealthDataAvailable) {
            if #available(iOS 9, *) {
                if observe {
                    HealthKitManager.sharedInstance.authorize(shouldAuthorizeBloodGlucoseSamples: false, shouldAuthorizeWorkoutSamples: true) {
                        success, error -> Void in
                        if (error == nil) {
                            NutDataController.controller().monitorForWorkoutData(true)
                            NSUserDefaults.standardUserDefaults().setBool(true, forKey: "workoutSamplingEnabled")
                            NSUserDefaults.standardUserDefaults().synchronize()
                        } else {
                            NSLog("Error authorizing health data \(error), \(error!.userInfo)")
                        }
                    }
                } else {
                    NutDataController.controller().monitorForWorkoutData(false)
                    NSUserDefaults.standardUserDefaults().setBool(false, forKey: "workoutSamplingEnabled")
                    NSUserDefaults.standardUserDefaults().synchronize()
                }
            }
        }
    }

    //
    // MARK: - UITextView delegate
    //
    
    // Intercept links in order to track metrics...
    func textView(textView: UITextView, shouldInteractWithURL URL: NSURL, inRange characterRange: NSRange) -> Bool {
        if URL.absoluteString.containsString("privacy-policy") {
            APIConnector.connector().trackMetric("Clicked privacy (Hamburger)")
        } else {
            APIConnector.connector().trackMetric("Clicked Terms of Use (Hamburger)")
        }
        return true
    }
    
}
