pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Widgets
import Caelestia.Config
import qs.components
import qs.services
import qs.utils

Item {
    id: root

    property var entry
    property string iconName: entry?.icon ?? ""
    property string appName: entry?.name ?? ""
    property var categories: entry?.categories ?? []
    property real implicitSize
    property color fallbackColour: Colours.palette.m3onSurfaceVariant

    readonly property string systemIconPath: iconName ? Quickshell.iconPath(iconName) : ""
    readonly property bool useFallback: systemIconPath === "" || Icons.shouldUseMaterialIcon(iconName)
    readonly property string fallbackIcon: Icons.getDesktopEntryFallbackIcon(iconName, categories, appName)

    implicitWidth: implicitSize
    implicitHeight: implicitSize

    Loader {
        anchors.fill: parent
        asynchronous: true
        sourceComponent: root.useFallback ? fallbackComp : iconComp
    }

    Component {
        id: iconComp

        IconImage {
            asynchronous: true
            implicitSize: root.implicitSize
            source: root.systemIconPath
        }
    }

    Component {
        id: fallbackComp

        MaterialIcon {
            anchors.centerIn: parent
            text: root.fallbackIcon
            color: root.fallbackColour
            fontStyle: Tokens.font.icon.size(Math.max(1, root.implicitSize * 0.7)).build()
        }
    }
}
