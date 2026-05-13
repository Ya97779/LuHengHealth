import Foundation

struct RemoteUserRecord: Codable, Equatable {
    let username: String
    let password: String
    let displayName: String
    let userId: String
    let avatarSystemName: String?
    let avatarAssetName: String?
    let fansCount: Int
    let followingCount: Int
}

final class MockRemoteUsers {
    static let shared = MockRemoteUsers()

    private let usersByUsername: [String: RemoteUserRecord]

    private init() {
        let records: [RemoteUserRecord] = [
            RemoteUserRecord(
                username: "140",
                password: "123456",
                displayName: "小明",
                userId: "1000140",
                avatarSystemName: "person.crop.circle.fill",
                avatarAssetName: nil,
                fansCount: 128,
                followingCount: 56
            ),
            RemoteUserRecord(
                username: "140237",
                password: "123456",
                displayName: "Mercy",
                userId: "1402375281",
                avatarSystemName: "person.fill",
                avatarAssetName: nil,
                fansCount: 5231,
                followingCount: 321
            ),
            RemoteUserRecord(
                username: "123",
                password: "123",
                displayName: "测试用户",
                userId: "1000123",
                avatarSystemName: "person.circle.fill",
                avatarAssetName: nil,
                fansCount: 12,
                followingCount: 8
            )
        ]
        var map: [String: RemoteUserRecord] = [:]
        for r in records { map[r.username] = r }
        self.usersByUsername = map
    }

    func fetchUser(username: String) -> RemoteUserRecord? {
        return usersByUsername[username]
    }

    func authenticate(username: String, password: String) -> RemoteUserRecord? {
        guard let user = usersByUsername[username] else { return nil }
        guard user.password == password else { return nil }
        return user
    }
}


