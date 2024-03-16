import QtQuick 2.0
import QtQuick.Controls 2.5
import QtQuick.Layouts 1.12
import org.kde.kirigami as Kirigami

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
            {text: "small", value: Kirigami.Units.iconSizes.small},
            {text: "small-medium", value: Kirigami.Units.iconSizes.smallMedium},
            {text: "medium", value: Kirigami.Units.iconSizes.medium},
            {text: "large", value: Kirigami.Units.iconSizes.large},
            {text: "huge", value: Kirigami.Units.iconSizes.huge},
            {text: "enormous", value: Kirigami.Units.iconSizes.enormous}
        ]
        textRole: "text"
        valueRole: "value"

        currentIndex: model.findIndex((element) => element.value === plasmoid.configuration.iconSize)
    }
}
