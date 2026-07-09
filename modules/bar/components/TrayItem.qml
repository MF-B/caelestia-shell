pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Services.SystemTray
import Caelestia.Config
import qs.components
import qs.components.effects
import qs.services
import qs.utils

MouseArea {
    id: root

    required property SystemTrayItem modelData

    acceptedButtons: Qt.LeftButton | Qt.RightButton
    implicitWidth: Tokens.font.body.small.pointSize * 2
    implicitHeight: Tokens.font.body.small.pointSize * 2

    onClicked: event => {
        if (event.button === Qt.LeftButton)
            modelData.activate();
        else
            modelData.secondaryActivate();
    }

    readonly property string fallbackIcon: Icons.getSystemIconFallback(root.modelData.icon)
    readonly property bool useFallback: fallbackIcon !== ""

    Loader {
        anchors.fill: parent
        asynchronous: true
        sourceComponent: root.useFallback ? fallbackComp : trayIconComp
    }

    Component {
        id: trayIconComp

        ColouredIcon {
            source: Icons.getTrayIcon(root.modelData.id, root.modelData.icon)
            colour: Colours.palette.m3secondary
            layer.enabled: Config.bar.tray.recolour
        }
    }

    Component {
        id: fallbackComp

        MaterialIcon {
            anchors.centerIn: parent
            text: root.fallbackIcon
            color: Colours.palette.m3secondary
            fontStyle: Tokens.font.icon.size(Math.max(1, Math.min(root.width, root.height) * 0.8)).build()
        }
    }
}
