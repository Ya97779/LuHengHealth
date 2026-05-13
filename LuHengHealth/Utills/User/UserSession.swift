//  负责用户认证、登录状态、账号管理
//  使用UserDefaults


import Foundation
import Combine


struct UserProfile: Codable, Equatable {
    var username: String
    var password: String
    var displayName: String
    var email: String
    var phone: String
    var userId: String
    var avatarSystemName: String?
    var avatarAssetName: String?
    var fansCount: Int
    var followingCount: Int
}

enum LoginFailure: Error, Equatable {
    case emptyFields
    case usernameNotFound
    case passwordIncorrect
}

final class UserSession: ObservableObject {
    static let storageKey = "UserProfileStorageKey"
    static let seededKey = "UserProfileSeededKey"
    static let registeredUsersKey = "RegisteredUsersStorageKey"

    @Published var isLoggedIn: Bool = false
    @Published var profile: UserProfile? = nil
    private(set) var registeredUsers: [String: String] = [:] // username -> password

    init() {
        loadFromDefaults()
        loadRegisteredUsers()
        #if DEBUG
        ensureDefaultUsersRegistered()
        #endif
        // 预览环境（Xcode Previews）下也确保有默认账号
        if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" {
            ensureDefaultUsersRegistered()
        }
    }

    func login(username: String, password: String) -> Bool {
        guard !username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              !password.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return false
        }

        // 优先使用模拟远程资料填充完整信息
        if let remote = MockRemoteUsers.shared.fetchUser(username: username) {
            let newProfile = UserProfile(
                username: remote.username,
                password: password,
                displayName: remote.displayName,
                email: "",
                phone: "",
                userId: remote.userId,
                avatarSystemName: remote.avatarSystemName,
                avatarAssetName: remote.avatarAssetName,
                fansCount: remote.fansCount,
                followingCount: remote.followingCount
            )
            profile = newProfile
            isLoggedIn = true
            saveToDefaults()
            return true
        }

        // 找不到远程资料则使用本地默认信息
        let newProfile = UserProfile(
            username: username,
            password: password,
            displayName: username,
            email: "",
            phone: "",
            userId: username,
            avatarSystemName: "person.fill",
            avatarAssetName: nil,
            fansCount: 0,
            followingCount: 0
        )
        profile = newProfile
        isLoggedIn = true
        saveToDefaults()
        return true
    }

    /// 尝试校验登录信息，区分错误类型
    func attemptLogin(username: String, password: String) -> Result<Void, LoginFailure> {
        let trimmedUser = username.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedPass = password.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedUser.isEmpty, !trimmedPass.isEmpty else {
            return .failure(.emptyFields)
        }
        // 先使用“远程”数据进行校验
        if let remote = MockRemoteUsers.shared.authenticate(username: trimmedUser, password: trimmedPass) {
            // 同步注册表
            registeredUsers[trimmedUser] = trimmedPass
            saveRegisteredUsers()
            // 填充完整的资料
            let profile = UserProfile(
                username: remote.username,
                password: remote.password,
                displayName: remote.displayName,
                email: "",
                phone: "",
                userId: remote.userId,
                avatarSystemName: remote.avatarSystemName,
                avatarAssetName: remote.avatarAssetName,
                fansCount: remote.fansCount,
                followingCount: remote.followingCount
            )
            self.profile = profile
            self.isLoggedIn = true
            saveToDefaults()
            return .success(())
        }
        // 若远程未命中，再走本地注册表
        guard let storedPassword = registeredUsers[trimmedUser] else {
            return .failure(.usernameNotFound)
        }
        guard storedPassword == trimmedPass else {
            return .failure(.passwordIncorrect)
        }
        _ = login(username: trimmedUser, password: trimmedPass)
        return .success(())
    }

    func logout() {
        isLoggedIn = false
        profile = nil
        clearDefaults()
    }

    func updateProfile(displayName: String? = nil, email: String? = nil, phone: String? = nil) {
        guard var current = profile else { return }
        if let displayName = displayName { current.displayName = displayName }
        if let email = email { current.email = email }
        if let phone = phone { current.phone = phone }
        profile = current
        saveToDefaults()
    }

    private func loadFromDefaults() {
        guard let data = UserDefaults.standard.data(forKey: Self.storageKey) else { return }
        if let decoded = try? JSONDecoder().decode(UserProfile.self, from: data) {
            profile = decoded
            isLoggedIn = true
        }
    }

    private func saveToDefaults() {
        guard let profile else { return }
        if let data = try? JSONEncoder().encode(profile) {
            UserDefaults.standard.set(data, forKey: Self.storageKey)
        }
    }

    private func clearDefaults() {
        UserDefaults.standard.removeObject(forKey: Self.storageKey)
    }

    /// 仅在本地无已登录用户时，种入一个测试账号并自动登录一次
    func seedDefaultAccountIfNeeded(username: String, password: String) {
        // 确保注册表中存在此用户
        if registeredUsers[username] == nil {
            registerUser(username: username, password: password)
        }
        // 若还未有登录会话且未种入过，自动登录一次
        guard UserDefaults.standard.data(forKey: Self.storageKey) == nil else { return }
        guard UserDefaults.standard.bool(forKey: Self.seededKey) == false else { return }
        _ = login(username: username, password: password)
        UserDefaults.standard.set(true, forKey: Self.seededKey)
    }

    // MARK: - 用户注册与持久化
    func registerUser(username: String, password: String) {
        registeredUsers[username] = password
        saveRegisteredUsers()
    }

    private func loadRegisteredUsers() {
        if let dict = UserDefaults.standard.dictionary(forKey: Self.registeredUsersKey) as? [String: String] {
            registeredUsers = dict
        }
    }

    private func saveRegisteredUsers() {
        UserDefaults.standard.set(registeredUsers, forKey: Self.registeredUsersKey)
    }

    private func ensureDefaultUsersRegistered() {
        let defaults: [(String, String)] = [
            ("140", "123456"),
            ("1402375281", "123456"),
            ("123", "123")
        ]
        var changed = false
        for (u, p) in defaults {
            if registeredUsers[u] == nil {
                registeredUsers[u] = p
                changed = true
            }
        }
        if changed { saveRegisteredUsers() }
    }

    // MARK: - 维护工具：清空所有持久化数据
    func clearAllPersistedData() {
        // 清空会话和注册信息以及种子标记
        UserDefaults.standard.removeObject(forKey: Self.storageKey)
        UserDefaults.standard.removeObject(forKey: Self.registeredUsersKey)
        UserDefaults.standard.removeObject(forKey: Self.seededKey)

        // 重置内存状态
        isLoggedIn = false
        profile = nil
        registeredUsers = [:]
    }
}


