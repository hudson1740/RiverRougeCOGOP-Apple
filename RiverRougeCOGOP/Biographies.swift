import SwiftUI

struct BiographiesView: View {
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    Text("Our Leadership")
                        .font(horizontalSizeClass == .regular ? .largeTitle : .title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.top, 40)
                        .padding(.bottom, 20)
                    
                    // Bishop Leonard Clarke
                    VStack(spacing: 15) {
                        Image("bishopclarke")
                            .resizable()
                            .scaledToFill()
                            .frame(width: horizontalSizeClass == .regular ? 200 : 150, height: horizontalSizeClass == .regular ? 200 : 150)
                            .offset(y: 40) // Move the image down within the circular frame
                            .offset(x: -5)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.white.opacity(0.3), lineWidth: 2))
                            .shadow(color: .white.opacity(0.2), radius: 8, x: 0, y: 4)
                        
                        Text("Bishop Leonard C. Clarke")
                            .font(horizontalSizeClass == .regular ? .title2 : .title3)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text("(T.T. Cert., Cert. Ed.M, M.Ed., D.P.M., EdS.)")
                            .font(horizontalSizeClass == .regular ? .subheadline : .caption)
                            .foregroundColor(.white.opacity(0.8))
                        
                        Text("""
                        Bishop Leonard Clarke began his walk with the Lord in 1972 when he became a member of the New Testament Church of God in Jamaica. He served in various capacities, including Sunday School Teacher, Youth Leader, Secretary for various auxiliaries, and member of the Pastor’s Council.

                        He migrated to the United States in 1998, became a member of the Greenfield Church of God of Prophecy, and thereafter, began work on his ministerial credentials; which were obtained in 2004. After four years as lay Minister at Greenfield, he was appointed Pastor of the River Rouge Church of God of Prophecy. In 2010 he received his Bishop’s licensure, and currently serves on the Ministerial Review Board (M.R.B.) in the Great Lakes Region.

                        Bishop Clarke is a graduate of Mico Teachers’ Training College (Jamaica), The University of the West Indies (Mona), Ashland Theological Seminary and Wayne State University (Detroit). A retired Math Teacher of forty years, he is married to his wife Deserene for over forty years and has two adult children, Nichole (Duran) and Shane (Kayan), who support him in the Ministry.
                        """)
                            .font(horizontalSizeClass == .regular ? .body : .subheadline)
                            .foregroundColor(.white.opacity(0.9))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding()
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.blue.opacity(0.6), Color.purple.opacity(0.6)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        .cornerRadius(15)
                        .shadow(color: .white.opacity(0.2), radius: 8, x: 0, y: 4)
                    )
                    .padding(.horizontal)
                    
                    // Deserene Clarke
                    VStack(spacing: 15) {
                        Image("desereneclarke")
                            .resizable()
                            .scaledToFill()
                            .frame(width: horizontalSizeClass == .regular ? 200 : 150, height: horizontalSizeClass == .regular ? 200 : 150)
                            .offset(y: 30) // Move the image down within the circular frame
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.white.opacity(0.3), lineWidth: 2))
                            .shadow(color: .white.opacity(0.2), radius: 8, x: 0, y: 4)
                        
                        Text("Deserene E. Clarke")
                            .font(horizontalSizeClass == .regular ? .title2 : .title3)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text("(T.T. Cert., DP.Ed., M.Ed.)")
                            .font(horizontalSizeClass == .regular ? .subheadline : .caption)
                            .foregroundColor(.white.opacity(0.8))
                        
                        Text("""
                        Deserene “grew up” in the New Testament Church of God, in Jamaica, under the nurturing of a Christian mother who was always guided by the tenets of Proverbs 22:6; in raising her – Train up a child in the way that he should go, and when he is old he will not depart from it. She accepted the Lord as her personal savior at an early age and served the church in various capacities. These include Youth Leader, Sunday School Teacher/Superintendent, Usher, Ladies’ Ministry Director and V.B.S. Coordinator.

                        She is a graduate of Mico Teachers’ Training College (Jamaica), G.C. Foster College of Physical Education (Jamaica), University of the West Indies (Mona, Jamaica) and Wayne State University (Detroit). After teaching both regular and Special Needs students for forty years, she is now retired and enjoying the fruits of her labor. Daughter, Nichole has a Bachelor’s degree in Electrical Engineering and an MBA from Wayne State University. While son Shane, has a Bachelor’s degree in Mechanical Engineering from Wayne State University and an MBA from the University of Michigan. Her hobbies include; listening to gospel music, crocheting and playing scrabble.
                        """)
                            .font(horizontalSizeClass == .regular ? .body : .subheadline)
                            .foregroundColor(.white.opacity(0.9))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding()
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.blue.opacity(0.6), Color.purple.opacity(0.6)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        .cornerRadius(15)
                        .shadow(color: .white.opacity(0.2), radius: 8, x: 0, y: 4)
                    )
                    .padding(.horizontal)
                    
                    Spacer(minLength: 20)
                }
                .padding(.bottom, 20)
            }
        }
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color.black, Color.gray.opacity(0.5)]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
    }
}

struct BiographiesView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            BiographiesView()
                .previewDevice("iPhone 14 Pro")
                .preferredColorScheme(.dark)
                .previewDisplayName("iPhone")
            
            BiographiesView()
                .previewDevice("iPad Pro (12.9-inch) (6th generation)")
                .preferredColorScheme(.dark)
                .previewDisplayName("iPad Pro 12.9")
        }
    }
}
