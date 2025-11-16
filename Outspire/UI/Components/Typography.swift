import SwiftUI

// Apple-aligned text styles for consistent hierarchy.
public enum AppText {
    // Use a true title ramp for card and section titles
    public static var title: Font { .title2.weight(.semibold) }
    // Primary reading size
    public static var body: Font { .body }
    // Secondary/meta information
    public static var meta: Font { .footnote }
}
