import SwiftUI

struct ExternalView: View {
    @EnvironmentObject private var patchStore: PatchProjectStore
    @EnvironmentObject private var repositoryStore: PackageRepositoryStore
    private enum Category: String, CaseIterable, Identifiable {
        case aim = "MIRA"
        case esp = "ESP"
        case general = "GERAL"
        case xray = "RAIO-X"

        var id: String { rawValue }

        var icon: String {
            switch self {
            case .aim: return "scope"
            case .esp: return "eye.fill"
            case .general: return "slider.horizontal.3"
            case .xray: return "viewfinder"
            }
        }
    }

    @State private var selectedCategory: Category = .aim
    @State private var distance = 120.0
    @State private var showPatchActions = false
    @State private var isApplying = false
    @State private var isRestoring = false

    @AppStorage("external.aimbotOnFire") private var aimbotOnFire = false
    @AppStorage("external.prioritizeHead") private var prioritizeHead = false
    @AppStorage("external.fineAim") private var fineAim = false
    @AppStorage("external.quickHeal") private var quickHeal = false
    @AppStorage("external.espBox") private var espBox = false
    @AppStorage("external.espHealth") private var espHealth = false
    @AppStorage("external.espName") private var espName = false
    @AppStorage("external.espDistance") private var espDistance = false
    @AppStorage("external.espDirection") private var espDirection = false
    @AppStorage("external.markEnemies") private var markEnemies = false
    @AppStorage("external.generalHighlight") private var generalHighlight = false
    @AppStorage("external.generalTouch") private var generalTouch = false
    @AppStorage("external.xrayGrid") private var xrayGrid = false
    @AppStorage("external.xrayContrast") private var xrayContrast = false
    @AppStorage("external.fireRate") private var fireRate = "NORMAL"

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 0) {
                header
                Divider().overlay(Color.white.opacity(0.08))
                HStack(spacing: 0) {
                    sidebar
                    Divider().overlay(Color.white.opacity(0.08))
                    content
                }
                footer
            }
        }
        .preferredColorScheme(.dark)
    }

    private var header: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.red.opacity(0.16))
                    .frame(width: 40, height: 40)
                Image(systemName: "bolt.fill")
                    .font(.system(size: 19, weight: .bold))
                    .foregroundStyle(.red)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text("ProjectX")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.white)
                Text("PAINEL EXTERNO")
                    .font(.system(size: 9, weight: .bold, design: .rounded))
                    .tracking(1.8)
                    .foregroundStyle(.gray)
            }
            Spacer()
            HStack(spacing: 6) {
                Circle().fill(Color.green).frame(width: 7, height: 7)
                Text("ONLINE")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(.green)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(Color.green.opacity(0.10), in: Capsule())
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
    }

    private var sidebar: some View {
        VStack(spacing: 8) {
            ForEach(Category.allCases) { category in
                Button {
                    withAnimation(.easeInOut(duration: 0.18)) { selectedCategory = category }
                } label: {
                    VStack(spacing: 7) {
                        Image(systemName: category.icon)
                            .font(.system(size: 19, weight: .semibold))
                        Text(category.rawValue)
                            .font(.system(size: 9, weight: .bold, design: .rounded))
                    }
                    .foregroundStyle(selectedCategory == category ? .red : .gray)
                    .frame(maxWidth: .infinity)
                    .frame(height: 66)
                    .background(selectedCategory == category ? Color.red.opacity(0.13) : .clear, in: RoundedRectangle(cornerRadius: 10))
                    .overlay(alignment: .leading) {
                        if selectedCategory == category {
                            Capsule().fill(Color.red).frame(width: 3, height: 32)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
            Spacer()
        }
        .padding(.horizontal, 8)
        .padding(.top, 14)
        .frame(width: 92)
        .background(Color(red: 0.035, green: 0.035, blue: 0.04))
    }

    private var content: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 18) {
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(selectedCategory.rawValue)
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                        Text("Configurações visuais do painel")
                            .font(.caption)
                            .foregroundStyle(.gray)
                    }
                    Spacer()
                    Image(systemName: selectedCategory.icon)
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(.red)
                }

                switch selectedCategory {
                case .aim: aimSection
                case .esp: espSection
                case .general: generalSection
                case .xray: xraySection
                }
            }
            .padding(18)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var aimSection: some View {
        VStack(spacing: 10) {
            sectionTitle("AIMBOT", icon: "scope")
            ExternalToggleRow(title: "Aimbot ao disparar", subtitle: "Preferência visual de assistência", isOn: $aimbotOnFire)
            ExternalToggleRow(title: "Priorizar cabeça", subtitle: "Preferência visual de alvo", isOn: $prioritizeHead)
            ExternalToggleRow(title: "Ajuste fino da mira", subtitle: "Controle visual de suavidade", isOn: $fineAim)
            ExternalToggleRow(title: "Cura rápida", subtitle: "Preferência visual de interface", isOn: $quickHeal)
            rateSelector
        }
    }

    private var espSection: some View {
        VStack(spacing: 10) {
            sectionTitle("PLAYER ESP", icon: "eye.fill")
            ExternalToggleRow(title: "Caixa", subtitle: "Exibição visual de caixa", isOn: $espBox)
            ExternalToggleRow(title: "Vida", subtitle: "Exibição visual de vida", isOn: $espHealth)
            ExternalToggleRow(title: "Nome", subtitle: "Exibição visual de nome", isOn: $espName)
            ExternalToggleRow(title: "Distância", subtitle: "Exibição visual de distância", isOn: $espDistance)
            ExternalToggleRow(title: "Direção", subtitle: "Exibição visual de direção", isOn: $espDirection)
            ExternalToggleRow(title: "Marcar inimigos", subtitle: "Destaque visual de itens", isOn: $markEnemies)
            distanceSlider
        }
    }

    private var generalSection: some View {
        VStack(spacing: 10) {
            sectionTitle("GERAL", icon: "slider.horizontal.3")
            ExternalToggleRow(title: "Realçar interface", subtitle: "Usar destaque vermelho no painel", isOn: $generalHighlight)
            ExternalToggleRow(title: "Controles avançados", subtitle: "Mostrar preferências extras", isOn: $generalTouch)
            infoCard("Estas opções são somente visuais e ficam salvas localmente no app.")
        }
    }

    private var xraySection: some View {
        VStack(spacing: 10) {
            sectionTitle("RAIO-X", icon: "viewfinder")
            ExternalToggleRow(title: "Grade visual", subtitle: "Exibir grade de referência", isOn: $xrayGrid)
            ExternalToggleRow(title: "Contraste", subtitle: "Ajustar contraste da interface", isOn: $xrayContrast)
            infoCard("O modo External não modifica, injeta ou controla outros aplicativos.")
        }
    }

    private var rateSelector: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("INTERVALO DE TIRO")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(.gray)
            HStack(spacing: 6) {
                ForEach(["NORMAL", "90%", "85%", "75%", "65%"], id: \.self) { rate in
                    Button { fireRate = rate } label: {
                        Text(rate)
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundStyle(fireRate == rate ? .white : .gray)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(fireRate == rate ? Color.red : Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 7))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(14)
        .background(Color.white.opacity(0.045), in: RoundedRectangle(cornerRadius: 12))
    }

    private var distanceSlider: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("DISTÂNCIA DOS EFEITOS")
                Spacer()
                Text("\(Int(distance)) m").foregroundStyle(.red)
            }
            .font(.system(size: 11, weight: .bold, design: .rounded))
            .foregroundStyle(.gray)
            Slider(value: $distance, in: 10...200, step: 5)
                .tint(.red)
        }
        .padding(14)
        .background(Color.white.opacity(0.045), in: RoundedRectangle(cornerRadius: 12))
    }

    private func sectionTitle(_ title: String, icon: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon).foregroundStyle(.red)
            Text(title).font(.system(size: 13, weight: .bold, design: .rounded)).foregroundStyle(.white)
            Spacer()
        }
        .padding(.bottom, 2)
    }

    private func infoCard(_ text: String) -> some View {
        Text(text)
            .font(.caption)
            .foregroundStyle(.gray)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .background(Color.red.opacity(0.07), in: RoundedRectangle(cornerRadius: 12))
    }

    private var footer: some View {
        HStack(spacing: 10) {
            Button {
                resetAll()
                showPatchActions = false
            } label: {
                Label("LIMPAR DADOS", systemImage: "trash")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 13)
                    .foregroundStyle(.gray)
                    .background(Color.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 9))
            }
            .buttonStyle(.plain)
            .disabled(isApplying || isRestoring)
            Button {
                showPatchActions = true
            } label: {
                Label("INICIAR", systemImage: "play.fill")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 13)
                    .foregroundStyle(.white)
                    .background(Color.red, in: RoundedRectangle(cornerRadius: 9))
            }
            .buttonStyle(.plain)
            .disabled(isApplying || isRestoring)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Color(red: 0.035, green: 0.035, blue: 0.04))
        .sheet(isPresented: $showPatchActions) {
            ExternalPatchActionsSheet(
                isApplying: $isApplying,
                isRestoring: $isRestoring,
                onApply: applyExternalPatches,
                onRestore: restoreExternalPatches
            )
            .presentationDetents([.height(250)])
            .presentationDragIndicator(.visible)
        }
    }

    private func resetAll() {
        aimbotOnFire = false
        prioritizeHead = false
        fineAim = false
        quickHeal = false
        espBox = false
        espHealth = false
        espName = false
        espDistance = false
        espDirection = false
        markEnemies = false
        generalHighlight = false
        generalTouch = false
        xrayGrid = false
        xrayContrast = false
        fireRate = "NORMAL"
        distance = 120
    }

    private func applyExternalPatches() {
        isApplying = true
        Task {
            await repositoryStore.applyExternalPatches(using: patchStore)
            isApplying = false
            showPatchActions = false
        }
    }

    private func restoreExternalPatches() {
        isRestoring = true
        Task {
            await repositoryStore.restoreExternalPatches(using: patchStore)
            isRestoring = false
            showPatchActions = false
        }
    }
}

private struct ExternalPatchActionsSheet: View {
    @Binding var isApplying: Bool
    @Binding var isRestoring: Bool
    let onApply: () -> Void
    let onRestore: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            Text("PATCH EXTERNAL")
                .font(.headline.weight(.bold))
            Text("Escolha uma ação para o patch enviado pelo site.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button(action: onApply) {
                Label(isApplying ? "APLICANDO..." : "APLICAR PATCH", systemImage: "checkmark.shield.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(.red)
            .disabled(isApplying || isRestoring)
            Button(action: onRestore) {
                Label(isRestoring ? "RESTAURANDO..." : "RESTAURAR ORIGINAL", systemImage: "arrow.uturn.backward.circle")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .disabled(isApplying || isRestoring)
        }
        .padding(20)
    }
}

private struct ExternalToggleRow: View {
    let title: String
    let subtitle: String
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.subheadline.weight(.semibold)).foregroundStyle(.white)
                Text(subtitle).font(.caption).foregroundStyle(.gray)
            }
            Spacer()
            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(.red)
        }
        .padding(13)
        .background(Color.white.opacity(0.045), in: RoundedRectangle(cornerRadius: 12))
    }
}
