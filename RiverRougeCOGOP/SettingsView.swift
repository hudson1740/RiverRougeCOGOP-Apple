// SettingsView.swift
import SwiftUI

struct SettingsView: View {
    @Binding var selectedGradient: GradientOption
    @Binding var selectedScriptureTheme: ScriptureTheme
    @Binding var selectedFontSize: FontSizeOption
    @Binding var selectedRefreshFrequency: ScriptureRefreshFrequency // Added for refresh frequency
    @State private var enableBackgroundMusic: Bool = false // Added for background music
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                VStack {
                    Text("Settings")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.top, 20)

                    Form {
                        Section(header: Text("Button Theme")
                                    .foregroundColor(.white)
                                    .font(.headline)) {
                            Picker("Color", selection: $selectedGradient) {
                                ForEach(GradientOption.allCases, id: \.self) { option in
                                    Text(option.rawValue).tag(option)
                                }
                            }
                            .pickerStyle(.menu)
                            .foregroundColor(.white)
                            .onChange(of: selectedGradient) { newValue in
                                saveGradientSelection(newValue)
                            }
                        }
                        .listRowBackground(Color.gray.opacity(0.2))

                        Section(header: Text("Scripture Theme")
                                    .foregroundColor(.white)
                                    .font(.headline)) {
                            Picker("Theme", selection: $selectedScriptureTheme) {
                                ForEach(ScriptureTheme.allCases, id: \.self) { theme in
                                    Text(theme.rawValue).tag(theme)
                                }
                            }
                            .pickerStyle(.menu)
                            .foregroundColor(.white)
                            .onChange(of: selectedScriptureTheme) { newValue in
                                saveScriptureThemeSelection(newValue)
                            }
                        }
                        .listRowBackground(Color.gray.opacity(0.2))

                        Section(header: Text("Scripture Font Size")
                                    .foregroundColor(.white)
                                    .font(.headline)) {
                            Picker("Font Size", selection: $selectedFontSize) {
                                ForEach(FontSizeOption.allCases, id: \.self) { size in
                                    Text(size.rawValue).tag(size)
                                }
                            }
                            .pickerStyle(.menu)
                            .foregroundColor(.white)
                            .onChange(of: selectedFontSize) { newValue in
                                saveFontSizeSelection(newValue)
                            }
                        }
                        .listRowBackground(Color.gray.opacity(0.2))

                        Section(header: Text("Scripture Refresh")
                                    .foregroundColor(.white)
                                    .font(.headline)) {
                            Picker("Refresh Frequency", selection: $selectedRefreshFrequency) {
                                ForEach(ScriptureRefreshFrequency.allCases, id: \.self) { frequency in
                                    Text(frequency.rawValue).tag(frequency)
                                }
                            }
                            .pickerStyle(.menu)
                            .foregroundColor(.white)
                            .onChange(of: selectedRefreshFrequency) { newValue in
                                saveRefreshFrequencySelection(newValue)
                            }
                        }
                        .listRowBackground(Color.gray.opacity(0.2))

                        Section(header: Text("Music Settings")
                                    .foregroundColor(.white)
                                    .font(.headline)) {
                            Toggle("Background Music Playback", isOn: $enableBackgroundMusic)
                                .foregroundColor(.white)
                                .onChange(of: enableBackgroundMusic) { newValue in
                                    saveBackgroundMusicSetting(newValue)
                                }
                        }
                        .listRowBackground(Color.gray.opacity(0.2))
                    }
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationBarItems(trailing: Button("Done") {
                dismiss()
            }
            .foregroundColor(.white))
            .onAppear {
                loadBackgroundMusicSetting()
            }
        }
    }

    func saveGradientSelection(_ gradient: GradientOption) {
        UserDefaults.standard.set(gradient.rawValue, forKey: "selectedGradient")
        print("Saved gradient selection: \(gradient.rawValue)")
    }

    func saveScriptureThemeSelection(_ theme: ScriptureTheme) {
        UserDefaults.standard.set(theme.rawValue, forKey: "selectedScriptureTheme")
        print("Saved scripture theme selection: \(theme.rawValue)")
    }

    func saveFontSizeSelection(_ fontSize: FontSizeOption) {
        UserDefaults.standard.set(fontSize.rawValue, forKey: "selectedFontSize")
        print("Saved font size selection: \(fontSize.rawValue)")
    }

    func saveRefreshFrequencySelection(_ frequency: ScriptureRefreshFrequency) {
        UserDefaults.standard.set(frequency.rawValue, forKey: "selectedRefreshFrequency")
        print("Saved refresh frequency selection: \(frequency.rawValue)")
    }

    func saveBackgroundMusicSetting(_ enabled: Bool) {
        UserDefaults.standard.set(enabled, forKey: "enableBackgroundMusic")
        print("Saved background music setting: \(enabled)")
        NotificationCenter.default.post(name: .backgroundMusicSettingChanged, object: nil, userInfo: ["enabled": enabled])
    }

    func loadBackgroundMusicSetting() {
        enableBackgroundMusic = UserDefaults.standard.bool(forKey: "enableBackgroundMusic")
        print("Loaded background music setting: \(enableBackgroundMusic)")
    }
}

extension Notification.Name {
    static let backgroundMusicSettingChanged = Notification.Name("backgroundMusicSettingChanged")
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView(
            selectedGradient: .constant(.defaultOption),
            selectedScriptureTheme: .constant(.defaultTheme),
            selectedFontSize: .constant(.medium),
            selectedRefreshFrequency: .constant(.onLaunch)
        )
        .preferredColorScheme(.dark)
    }
}
