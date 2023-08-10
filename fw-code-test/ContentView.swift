//
//  ContentView.swift
//  fw-code-test
//
//  Created by Taha Chaudhry on 08/08/2023.
//
//
import SwiftUI
import Security

// MARK: Model

struct Token: Decodable {
    let access_token: String
    let refresh_token: String
}

// MARK: -

struct ContentView: View {
    @State private var checkComplete = false
    @State var isLoggedIn: Bool = false
    @State var token: Token?
    
    var body: some View {
        VStack {
            if checkComplete {
                if isLoggedIn {
                    NavigationView { ArticleListView(token: token!) }
                } else {
                    LoginView()
                }
            } else {
                ProgressView("Loading...")
            }
        }.onAppear {
            if let refreshToken = getRefreshToken() {
                refreshTokenCheck(refreshToken) { result in
                    switch result {
                    case .success(let receivedToken):
                        storeRefreshToken(receivedToken)
                        token = receivedToken
                        withAnimation {
                            isLoggedIn = true
                        }
                    case .failure(_):
                        removeRefreshToken()
                        withAnimation {
                            isLoggedIn = false
                        }
                    }
                    withAnimation {
                        checkComplete = true
                    }
                }
            } else {
                withAnimation {
                    isLoggedIn = false
                    checkComplete = true
                }
            }
        }
    }
    
}

// MARK: - Keychain Storing

func getRefreshToken() -> String? {
    let query: [String: Any] = [
        kSecClass as String: kSecClassGenericPassword,
        kSecAttrService as String: "com.fw-code-test.refreshToken",
        kSecReturnData as String: true
    ]
    
    var item: CFTypeRef?
    let status = SecItemCopyMatching(query as CFDictionary, &item)
    
    if status == errSecSuccess, let data = item as? Data, let token = String(data: data, encoding: .utf8) {
        return token
    } else {
        return nil
    }
}

func storeRefreshToken(_ token: Token) {
    if let data = token.refresh_token.data(using: .utf8) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: "com.fw-code-test.refreshToken",
            kSecValueData as String: data
        ]
        
        SecItemDelete(query as CFDictionary)
        let status = SecItemAdd(query as CFDictionary, nil)
        if status != errSecSuccess {
            print("Failed to store refresh token in keychain")
        }
    }
}

func removeRefreshToken() {
    let query: [String: Any] = [
        kSecClass as String: kSecClassGenericPassword,
        kSecAttrService as String: "com.fw-code-test.refreshToken"
    ]
    
    let status = SecItemDelete(query as CFDictionary)
    if status != errSecSuccess {
        print("Failed to remove refresh token from keychain")
    }
}



// MARK: - Check Refresh Token

func refreshTokenCheck(_ refreshToken: String, completion: @escaping (Result<Token, Error>) -> Void) {
    let urlString = "https://mobilecodetest.fws.io/auth/token"
    guard let url = URL(string: urlString) else {
        completion(.failure(NSError(domain: "", code: -1, userInfo: nil)))
        return
    }
    
    let body = ["refresh_token": refreshToken, "grant_type": "refresh_token"]
    
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.addValue("application/json", forHTTPHeaderField: "Content-Type")
    
    do {
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
    } catch {
        completion(.failure(error))
        return
    }
    
    URLSession.shared.dataTask(with: request) { data, response, error in
        if let data = data, let token = try? JSONDecoder().decode(Token.self, from: data) {
            completion(.success(token))
        } else if let error = error {
            completion(.failure(error))
        } else {
            completion(.failure(NSError(domain: "", code: -1, userInfo: nil)))
        }
    }.resume()
}
