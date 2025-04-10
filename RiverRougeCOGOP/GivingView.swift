// GivingView.swift

import SwiftUI

struct GivingView: View {
    var body: some View {
        VStack(spacing: 20) {
            // Title
            Text("COGOP Giving Options")
                .underline()
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .padding(.top, 40)
            
            // Description
            Text("Below are some ways you can give")
                .font(.title3)
                .foregroundColor(.white.opacity(0.9))
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            // Cash App Button
            Button(action: {
                if let url = URL(string: "https://cash.app/$RiverRougeCOGOP") {
                    UIApplication.shared.open(url)
                }
            }) {
                HStack {
                    Image("cashapp") // Assumes you have this in your Asset Catalog
                        .resizable()
                        .scaledToFit()
                        .frame(width: 40, height: 40)
                    Text("Cash App ($RiverRougeCOGOP)")
                        .font(.headline)
                        .foregroundColor(.white)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.green.opacity(0.8))
                .cornerRadius(10)
            }
            .padding(.horizontal)
            
            // Address Text (replacing Mailto Link)
            VStack {
                Image(systemName: "envelope.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 40, height: 40)
                    .foregroundColor(.white)
                Text("41 Orchard St. River Rouge, MI 48218")
                    .font(.headline)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.blue.opacity(0.8))
            .cornerRadius(10)
            .padding(.horizontal)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black) // Matches your app's background
    }
}

// Preview Provider
struct GivingView_Previews: PreviewProvider {
    static var previews: some View {
        GivingView()
            .preferredColorScheme(.dark)
    }
}
