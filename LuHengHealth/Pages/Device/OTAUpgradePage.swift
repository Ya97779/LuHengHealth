//
//  OTAUpgradePage.swift
//  LuHengHealth
//
//  OTA固件升级页面
//  提供固件选择、升级进度显示和日志记录功能

import SwiftUI
import UniformTypeIdentifiers

struct OTAUpgradePage: View {
    @EnvironmentObject var viewModel: BLEViewModel
    @StateObject private var otaService = BLEOTAService()
    @Environment(\.dismiss) private var dismiss
    
    @State private var showFilePicker = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // 设备信息卡片
                    deviceInfoCard
                    
                    // 固件选择卡片
                    firmwareSelectionCard
                    
                    // 升级进度卡片
                    if otaService.state != .idle && otaService.state != .fileSelected {
                        progressCard
                    }
                    
                    // 升级日志卡片
                    if !otaService.logs.isEmpty {
                        logCard
                    }
                    
                    // 升级按钮
                    upgradeButton
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("OTA固件升级")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showFilePicker) {
                DocumentPicker { url in
                    loadFirmware(from: url)
                }
            }
            .onAppear {
                // 设置写入回调
                otaService.setWriteHandler { data in
                    viewModel.writeToFFE3(data)
                }
                // 设置OTA服务引用到ViewModel，用于接收OTA ACK
                viewModel.otaService = otaService
            }
            .onDisappear {
                // 清除OTA服务引用
                viewModel.otaService = nil
            }
            .alert("升级完成", isPresented: .constant(otaService.state == .complete)) {
                Button("确定") {
                    dismiss()
                }
            } message: {
                Text("固件升级已完成，请重启设备以完成更新。")
            }
            .alert("升级失败", isPresented: .constant(otaService.state == .failed)) {
                Button("重试") {
                    otaService.clearFirmware()
                }
                Button("取消") {
                    dismiss()
                }
            } message: {
                Text(otaService.errorMessage ?? "未知错误")
            }
        }
    }
    
    // MARK: - 设备信息卡片
    
    private var deviceInfoCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "info.circle.fill")
                    .foregroundColor(.blue)
                Text("设备信息")
                    .font(.headline)
                Spacer()
            }
            
            Divider()
            
            HStack {
                Text("设备名称")
                    .foregroundColor(.secondary)
                Spacer()
                Text(viewModel.connectedDevices.first?.name ?? "未连接")
                    .foregroundColor(.primary)
            }
            
            HStack {
                Text("固件版本")
                    .foregroundColor(.secondary)
                Spacer()
                if let version = viewModel.firmwareVersion {
                    Text("v\(version / 10).\(version % 10)")
                        .foregroundColor(.primary)
                } else {
                    Text("未获取")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
    
    // MARK: - 固件选择卡片
    
    private var firmwareSelectionCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "doc.fill")
                    .foregroundColor(.orange)
                Text("固件文件")
                    .font(.headline)
                Spacer()
            }
            
            Divider()
            
            if let fileName = otaService.firmwareFileName {
                // 已选择固件
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("已选择固件")
                            .font(.subheadline)
                            .foregroundColor(.green)
                    }
                    
                    Text(fileName)
                        .font(.body)
                        .foregroundColor(.primary)
                    
                    if let data = otaService.firmwareData {
                        Text("文件大小: \(data.count) 字节")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Button("重新选择") {
                        showFilePicker = true
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                }
            } else {
                // 未选择固件
                Button(action: {
                    showFilePicker = true
                }) {
                    VStack(spacing: 12) {
                        Image(systemName: "arrow.up.doc")
                            .font(.system(size: 40))
                            .foregroundColor(.blue)
                        
                        Text("点击选择 .bin 固件文件")
                            .font(.body)
                            .foregroundColor(.blue)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
    
    // MARK: - 进度卡片
    
    private var progressCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "arrow.up.circle.fill")
                    .foregroundColor(.blue)
                Text("升级进度")
                    .font(.headline)
                Spacer()
                
                // 状态标签
                Text(stateText)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(stateColor.opacity(0.2))
                    .foregroundColor(stateColor)
                    .cornerRadius(4)
            }
            
            Divider()
            
            // 进度条
            VStack(alignment: .leading, spacing: 8) {
                ProgressView(value: Double(otaService.progress), total: 100)
                    .progressViewStyle(LinearProgressViewStyle(tint: stateColor))
                    .scaleEffect(y: 2)
                
                HStack {
                    Text("\(otaService.progress)%")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(stateColor)
                    
                    Spacer()
                    
                    if otaService.state == .transferring {
                        Text("正在传输...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
    
    // MARK: - 日志卡片
    
    private var logCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "text.alignleft")
                    .foregroundColor(.gray)
                Text("升级日志")
                    .font(.headline)
                Spacer()
                
                Button("清除") {
                    otaService.logs.removeAll()
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
            
            Divider()
            
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 4) {
                    ForEach(otaService.logs) { log in
                        HStack(alignment: .top, spacing: 8) {
                            Text(log.timeString)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                                .frame(width: 60, alignment: .leading)
                            
                            Text(log.message)
                                .font(.caption)
                                .foregroundColor(log.isError ? .red : .primary)
                        }
                    }
                }
            }
            .frame(maxHeight: 200)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
    
    // MARK: - 升级按钮
    
    private var upgradeButton: some View {
        Button(action: {
            otaService.startOTA()
        }) {
            HStack {
                Image(systemName: buttonIcon)
                Text(buttonText)
            }
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(buttonColor)
            .cornerRadius(12)
        }
        .disabled(!isButtonEnabled)
    }
    
    // MARK: - 计算属性
    
    private var stateText: String {
        switch otaService.state {
        case .idle, .fileSelected:
            return "等待"
        case .entering:
            return "进入模式"
        case .transferring:
            return "传输中"
        case .verifying:
            return "验证中"
        case .complete:
            return "完成"
        case .failed:
            return "失败"
        }
    }
    
    private var stateColor: Color {
        switch otaService.state {
        case .idle, .fileSelected:
            return .gray
        case .entering, .transferring, .verifying:
            return .blue
        case .complete:
            return .green
        case .failed:
            return .red
        }
    }
    
    private var buttonText: String {
        switch otaService.state {
        case .idle:
            return "请先选择固件文件"
        case .fileSelected:
            return "开始升级"
        case .entering, .transferring, .verifying:
            return "升级中..."
        case .complete:
            return "升级完成"
        case .failed:
            return "升级失败，点击重试"
        }
    }
    
    private var buttonIcon: String {
        switch otaService.state {
        case .idle:
            return "doc.badge.arrow.up"
        case .fileSelected:
            return "arrow.up.circle.fill"
        case .entering, .transferring, .verifying:
            return "arrow.triangle.2.circlepath"
        case .complete:
            return "checkmark.circle.fill"
        case .failed:
            return "exclamationmark.triangle.fill"
        }
    }
    
    private var buttonColor: Color {
        switch otaService.state {
        case .idle:
            return .gray
        case .fileSelected:
            return .blue
        case .entering, .transferring, .verifying:
            return .orange
        case .complete:
            return .green
        case .failed:
            return .red
        }
    }
    
    private var isButtonEnabled: Bool {
        switch otaService.state {
        case .fileSelected, .failed:
            return true
        default:
            return false
        }
    }
    
    // MARK: - 方法
    
    private func loadFirmware(from url: URL) {
        guard url.startAccessingSecurityScopedResource() else {
            otaService.errorMessage = "无法访问文件"
            return
        }
        
        defer {
            url.stopAccessingSecurityScopedResource()
        }
        
        do {
            let data = try Data(contentsOf: url)
            let fileName = url.lastPathComponent
            
            // 验证文件扩展名
            guard fileName.hasSuffix(".bin") else {
                otaService.errorMessage = "请选择 .bin 格式的固件文件"
                return
            }
            
            // 验证文件大小
            guard data.count > 0 && data.count < 1024 * 1024 else {
                otaService.errorMessage = "固件文件大小异常"
                return
            }
            
            otaService.selectFirmware(data: data, fileName: fileName)
        } catch {
            otaService.errorMessage = "读取文件失败: \(error.localizedDescription)"
        }
    }
}

// MARK: - 文档选择器

struct DocumentPicker: UIViewControllerRepresentable {
    var onPick: (URL) -> Void
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(
            forOpeningContentTypes: [
                UTType(filenameExtension: "bin") ?? .data
            ]
        )
        picker.delegate = context.coordinator
        picker.allowsMultipleSelection = false
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let parent: DocumentPicker
        
        init(_ parent: DocumentPicker) {
            self.parent = parent
        }
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else { return }
            parent.onPick(url)
        }
    }
}

// MARK: - 预览

#Preview {
    OTAUpgradePage()
        .environmentObject(BLEViewModel())
}
