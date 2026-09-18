import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.appLanguage) private var language
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var licenseManager: LicenseManager

    @AppStorage(AppLanguage.storageKey) private var languageCode = AppLanguage.english.rawValue
    @AppStorage(AppTheme.darkModeStorageKey) private var darkModeEnabled = true
    @AppStorage(AppTheme.paletteStorageKey) private var palette = AppTheme.defaultPalette
    @AppStorage(AppTheme.customColorStorageKey) private var customColorHex = ""
    @AppStorage(AppTheme.useCustomColorStorageKey) private var useCustomColor = false
    @AppStorage(AppTheme.glassOpacityStorageKey) private var glassOpacity = 0.55
    @AppStorage(AppTheme.blurStorageKey) private var blurAmount = 0.72
    @AppStorage(AppTheme.densityStorageKey) private var density = "normal"
    @AppStorage(AppTheme.layoutStorageKey) private var layout = "list"
    @AppStorage(AppTheme.themeStyleStorageKey) private var themeStyle = "midnight"
    @State private var customColor = Color.orange

    var body: some View {
        NavigationStack {
            Form {
                languageSection
                appearanceSection
                deviceSection
                diagnosticsSection
                compatibilitySection
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
            .onAppear {
                if !customColorHex.isEmpty { customColor = Color(hex: customColorHex) }
            }
        }
    }

    private var languageSection: some View {
        Section(language.text("settings.language")) {
            Picker(language.text("settings.language"), selection: $languageCode) {
                ForEach(AppLanguage.allCases) { option in
                    Text(option.displayName).tag(option.rawValue)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
        }
    }

    private var appearanceSection: some View {
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
            paletteSwatches
            SliderRow(title: "Transparência", value: $glassOpacity, range: 0.25...0.9)
            SliderRow(title: "Intensidade do blur", value: $blurAmount, range: 0.15...1.0)
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
            appearancePreview
        } header: {
            Text("Aparência")
        } footer: {
            Text("A paleta pronta e a cor personalizada são modos separados. Ative somente o modo que deseja usar.")
        }
    }

    private var paletteSwatches: some View {
        HStack(spacing: 12) {
            Text("Paleta global")
            Spacer()
            ForEach(["coral", "blue", "purple", "green", "pink"], id: \.self) { option in
                Circle()
                    .fill(paletteColor(option))
                    .frame(width: 25, height: 25)
                    .overlay(Circle().stroke(.white, lineWidth: palette == option && !useCustomColor ? 2 : 0))
                    .shadow(color: paletteColor(option).opacity(0.55), radius: palette == option ? 5 : 0)
                    .onTapGesture {
                        palette = option
                        customColorHex = ""
                        useCustomColor = false
                    }
            }
        }
    }

    private var appearancePreview: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Pré-visualização").font(.caption.weight(.semibold)).foregroundStyle(.secondary)
            HStack {
                Image(systemName: "sparkles")
                Text("Glass 26").fontWeight(.semibold)
                Spacer()
                Text(useCustomColor ? "Personalizado" : "Paleta")
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
    }

    private var deviceSection: some View {
        Section(language.text("common.device")) {
            LabeledContent(language.text("dashboard.hardware_model"), value: AppInfo.displayMachineName)
            LabeledContent(language.text("settings.ios_version"), value: "\(AppInfo.osVersion) (\(AppInfo.osBuild))")
        }
    }

    private var diagnosticsSection: some View {
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
    }

    private var compatibilitySection: some View {
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
            ForEach(ExploitSupportPolicy.verifiedIOS27Builds, id: \.build) { version in
                Text(versionLabel(version)).font(.caption.monospaced()).foregroundStyle(.secondary)
            }
        } header: {
            Text(language.text("settings.verified_versions"))
        } footer: {
            Text(language.text("settings.supported_versions_footer"))
        }
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

    private func versionLabel(_ version: (beta: Int, publicBeta: Int?, build: String)) -> String {
        if let publicBeta = version.publicBeta {
            return language.text("settings.developer_public_beta_build", Int64(version.beta), Int64(publicBeta), version.build)
        }
        return language.text("settings.developer_beta_build", Int64(version.beta), version.build)
    }
}

private struct SliderRow: View {
    let title: String
    @Binding var value: Double
    let range: ClosedRange<Double>

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Text(title)
                Spacer()
                Text("\(Int(value * 100))%")
            }
            .font(.caption)
            Slider(value: $value, in: range)
        }
    }
}
