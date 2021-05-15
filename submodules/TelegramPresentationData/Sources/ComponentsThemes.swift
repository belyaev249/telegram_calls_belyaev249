import Foundation
import UIKit
import Display
import TelegramUIPreferences

public extension PresentationFontSize {
    init(systemFontSize: CGFloat) {
        var closestIndex = 0
        let allSizes = PresentationFontSize.allCases
        for i in 0 ..< allSizes.count {
            if abs(allSizes[i].baseDisplaySize - systemFontSize) < abs(allSizes[closestIndex].baseDisplaySize - systemFontSize) {
                closestIndex = i
            }
        }
        self = allSizes[closestIndex]
    }
}

public extension PresentationFontSize {
    var baseDisplaySize: CGFloat {
        switch self {
        case .extraSmall:
            return 14.0
        case .small:
            return 15.0
        case .medium:
            return 16.0
        case .regular:
            return 17.0
        case .large:
            return 19.0
        case .extraLarge:
            return 23.0
        case .extraLargeX2:
            return 26.0
        }
    }
}

public extension TabBarControllerTheme {
    convenience init(rootControllerTheme: PresentationTheme) {
        let theme = rootControllerTheme.rootController.tabBar
        self.init(backgroundColor: rootControllerTheme.list.plainBackgroundColor, tabBarBackgroundColor: theme.backgroundColor, tabBarSeparatorColor: theme.separatorColor, tabBarIconColor: theme.iconColor, tabBarSelectedIconColor: theme.selectedIconColor, tabBarTextColor: theme.textColor, tabBarSelectedTextColor: theme.selectedTextColor, tabBarBadgeBackgroundColor: theme.badgeBackgroundColor, tabBarBadgeStrokeColor: theme.badgeStrokeColor, tabBarBadgeTextColor: theme.badgeTextColor, tabBarExtractedIconColor: rootControllerTheme.contextMenu.extractedContentTintColor, tabBarExtractedTextColor: rootControllerTheme.contextMenu.extractedContentTintColor)
    }
}

public extension NavigationBarTheme {
    convenience init(rootControllerTheme: PresentationTheme, enableBackgroundBlur: Bool = true, hideBackground: Bool = false, hideBadge: Bool = false) {
        let theme = rootControllerTheme.rootController.navigationBar
        self.init(buttonColor: theme.buttonColor, disabledButtonColor: theme.disabledButtonColor, primaryTextColor: theme.primaryTextColor, backgroundColor: hideBackground ? .clear : theme.backgroundColor, enableBackgroundBlur: enableBackgroundBlur, separatorColor: hideBackground ? .clear : theme.separatorColor, badgeBackgroundColor: hideBadge ? .clear : theme.badgeBackgroundColor, badgeStrokeColor: hideBadge ? .clear : theme.badgeStrokeColor, badgeTextColor: hideBadge ? .clear : theme.badgeTextColor)
    }
}

public extension NavigationBarStrings {
    convenience init(presentationStrings: PresentationStrings) {
        self.init(back: presentationStrings.Common_Back, close: presentationStrings.Common_Close)
    }
}

public extension NavigationBarPresentationData {
    convenience init(presentationData: PresentationData) {
        self.init(theme: NavigationBarTheme(rootControllerTheme: presentationData.theme), strings: NavigationBarStrings(presentationStrings: presentationData.strings))
    }
    
    convenience init(presentationData: PresentationData, hideBackground: Bool, hideBadge: Bool) {
        self.init(theme: NavigationBarTheme(rootControllerTheme: presentationData.theme, hideBackground: hideBackground, hideBadge: hideBadge), strings: NavigationBarStrings(presentationStrings: presentationData.strings))
    }
    
    convenience init(presentationTheme: PresentationTheme, presentationStrings: PresentationStrings) {
        self.init(theme: NavigationBarTheme(rootControllerTheme: presentationTheme), strings: NavigationBarStrings(presentationStrings: presentationStrings))
    }
}

public extension ActionSheetControllerTheme {
    convenience init(presentationData: PresentationData) {
        let presentationTheme = presentationData.theme
        
        let actionSheet = presentationTheme.actionSheet
        self.init(dimColor: actionSheet.dimColor, backgroundType: actionSheet.backgroundType == .light ? .light : .dark, itemBackgroundColor: actionSheet.itemBackgroundColor, itemHighlightedBackgroundColor: actionSheet.itemHighlightedBackgroundColor, standardActionTextColor: actionSheet.standardActionTextColor, destructiveActionTextColor: actionSheet.destructiveActionTextColor, disabledActionTextColor: actionSheet.disabledActionTextColor, primaryTextColor: actionSheet.primaryTextColor, secondaryTextColor: actionSheet.secondaryTextColor, controlAccentColor: actionSheet.controlAccentColor, controlColor: presentationTheme.list.disclosureArrowColor, switchFrameColor: presentationTheme.list.itemSwitchColors.frameColor, switchContentColor: presentationTheme.list.itemSwitchColors.contentColor, switchHandleColor: presentationTheme.list.itemSwitchColors.handleColor, baseFontSize: presentationData.listsFontSize.baseDisplaySize)
    }
    
    convenience init(presentationTheme: PresentationTheme, fontSize: PresentationFontSize) {
        let actionSheet = presentationTheme.actionSheet
        self.init(dimColor: actionSheet.dimColor, backgroundType: actionSheet.backgroundType == .light ? .light : .dark, itemBackgroundColor: actionSheet.itemBackgroundColor, itemHighlightedBackgroundColor: actionSheet.itemHighlightedBackgroundColor, standardActionTextColor: actionSheet.standardActionTextColor, destructiveActionTextColor: actionSheet.destructiveActionTextColor, disabledActionTextColor: actionSheet.disabledActionTextColor, primaryTextColor: actionSheet.primaryTextColor, secondaryTextColor: actionSheet.secondaryTextColor, controlAccentColor: actionSheet.controlAccentColor, controlColor: presentationTheme.list.disclosureArrowColor, switchFrameColor: presentationTheme.list.itemSwitchColors.frameColor, switchContentColor: presentationTheme.list.itemSwitchColors.contentColor, switchHandleColor: presentationTheme.list.itemSwitchColors.handleColor, baseFontSize: fontSize.baseDisplaySize)
    }
}

public extension ActionSheetController {
    convenience init(presentationData: PresentationData, allowInputInset: Bool = false) {
        self.init(theme: ActionSheetControllerTheme(presentationData: presentationData), allowInputInset: allowInputInset)
    }
}

public extension AlertControllerTheme {
    convenience init(presentationTheme: PresentationTheme, fontSize: PresentationFontSize) {
        let actionSheet = presentationTheme.actionSheet
        self.init(backgroundType: actionSheet.backgroundType == .light ? .light : .dark, backgroundColor: actionSheet.itemBackgroundColor, separatorColor: actionSheet.itemHighlightedBackgroundColor, highlightedItemColor: actionSheet.itemHighlightedBackgroundColor, primaryColor: actionSheet.primaryTextColor, secondaryColor: actionSheet.secondaryTextColor, accentColor: actionSheet.controlAccentColor, contrastColor: presentationTheme.list.itemCheckColors.foregroundColor, destructiveColor: actionSheet.destructiveActionTextColor, disabledColor: actionSheet.disabledActionTextColor, controlBorderColor: presentationTheme.list.itemCheckColors.strokeColor, baseFontSize: fontSize.baseDisplaySize)
    }
    
    convenience init(presentationData: PresentationData) {
        let presentationTheme = presentationData.theme
        let actionSheet = presentationTheme.actionSheet
        self.init(backgroundType: actionSheet.backgroundType == .light ? .light : .dark, backgroundColor: actionSheet.itemBackgroundColor, separatorColor: actionSheet.itemHighlightedBackgroundColor, highlightedItemColor: actionSheet.itemHighlightedBackgroundColor, primaryColor: actionSheet.primaryTextColor, secondaryColor: actionSheet.secondaryTextColor, accentColor: actionSheet.controlAccentColor, contrastColor: presentationData.theme.list.itemCheckColors.foregroundColor, destructiveColor: actionSheet.destructiveActionTextColor, disabledColor: actionSheet.disabledActionTextColor, controlBorderColor: presentationData.theme.list.itemCheckColors.strokeColor, baseFontSize: presentationData.listsFontSize.baseDisplaySize)
    }
}

public extension NavigationControllerTheme {
    convenience init(presentationTheme: PresentationTheme) {
        let navigationStatusBar: NavigationStatusBarStyle
        switch presentationTheme.rootController.statusBarStyle {
        case .black:
            navigationStatusBar = .black
        case .white:
            navigationStatusBar = .white
        }
        self.init(statusBar: navigationStatusBar, navigationBar: NavigationBarTheme(rootControllerTheme: presentationTheme), emptyAreaColor: presentationTheme.chatList.backgroundColor)
    }
}
