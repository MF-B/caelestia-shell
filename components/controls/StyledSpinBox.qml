import QtQuick
import QtQuick.Templates as T
import Caelestia.Config
import qs.components
import qs.services

Item {
    id: root

    property real value: 0
    property real from: 0
    property real to: 99
    property real stepSize: 1
    property bool editable: true
    property int repeatRate: 400
    property int repeatDecay: 50
    property int cLayer: 1
    readonly property int decimals: stepSize < 1 ? Math.max(1, Math.ceil(-Math.log10(stepSize))) : 0
    readonly property int scale: Math.pow(10, decimals)

    signal valueModified

    function increase(): void {
        value = normalise(value + stepSize);
        valueModified();
    }

    function decrease(): void {
        value = normalise(value - stepSize);
        valueModified();
    }

    function normalise(val: real): real {
        const rounded = Math.round(val * scale) / scale;
        return Math.min(to, Math.max(from, rounded));
    }

    function scaled(val: real): int {
        return Math.round(val * scale);
    }

    function unscaled(val: int): real {
        return val / scale;
    }

    implicitWidth: spinBox.implicitWidth
    implicitHeight: spinBox.implicitHeight

    T.SpinBox {
        id: spinBox

        anchors.fill: parent
        enabled: root.enabled
        editable: root.editable
        from: root.scaled(root.from)
        to: root.scaled(root.to)
        stepSize: Math.max(1, root.scaled(root.stepSize))
        value: root.scaled(root.normalise(root.value))
        spacing: Tokens.spacing.small

        textFromValue: function (value, locale): string {
            return root.unscaled(value).toLocaleString(locale, "f", root.decimals);
        }

        valueFromText: function (text, locale): int {
            const parsed = Number.fromLocaleString(locale, text);
            return root.scaled(isNaN(parsed) ? root.value : parsed);
        }

        validator: DoubleValidator {
            bottom: Math.min(root.from, root.to)
            top: Math.max(root.from, root.to)
            decimals: root.decimals
            notation: DoubleValidator.StandardNotation
        }

        onValueModified: {
            root.value = root.normalise(root.unscaled(value));
            root.valueModified();
        }

        implicitWidth: contentItem.implicitWidth + leftPadding + rightPadding
        implicitHeight: Math.max(up.indicator.implicitHeight, down.indicator.implicitHeight, contentItem.implicitHeight) + topPadding + bottomPadding

        leftPadding: up.indicator.implicitWidth + Tokens.spacing.extraSmall / 2
        rightPadding: down.indicator.implicitWidth + Tokens.spacing.extraSmall / 2

        contentItem: TextFieldBase {
            text: spinBox.textFromValue(spinBox.value, spinBox.locale)

            readOnly: !spinBox.editable
            validator: spinBox.validator
            inputMethodHints: Qt.ImhFormattedNumbersOnly

            leftPadding: Tokens.padding.medium
            rightPadding: Tokens.padding.medium

            implicitWidth: 65
            horizontalAlignment: TextInput.AlignHCenter

            background: StyledRect {
                radius: Tokens.rounding.extraSmall
                color: Colours.layer(Colours.palette.m3surfaceContainerHighest, root.cLayer)
            }
        }

        down.indicator: IconButton {
            id: downButton

            topRightRadius: pressed ? Tokens.rounding.small : Tokens.rounding.extraSmall
            bottomRightRadius: pressed ? Tokens.rounding.small : Tokens.rounding.extraSmall

            icon: "remove"
            disabledColour: Qt.alpha(Colours.palette.m3surfaceContainerHighest, 0.4)
            color: disabled ? disabledColour : Colours.layer(Colours.palette.m3surfaceContainerHighest, root.cLayer)
            type: IconButton.Text
            padding: Tokens.padding.extraSmall
            isRound: true
            label.anchors.horizontalCenterOffset: pressed ? 0 : 2
            disabled: !enabled

            Behavior on topRightRadius {
                Anim {
                    type: Anim.DefaultEffects
                }
            }

            Behavior on bottomRightRadius {
                Anim {
                    type: Anim.DefaultEffects
                }
            }

            Behavior on label.anchors.horizontalCenterOffset {
                Anim {
                    type: Anim.DefaultEffects
                }
            }
        }

        up.indicator: IconButton {
            id: upButton

            anchors.right: parent.right

            topLeftRadius: pressed ? Tokens.rounding.small : Tokens.rounding.extraSmall
            bottomLeftRadius: pressed ? Tokens.rounding.small : Tokens.rounding.extraSmall

            icon: "add"
            disabledColour: Qt.alpha(Colours.palette.m3surfaceContainerHighest, 0.4)
            color: disabled ? disabledColour : Colours.layer(Colours.palette.m3surfaceContainerHighest, root.cLayer)
            type: IconButton.Text
            padding: Tokens.padding.extraSmall
            isRound: true
            label.anchors.horizontalCenterOffset: pressed ? 0 : -2
            disabled: !enabled

            Behavior on topLeftRadius {
                Anim {
                    type: Anim.DefaultEffects
                }
            }

            Behavior on bottomLeftRadius {
                Anim {
                    type: Anim.DefaultEffects
                }
            }

            Behavior on label.anchors.horizontalCenterOffset {
                Anim {
                    type: Anim.DefaultEffects
                }
            }
        }
    }

    Timer {
        id: timer

        running: upButton.pressed || downButton.pressed
        onRunningChanged: {
            if (!running)
                interval = root.repeatRate;
        }

        interval: root.repeatRate
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            if (upButton.pressed)
                root.increase();
            else if (downButton.pressed)
                root.decrease();
            if (interval > root.repeatDecay)
                interval -= root.repeatDecay;
        }
    }
}
