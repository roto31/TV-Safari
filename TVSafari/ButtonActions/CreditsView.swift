//
//  CreditsView.swift
//  TV Safari
//
//  Created by RealKGB on 4/6/23.
//

import SwiftUI

struct CreditsView: View {
	var body: some View {
		VStack {
			Text("© 2026 Roto31")
				.if(UserDefaults.settings.bool(forKey: "sheikahFontApply")) { view in
					view.scaledFont(name: "BotW Sheikah Regular", size: 60)
				}
				.font(.system(size: 60))
			Text("""
			"Hopefully not the only tvOS file browser ever"
			""")
				.if(UserDefaults.settings.bool(forKey: "sheikahFontApply")) { view in
					view.scaledFont(name: "BotW Sheikah Regular", size: 25)
				}
			Text("")
			Text("""
Credits to:
                SerenaKit: Inspiration from Santander, PrivateKits, explaining how sandboxes work
                staturnz: Improving yandereDevFileTypes
ethanrdoesmc: Advice on improving ContentView load times
                llsc12: SwiftUI advice
                flower: UI/UX advice
trebrick: Testing and feature requests
                ChatGPT: Explaining stuff better than StackOverflow™
                ...and also writing me UIKit
                StackOverflow: Working with Data in Swift
""")
			.multilineTextAlignment(.center)
			.if(UserDefaults.settings.bool(forKey: "sheikahFontApply")) { view in
				view.scaledFont(name: "BotW Sheikah Regular", size: 25)
			}
		}
		.focusable(true)
	}
}
