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
    property alias cfg_iconSize: iconSizeComboBox.currentValue


    TextField {
        id: envyControlQueryCommandField
        Kirigami.FormData.label: i18n("EnvyControl query command:")
    }

    TextField {
        id: envyControlSetCommandField
        Kirigami.FormData.label: i18n("EnvyControl set mode command:")
    }

    TextField {
        id: envyControlSetHybridOptionsField
        Kirigami.FormData.label: i18n("Hybrid mode options:")
    }

    TextField {
        id: envyControlSetNvidiaOptionsField
        Kirigami.FormData.label: i18n("Nvidia mode options:")
    }

    ComboBox {
        id: iconSizeComboBox

        Kirigami.FormData.label: i18n("Icon size:")
        model: [
            {text: "small", value: units.iconSizes.small},
            {text: "small-medium", value: units.iconSizes.smallMedium},
            {text: "medium", value: units.iconSizes.medium},
            {text: "large", value: units.iconSizes.large},
            {text: "huge", value: units.iconSizes.huge}
        ]
        textRole: "text"
        valueRole: "value"

        currentIndex: model.findIndex((element) => element.value === plasmoid.configuration.iconSize)
    }
}
