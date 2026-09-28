import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import org.kde.plasma.components as PlasmaComponents3
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami
import org.kde.plasma.plasmoid



PlasmoidItem {
    id: root

    // Keep notifications open because EnvyControl operations can take several seconds to complete.
    // This option is only valid for the notify-send tool.
    property string const_ZERO_TIMEOUT_NOTIFICATION: "-t 0"

    // GPU modes available for the EnvyControl tool.
    property var const_GPU_MODES: {
        "gpuModes": ["integrated", "nvidia", "hybrid"],
        "integrated": "integrated",
        "nvidia": "nvidia",
        "hybrid": "hybrid"
    }

    property string imageIntegrated: Qt.resolvedUrl("image/integrated-" + plasmoid.configuration.cpuManufacturer + ".png")
    property string imageHybrid: Qt.resolvedUrl("image/hybrid-" + plasmoid.configuration.cpuManufacturer + ".png")

    property var icons: {
        "integrated": imageIntegrated,
        "nvidia": Qt.resolvedUrl("./image/nvidia.png"),
        "hybrid": imageHybrid,
        "error": Qt.resolvedUrl("./image/error.png")
    }

    // Whether or not the EnvyControl tool is installed. Assume by default that it is installed, however it is checked in onCompleted().
    property bool envycontrolAvailable: true

    // currentGPUMode: The default is "integrated". However, upon completing the initialization of the widget, the current mode is checked and this variable is updated.
    property string currentGPUMode: const_GPU_MODES.integrated
    // desiredGPUMode: The mode the user wants to switch to. It stays in sync with the combobox and is useful for detecting and handling errors.
    property string desiredGPUMode: const_GPU_MODES.integrated
    // pendingRebootGPUMode: Mode that was successfully changed to, generally matches the variable desiredGPUMode, except in case of errors.
    property string pendingRebootGPUMode

    // To show or hide the loading indicator, also to prevent the use of any feature while changing modes.
    property bool loading: false

    property string icon: root.icons[root.currentGPUMode]
    Plasmoid.icon: root.icon

    Component.onCompleted: {
        findNotificationTool()
    }



    // Try to find out the manufacturer of the CPU to use an appropriate icon.
    function setupCPUManufacturer() {
        if(plasmoid.configuration.cpuManufacturer === "std"){
            cpuManufacturerDataSource.exec()
        } else {
            queryMode()
        }
    }

    function queryMode() {
        root.loading = true
        envyControlQueryModeDataSource.exec()
    }

    function switchMode(mode: string) {
        root.desiredGPUMode = mode
        root.loading = true

        showNotification(root.icons[mode], i18n("Switching to %1 GPU mode, please wait.", mode))

        envyControlSetModeDataSource.mode = mode
        envyControlSetModeDataSource.exec()
    }

    function showNotification(iconURL: string, message: string, title = "Optimus GPU Switcher", options = const_ZERO_TIMEOUT_NOTIFICATION){
        if (plasmoid.configuration.notificationToolPath) {
            sendNotification.tool = plasmoid.configuration.notificationToolPath

            sendNotification.iconURL = iconURL
            sendNotification.title = title
            sendNotification.message = message
            sendNotification.options = options

            sendNotification.exec()
        } else {
            console.warn(title + ": " + message)
        }
    }

    function findNotificationTool() {
        if(!plasmoid.configuration.notificationToolPath){
            findNotificationToolDataSource.exec()
        } else {
            setupCPUManufacturer()
        }
    }


    CustomDataSource {
        id: envyControlQueryModeDataSource
        command: plasmoid.configuration.envyControlQueryCommand
    }

    CustomDataSource {
        id: envyControlSetModeDataSource

        // Dynamically set in switchMode(). Set a default value to avoid errors at startup.
        property string mode: const_GPU_MODES.integrated
        
        property string baseCommand: `${plasmoid.configuration.elevatedPivilegesTool} ${plasmoid.configuration.envyControlSetCommand} %1`
        property var cmds: {
            "integrated": baseCommand.replace(/%1/g, const_GPU_MODES.integrated),
            "nvidia": baseCommand.replace(/%1/g, `${const_GPU_MODES.nvidia} ${plasmoid.configuration.envyControlSetNvidiaOptions}`),
            "hybrid": baseCommand.replace(/%1/g, `${const_GPU_MODES.hybrid} ${plasmoid.configuration.envyControlSetHybridOptions}`)
        }

        command: cmds[mode]
    }

    CustomDataSource {
        id: cpuManufacturerDataSource
        command: "lscpu | grep \"GenuineIntel\\|AuthenticAMD\""
    }

    CustomDataSource {
        id: findNotificationToolDataSource
        command: "sh -c 'command -v notify-send || command -v zenity'"
    }

    CustomDataSource {
        id: sendNotification

        // Dynamically set in showNotification(). Set a default value to avoid errors at startup.
        property string tool: "notify-send"

        property string iconURL: ""
        property string title: ""
        property string message: ""
        property string options: ""

        property var cmds: {
            "notify-send": `notify-send -i ${iconURL} '${title}' '${message}' ${options}`,
            "zenity": `zenity --notification --text='${title}\\n${message}'`
        }

        command: cmds[tool]
    }


    Connections {
        target: envyControlQueryModeDataSource
        function onExited(exitCode, exitStatus, stdout, stderr){
            if (stderr) {
                root.envycontrolAvailable = false
                root.icon = root.icons.error

                showNotification(root.icons.error, stderr + " \n " + stdout)

            } else {
                var mode = stdout.trim()

                /*
                * Check if there was an attempt to change the GPU mode and something went wrong.
                * Only notify if EnvyControl ended up in an unexpected mode that was neither current nor desired.
                */
                if (root.currentGPUMode !== root.desiredGPUMode && root.desiredGPUMode !== mode && root.currentGPUMode !== mode) {
                    root.pendingRebootGPUMode = mode
                    showNotification(root.icons[mode], i18n("A change to %1 mode was detected. Please reboot!", mode))
                } else if (!root.pendingRebootGPUMode) {
                    root.currentGPUMode = mode
                }

                if (!root.pendingRebootGPUMode) {
                    root.desiredGPUMode = mode
                }
                root.loading = false
            }
        }
    }


    Connections {
        target: envyControlSetModeDataSource
        function onExited(exitCode, exitStatus, stdout, stderr){
            root.loading = false

            if(exitCode === 126 || exitCode === 127){
                showNotification(root.icons.error, i18n("Root privileges are required."))
                root.desiredGPUMode = root.currentGPUMode
                return
            }

            var isSuccess = (exitCode === 0 && !stderr) || (stdout && stdout.indexOf("Operation completed successfully") !== -1)

            if (isSuccess) {
                /*
                * You can switch to a mode, and then switch back to the current mode, all without restarting your computer.
                * In this scenario, do the changes that EnvyControl can make really require a reboot? In the end without a reboot,
                * the current mode is always the one that will continue to run.
                * I am going to assume that in this case there is no point in restarting the computer, and therefore displaying the message "restart required".
                */
                if(root.desiredGPUMode !== root.currentGPUMode){
                    root.pendingRebootGPUMode = root.desiredGPUMode

                    var message = stdout.trim()
                    if (stderr) {
                        message = stderr.trim() + "\n\n" + message
                    }
                    showNotification(root.icons[root.desiredGPUMode], message)
                }else{
                    root.pendingRebootGPUMode = ""
                    showNotification(root.icons[root.desiredGPUMode], i18n("You have switched back to the current mode."))
                }
            } else {
                var errorMessage = stderr ? (stdout ? stderr.trim() + "\n" + stdout.trim() : stderr.trim()) : (stdout ? stdout.trim() : i18n("EnvyControl is not working."))
                showNotification(root.icons.error, errorMessage)
                // Check the current state in case EnvyControl made changes without warning.
                queryMode()
            }
        }
    }


    Connections {
        target: cpuManufacturerDataSource
        function onExited(exitCode, exitStatus, stdout, stderr){
            root.loading = false

            if (stderr) {
                showNotification(root.icons.error, `${stderr} \n ${stdout}`)
            } else {
                var amdRegex = new RegExp("AuthenticAMD")
                var intelRegex = new RegExp("GenuineIntel")

                if(amdRegex.test(stdout)){
                    plasmoid.configuration.cpuManufacturer = "amd"                    
                }else if(intelRegex.test(stdout)){
                    plasmoid.configuration.cpuManufacturer = "intel"
                }
            }

            queryMode()
        }
    }

    Connections {
        target: findNotificationToolDataSource
        function onExited(exitCode, exitStatus, stdout, stderr){

            if (stdout) {
                var paths = stdout.trim().split("\n");
                var notificationTool = "";

                // Many Linux distros have two notification tools: notify-send and zenity
                // Prefer notify-send because it allows using an icon; zenity v3.44.0 does not accept an icon option
                for (let i = 0; i < paths.length; ++i) {
                    let currentPath = paths[i].trim();
                    
                    if (currentPath.endsWith("notify-send")) {
                        notificationTool = "notify-send";
                        break;
                    } else if (currentPath.endsWith("zenity")) {
                        notificationTool = "zenity";
                    }
                }

                if (notificationTool) {
                    plasmoid.configuration.notificationToolPath = notificationTool;
                } else {
                    console.warn("No compatible notification tool found.");
                }
            }

            setupCPUManufacturer()
        }
    }

    compactRepresentation: Item {
        Kirigami.Icon {
            height: plasmoid.configuration.iconSize
            width: plasmoid.configuration.iconSize
            anchors.centerIn: parent

            source: root.icon
            active: compactMouse.containsMouse

            MouseArea {
                id: compactMouse
                anchors.fill: parent
                hoverEnabled: true
                onClicked: {
                    expanded = !expanded
                }
            }
        }
    }

    fullRepresentation: Item {
        Layout.preferredWidth: 400
        Layout.preferredHeight: 300

        ColumnLayout {
            anchors.centerIn: parent

            Image {
                id: mode_image
                source: root.icon
                Layout.alignment: Qt.AlignCenter
                Layout.preferredHeight: 64
                fillMode: Image.PreserveAspectFit
            }


            PlasmaComponents3.Label {
                Layout.alignment: Qt.AlignCenter
                text: root.envycontrolAvailable ? i18n("%1 currently in use.", root.currentGPUMode.toUpperCase()) : i18n("EnvyControl is not working.")
            }

            PlasmaComponents3.Label {
                Layout.alignment: Qt.AlignCenter
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                visible: root.pendingRebootGPUMode && !root.loading
                color: Kirigami.Theme.negativeTextColor
                text: i18n("Switched to: %1", root.pendingRebootGPUMode.toUpperCase()) + "\n" + i18n("Please reboot your computer for changes to take effect.")
            }

            PlasmaComponents3.Label {
                Layout.topMargin: 10
                text: i18n("Change mode:")
                Layout.alignment: Qt.AlignCenter
            }


            PlasmaComponents3.ComboBox {
                Layout.alignment: Qt.AlignCenter

                enabled: !root.loading && root.envycontrolAvailable
                model: const_GPU_MODES.gpuModes
                currentIndex: model.indexOf(root.desiredGPUMode)

                onActivated: (index) => {
                    switchMode(model[index])
                }
            }


            PlasmaComponents3.Button {
                Layout.alignment: Qt.AlignCenter
                icon.name: "view-refresh-symbolic"
                text: i18n("Refresh")
                onClicked: queryMode()
                enabled: !root.loading && root.envycontrolAvailable
            }


            BusyIndicator {
                id: loadingIndicator
                Layout.alignment: Qt.AlignCenter
                running: root.loading
            }


        }
    }

    Plasmoid.contextualActions: [
        PlasmaCore.Action {
            text: i18n("Switch to Integrated")
            icon.name: "video-card-inactive"
            enabled: !root.loading && root.envycontrolAvailable
            checkable: true
            checked: root.desiredGPUMode === "integrated"
            onTriggered: switchMode("integrated")
        },
        PlasmaCore.Action {
            text: i18n("Switch to NVIDIA")
            icon.name: "show-gpu-effects"
            enabled: !root.loading && root.envycontrolAvailable
            checkable: true
            checked: root.desiredGPUMode === "nvidia"
            onTriggered: switchMode("nvidia")
        },
        PlasmaCore.Action {
            text: i18n("Switch to Hybrid")
            icon.name: "video-display"
            enabled: !root.loading && root.envycontrolAvailable
            checkable: true
            checked: root.desiredGPUMode === "hybrid"
            onTriggered: switchMode("hybrid")
        }
    ]

    toolTipMainText: i18n("Switch GPU mode.")
    toolTipSubText: root.envycontrolAvailable ? i18n("%1 currently in use.", root.currentGPUMode.toUpperCase()) : i18n("EnvyControl is not working.")
}
