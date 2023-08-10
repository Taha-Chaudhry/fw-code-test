//
//  ArticlesListView.swift
//  fw-code-test
//
//  Created by Taha Chaudhry on 08/08/2023.
//

import SwiftUI

// MARK: Model

struct Article: Decodable {
    var id: Int
    var title: String
    var date: String
    var summary: String
    var thumbnail_template_url: String
    var thumbnail_url: String
}

// MARK: -

struct ArticleListView: View {
    let token: Token
    @StateObject private var viewModel = ArticlesViewModel()

    var body: some View {
        NavigationView {
            List {
                ForEach(viewModel.articles, id: \.id) { article in
                    NavigationLink(destination: ArticleDetailView(article: article, viewModel: viewModel)) {
                        ArticleRowView(article: article)
                    }
                }
            }
        }
        .navigationTitle("Articles")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden()
        .navigationBarItems(
            trailing:
                NavigationLink {
                    LoginView()
                        .onAppear{
                            removeRefreshToken()
                        }
                } label: {
                    Text("LOGOUT")
                        .bold()
                        .foregroundColor(.purple)
                }
        )
        .onAppear {
            viewModel.loadArticles(token: token)
        }
    }
}

// MARK: - Row View

struct ArticleRowView: View {
    var article: Article
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                AsyncImage(url: URL(string: article.thumbnail_url)) { phase in
                    if let image = phase.image {
                        image
                            .resizable()
                            .scaledToFit()
                            .frame(width: 80, height: 80)
                            .cornerRadius(6)

                    } else {
                        ProgressView()
                            .frame(width: 80, height: 80)
                    }
                }
                
                Text(article.date.components(separatedBy: "-").joined(separator: "/"))
                    .fontWeight(.thin)
                    .font(.footnote)
            }
            
            VStack(alignment: .leading) {
                Text(article.title)
                    .padding(5)
                Text(article.summary)
                    .font(.footnote)
                    .padding(5)
                    .lineLimit(3)
            }
        }
    }
}

// MARK: - View Model

class ArticlesViewModel: ObservableObject {
    @Published var articles: [Article] = []
    var loadedImages: [String: UIImage] = [:]
    
    func loadArticles(token: Token) {
        fetchArticles(token) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let fetchedArticles):
                    self.articles = fetchedArticles
                    self.preloadImages(for: fetchedArticles)
                case .failure:
                    break
                }
            }
        }
    }
    
    private func preloadImages(for articles: [Article]) {
        for article in articles {
            let imageUrl = article.thumbnail_template_url.replacingOccurrences(of: ":width", with: "1000", options: .literal, range: nil).replacingOccurrences(of: ":height", with: "1000", options: .literal, range: nil)
            guard loadedImages[imageUrl] == nil else {
                continue
            }
            
            if let url = URL(string: imageUrl) {
                URLSession.shared.dataTask(with: url) { data, _, _ in
                    if let data = data, let image = UIImage(data: data) {
                        self.loadedImages[imageUrl] = image
                    }
                }.resume()
            }
        }
    }

}

// MARK: - Fetch Articles

func fetchArticles(_ token: Token, completion: @escaping (Result<[Article], Error>) -> Void) {
    let urlString = "https://mobilecodetest.fws.io/api/v1/articles"
    guard let url = URL(string: urlString) else { return }

    var request = URLRequest(url: url)
    request.httpMethod = "GET"
    request.addValue("Bearer \(token.access_token)", forHTTPHeaderField: "Authorization")

    URLSession.shared.dataTask(with: request) { data, response, error in
        if let data = data {
            do {
                let articles = try JSONDecoder().decode([Article].self, from: data)
                completion(.success(articles))
            } catch {
                completion(.failure(error))
            }
        } else if let error = error {
            completion(.failure(error))
        } else {
            completion(.failure(NSError(domain: "", code: -1, userInfo: nil)))
        }
    }.resume()
}
