//
//  HomeFeedView.swift
//  Bubble
//
//  Created by Harsh Fadnavis on 9/3/16.
//  Copyright © 2016 Harsh Fadnavis. All rights reserved.
//

import UIKit
import CoreData
import Kingfisher

var recentChannels = Array<String>()
var recentChannelNumbers = Array<String>()

protocol HomeFeedLoadedDelegate : class{
    func feedLoaded()
}
class HomeFeedView : UIViewController, UITableViewDataSource, UITableViewDelegate {
    
//    lazy var refreshControl: UIRefreshControl = { [unowned self] in
//        let refreshControl = UIRefreshControl()
//        refreshControl.addTarget(self, action: #selector(HomeFeedView.handleRefresh(_:)), for: UIControlEvents.valueChanged)
//        
//        return refreshControl
//    }()
    
    let refreshControl = UIRefreshControl()
    var programData = [NSManagedObject]()
    var request = NSFetchRequest<NSFetchRequestResult>(entityName: "ProgramsNow")
    var hdMapRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "HDMap")
    var requestNext = NSFetchRequest<NSFetchRequestResult>(entityName: "ProgramsNext")
    var requestLater = NSFetchRequest<NSFetchRequestResult>(entityName: "ProgramsLater")
    var primaryKeySort = NSSortDescriptor()
    var channelNumSort = NSSortDescriptor()
    var isVisible: Bool!
    var isPosting: Bool!
    var noNetwork: Bool!
    weak var homeFeedDelegate : HomeFeedLoadedDelegate?

    
    var hdKeyData = [NSManagedObject]()
    var resultsNext = [NSManagedObject]()
    var resultsLater = [NSManagedObject]()
    var mainProgramData = [NSManagedObject]()
    let userData = UserData.sharedInstance
    var bubbleDateFormat = DateFormatter()
    var dformat = DateFormatter()
    let fetchPrograms = FetchEPGData()

    
    @IBOutlet weak var programDataTableView: UITableView!
    
    
    @IBOutlet weak var pullRefreshLabel: UILabel!
    @IBOutlet weak var loadingView: UIActivityIndicatorView!
    override func viewDidLoad() {
        super.viewDidLoad()

        programDataTableView.delegate = self
        programDataTableView.dataSource = self
        programDataTableView.rowHeight = UITableViewAutomaticDimension
        refreshControl.addTarget(self, action: #selector(HomeFeedView.handleRefresh(_:)), for: UIControlEvents.valueChanged)
        refreshControl.backgroundColor = UIColor.BubbleDarkIndigo()
        refreshControl.tintColor = UIColor.BubbleOffWhite()
        let footerView = UIView(frame: CGRect(x: 0, y: 0, width: programDataTableView.frame.size.width, height: 20))
        footerView.backgroundColor = UIColor.BubbleDarkIndigo()
        programDataTableView.tableFooterView = footerView

        if #available(iOS 10.0, *) {
            programDataTableView.refreshControl = refreshControl
        } else {
            // Fallback on earlier versions
            programDataTableView.addSubview(refreshControl)
        }
        
        noNetwork = false
        programDataTableView.estimatedRowHeight = 100
        
        dformat.dateFormat = GlobalConstants.BubbleDateFormat.DATE_FORMAT_AM
        dformat.amSymbol = "AM"
        dformat.pmSymbol = "PM"

        
        NotificationCenter.default.addObserver(self, selector: #selector(HomeFeedView.refreshTableViewData), name: Notification.Name( NotificationKeys().dataRefreshNotificationKey + self.title!), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(HomeFeedView.handleNetworkError), name: Notification.Name( NotificationKeys().NetworkErrorKey + self.title!), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(HomeFeedView.applicationDidEnterBackground), name: Notification.Name(NotificationKeys().ApplicationDidEnterBackground), object: nil)
        
        request = NSFetchRequest(entityName: "ProgramsNow")
        hdMapRequest = NSFetchRequest(entityName: "HDMap")
        requestNext = NSFetchRequest(entityName: "ProgramsNext")
        requestLater = NSFetchRequest(entityName: "ProgramsLater")
        primaryKeySort = NSSortDescriptor(key: "primaryKey", ascending: true)
        channelNumSort = NSSortDescriptor(key: "channelNum", ascending: true)
        
        // fetch program data for this user
        startFetchingProcess()

    }
    
    func startFetchingProcess() {
        var paramstest: [String: String] = [:]
        paramstest["method"] = GlobalConstants.HttpMethodName.BUBBLE_API_CURRENT_PROGRAMS
        paramstest["emailid"] = UserData.sharedInstance.userEmail
        bubbleDateFormat.dateFormat = GlobalConstants.BubbleDateFormat.DATE_FORMAT
        let currenttime = bubbleDateFormat.string(from: Date())
        paramstest["starttime"] = currenttime
        let endtime = bubbleDateFormat.string(from: Date().addingTimeInterval(60*60*10))
        paramstest["endtime"] = endtime
        if let lang = UserDefaults.standard.value(forKey: GlobalConstants.UserDefaults.RECENT_LANGUAGE) as? String {
            paramstest["language"] = lang
        } else {
            paramstest["language"] = "English"
        }
        
        paramstest["category"] = self.title!
        pullRefreshLabel.isHidden = true
        fetchPrograms.post(paramstest)
    }
    
    func applicationDidEnterBackground() {
        fetchPrograms.cancelURLTask()        
        isVisible = false
        invalidateTimer()
    }
    
    func refreshTableViewData() {
        noNetwork = false
        if(loadingView.isAnimating) {
            loadingView.stopAnimating()
        }
        initializeFetchedResultsController()
        homeFeedDelegate?.feedLoaded()
//        if(isVisible == true) {
//            
//        }
    }
    
    func handleRefresh(_ refreshControl: UIRefreshControl) {
        startFetchingProcess()        
        refreshControl.endRefreshing()
    }
    
    
    func handleNetworkError() {
        noNetwork = true
        let _ = Timer.scheduledTimer(timeInterval: 0.4, target: self, selector: #selector(HomeFeedView.showNetworkErrorAlert), userInfo: nil, repeats: false)
    }
    
    func showNetworkErrorAlert() {
        loadingView.stopAnimating()
        if(mainProgramData.count == 0) {
            pullRefreshLabel.isHidden = false
        }
        if(isVisible == true) {
            let alert = UIAlertController(title: "Connectivity Issue", message: "Are you connected to the internet? Pull down to try again", preferredStyle: .actionSheet)
            
            let okAction = UIAlertAction(title: "Ok", style: .default, handler: nil)
            alert.addAction(okAction)
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    func invalidateTimer() {        
        fetchPrograms.invalidateTimer(category: self.title!)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        isVisible = false
    }
    
    func tableView(_ tableView: UITableView,
                   numberOfRowsInSection section: Int) -> Int {
        
        if(mainProgramData.count == 0) {
            return 0
        }
        return hdKeyData.count

    }
    
    func tableView(_ tableView: UITableView,
                   cellForRowAt
        indexPath: IndexPath) -> UITableViewCell {
        
        let cell =
            tableView.dequeueReusableCell(withIdentifier: "programCell",for: indexPath)
                as! ProgramDataTableViewCell
        
        let row = hdKeyData[(indexPath as NSIndexPath).row]
        
        let rowNumber: Int
        var otherRowNumber: Int?
        let currentRowisHD: Bool!
        guard let rowNumberHD = row.value(forKey: "hdRow") as? Int else {
            return cell
        }
        
        guard let rowNumberSD = row.value(forKey: "sdRow") as? Int else {
            return cell
        }
        
        if(rowNumberHD != 0 && rowNumberSD != 0) {
            if(userData.isHD == true) {
                rowNumber = rowNumberHD
                currentRowisHD = true
                otherRowNumber = rowNumberSD
            } else {
                rowNumber = rowNumberSD
                currentRowisHD = false
                otherRowNumber = rowNumberHD
            }
        } else {
            if(rowNumberSD != 0) {
                rowNumber = rowNumberSD
                otherRowNumber = nil
                currentRowisHD = false
            } else {
                rowNumber = rowNumberHD
                otherRowNumber = nil
                currentRowisHD = true
            }
        }
        
        let program = mainProgramData[rowNumber-1]
        if let othernumber = otherRowNumber {
            if (currentRowisHD == true) {
                cell.setHDData(hdProgram: program)
                cell.setSDData(sdProgram: mainProgramData[othernumber-1])
            } else {
                cell.setSDData(sdProgram: program)
                cell.setHDData(hdProgram: mainProgramData[othernumber-1])
            }
        }
        
        
        
        //cell.textLabel?.text = program.programName
        if let start = program.value(forKey: "startTime") as? String, let dur = program.value(forKey: "duration") as? String, let cnum = program.value(forKey: "channelNum") as? String, let cid = program.value(forKey: "channelId") as? String,
            let channame = program.value(forKey: "channelName") as? String,
            let progId = program.value(forKey: "programId") as? String {
            cell.setProgramData(start,programDuration: Int(dur)!,channelNumber: cnum, channelId: cid, chanName: channame)
            cell.programId = progId
        }
        
        let channelname = program.value(forKey: "channelName") as? String
        cell.programName?.text = program.value(forKey: "programName") as? String
        cell.genreLabel?.text = program.value(forKey: "genre") as? String
        
        if(mainProgramData.count == resultsNext.count) {
            let pg_next = resultsNext[rowNumber-1]
            if let othernumber = otherRowNumber {
                if (currentRowisHD == true) {
                    cell.setNextHDProgram(nHDProgram: pg_next)
                    cell.setNextSDProgram(nSDProgram: resultsNext[othernumber-1])
                } else {
                    cell.setNextSDProgram(nSDProgram: pg_next)
                    cell.setNextHDProgram(nHDProgram: resultsNext[othernumber-1])
                }
            }
            if let nextdate = bubbleDateFormat.date(from: (pg_next.value(forKey: "startTime") as? String)!) {
                let nextdatestring = dformat.string(from: nextdate)
                cell.programNext?.text = nextdatestring + " | " + String(pg_next.value(forKey: "programName") as! String)
            }
        } else {
            for nexts in resultsNext {
                if let nxt_primaryKey = nexts.value(forKey: "primaryKey") as? Int, let now_primarykey = program.value(forKey: "primaryKey") as? Int {
                    if(nxt_primaryKey == now_primarykey) {
                        if (currentRowisHD == true) {
                            cell.setNextHDProgram(nHDProgram: nexts)
                        } else {
                            cell.setNextSDProgram(nSDProgram: nexts)
                        }
                        if let nextdate = bubbleDateFormat.date(from: (nexts.value(forKey: "startTime") as? String)!) {
                            let nextdatestring = dformat.string(from: nextdate)
                            cell.programNext?.text = nextdatestring + " | " + String(nexts.value(forKey: "programName") as! String)
                            break
                        }
                    }
                }
            }
            
            if let othernumber = otherRowNumber {
                let otherprogram = mainProgramData[othernumber-1]
                for nexts in resultsNext {
                    if let nxt_primaryKey = nexts.value(forKey: "primaryKey") as? Int, let now_primarykey = otherprogram.value(forKey: "primaryKey") as? Int {
                        if(nxt_primaryKey == now_primarykey) {
                            if (currentRowisHD == false) {
                                cell.setNextHDProgram(nHDProgram: nexts)
                            } else {
                                cell.setNextSDProgram(nSDProgram: nexts)
                            }
                        }
                    }
                }
            }
        }
        
        if(mainProgramData.count == resultsLater.count) {
            let pg_later = resultsLater[rowNumber-1]
            if let othernumber = otherRowNumber {
                if (currentRowisHD == true) {
                    cell.setLaterHDProgram(lHDProgram: pg_later)
                    cell.setLaterSDProgram(lSDProgram: resultsLater[othernumber-1])
                } else {
                    cell.setLaterSDProgram(lSDProgram: pg_later)
                    cell.setLaterHDProgram(lHDProgram: resultsLater[othernumber-1])
                }
            }
            if let laterdate = bubbleDateFormat.date(from: (pg_later.value(forKey: "startTime") as? String)!) {
                let laterdatestring = dformat.string(from: laterdate)
                cell.programLater?.text = laterdatestring + " | " + String(pg_later.value(forKey: "programName") as! String)
            }
        } else {
            for laters in resultsLater {
                if let ltr_primaryKey = laters.value(forKey: "primaryKey") as? Int, let now_primarykey = program.value(forKey: "primaryKey") as? Int {
                    if(ltr_primaryKey == now_primarykey) {
                        if (currentRowisHD == true) {
                            cell.setLaterHDProgram(lHDProgram: laters)
                        } else {
                            cell.setLaterSDProgram(lSDProgram: laters)
                        }
                        if let laterdate = bubbleDateFormat.date(from: (laters.value(forKey: "startTime") as? String)!) {
                            let laterdatestring = dformat.string(from: laterdate)
                            cell.programLater?.text = laterdatestring + " | " + String(laters.value(forKey: "programName") as! String)
                            break
                        }
                    }
                }
            }
            
            if let othernumber = otherRowNumber {
                let otherprogram = mainProgramData[othernumber-1]
                for laters in resultsLater {
                    if let ltr_primaryKey = laters.value(forKey: "primaryKey") as? Int, let now_primarykey = otherprogram.value(forKey: "primaryKey") as? Int {
                        if(ltr_primaryKey == now_primarykey) {
                            if (currentRowisHD == false) {
                                cell.setLaterHDProgram(lHDProgram: laters)
                            } else {
                                cell.setLaterSDProgram(lSDProgram: laters)
                            }
                        }
                    }
                }
            }
        }
        
        
        if(rowNumberHD == 0 || rowNumberSD == 0) {
            cell.sdLabel?.isHidden = true
            cell.hdLabel?.isHidden = true
        } else {
            cell.sdLabel?.isHidden = false
            cell.hdLabel?.isHidden = false
            if let cname = channelname  {
                if(cname.contains(" HD")) {
                    cell.setHDSelected()
                } else {
                    cell.setSDSelected()
                }
            }
        }
        
        if let chnlid = program.value(forKey: "channelId") as? String {
            let urlstring = GlobalConstants.BubbleAPI.BUBBLE_URL_PREFIX + "/images/channels_logo/" + chnlid + ".png"
            
            let url = URL(string: urlstring)
            cell.channelLogo?.kf.setImage(with: url, placeholder: UIImage(named: "chanlogoplaceholder"), options: [.transition(.fade(0.3))])
        }

        if let imdb = program.value(forKey: "imdbRating") as? String {
            if imdb != "" && imdb != "0" && imdb != "N/A" && imdb != "-1" {
                cell.imdbLabel.text = "IMDB Rating: "+imdb + "/10"
                cell.showIMDBText()
            } else {
                cell.hideIMDBText()
            }
        } else {
            cell.hideIMDBText()
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let cell = cell as! ProgramDataTableViewCell
        cell.channelLogo?.kf.cancelDownloadTask()
        cell.postTimer?.invalidate()
    }
    
//    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
//        return UITableViewAutomaticDimension
//    }
    
//    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
//        return 20
//    }
//    
//    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
//        return 0
//    }    
    
//    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
//        return 250
//    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        isVisible = true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        initializeFetchedResultsController()
    }
    
    override func didReceiveMemoryWarning() {
    }
    
    
    
    func initializeFetchedResultsController() {
        
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.dataStoreController.inContext { [weak self] context in
            guard let context = context else {
                return
            }
            
            guard let homefeedview = self else {
                return
            }
            let moc = context
            homefeedview.request.sortDescriptors = [homefeedview.primaryKeySort]
            
            //let categoryPredicate = NSPredicate(format: "category == Entertainment")
            let categoryPredicate = NSPredicate(format: "category = %@", argumentArray: [homefeedview.title!])
            homefeedview.request.predicate = categoryPredicate
            
            
            homefeedview.hdMapRequest.predicate = categoryPredicate
            homefeedview.requestNext.predicate = categoryPredicate
            homefeedview.requestLater.predicate = categoryPredicate
            
            homefeedview.hdMapRequest.sortDescriptors = [homefeedview.primaryKeySort]
            homefeedview.requestNext.sortDescriptors = [homefeedview.primaryKeySort]
            homefeedview.requestLater.sortDescriptors = [homefeedview.primaryKeySort]
            
            do {
                
                homefeedview.mainProgramData = try moc.fetch(homefeedview.request) as! [NSManagedObject]
                
                homefeedview.hdKeyData = try moc.fetch(homefeedview.hdMapRequest) as! [NSManagedObject]
                
                homefeedview.resultsNext = try moc.fetch(homefeedview.requestNext) as! [NSManagedObject]
                
                homefeedview.resultsLater = try moc.fetch(homefeedview.requestLater) as! [NSManagedObject]
                
            } catch {
            }
            
            DispatchQueue.main.async {
                homefeedview.programDataTableView.reloadData()
                if(homefeedview.mainProgramData.count == 0 && homefeedview.noNetwork == false) {
                    homefeedview.loadingView.startAnimating()
                }
            }
        }
    }
}
