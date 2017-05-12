//
//  ViewController.swift
//  circleci
//
//  Created by Adrien Caranta on 2017-04-06.
//  Copyright © 2017 Impak Finance. All rights reserved.
//

import UIKit
import SwiftyJSON
import Alamofire

class ViewController: UIViewController {
    
    let oldBaseUrl:String            = "https://ec2-52-60-125-84.ca-central-1.compute.amazonaws.com"
    let baseUrl:String               = "https://unstable-frontdoor.impak.eco"
    let helloEndPoint:String         = "/hello"
    let createUserEndPoint:String    = "/user"
    let generateTokenEndPoint:String = "/authenticate"
    let level0EndPoint:String        = "/test/level_0"
    let level1EndPoint:String        = "/test/level_1"
    let level2EndPoint:String        = "/test/level_2"
    let level3EndPoint:String        = "/test/level_3"
    let appId:String                 = "0a9d3013912a4b5e95c28094e7a813e1"
    
    var token:String?
    var currentUser:User?
    
    var alamoManager:SessionManager!

    // MARK: - Life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        let configuration = URLSessionConfiguration.default
        self.alamoManager = Alamofire.SessionManager(configuration: configuration)
        self.alamoManager.delegate.sessionDidReceiveChallengeWithCompletion = { session, challenge, completionHandler in
            var disposition: URLSession.AuthChallengeDisposition = .performDefaultHandling
            var credential: URLCredential?
                    
            if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust {
                disposition = .useCredential
                credential = URLCredential(trust: challenge.protectionSpace.serverTrust!)
            } else {
                if challenge.previousFailureCount > 0 {
                    disposition = .cancelAuthenticationChallenge
                } else {
                    credential = self.alamoManager.session.configuration.urlCredentialStorage?.defaultCredential(for: challenge.protectionSpace)
                    if credential != nil {
                        disposition = .useCredential
                    }
                }
            }
            
            return completionHandler(disposition, credential)
        }
    }

    private func showAlert(title:String, message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let action = UIAlertAction(title: "Okay", style: .default, handler: nil)
        alertController.addAction(action)
        self.present(alertController, animated: true, completion: nil)
    }
    
    private func getToken(level: Int, completionHandler:@escaping (_ token: String?, _ error: Error?) -> Void) {
        if UserDefaults.standard.object(forKey: "api_user_id") != nil && UserDefaults.standard.object(forKey: "user_imei") != nil {
            let userId = UserDefaults.standard.object(forKey: "api_user_id")
            let userImei = UserDefaults.standard.object(forKey: "user_imei")
            if let url = URL(string: self.baseUrl + self.generateTokenEndPoint) {
                let params:Parameters = ["app_id": self.appId, "user_id": userId!, "imei": userImei!, "level": level]
                let headers:HTTPHeaders = ["Content-type": "application/json"]
                self.alamoManager.request(url, method: .post, parameters: params, encoding: JSONEncoding.default, headers: headers).responseJSON(completionHandler: { (response) in
                    switch response.result {
                    case .success(_):
                        if let json = response.result.value as? [String: Any] {
                            self.token = json["token"] as? String
                            completionHandler(self.token, nil)
                        }
                    case .failure(_):
                        completionHandler(nil, response.result.error)
                    }
                    
                })
            }
        } else {
            self.showAlert(title: "Get token", message: "Current user is nil. Before getting a token please create a user.")
            completionHandler(nil, nil)
        }
    }
    
    // MARK: - IBActions
    
    @IBAction func testBaseUrlAction(_ sender: Any) {
        self.alamoManager.request(self.baseUrl + self.helloEndPoint).responseJSON { (response) in
            switch response.result {
            case .success(_):
                if let json = response.result.value as? [String: Any] {
                    let msg = json["message"] as! String
                    self.showAlert(title: "Test Base Url", message: msg)
                }
            case .failure(_):
                self.showAlert(title: "Error", message: "Error request base url : \(String(describing: response.result.error?.localizedDescription))")
            }
        }
    }

    @IBAction func createUserAction(_ sender: Any) {
        if UserDefaults.standard.object(forKey: "api_user_id") == nil {
            if let url = URL(string: self.baseUrl + self.createUserEndPoint) {
                let headers:HTTPHeaders = ["Content-type": "application/json", "Accept": "application/json"]
                let params:Parameters = ["name": "John", "imei": "abcdefg"]
                self.alamoManager.request(url, method: .post, parameters: params, encoding: JSONEncoding.default, headers: headers).responseJSON(completionHandler: { (response) in
                    switch response.result {
                    case .success(_):
                        if let json = response.result.value as? [String: Any] {
                            self.currentUser = User(data: json)
                            UserDefaults.standard.set(self.currentUser!.uid, forKey: "api_user_id")
                            UserDefaults.standard.set(self.currentUser!.imei, forKey: "user_imei")
                            self.showAlert(title: "User Creation", message: "Welcome \(self.currentUser!.name)")
                        }
                    case .failure(_):
                        self.showAlert(title: "Error", message: "Error creating user : \(String(describing: response.result.error?.localizedDescription))")
                    }
                })
            }
        } else {
            self.showAlert(title: "Error", message: "User has already been created")
        }
    }
    
    @IBAction func getUserAction(_ sender: Any) {
        if UserDefaults.standard.object(forKey: "api_user_id") != nil {
            self.getToken(level: 1, completionHandler: { (token, error) in
                if let _ = error {
                    NSLog("getUserAction() | getToken() | Error: \(error!.localizedDescription)")
                } else {
                    if let _ = token {
                        if let url = URL(string: self.baseUrl + self.createUserEndPoint) {
                            let headers:HTTPHeaders = ["Content-type": "application/json", "Accept": "application/json", "Authorization": "JWT \(token!)"]
                            let userId = UserDefaults.standard.string(forKey: "api_user_id")
                            let params:Parameters = ["id": userId ?? ""]
                            self.alamoManager.request(url, method: .get, parameters: params, encoding: JSONEncoding.default, headers: headers).responseJSON(completionHandler: { (response) in
                                switch response.result {
                                case .success(_):
                                    if let json = response.result.value as? [String: Any] {
                                        self.currentUser = User(data: json)
                                        self.showAlert(title: "Returning User", message: "Welcome back \(self.currentUser!.name)")
                                    }
                                case .failure(_):
                                    self.showAlert(title: "Error", message: "Error creating user : \(String(describing: response.result.error?.localizedDescription))")
                                }
                            })
                        }
                    }
                }
            })
        } else {
            self.showAlert(title: "Error", message: "User has never been created before.")
        }
    }
    
    @IBAction func testLevel0Action(_ sender: Any) {
        if let url = URL(string: self.baseUrl + self.level0EndPoint) {
            self.alamoManager.request(url, method: .get, parameters: nil, encoding: JSONEncoding.default, headers: nil).responseJSON(completionHandler: { (response) in
                if let json = response.result.value as? [String: Any] {
                    self.showAlert(title: "Level \(json["level"]!) Access", message: "\(json["message"]!)")
                }
            })
        }
    }

    @IBAction func testLevel1Action(_ sender: Any) {
        self.getToken(level: 1) { (token, error) in
            if let _ = error {
                NSLog("Level 1 Error : \(error!.localizedDescription)")
            } else {
                if let url = URL(string: self.baseUrl + self.level1EndPoint) {
                    if let _ = token {
                        let headers:HTTPHeaders = ["Authorization": "JWT \(token!)"]
                        self.alamoManager.request(url, method: .get, parameters: nil, encoding: JSONEncoding.default, headers: headers).responseJSON(completionHandler: { (response) in
                            if let json = response.result.value as? [String: Any] {
                                self.showAlert(title: "Level \(json["level"]!) Access", message: "\(json["message"]!)")
                            }
                        })
                    }
                }
            }
        }
    }
    
    @IBAction func testLevel2Action(_ sender: Any) {
        self.getToken(level: 2) { (token, error) in
            if let _ = error {
                NSLog("Level 2 Error : \(error!.localizedDescription)")
            } else {
                if let url = URL(string: self.baseUrl + self.level2EndPoint) {
                    if let _ = token {
                        let headers:HTTPHeaders = ["Authorization": "JWT \(token!)"]
                        self.alamoManager.request(url, method: .get, parameters: nil, encoding: JSONEncoding.default, headers: headers).responseJSON(completionHandler: { (response) in
                            if let json = response.result.value as? [String: Any] {
                                self.showAlert(title: "Level \(json["level"]!) Access", message: "\(json["message"]!)")
                            }
                        })
                    }
                }
            }
        }
    }
    
    @IBAction func testLevel3Action(_ sender: Any) {
        self.getToken(level: 3) { (token, error) in
            if let _ = error {
                NSLog("Level 3 Error : \(error!.localizedDescription)")
            } else {
                if let url = URL(string: self.baseUrl + self.level3EndPoint) {
                    if let _ = token {
                        let headers:HTTPHeaders = ["Authorization": "JWT \(token!)"]
                        self.alamoManager.request(url, method: .get, parameters: nil, encoding: JSONEncoding.default, headers: headers).responseJSON(completionHandler: { (response) in
                            if let json = response.result.value as? [String: Any] {
                                self.showAlert(title: "Level \(json["level"]!) Access", message: "\(json["message"]!)")
                            }
                        })
                    }
                }
            }
        }
    }
    
}

