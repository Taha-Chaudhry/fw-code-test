//
//  ArticleDetailView.swift
//  fw-code-test
//
//  Created by Taha Chaudhry on 09/08/2023.
//

import SwiftUI

struct ArticleDetailView: View {
    let article: Article
    @ObservedObject var viewModel: ArticlesViewModel
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 0) {
                let imageUrl = article.thumbnail_template_url.replacingOccurrences(of: ":width", with: "1000", options: .literal, range: nil).replacingOccurrences(of: ":height", with: "1000", options: .literal, range: nil)
                
                if let image = viewModel.loadedImages[imageUrl] {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .clipped()
                        .edgesIgnoringSafeArea(.bottom)
                }
                
                VStack(alignment: .leading) {
                    Text(article.title)
                        .font(.title)
                        .padding(0.5)
                    
                    Text(article.date.components(separatedBy: "-").joined(separator: "/"))
                        .fontWeight(.thin)
                        .padding(0.5)
                }.padding()
                
                
                Text(article.summary)
                    .padding()
                Spacer()
                Spacer()

            }
        }
    }

}
