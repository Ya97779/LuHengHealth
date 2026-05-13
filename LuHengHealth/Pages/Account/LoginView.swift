import SwiftUI

struct LoginView: View {
    @EnvironmentObject var userSession: UserSession
    @State private var username: String = ""
    @State private var password: String = ""
    @State private var errorMessage: String? = nil
    @State private var showAlert: Bool = false

    var body: some View {
        VStack(spacing: 24) {
            Spacer(minLength: 40)

            VStack(spacing: 8) {
                Text("欢迎登陆")
                    .font(.system(size: 28, weight: .bold))
                Text("请使用您的账号密码登陆")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
            }

            VStack(spacing: 16) {
                TextField("用户名", text: $username)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled(true)
                    .padding(14)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(10)

                SecureField("密码", text: $password)
                    .padding(14)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(10)
            }
            .padding(.horizontal, 24)

            Button(action: handleLogin) {
                Text("登陆")
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.orange)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 24)
            .alert(isPresented: $showAlert) {
                Alert(title: Text("登陆失败"), message: Text(errorMessage ?? "未知错误"), dismissButton: .default(Text("我知道了")))
            }

            Button(role: .destructive) {
                userSession.clearAllPersistedData()
            } label: {
                Text("清空历史数据")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
            }
            .padding(.horizontal, 24)

            Spacer()
        }
        .background(Color.white.ignoresSafeArea())
    }

    private func handleLogin() {
        switch userSession.attemptLogin(username: username, password: password) {
        case .success:
            errorMessage = nil
        case .failure(let failure):
            switch failure {
            case .emptyFields:
                errorMessage = "用户名和密码不能为空"
            case .usernameNotFound:
                errorMessage = "用户名不存在"
            case .passwordIncorrect:
                errorMessage = "密码错误"
            }
            showAlert = true
        }
    }
}

#Preview {
    LoginView().environmentObject(UserSession())
}


