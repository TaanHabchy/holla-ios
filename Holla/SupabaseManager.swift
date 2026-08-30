import Foundation
import Supabase

enum SupabaseManager {
    static let client = SupabaseClient(
        supabaseURL: Config.supabaseURL,
        supabaseKey: Config.supabaseAnonKey
    )
}
