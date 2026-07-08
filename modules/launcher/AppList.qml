pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Caelestia.Config
import qs.components
import qs.components.containers
import qs.components.controls
import qs.services
import qs.modules.launcher.items
import qs.modules.launcher.services

StyledListView {
    id: root

    required property SearchBar search
    required property ScreenState screenState

    function actionPrefixLength(text: string): int {
        const prefix = GlobalConfig.launcher.actionPrefix;
        if (text.startsWith(prefix))
            return prefix.length;
        if (prefix === ">" && text.startsWith("＞"))
            return 1;
        return 0;
    }

    readonly property string mode: {
        const text = search.text;
        const prefixLength = actionPrefixLength(text);
        if (prefixLength > 0) {
            const actionText = text.slice(prefixLength).trimStart();
            for (const action of ["calc", "scheme", "variant"])
                if (actionText.startsWith(`${action} `))
                    return action;

            return "actions";
        }

        return "apps";
    }

    readonly property var results: {
        if (mode === "actions")
            return Actions.query(search.text);
        if (mode === "calc")
            return [0];
        if (mode === "scheme")
            return Schemes.query(search.text);
        if (mode === "variant")
            return M3Variants.query(search.text);
        return Apps.search(search.text);
    }

    model: ScriptModel {
        id: model

        values: root.results
        onValuesChanged: root.currentIndex = 0
    }

    spacing: Tokens.spacing.small
    orientation: Qt.Vertical
    implicitHeight: (Tokens.sizes.launcher.itemHeight + spacing) * Math.min(Config.launcher.maxShown, count) - spacing

    preferredHighlightBegin: 0
    preferredHighlightEnd: height
    highlightRangeMode: ListView.ApplyRange

    highlightFollowsCurrentItem: false
    highlight: StyledRect {
        radius: Tokens.rounding.large
        color: Colours.palette.m3onSurface
        opacity: 0.08

        y: root.currentItem?.y ?? 0
        implicitWidth: root.width
        implicitHeight: root.currentItem?.implicitHeight ?? 0

        Behavior on y {
            Anim {}
        }
    }

    delegate: {
        if (mode === "actions")
            return actionItem;
        if (mode === "calc")
            return calcItem;
        if (mode === "scheme")
            return schemeItem;
        if (mode === "variant")
            return variantItem;
        return appItem;
    }

    state: mode

    onModeChanged: {
        if (mode === "scheme" || mode === "variant")
            Schemes.reload();
    }

    states: [
        State {
            name: "apps"
        },
        State {
            name: "actions"
        },
        State {
            name: "calc"
        },
        State {
            name: "scheme"
        },
        State {
            name: "variant"
        }
    ]

    transitions: Transition {
        SequentialAnimation {
            ParallelAnimation {
                Anim {
                    target: root
                    property: "opacity"
                    from: 1
                    to: 0
                    duration: Tokens.anim.durations.small
                    easing: Tokens.anim.standardAccel
                }
                Anim {
                    target: root
                    property: "scale"
                    from: 1
                    to: 0.9
                    duration: Tokens.anim.durations.small
                    easing: Tokens.anim.standardAccel
                }
            }
            ParallelAnimation {
                Anim {
                    target: root
                    property: "opacity"
                    from: 0
                    to: 1
                    duration: Tokens.anim.durations.small
                    easing: Tokens.anim.standardDecel
                }
                Anim {
                    target: root
                    property: "scale"
                    from: 0.9
                    to: 1
                    duration: Tokens.anim.durations.small
                    easing: Tokens.anim.standardDecel
                }
            }
            PropertyAction {
                targets: [root.add, root.remove]
                property: "enabled"
                value: true
            }
        }
    }

    StyledScrollBar.vertical: StyledScrollBar {
        flickable: root
    }

    add: Transition {
        enabled: !root.state

        Anim {
            type: Anim.DefaultEffects
            property: "opacity"
            from: 0
            to: 1
        }
    }

    remove: Transition {
        enabled: !root.state

        Anim {
            type: Anim.DefaultEffects
            property: "opacity"
            from: 1
            to: 0
        }
    }

    move: Transition {
        Anim {
            property: "y"
        }
        Anim {
            type: Anim.DefaultEffects
            property: "opacity"
            to: 1
        }
    }

    addDisplaced: Transition {
        Anim {
            property: "y"
            type: Anim.StandardSmall
        }
        Anim {
            type: Anim.DefaultEffects
            property: "opacity"
            to: 1
        }
    }

    displaced: Transition {
        Anim {
            property: "y"
        }
        Anim {
            type: Anim.DefaultEffects
            property: "opacity"
            to: 1
        }
    }

    Component {
        id: appItem

        AppItem {
            screenState: root.screenState
        }
    }

    Component {
        id: actionItem

        ActionItem {
            list: root
        }
    }

    Component {
        id: calcItem

        CalcItem {
            list: root
        }
    }

    Component {
        id: schemeItem

        SchemeItem {
            list: root
        }
    }

    Component {
        id: variantItem

        VariantItem {
            list: root
        }
    }
}
