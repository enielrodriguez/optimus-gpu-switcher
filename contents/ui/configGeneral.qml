import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents3

Kirigami.FormLayout {
    id: configGeneral

    property alias cfg_envyControlQueryCommand: envyControlQueryCommandField.text
    property alias cfg_envyControlSetCommand: envyControlSetCommandField.text
    property alias cfg_envyControlSetHybridOptions: envyControlSetHybridOptionsField.text
    property alias cfg_envyControlSetNvidiaOptions: envyControlSetNvidiaOptionsField.text
    property alias cfg_iconSize: iconSizeComboBox.currentValue


    PlasmaComponents3.TextField {
        id: envyControlQueryCommandField
        Kirigami.FormData.label: i18n("EnvyControl query command:")
    }

    PlasmaComponents3.TextField {
        id: envyControlSetCommandField
        Kirigami.FormData.label: i18n("EnvyControl set mode command:")
    }

    PlasmaComponents3.TextField {
        id: envyControlSetHybridOptionsField
        Kirigami.FormData.label: i18n("Hybrid mode options:")
    }

    PlasmaComponents3.TextField {
        id: envyControlSetNvidiaOptionsField
        Kirigami.FormData.label: i18n("Nvidia mode options:")
    }

    PlasmaComponents3.ComboBox {
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
