import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.appLanguage) private var language
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var licenseManager: LicenseManager
    @AppStorage(AppLanguage.storageKey) private var languageCode = AppLanguage.english.rawValue
    @AppStorage(FeatureVisibility.cleanerStorageKey) private var cleanerEnabled = true
    @AppStorage(FeatureVisibility.developerModeStorageKey)
    private var developerModeEnabled = false
    @AppStorage(AppTheme.darkModeStorageKey) private var darkModeEnabled = true
    @AppStorage(AppTheme.paletteStorageKey) private var palette = AppTheme.defaultPalette
    @AppStorage(AppTheme.customColorStorageKey) private var customColorHex = ""
    @AppStorage(AppTheme.useCustomColorStorageKey) private var useCustomColor = false
    @State private var customColor = Color.orange
    @AppStorage(AppTheme.glassOpacityStorageKey) private var glassOpacity = 0.55
    @AppStorage(AppTheme.blurStorageKey) private var blurAmount = 0.72
    @AppStorage(AppTheme.densityStorageKey) private var density = "normal"
    @AppStorage(AppTheme.layoutStorageKey) private var layout = "list"
    @AppStorage(AppTheme.themeStyleStorageKey) private var themeStyle = "midnight"

    var body: some View {
        AnyView(NavigationStack {
            Form {
                Section(language.text("settings.language")) {
                    Picker(language.text("settings.language"), selection: $languageCode) {
                        ForEach(AppLanguage.allCases) { option in
                            Text(option.displayName).tag(option.rawValue)
                        }
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                }

                Section {
                    Toggle(isOn: $darkModeEnabled) {
                        Label(
                            darkModeEnabled ? "Modo dark ativado" : "Modo claro ativado",
                            systemImage: darkModeEnabled ? "moon.fill" : "sun.max.fill"
                        )
                    }
                    Toggle("Usar cor personalizada", isOn: $useCustomColor)
                    Picker("Cor do app", selection: $palette) {
                        Text("Coral").tag("coral")
                        Text("Azul").tag("blue")
                        Text("Roxo").tag("purple")
                        Text("Verde").tag("green")
                        Text("Rosa").tag("pink")
                    }
                    .pickerStyle(.menu)
                    .onChange(of: palette) { _ in
                        customColorHex = ""
                        useCustomColor = false
                    }
                    ColorPicker("Cor personalizada", selection: $customColor, supportsOpacity: false)
                        .disabled(!useCustomColor)
                        .onChange(of: customColor) { color in
                            customColorHex = color.hexValue()
                        }
                    VStack(alignment: .leading, spacing: 5) {
                        HStack {
                            Text("Transparência")
                            Spacer()
                            Text("\(Int(glassOpacity * 100))%")
                        }
                        .font(.caption)
                        Slider(value: $glassOpacity, in: 0.25...0.9)
                    }
                    VStack(alignment: .leading, spacing: 5) {
                        HStack {
                            Text("Intensidade do blur")
                            Spacer()
                            Text("\(Int(blurAmount * 100))%")
                        }
                        .font(.caption)
                        Slider(value: $blurAmount, in: 0.15...1.0)
                    }
                    Picker("Tema visual", selection: $themeStyle) {
                        Text("Midnight Glass").tag("midnight")
                        Text("Aurora").tag("aurora")
                        Text("Crystal").tag("crystal")
                        Text("Neon Holographic").tag("neon")
                        Text("Carbon Pro").tag("carbon")
                    }
                    Picker("Densidade", selection: $density) {
                        Text("Compacta").tag("compact")
                        Text("Normal").tag("normal")
                        Text("Espaçada").tag("spacious")
                    }
                    Picker("Visual dos patches", selection: $layout) {
                        Text("Lista").tag("list")
                        Text("Cartões").tag("cards")
                    }
                    HStack(spacing: 12) {
                        Text("Paleta global")
                        Spacer()
                        ForEach(["coral", "blue", "purple", "green", "pink"], id: \.self) { option in
                            Circle()
                                .fill(paletteColor(option))
                                .frame(width: 25, height: 25)
                                .overlay {
                                    Circle().stroke(.white, lineWidth: palette == option ? 2 : 0)
                                }
                                .shadow(color: paletteColor(option).opacity(0.55), radius: palette == option ? 5 : 0)
                                .onTapGesture {
                                    palette = option
                                    customColorHex = ""
                                    useCustomColor = false
                                }
                        }
                    }
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Pré-visualização")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                        HStack {
                            Image(systemName: "sparkles")
                            Text("Glass 26").fontWeight(.semibold)
                            Spacer()
                            Text("Ativo")
                                .font(.caption.weight(.bold))
                                .padding(.horizontal, 9)
                                .padding(.vertical, 5)
                                .background(.white.opacity(0.18), in: Capsule())
                        }
                        .foregroundStyle(.white)
                        .padding(14)
                        .background(AppTheme.accentGradient, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(.white.opacity(0.2)))
                    }
                } header: {
                    Text("Aparência")
                } footer: {
                    Text("A cor é aplicada globalmente aos botões, seleções e destaques.")
                }

                Section(language.text("common.device")) {
                    LabeledContent(language.text("dashboard.hardware_model"), value: AppInfo.displayMachineName)
                    LabeledContent(language.text("settings.ios_version"), value: "\(AppInfo.osVersion) (\(AppInfo.osBuild))")
                }

                Section("Diagnóstico seguro") {
                    LabeledContent("Sessão", value: licenseManager.isAuthorized ? "Key ativa" : "Bloqueada")
                    LabeledContent("API", value: licenseManager.isAuthorized ? "Conectada" : "Aguardando key")
                    LabeledContent("Sincronização", value: licenseManager.isAuthorized ? "Automática · 2s" : "Desativada")
                    if let expiration = licenseManager.expirationDate {
                        LabeledContent("Validade", value: expiration.formatted(date: .abbreviated, time: .shortened))
                    }
                    LabeledContent("Dispositivo", value: AppInfo.displayMachineName)
                } footer: {
                    Text("Patches remotos só são baixados durante uma sessão autorizada.")
                }

                Section {
                    HStack {
                        Text(language.text("settings.current_version"))
                        Spacer()
                        Text(language.text(appState.isSupported ? "settings.supported" : "settings.unsupported"))
                        .foregroundStyle(appState.isSupported ? Color.green : Color.red)
                    }
                    LabeledContent("iOS 17", value: ExploitSupportPolicy.verifiedIOS17Range)
                    LabeledContent("iOS 18", value: ExploitSupportPolicy.verifiedIOS18Range)
                    LabeledContent("iOS 26", value: ExploitSupportPolicy.verifiedIOS26Range)
                    VStack(alignment: .leading, spacing: 8) {
                        Text("iOS 27.0")
                            .font(.body)
                        ForEach(ExploitSupportPolicy.verifiedIOS27Builds, id: \.build) { version in
                            Text(versionLabel(version))
                            .font(.caption.monospaced())
                            .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 2)
                } header: {
                    Text(language.text("settings.verified_versions"))
                } footer: {
                    Text(language.text("settings.supported_versions_footer"))
                }

            }
            .tint(AppTheme.accent)
            .navigationTitle(language.text("settings.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(language.text("common.done")) { dismiss() }
                        .fontWeight(.semibold)
                    }
                }
            }
            .onAppear {
                if !customColorHex.isEmpty { customColor = Color(hex: customColorHex) }
            }
        })
    }

    private func paletteColor(_ value: String) -> Color {
        switch value {
        case "blue": return .cyan
        case "purple": return .purple
        case "green": return .green
        case "pink": return .pink
        default: return Color(red: 1.00, green: 0.50, blue: 0.28)
        }
    }

    private var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "AppReleaseDisplayVersion") as? String
            ?? Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
            ?? "1.0"
    }

    private func versionLabel(
        _ version: (beta: Int, publicBeta: Int?, build: String)
    ) -> String {
        if let publicBeta = version.publicBeta {
            return language.text(
                "settings.developer_public_beta_build",
                Int64(version.beta),
                Int64(publicBeta),
                version.build
            )
        }
        return language.text(
            "settings.developer_beta_build",
            Int64(version.beta),
            version.build
        )
    }

    @ViewBuilder
    private func creditsRow(name: String, role: String, url: String) -> some View {
        if let destination = URL(string: url) {
            Link(destination: destination) {
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(name)
                            .font(.headline)
                            .foregroundStyle(.primary)
                        Text(role)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(AppTheme.accent)
                        .frame(width: 28, height: 28)
                }
                .contentShape(Rectangle())
            }
            .accessibilityLabel(language.text("accessibility.open_profile", name))
        }
    }
}
