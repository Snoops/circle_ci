//
//  NetworkManager.swift
//  circleci
//
//  Created by Adrien CARANTA on 2017-05-17.
//  Copyright © 2017 Impak Finance. All rights reserved.
//

import Foundation
import SwiftyJSON
import Alamofire

class NetworkManager {
    
    typealias NetworkCallback = ([String: Any]) -> Void
    typealias ErrorCallback = (Error) -> Void
    
    static let shared = NetworkManager()
    
    let baseUrl:String               = "https://unstable-frontdoor.impak.eco"
    let helloEndPoint:String         = "/hello"
    
    var alamoManager:SessionManager!
    
    init() {
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
    
    func testBaseUrl(onSuccess: @escaping NetworkCallback, onFailure: @escaping ErrorCallback) {
        self.alamoManager.request(self.baseUrl + self.helloEndPoint).responseJSON { (response) in
            switch response.result {
            case .success(_):
                if let json = response.result.value as? [String: Any] {
                    onSuccess(json)
                }
            case .failure(_):
                onFailure(response.result.error!)
            }
        }
    }
    
}
