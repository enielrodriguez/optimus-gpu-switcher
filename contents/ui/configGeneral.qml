import QtQuick 2.0
import QtQuick.Controls 2.5
import QtQuick.Layouts 1.12
import org.kde.kirigami 2.4 as Kirigami
import org.kde.plasma.core 2.0 as PlasmaCore

Kirigami.FormLayout {
    id: configGeneral

    property alias cfg_envyControlQueryCommand: envyControlQueryCommandField.text
    property alias cfg_envyControlSetCommand: envyControlSetCommandField.text
    property alias cfg_envyControlSetHybridOptions: envyControlSetHybridOptionsField.text
    property alias cfg_envyControlSetNvidiaOptions: envyControlSetNvidiaOptionsField.text
    property alias cfg_envyControlResetCommand: envyControlResetCommandField.text
    property alias cfg_iconSizeIdx: iconSizeComboBox.currentIndex
    property alias cfg_iconSize: iconSizeComboBox.currentValue



    SpinBox {
        id: delaySpinBox
        Kirigami.FormData.label: i18n("Delay:")
        from: 1
        to: 120

        Rectangle {
            width: 50
            height: delaySpinBox.height
            color: "transparent"
            x: 50
            Text {
                anchors.centerIn: parent
                text: "seconds"
                color: PlasmaCore.Theme.textColor
            }
        }
    }

    TextField {
        id: envyControlQueryCommandField
        Kirigami.FormData.label: i18n("Envy Control Query Command:")
    }

    TextField {
        id: envyControlSetCommandField
        Kirigami.FormData.label: i18n("Envy Control Set Command:")
    }

    TextField {
        id: envyControlSetHybridOptionsField
        Kirigami.FormData.label: i18n("Envy Control Set Hybrid Options:")
    }

    TextField {
        id: envyControlSetNvidiaOptionsField
        Kirigami.FormData.label: i18n("Envy Control Set Nvidia Options:")
    }

    TextField {
        id: envyControlResetCommandField
        Kirigami.FormData.label: i18n("Envy Control Reset Command:")
    }

    ComboBox {
        id: iconSizeComboBox

        Kirigami.FormData.label: i18n("Icon size")
        model: [
            {text: "tiny", value: units.iconSizes.tiny},
            {text: "small", value: units.iconSizes.small},
            {text: "smallMedium", value: units.iconSizes.smallMedium},
            {text: "medium", value: units.iconSizes.medium},
            {text: "large", value: units.iconSizes.large},
            {text: "huge", value: units.iconSizes.huge}
        ]
        textRole: "text"
        valueRole: "value"
    }

    SpinBox {
        id: iconSizeSpinBox
        Kirigami.FormData.label: i18n("Icon Size:")
        from: 16
        to: 64
    }
}
