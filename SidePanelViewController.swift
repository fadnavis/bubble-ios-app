//
//  SidePanelViewController.swift
//  Bubble
//
//  Created by Harsh Fadnavis on 9/9/16.
//  Copyright © 2016 Harsh Fadnavis. All rights reserved.
//

import UIKit
import Kingfisher


func getDocumentsURL() -> URL {
    let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    return documentsURL
}


protocol SidePanelViewControllerDelegate {
    func menuSelected(_ menu: Menu, isLanguage: Bool)
}

class SidePanelViewController: UIViewController {
    
    var userEmail: String!
    var fbID: String!
    var gID: String!
    var name: String!
    var isLanguageMenu: Bool!
    @IBOutlet weak var imgViewProfilePicture: UIImageView!

    @IBOutlet weak var imgViewBackground: UIImageView!
    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet weak var userName: UILabel!
    var delegate: SidePanelViewControllerDelegate?
    var isPictureLoaded: Bool!
    
    var menu: Array<Menu>!
    
    struct TableView {
        struct CellIdentifiers {
            static let MenuCell = "MenuCell"
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //loadUserData()
        tableView.reloadData()
        if(!(userName == nil)) {
            //userName.text = name
            isLanguageMenu = false
        } else {
            isLanguageMenu = true
        }
//        isPictureLoaded = false
        
//        if(!isLanguageMenu) {
//            if(!isPictureLoaded) {
//                if(gID == "") {
//                    loadProfilePictureFB()
//                } else if (fbID == "") {
//                    loadProfilePictureGoogle()
//                }
//                isPictureLoaded = true
//            }
//        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
//        if(!isLanguageMenu) {
//            if(!isPictureLoaded) {
//                if(gID == "") {
//                    loadProfilePictureFB()
//                } else if (fbID == "") {
//                    loadProfilePictureGoogle()
//                }
//                isPictureLoaded = true
//            }
//        }
    }
    
    func loadUserData() {
        let defaults = UserDefaults.standard
        userEmail = defaults.object(forKey: GlobalConstants.UserDefaults.USER_EMAIL_KEY) as! String
        fbID = defaults.object(forKey: GlobalConstants.UserDefaults.USER_FACEBOOK_ID) as! String
        gID = defaults.object(forKey: GlobalConstants.UserDefaults.USER_GOOGLE_ID) as! String
        name = defaults.object(forKey: GlobalConstants.UserDefaults.USER_NAME) as! String
    }
    
    func loadProfilePictureFB() {
        let height = Int(imgViewProfilePicture.frame.size.height)
        let width = Int(imgViewProfilePicture.frame.size.width)
        var url: String!
        url = "https://graph.facebook.com/"
        url = url + "\(fbID!)"
        url = url + "/picture?type=large&height=" + "\(height)" + "&width=" + "\(width)"
        let nsurl = URL(string: url)
        
        imgViewProfilePicture.kf.setImage(with: nsurl, placeholder: UIImage(named: "chanlogoplaceholder"), options: [.transition(.fade(0.3))])
        imgViewBackground.kf.setImage(with: nsurl, placeholder: UIImage(named: "chanlogoplaceholder"), options: [.transition(.fade(0.3))])
        imgViewBackground.blurImage()
    }
    
    func loadProfilePictureGoogle() {
        let googleuser = GIDSignIn.sharedInstance().currentUser
        if(googleuser?.profile.hasImage)! {
            let profileImageURL = googleuser?.profile.imageURL(withDimension: 100)
            imgViewProfilePicture.kf.setImage(with: profileImageURL, placeholder: UIImage(named: "chanlogoplaceholder"), options: [.transition(.fade(0.3))])
            imgViewBackground.kf.setImage(with: profileImageURL, placeholder: UIImage(named: "chanlogoplaceholder"), options: [.transition(.fade(0.3))])
            imgViewBackground.blurImage()
//            DispatchQueue.global(qos: .userInitiated).async {
//                let data = try? Data(contentsOf: profileImageURL!) //make sure your image in this url does exist, otherwise unwrap in a if let check
//                DispatchQueue.main.async(execute: {
//                    self.imgViewProfilePicture.image = UIImage(data: data!)
//                });
//            }
        }
    }
    
    
    
    func saveProfileImage (image: UIImage) -> Bool{
        
        //let pngImageData = UIImagePNGRepresentation(image)
        let jpgImageData = UIImageJPEGRepresentation(image, 1.0)   // if you want to save as JPEG
        let filename = getDocumentsURL().appendingPathComponent("profilePicture.jpg")
        do {
            try jpgImageData?.write(to: filename)
        } catch {
            return false
        }
        
        return true
        
    }
    
    
    func loadImageFromPath(path: String) -> UIImage? {
        
        let image = UIImage(contentsOfFile: path)
        
        if image == nil {
            
            return nil
        }
//        print("Loading image from path: \(path)") // this is just for you to see the path in case you want to go to the directory, using Finder.
        return image
        
    }
    
}

// MARK: Table View Data Source

extension SidePanelViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return menu.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: TableView.CellIdentifiers.MenuCell, for: indexPath) as! MenuCell
        cell.configureForMenu(menu[(indexPath as NSIndexPath).row])
        return cell
    }
    
    
}

// Mark: Table View Delegate

extension SidePanelViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedMenu = menu[(indexPath as NSIndexPath).row]
        delegate?.menuSelected(selectedMenu,isLanguage: self.isLanguageMenu)
    }
    
}

class MenuCell: UITableViewCell {
    
    
    @IBOutlet weak var label: UILabel!
    
    @IBOutlet weak var menuIcon: UIImageView?
    func configureForMenu(_ menu: Menu) {
        label.text = menu.title
        menuIcon?.image = menu.icon
    }
    
    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        if (highlighted) {
            label.textColor = UIColor.BubbleBlue()
        } else {
            label.textColor = UIColor.white
        }
    }
    
}
