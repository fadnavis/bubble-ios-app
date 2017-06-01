//
//  ConfigureTVViewController.swift
//  Bubble
//
//  Created by Harsh Fadnavis on 10/17/16.
//  Copyright © 2016 Harsh Fadnavis. All rights reserved.
//

import UIKit
import CoreData

class ConfigureTVViewController: UIViewController, BubbleAPIDelegate, BubbleWriteProcessDelegate {

    var tvCodesArray = [TVPowerCodes]()
    var currentCodeNumber = 0
    var totalCodes = 0
    var TVModel = ""
    //MARK: View 1
    
    @IBOutlet weak var viewIntro: UIView!
    
    @IBOutlet weak var proceed: UILabel!
    //MARK: View 2
    
    @IBOutlet weak var previousModel: UILabel!
    @IBOutlet weak var No: UILabel!
    @IBOutlet weak var Yes: UILabel!
    @IBOutlet weak var askUserText: UILabel!
    @IBOutlet weak var loadingView: UIActivityIndicatorView!
    @IBOutlet weak var modelNumberText: UILabel!
    @IBOutlet weak var tvModelText: UILabel!
    @IBOutlet weak var viewConfigure: UIView!
    
    //MARK: ViewSuccess
    
    @IBOutlet weak var doneSuccess: UILabel!
    @IBOutlet weak var viewSuccess: UIView!
    
    //MARK: ViewError
    
    @IBOutlet weak var doneError: UILabel!
    @IBOutlet weak var viewError: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = "TV Setup"
        callBubbleAPI()
        showViewIntro()
        TVModel = (UserDefaults.standard.value(forKey: GlobalConstants.UserDefaults.USER_TV_BRAND) as? String)!
        // Do any additional setup after loading the view.
    }
    
    func showViewIntro() {
        viewIntro.isHidden = false
        viewConfigure.isHidden = true
        viewSuccess.isHidden = true
        viewError.isHidden = true
        currentCodeNumber = 0
    }
    
    func showViewConfigure() {
        tvModelText.text = "Matching your \(TVModel) TV Model"
        viewIntro.isHidden = true
        viewConfigure.isHidden = false
        viewSuccess.isHidden = true
        viewError.isHidden = true
        sendCodeToBubble(index: currentCodeNumber)
    }
    
    func showViewSuccess() {
        viewIntro.isHidden = true
        viewConfigure.isHidden = true
        viewSuccess.isHidden = false
        viewError.isHidden = true
    }
    
    func showViewError() {
        viewIntro.isHidden = true
        viewConfigure.isHidden = true
        viewSuccess.isHidden = true
        viewError.isHidden = false
    }
    
    override func viewWillAppear(_ animated: Bool) {
        proceed.isHidden = false
        askUserText.isHidden = true
    }
    
    func sendCodeToBubble(index: Int) {
        let data = tvCodesArray[index]
        var datastring = data.IRProtocol!
        datastring += ":"
        datastring += data.address!
        datastring += ":"
        datastring += data.hexcode!
        datastring += ":"
        datastring += data.nbits!
        datastring += ":"
        if(!BluetoothSerialMain.sharedInstance.getIsSending()) {
            BluetoothSerialMain.sharedInstance.setWriteProcessDelegate(delegate: self)
            BluetoothSerialMain.sharedInstance.setTVCodeString(dataString: datastring)
            BluetoothSerialMain.sharedInstance.startProcessBubble()
        }
    }
    
    @IBAction func tapProceed(_ sender: UITapGestureRecognizer) {
        showViewConfigure()        
    }
    
    func callBubbleAPI() {
        let callBubble = CallBubbleApi()
        callBubble.delegate = self
        // fetch program data for this user
        var params: [String: String] = [:]
        params["method"] = GlobalConstants.HttpMethodName.BUBBLE_TV_CODES_FOR_BRAND
        params["emailid"] = UserData.sharedInstance.userEmail
        params["tvbrand"] = UserDefaults.standard.value(forKey: GlobalConstants.UserDefaults.USER_TV_BRAND) as? String
        callBubble.post(params)
    }
    
    func onResponseReceived(_ responseJSON: [String : AnyObject], methodName: String) {
        if let status = responseJSON["status"] as? Int {
            if status == 0 {
                if (methodName == GlobalConstants.HttpMethodName.BUBBLE_TV_CODES_FOR_BRAND) {
                    if let models = responseJSON["powercodes"] as? [Any] {
                        for model in models {
                            if let modelString = model as? [String] {
                                self.tvCodesArray.append(TVPowerCodes(model: modelString[0], proto: modelString[1], hex: modelString[3], bits: modelString[4], address: modelString[2]))
                            }
                        }
                        proceed.isHidden = false
                    }
                } else if (methodName == GlobalConstants.HttpMethodName.BUBBLE_SET_TV_MODEL) {
                    deleteAllTVCodes()
                    saveTVRemoteCodesToEntity(responseJSON)
                    showViewSuccess()
                }
            }
        }
    }
    
    func BubbleWriteStarted() {
        loadingView.startAnimating()
        askUserText.isHidden = true
        modelNumberText.text = "\(currentCodeNumber + 1)/\(tvCodesArray.count)"
        Yes.isHidden = true
        No.isHidden = true
        previousModel.isHidden = true
    }
    
    func BubbleWriteEnded() {
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1) { [weak self] in
            self?.loadingView.stopAnimating()
            self?.askUserText.isHidden = false
            self?.Yes.isHidden = false
            self?.No.isHidden = false
            if let ccn = self?.currentCodeNumber {
                if (ccn > 0) {
                    //previousModel.isHidden = false
                    self?.previousModel.isHidden = false
                }
            }
        }
    }
    
    func BubbleWriteEndedWithError() {
        showViewIntro()
        BluetoothSerialMain.sharedInstance.removeWriteProcessDelegate()
        let viewController:UIViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "configBubble_main") as UIViewController
        self.navigationController!.pushViewController(viewController, animated: true)
        //self.present(viewController, animated: true, completion: nil)
    }
    
    func BubbleWriteBLEOff() {
        BluetoothSerialMain.sharedInstance.removeWriteProcessDelegate()
        let alert = UIAlertController(title: "Turn On Bluetooth", message: "Turn on Bluetooth to finish TV setup. Try again!", preferredStyle: .alert)
        
        let okAction = UIAlertAction(title: "Ok", style: .default, handler: nil)
        alert.addAction(okAction)
        self.present(alert, animated: true, completion: nil)
    }
    
    
    @IBAction func tapNo(_ sender: UITapGestureRecognizer) {
        if(currentCodeNumber < tvCodesArray.count - 1) {
            currentCodeNumber += 1
            sendCodeToBubble(index: currentCodeNumber)
        } else {
            showViewError()
        }
    }

    func deleteAllTVCodes() {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.dataStoreController.inContext {
            context in
            
            guard let context = context else {
                return
            }
            let requestTVCodes = NSFetchRequest<NSFetchRequestResult>(entityName: "STBCodes")
            let mediumPredicate = NSPredicate(format: "medium = %@", argumentArray: ["TV"])
            requestTVCodes.predicate = mediumPredicate
            
            let batchDeleteTVCodes = NSBatchDeleteRequest(fetchRequest: requestTVCodes)
            
            do {
                try context.execute(batchDeleteTVCodes)
            } catch {
                fatalError()
            }
        }
    }
    
    func saveTVRemoteCodesToEntity(_ json: [String: AnyObject]) {
        let appdelegate = UIApplication.shared.delegate as! AppDelegate!
        appdelegate?.dataStoreController.inContext { context in
            guard let context = context else {
                return
            }
            guard let codeslist = json["usercodes"] as? NSArray else {
                return
            }
            UserDefaults.standard.set(codeslist.count > 1, forKey: GlobalConstants.UserDefaults.USER_TV_REMOTES_DETAILED)
            
            for code in codeslist {
                let entity = NSEntityDescription.insertNewObject(forEntityName: "STBCodes", into: context)
                if let data = code as? [String] {
                    entity.setValue("TV", forKey: "medium")
                    entity.setValue(data[1], forKey: "remoteNumber")
                    entity.setValue(data[2], forKey: "protocol")
                    entity.setValue(data[3], forKey: "address")
                    entity.setValue(data[4], forKey: "hexcode")
                    entity.setValue(data[5], forKey: "bits")
                    entity.setValue(data[6], forKey: "rawcode")
                    entity.setValue(data[7], forKey: "rawlength")
                    entity.setValue(data[8], forKey: "frequency")
                }
            }
            
            do {
                try context.save()
            } catch {
                fatalError("error saving tv codes to entity")
            }
        }
        
    }
    
    @IBAction func tapYes(_ sender: UITapGestureRecognizer) {
        let data = tvCodesArray[currentCodeNumber]
//        var datastring = data.IRProtocol!
//        datastring += ":"
//        datastring += data.address!
//        datastring += ":"
//        datastring += data.hexcode!
//        datastring += ":"
//        datastring += data.nbits!
//        datastring += ":"
//        UserDefaults.standard.set(datastring, forKey: GlobalConstants.UserDefaults.USER_TV_CODE)
        
        var params : [String: String] = [:]
        params["method"] = GlobalConstants.HttpMethodName.BUBBLE_SET_TV_MODEL
        params["emailid"] = UserData.sharedInstance.userEmail
        params["brand"] = TVModel
        params["tvmodel"] = data.modelName
        let callBubble = CallBubbleApi()
        callBubble.delegate = self
        callBubble.post(params)
    }
    
    
    @IBAction func tapDoneError(_ sender: UITapGestureRecognizer) {
        //_ = self.navigationController?.popViewController(animated: true)
        _ = self.navigationController?.popToRootViewController(animated: true)
    }
    
    
    @IBAction func tapDoneSuccess(_ sender: UITapGestureRecognizer) {
        //_ = self.navigationController?.popViewController(animated: true)
        if let numofcontrollers = self.navigationController?.viewControllers.count {
            if numofcontrollers <= 3 {
                _ = self.navigationController?.popToRootViewController(animated: true)
            } else {
                let a = self.navigationController?.popViewController(animated: true)
                let _ = a?.navigationController?.popViewController(animated: true)
            }
        }
    }
    
    
    @IBAction func tapPreviousModel(_ sender: UITapGestureRecognizer) {
        currentCodeNumber -= 1
        sendCodeToBubble(index: currentCodeNumber)
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    
    class TVPowerCodes {
        var modelName: String?
        var IRProtocol: String?
        var hexcode: String?
        var nbits: String?
        var address: String?
        var tested = false
        
        init(model: String,proto: String, hex: String, bits: String, address: String) {
            self.modelName = model
            self.IRProtocol = proto
            self.hexcode = hex
            self.nbits = bits
            self.address = address
        }
    }

}
