import SwiftUI

struct Theme: Equatable {
    var bg: Color
    var card: Color
    var darkCard: Color
    var fg: Color
    var comment: Color
    var blue: Color
    var cyan: Color
    var green: Color
    var yellow: Color
    var red: Color
    var purple: Color
    var magenta: Color
    var orange: Color

    static let base = Theme(
        bg:       TN.bg,
        card:     TN.card,
        darkCard: TN.darkCard,
        fg:       TN.fg,
        comment:  TN.comment,
        blue:     TN.blue,
        cyan:     TN.cyan,
        green:    TN.green,
        yellow:   TN.yellow,
        red:      TN.red,
        purple:   TN.purple,
        magenta:  TN.magenta,
        orange:   TN.orange
    )
}

private struct ThemeKey: EnvironmentKey {
    static let defaultValue: Theme = .base
}

extension EnvironmentValues {
    var theme: Theme {
        get { self[ThemeKey.self] }
        set { self[ThemeKey.self] = newValue }
    }
}
