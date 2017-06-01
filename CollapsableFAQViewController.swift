//
//  CollapsableFAQViewController.swift
//  Bubble
//
//  Created by Harsh Fadnavis on 10/13/16.
//  Copyright © 2016 Harsh Fadnavis. All rights reserved.
//

import UIKit

struct Section {
    var name: String!
    var items: [String]!
    var collapsed: Bool!
    
    init(name: String, items: [String], collapsed: Bool = true) {
        self.name = name
        self.items = items
        self.collapsed = collapsed
    }
}

//
// MARK: - View Controller
//
class CollapsibleTableViewController: UITableViewController, BubbleAPIDelegate {
    
    var sections = [Section]()
    var heights = [CGFloat]()
    //var faqArray = [String]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "FAQ"
        
        // Initialize the sections array
        // Here we have three sections: Mac, iPad, iPhone
        let bubbleAPI = CallBubbleApi()
        bubbleAPI.delegate = self
        var params : [String : String] = [:]
        params["method"] = GlobalConstants.HttpMethodName.BUBBLE_GET_FAQ
        bubbleAPI.post(params)
        //tableView.sectionHeaderHeight = UITableViewAutomaticDimension
        //tableView.rowHeight = UITableViewAutomaticDimension

        
        sections = []
//            Section(name: "Mac", items: ["MacBook", "MacBook Air", "MacBook Pro", "iMac", "Mac Pro", "Mac mini", "Accessories", "OS X El Capitan"]),
//            Section(name: "iPad", items: ["iPad Pro", "iPad Air 2", "iPad mini 4", "Accessories"]),
//            Section(name: "iPhone", items: ["iPhone 6s", "iPhone 6", "iPhone SE", "Accessories"]),
//        ]
    }
    
    func onResponseReceived(_ responseJSON: [String : AnyObject], methodName: String) {
        if let status = responseJSON["status"] as? Int {
            if status == 0 {
                if let faqdata = responseJSON["faq"] as? [Any] {
                    //let faqarray = faqdata[0] as! [Any]
                    for each in faqdata {
                        let eachstringarray = each as! [String]
                        self.sections.append(Section(name: eachstringarray[0], items: [eachstringarray[1]],collapsed : true))
                    }
                    self.tableView.reloadData()
                }
            } else {
            }
        }
    }
    
    func onNetworkError(methodName: String) {        
        let alert = UIAlertController(title: "Connectivity Issue", message: "Are you connected to the internet? Try again", preferredStyle: .actionSheet)
        
        let okAction = UIAlertAction(title: "Ok", style: .default, handler: nil)
        alert.addAction(okAction)
        self.present(alert, animated: true, completion: nil)
    }
    
}

//
// MARK: - View Controller DataSource and Delegate
//
extension CollapsibleTableViewController {
    

    override func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections[section].items.count
    }
    
    // Cell
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell") as UITableViewCell? ?? UITableViewCell(style: .default, reuseIdentifier: "cell")
        
        cell.textLabel?.text = sections[indexPath.section].items[indexPath.row]
        cell.textLabel?.font = UIFont(name: "Quicksand-Regular", size: 17.0)
        cell.textLabel?.numberOfLines = 0
        //heights[indexPath.row] = (cell.textLabel?.intrinsicContentSize.height)!
        //cell.frame.height = cell.textLabel?.intrinsicContentSize.height
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 100.0
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        //print(cell?.textLabel?.intrinsicContentSize.height)
        return sections[indexPath.section].collapsed! ? 0 : UITableViewAutomaticDimension
    }
    
    // Header
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: "header") as? CollapsibleTableViewHeader ?? CollapsibleTableViewHeader(reuseIdentifier: "header")
        
        header.titleLabel.text = sections[section].name
        header.arrowLabel.text = ">"
        header.arrowLabel.font = UIFont(name: "Quicksand-Regular", size: 17.0)
        header.titleLabel.font = UIFont(name: "Quicksand-Regular", size: 17.0)
        header.setCollapsed(collapsed: sections[section].collapsed)
        
        header.section = section
        header.delegate = self
        return header
    }
    
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 100
    }
    
//    override func tableView(_ tableView: UITableView, estimatedHeightForHeaderInSection section: Int) -> CGFloat {
//        return 80.0
//    }
    
    
    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 1.0
    }
    
}

//
// MARK: - Section Header Delegate
//
extension CollapsibleTableViewController: CollapsibleTableViewHeaderDelegate {
    
    func toggleSection(header: CollapsibleTableViewHeader, section: Int) {
        let collapsed = !sections[section].collapsed
        
        // Toggle collapse
        sections[section].collapsed = collapsed
        header.setCollapsed(collapsed: collapsed)
        
        // Adjust the height of the rows inside the section
        tableView.beginUpdates()
        for i in 0 ..< sections[section].items.count {
            //tableView.reloadRowsAtIndexPaths([NSIndexPath(forRow: i, inSection: section)], withRowAnimation: .Automatic)
            tableView.reloadRows(at: [IndexPath(row: i, section: section)], with: .automatic)
        }
        tableView.endUpdates()
    }
    
}
