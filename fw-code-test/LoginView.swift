//
//  LoginView.swift
//  fw-code-test
//
//  Created by Taha Chaudhry on 09/08/2023.
//

import SwiftUI

// MARK: Model

struct User {
    let username: String
    let password: String
}

// MARK: -

struct LoginView: View {
    @State private var username: String = ""
    @State private var password: String = ""
    @State private var errorText: String = ""
    @State private var token: Token?
    @State private var isAuthenticated: Bool = false
    @State private var isLoading: Bool = false

    var body: some View {
        NavigationView {
            VStack {
                VStack {
                    Image("loginImage")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 500, height: 200, alignment: .bottom)
                        .safeAreaInset(edge: .bottom) {
                            VStack {
                                VStack {
                                    GroupBox {
                                        VStack(alignment: .leading) {
                                            Text("Username")
                                                .font(.headline)
                                            TextField("john_appleseed...", text: $username)
                                                .textInputAutocapitalization(.never)
                                                .padding()
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 5)
                                                        .stroke(Color.black, lineWidth: 2).opacity(0.4)
                                                )
                                                .onSubmit {
                                                    attemptLogin()
                                                }
                                        }
                                    }

                                    GroupBox {
                                        VStack(alignment: .leading) {
                                            Text("Password")
                                                .font(.headline)
                                            SecureField("Required...", text: $password)
                                                .padding()
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 5)
                                                        .stroke(Color.black, lineWidth: 2).opacity(0.4)
                                                )
                                                .onSubmit {
                                                    attemptLogin()
                                                }
                                        }
                                    }
                                }.padding()

                                Text(errorText)
                                    .foregroundColor(.red)

                                if isLoading {
                                    ProgressView()
                                }

                                Button {
                                    attemptLogin()
                                } label: {
                                    Text("LOGIN")
                                        .bold()
                                        .foregroundColor(.purple)
                                }.padding()

                                NavigationLink(destination: token != nil ? ArticleListView(token: token!) : nil, isActive: $isAuthenticated) {
                                    EmptyView()
                                }
                            }
                        }
                }
                
                Spacer()
            }.padding()
        }
        .navigationBarBackButtonHidden()
    }
    
    func attemptLogin() {
        guard username != "" && password != "" else { return errorText = "Fields can not be empty" }
        guard !username.contains(" ") else { return errorText = "Username cannot contain spaces" }
        
        isLoading = true
        let user = User(username: username, password: password)
        
        
        authenticateUser(user) { result in
            withAnimation {
                isLoading = false
            }
            
            switch result {
            case .success(let receivedToken):
                token = receivedToken
                storeRefreshToken(receivedToken)
                withAnimation {
                    errorText = ""
                    isAuthenticated = true
                }
            case .failure:
                withAnimation {
                    errorText = "Invalid username or password"
                }
            }
        }
    }
}

// MARK: - User Authentication

func authenticateUser(_ user: User, completion: @escaping (Result<Token, Error>) -> Void) {
    let urlString = "https://mobilecodetest.fws.io/auth/token"
    guard let url = URL(string: urlString) else { return }
    
    let body = ["username": user.username, "password": user.password, "grant_type": "password"]
    
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.addValue("application/json", forHTTPHeaderField: "Content-Type")
    
    do { request.httpBody = try JSONSerialization.data(withJSONObject: body) }
    catch { completion(.failure(error)); return }
    
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

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
    }
}
