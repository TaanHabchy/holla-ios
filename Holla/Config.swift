import Foundation

enum Config {
    static let supabaseURL = URL(string: Secrets.supabaseURL)!
    static let supabaseAnonKey = Secrets.supabaseAnonKey
    static let backendBaseURL = URL(string: Secrets.backendBaseURL)!
    /// Legacy .NET backend; only contacts sync and add friend still go here.
    static let apiBaseURL = URL(string: Secrets.apiBaseURL)!
}
