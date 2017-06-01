//
//  NextProgramsViewController.swift
//  Bubble
//
//  Created by Harsh Fadnavis on 10/14/16.
//  Copyright © 2016 Harsh Fadnavis. All rights reserved.
//

import UIKit
import CoreData
import Kingfisher

class NextProgramsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, BubbleAPIDelegate {

    
    @IBOutlet weak var nextProgramsTableVIew: UITableView!
    
    @IBOutlet weak var loadingView: UIActivityIndicatorView!
    var channelId : String!
    
    var channelNameString: String!
    var channelNumber: String?
    var nextProgramsArray = [Any]()
    var headerProgram = [Any]()
    var bubbleDateFormat = DateFormatter()
    var dformat = DateFormatter()
    var helperView: UIView!
    var synopsis: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.nextProgramsTableVIew.delegate = self
        self.nextProgramsTableVIew.dataSource = self
        self.nextProgramsTableVIew.sectionHeaderHeight = UITableViewAutomaticDimension
        self.nextProgramsTableVIew.estimatedSectionHeaderHeight = 400
        self.nextProgramsTableVIew.rowHeight = UITableViewAutomaticDimension
        self.nextProgramsTableVIew.estimatedRowHeight = 50
        //self.nextProgramsTableVIew.bounces = false
        
        bubbleDateFormat.dateFormat = GlobalConstants.BubbleDateFormat.DATE_FORMAT
        dformat.dateFormat = GlobalConstants.BubbleDateFormat.DATE_FORMAT_AM
        dformat.amSymbol = "AM"
        dformat.pmSymbol = "PM"

//        NotificationCenter.default.addObserver(self, selector: #selector(NextProgramsViewController.handleWatchNowNotification), name: NSNotification.Name(rawValue: "watchnowbubble"), object: nil)
        
        let bubbleAPI = CallBubbleApi()
        bubbleAPI.delegate = self
        var paramstest: [String: String] = [:]
        paramstest["method"] = GlobalConstants.HttpMethodName.BUBBLE_NEXT_PROGRAMS
        paramstest["email_id"] = UserData.sharedInstance.userEmail

        let currenttime = bubbleDateFormat.string(from: Date())
        paramstest["starttime"] = currenttime
        let endtime = bubbleDateFormat.string(from: Date().addingTimeInterval(60*60*10))
        paramstest["endtime"] = endtime
        paramstest["channelid"] = self.channelId
        bubbleAPI.post(paramstest)

        if(channelNumber == nil) {
            fetchChannelNumber()
        }
        loadingView.startAnimating()
        // Do any additional setup after loading the view.
    }
    
    func fetchChannelNumber() {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.dataStoreController.inContext { context in
            guard let context = context else {
                return
            }
            let channelFetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "ChannelData")
            let channelIdPredicate = NSPredicate(format: "channelId = %@", argumentArray: [self.channelId])
            channelFetchRequest.predicate = channelIdPredicate
            do {
                if let channels = try context.fetch(channelFetchRequest) as? [Channels] {
                    self.channelNumber = channels[0].channelNumber
                }
            } catch {
            }
        }
    }
    
    
//    func handleWatchNowNotification() {
//        print("reached next programs view controller")
//    }

    func tableView(_ tableView: UITableView, estimatedHeightForHeaderInSection section: Int) -> CGFloat {
        return 400
    }
    
//    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
//        return 60
//    }
    
    
    
    func onResponseReceived(_ responseJSON: [String : AnyObject], methodName: String) {
        if let status = responseJSON["status"] as? Int {
            if status == 0 {
                setup(response: responseJSON)
            } else {
                
            }
        }
    }
    
    func onNetworkError(methodName: String) {
        loadingView.stopAnimating()
        let alert = UIAlertController(title: "Connectivity Issue", message: "Are you connected to the internet? Try again", preferredStyle: .actionSheet)
        
        let okAction = UIAlertAction(title: "Ok", style: .default) {
            (_) -> Void in
            _ = self.navigationController?.popToRootViewController(animated: true)
        }
        alert.addAction(okAction)
        self.present(alert, animated: true, completion: nil)
    }
    
    func setup(response: [String: AnyObject]) {
        let bubbleDateFormat = DateFormatter()
        bubbleDateFormat.dateFormat = GlobalConstants.BubbleDateFormat.DATE_FORMAT
        
        if let syn = response["synopsis"] as? String {
            self.synopsis = syn
        }
        
        if let channeldata = response["channelprograms"] as? [Any] {
                var first = true
                for program in channeldata {
                    //let pg = program as! [Any]
                    if let pg = program as? [Any] {
                        if first == true {
//                            headerProgram[0] = pg[0] as! String
//                            headerProgram[1] = pg[1] as! String
//                            headerProgram[2] = pg[2] as! String
//                            headerProgram[3] = pg[3] as! String
//                            headerProgram[4] = pg[4] as! String
//                            headerProgram[5] = pg[5] as! String
//                            headerProgram[6] = pg[6] as! String
//                            headerProgram[7] = String(pg[7] as! Int)
                            
                            headerProgram = pg
                            first = false
                        } else {
                            self.nextProgramsArray.append(program)
                        }
                    }
                }
            loadingView.stopAnimating()
            self.nextProgramsTableVIew.reloadData()
            if let _ = UserDefaults.standard.value(forKey: GlobalConstants.UserDefaults.UPCOMING_HELPER) {} else {
                setupHelperOverlay()
            }
        }
    }
    
    func tapHelperScreen(recognizer: UITapGestureRecognizer) {
        self.helperView.isHidden = true
        self.helperView.removeFromSuperview()
    }
    
    func setupHelperOverlay() {
        self.helperView = UIView(frame: CGRect(x: 0, y: 0, width: 320, height: 480))
        self.helperView.backgroundColor = UIColor.clear
        self.helperView.isUserInteractionEnabled = true
        
        let helperTapGesture = UITapGestureRecognizer(target: self, action: #selector(HomeMainViewController.tapHelperScreen(recognizer:)))
        self.helperView.addGestureRecognizer(helperTapGesture)
        
        self.view.addSubview(self.helperView)
        self.helperView.translatesAutoresizingMaskIntoConstraints = false
        self.view.addConstraint(NSLayoutConstraint(item: helperView, attribute: NSLayoutAttribute.trailing, relatedBy: NSLayoutRelation.equal, toItem: self.view, attribute: NSLayoutAttribute.trailing, multiplier: 1, constant: 0))
        self.view.addConstraint(NSLayoutConstraint(item: helperView, attribute: NSLayoutAttribute.bottom, relatedBy: NSLayoutRelation.equal, toItem: self.view, attribute: NSLayoutAttribute.bottom, multiplier: 1, constant: 0))
        self.view.addConstraint(NSLayoutConstraint(item: helperView, attribute: NSLayoutAttribute.leading, relatedBy: NSLayoutRelation.equal, toItem: self.view, attribute: NSLayoutAttribute.leading, multiplier: 1, constant: 0))
        self.view.addConstraint(NSLayoutConstraint(item: helperView, attribute: NSLayoutAttribute.top, relatedBy: NSLayoutRelation.equal, toItem: self.view, attribute: NSLayoutAttribute.top, multiplier: 1, constant: 0))
        
        let backgroundview = UIView(frame: CGRect(x: 0, y: 0, width: 200, height: 200))
        backgroundview.backgroundColor = UIColor.BubbleDarkIndigo()
        backgroundview.alpha = 0.6
        backgroundview.isUserInteractionEnabled = false
        self.helperView.addSubview(backgroundview)
        backgroundview.translatesAutoresizingMaskIntoConstraints = false
        self.helperView.addConstraint(NSLayoutConstraint(item: backgroundview, attribute: NSLayoutAttribute.trailing, relatedBy: NSLayoutRelation.equal, toItem: self.helperView, attribute: NSLayoutAttribute.trailing, multiplier: 1, constant: 0))
        self.helperView.addConstraint(NSLayoutConstraint(item: backgroundview, attribute: NSLayoutAttribute.bottom, relatedBy: NSLayoutRelation.equal, toItem: self.helperView, attribute: NSLayoutAttribute.bottom, multiplier: 1, constant: 0))
        self.helperView.addConstraint(NSLayoutConstraint(item: backgroundview, attribute: NSLayoutAttribute.leading, relatedBy: NSLayoutRelation.equal, toItem: self.helperView, attribute: NSLayoutAttribute.leading, multiplier: 1, constant: 0))
        self.helperView.addConstraint(NSLayoutConstraint(item: backgroundview, attribute: NSLayoutAttribute.top, relatedBy: NSLayoutRelation.equal, toItem: self.helperView, attribute: NSLayoutAttribute.top, multiplier: 1, constant: 0))
        
        
        let uicircleview1 = UIImageView(frame: CGRect(x: 0, y: 0, width: 200, height: 200))
        uicircleview1.image = UIImage(named: "circle")
        uicircleview1.isUserInteractionEnabled = false
        self.helperView.addSubview(uicircleview1)
        uicircleview1.translatesAutoresizingMaskIntoConstraints = false
        self.helperView.addConstraint(NSLayoutConstraint(item: uicircleview1, attribute: .trailing, relatedBy: .equal, toItem: self.helperView, attribute: .trailing, multiplier: 1, constant: -20))
        self.helperView.addConstraint(NSLayoutConstraint(item: uicircleview1, attribute: .top, relatedBy: .equal, toItem: self.helperView, attribute: .top, multiplier: 1, constant: 130))
        self.helperView.addConstraint(NSLayoutConstraint(item: uicircleview1, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 50))
        self.helperView.addConstraint(NSLayoutConstraint(item: uicircleview1, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 50))
        
        let arrowView1 = UIImageView(frame: CGRect(x: 0, y: 0, width: 50, height: 50))
        arrowView1.image = UIImage(named: "helperArrow2")
        arrowView1.isUserInteractionEnabled = false
        self.helperView.addSubview(arrowView1)
        arrowView1.translatesAutoresizingMaskIntoConstraints = false
        self.helperView.addConstraint(NSLayoutConstraint(item: arrowView1, attribute: .trailing, relatedBy: .equal, toItem: uicircleview1, attribute: .leading, multiplier: 1, constant: 0))
        self.helperView.addConstraint(NSLayoutConstraint(item: arrowView1, attribute: .top, relatedBy: .equal, toItem: uicircleview1, attribute: .bottom, multiplier: 1, constant: 0))
        self.helperView.addConstraint(NSLayoutConstraint(item: arrowView1, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 100))
        self.helperView.addConstraint(NSLayoutConstraint(item: arrowView1, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 38))
        
        let arrowView2 = UIImageView(frame: CGRect(x: 0, y: 0, width: 200, height: 200))
        arrowView2.image = UIImage(named: "helperArrow3")
        arrowView2.isUserInteractionEnabled = false
        self.helperView.addSubview(arrowView2)
        arrowView2.translatesAutoresizingMaskIntoConstraints = false
        self.helperView.addConstraint(NSLayoutConstraint(item: arrowView2, attribute: .trailing, relatedBy: .equal, toItem: self.helperView, attribute: .trailing, multiplier: 1, constant: -50))
        self.helperView.addConstraint(NSLayoutConstraint(item: arrowView2, attribute: .bottom, relatedBy: .equal, toItem: self.helperView, attribute: .bottom, multiplier: 1, constant: -80))
        self.helperView.addConstraint(NSLayoutConstraint(item: arrowView2, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 100))
        self.helperView.addConstraint(NSLayoutConstraint(item: arrowView2, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 67))
        
        let helperPlayText = UIImageView(frame: CGRect(x: 0, y: 0, width: 200, height: 200))
        helperPlayText.image = UIImage(named: "helperTextPlay")
        helperPlayText.isUserInteractionEnabled = false
        self.helperView.addSubview(helperPlayText)
        helperPlayText.translatesAutoresizingMaskIntoConstraints = false
        self.helperView.addConstraint(NSLayoutConstraint(item: helperPlayText, attribute: .leading, relatedBy: .equal, toItem: self.helperView, attribute: .leading, multiplier: 1, constant: 20))
        self.helperView.addConstraint(NSLayoutConstraint(item: helperPlayText, attribute: .top, relatedBy: .equal, toItem: arrowView1, attribute: .bottom, multiplier: 1, constant: 0))
        self.helperView.addConstraint(NSLayoutConstraint(item: helperPlayText, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 150))
        self.helperView.addConstraint(NSLayoutConstraint(item: helperPlayText, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 50))
        
        
        let helperReminderText = UIImageView(frame: CGRect(x: 0, y: 0, width: 200, height: 200))
        helperReminderText.image = UIImage(named: "helperTextReminder")
        helperReminderText.isUserInteractionEnabled = false
        self.helperView.addSubview(helperReminderText)
        helperReminderText.translatesAutoresizingMaskIntoConstraints = false
        self.helperView.addConstraint(NSLayoutConstraint(item: helperReminderText, attribute: .leading, relatedBy: .equal, toItem: self.helperView, attribute: .leading, multiplier: 1, constant: 20))
        self.helperView.addConstraint(NSLayoutConstraint(item: helperReminderText, attribute: .bottom, relatedBy: .equal, toItem: arrowView2, attribute: .top, multiplier: 1, constant: 0))
        self.helperView.addConstraint(NSLayoutConstraint(item: helperReminderText, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 150))
        self.helperView.addConstraint(NSLayoutConstraint(item: helperReminderText, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 50))
        
        UserDefaults.standard.set(true, forKey: GlobalConstants.UserDefaults.UPCOMING_HELPER)
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(_ animated: Bool) {
//        nextProgramsTableVIew.tableHeaderView = contentView
//        if let _ = UserDefaults.standard.value(forKey: GlobalConstants.UserDefaults.UPCOMING_HELPER) {} else {
//            setupHelperOverlay()
//        }
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if headerProgram.count != 0 {
            
        
            let headerCell = tableView.dequeueReusableCell(withIdentifier: "headernextprograms") as? NextProgramsHeaderTableViewCell
            headerCell?.programName.text = (headerProgram[1] as! String)
            headerCell?.genre.text = (headerProgram[2] as! String)
            headerCell?.synopsis.text = synopsis
            headerCell?.channelNumber  = self.channelNumber
            headerCell?.channelId = self.channelId
            if let progId = headerProgram[0] as? String {
                headerCell?.programId = progId
            } else {
                headerCell?.programId = ""
            }
            
            let imdb = (headerProgram[5] as! String)
            if imdb == "0" || imdb == "" {
                headerCell?.imdbRating.isHidden = true
            } else {
                headerCell?.imdbRating.isHidden = false
                headerCell?.imdbRating.text = "IMDB Rating: \(imdb)"
            }
            headerCell?.channelName.text = self.channelNameString
            let urlstring = GlobalConstants.BubbleAPI.BUBBLE_URL_PREFIX + "/images/channels_logo/" + self.channelId + ".png"
            let url = URL(string: urlstring)
            
            headerCell?.channelLogo.kf.setImage(with: url, placeholder: UIImage(named: "chanlogoplaceholder"), options: [.transition(.fade(0.3))])
            
            let progduration = Int(headerProgram[4] as! String)
            let minspassed = Date().minutesFrom(bubbleDateFormat.date(from: (headerProgram[3] as! String))!)
            let x = progduration! - minspassed
            if x > 0 {
                headerCell?.endsIn.text = "Ends in " + "\(x)" + " mins"
            } else {
                headerCell?.endsIn.text = "Show Ended"
            }
            
            return headerCell!
        } else {
            return nil
        }
    }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.nextProgramsArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = self.nextProgramsTableVIew.dequeueReusableCell(withIdentifier: "nextprograms", for: indexPath) as? NextProgramsTableViewCell
        if let program = self.nextProgramsArray[indexPath.row] as? [Any] {
            if let startdate = bubbleDateFormat.date(from: program[3] as! String) {
                let startdatestring = dformat.string(from: startdate)
                cell?.setTime(reminderTime: startdate)
                cell?.setProgramInfo(progId: (program[0] as? String)!, progName: (program[1] as? String)!)
                cell?.setChannelInfo(chanId: self.channelId, chanName: self.channelNameString)
                cell?.time.text = startdatestring
                cell?.name.text = program[1] as? String
                cell?.setIsReminderSet()
                cell?.setClockView()
            }
            if let genre = program[2] as? String {
                if genre != "" {
                    cell?.genre.text = genre
                } else {
                    cell?.genre.text = ""
                }
            }
        }
        
        return cell!
    }
    
    
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
