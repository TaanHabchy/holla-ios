import Foundation

enum Config {
    static let supabaseURL = URL(string: Secrets.supabaseURL)!
    static let supabaseAnonKey = Secrets.supabaseAnonKey
    static let apiBaseURL = URL(string: Secrets.apiBaseURL)!
}
