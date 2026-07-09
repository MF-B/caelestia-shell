pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Widgets
import Caelestia.Config
import qs.components
import qs.services
import qs.utils

StackView {
    id: root

    required property PopoutState popouts
    required property QsMenuHandle trayItem

    implicitWidth: currentItem?.implicitWidth ?? 0
    implicitHeight: currentItem?.implicitHeight ?? 0

    initialItem: SubMenu {
        handle: root.trayItem
    }

    pushEnter: NoAnim {}
    pushExit: NoAnim {}
    popEnter: NoAnim {}
    popExit: NoAnim {}

    Component {
        id: subMenuComp

        SubMenu {}
    }

    component NoAnim: Transition {
        NumberAnimation {
            duration: 0
        }
    }

    component SubMenu: Column {
        id: menu

        required property QsMenuHandle handle
        property bool isSubMenu
        property bool shown

        padding: Tokens.padding.small
        spacing: Tokens.spacing.small

        opacity: shown ? 1 : 0
        scale: shown ? 1 : 0.8

        Component.onCompleted: shown = true
        StackView.onActivating: shown = true
        StackView.onDeactivating: shown = false
        StackView.onRemoved: destroy()

        Behavior on opacity {
            Anim {
                type: Anim.DefaultEffects
            }
        }

        Behavior on scale {
            Anim {}
        }

        QsMenuOpener {
            id: menuOpener

            menu: menu.handle
        }

        Repeater {
            model: menuOpener.children

            StyledRect {
                id: item

                required property QsMenuEntry modelData
                readonly property bool hasEntry: modelData !== null && modelData !== undefined
                readonly property bool isSeparator: hasEntry && modelData.isSeparator

                implicitWidth: Tokens.sizes.bar.trayMenuWidth
                implicitHeight: !hasEntry ? 0 : isSeparator ? 1 : children.implicitHeight
                visible: hasEntry

                radius: Tokens.rounding.full
                color: isSeparator ? Colours.palette.m3outlineVariant : "transparent"

                function materialIconName(iconName: string, label: string): string {
                    const icon = iconName.toLowerCase();
                    const text = label.toLowerCase();

                    if (icon.includes("refresh") || text.includes("restart") || text.includes("reload"))
                        return "refresh";
                    if (icon.includes("exit") || icon.includes("quit") || text.includes("exit") || text.includes("quit"))
                        return "logout";
                    if (icon.includes("configure") || icon.includes("preferences") || icon.includes("settings"))
                        return "settings";
                    if (icon.includes("help") || icon.includes("about"))
                        return "info";
                    if (icon.includes("clear") || icon.includes("delete") || icon.includes("remove"))
                        return "delete";

                    return "";
                }

                Loader {
                    id: children

                    asynchronous: true
                    anchors.left: parent.left
                    anchors.right: parent.right

                    active: item.hasEntry && !item.isSeparator

                    sourceComponent: Item {
                        implicitHeight: label.implicitHeight

                        StateLayer {
                            anchors.margins: -Tokens.padding.extraSmall / 2
                            anchors.leftMargin: -Tokens.padding.small
                            anchors.rightMargin: -Tokens.padding.small

                            radius: item.radius
                            disabled: !item.modelData.enabled

                            onClicked: {
                                const entry = item.modelData;
                                if (entry.hasChildren)
                                    root.push(subMenuComp.createObject(null, {
                                        handle: entry,
                                        isSubMenu: true
                                    }));
                                else {
                                    item.modelData.triggered();
                                    root.popouts.hasCurrent = false;
                                }
                            }
                        }

                        Loader {
                            id: icon

                            asynchronous: true
                            anchors.left: parent.left

                            active: item.modelData.icon !== ""

                            sourceComponent: Item {
                                readonly property real size: label.implicitHeight
                                readonly property string materialIcon: Icons.getSystemIconFallback(item.modelData.icon.toString()) || item.materialIconName(item.modelData.icon.toString(), item.modelData.text)

                                implicitWidth: size
                                implicitHeight: size

                                Loader {
                                    id: sysIcon

                                    anchors.fill: parent
                                    asynchronous: true
                                    active: materialIcon === ""
                                    opacity: fallback.visible ? 0 : 1
                                    sourceComponent: IconImage {
                                        asynchronous: true
                                        source: item.modelData.icon
                                    }

                                    Behavior on opacity {
                                        CAnim {}
                                    }
                                }

                                MaterialIcon {
                                    id: fallback

                                    anchors.centerIn: parent
                                    visible: materialIcon !== "" || sysIcon.item?.status === Image.Error
                                    text: materialIcon || "radio_button_unchecked"
                                    color: item.modelData.enabled ? Colours.palette.m3onSurface : Colours.palette.m3outline
                                    fontStyle: Tokens.font.icon.builders.small.scale(1.2).weight(Font.Medium).build()
                                }

                            }
                        }

                        StyledText {
                            id: label

                            anchors.left: icon.right
                            anchors.leftMargin: icon.active ? Tokens.spacing.medium : 0

                            text: labelMetrics.elidedText
                            color: item.modelData.enabled ? Colours.palette.m3onSurface : Colours.palette.m3outline
                        }

                        TextMetrics {
                            id: labelMetrics

                            text: item.modelData.text
                            font: label.font

                            elide: Text.ElideRight
                            elideWidth: root.Tokens.sizes.bar.trayMenuWidth - (icon.active ? icon.implicitWidth + label.anchors.leftMargin : 0) - (expand.active ? expand.implicitWidth + root.Tokens.spacing.medium : 0)
                        }

                        Loader {
                            id: expand

                            asynchronous: true
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.right: parent.right

                            active: item.modelData.hasChildren

                            sourceComponent: MaterialIcon {
                                text: "chevron_right"
                                color: item.modelData.enabled ? Colours.palette.m3onSurface : Colours.palette.m3outline
                            }
                        }
                    }
                }
            }
        }

        Loader {
            asynchronous: true
            active: menu.isSubMenu

            sourceComponent: Item {
                implicitWidth: back.implicitWidth
                implicitHeight: back.implicitHeight + Tokens.spacing.extraSmall

                Item {
                    anchors.bottom: parent.bottom
                    implicitWidth: back.implicitWidth
                    implicitHeight: back.implicitHeight

                    StyledRect {
                        anchors.fill: parent
                        anchors.margins: -Tokens.padding.extraSmall / 2
                        anchors.leftMargin: -Tokens.padding.small
                        anchors.rightMargin: -Tokens.padding.large

                        radius: Tokens.rounding.full
                        color: Colours.palette.m3secondaryContainer

                        StateLayer {
                            radius: parent.radius
                            color: Colours.palette.m3onSecondaryContainer
                            onClicked: root.pop()
                        }
                    }

                    Row {
                        id: back

                        anchors.verticalCenter: parent.verticalCenter

                        MaterialIcon {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "chevron_left"
                            color: Colours.palette.m3onSecondaryContainer
                        }

                        StyledText {
                            anchors.verticalCenter: parent.verticalCenter
                            text: qsTr("Back")
                            color: Colours.palette.m3onSecondaryContainer
                        }
                    }
                }
            }
        }
    }
}
