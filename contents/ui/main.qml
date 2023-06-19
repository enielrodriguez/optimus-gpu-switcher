import QtQuick 2.0
import QtQuick.Layouts 1.0
import QtQuick.Controls 2.0
import org.kde.plasma.components 3.0 as PlasmaComponents3
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.plasmoid 2.0

Item {
    id: root

    property string imageNvidia: Qt.resolvedUrl("./image/nvidia.svg")
    // TODO: These two properties depend on the manufacturer of the CPU.
    property string imageHybrid: Qt.resolvedUrl("./image/hybrid.svg")
    property string imageIntegrated: Qt.resolvedUrl("./image/integrated.svg")

    property string imageError: Qt.resolvedUrl("./image/error.svg")

    // Whether or not the EnvyControl tool is installed. Assume by default that it is installed, however it is checked in onCompleted().
    property bool envycontrol: true

    /*
     * GPU modes available for the EnvyControl tool.
     * TODO: It might be a good idea to make this property a configuration property.
     */
    property var gpuModes: ["integrated", "nvidia", "hybrid"]

    /*
     * EnvyControl commands.
     * TODO: Replace manual entries of the GPU modes with references to the gpuModes array. Maybe not worth it because of the increase
     * in string concatenations and the loss of code clarity.This makes more sense if the above TODO is done.
     */
    property var commands: {
        "query": Plasmoid.configuration.envyControlQueryCommand,
        "reset": "pkexec " + Plasmoid.configuration.envyControlResetCommand,
        "integrated": "pkexec " + Plasmoid.configuration.envyControlSetCommand + " integrated",
        "nvidia": "pkexec " + Plasmoid.configuration.envyControlSetCommand + " nvidia " + Plasmoid.configuration.envyControlSetNvidiaOptions,
        "hybrid": "pkexec " + Plasmoid.configuration.envyControlSetCommand + " hybrid " + Plasmoid.configuration.envyControlSetHybridOptions
    }

    /*
     * Current GPU mode.
     * On a fresh installation of the system and drivers "integrated" is the most common mode. However, this value is checked when loading the widget.
     */
    property string currentGPUMode: root.gpuModes[0]
    property string icon: root.imageIntegrated

    // Property used to keep the combobox in sync with the current mode (taking advantage of QT bindings) if errors occur when switching mode
    property int desiredGPUModeIdx: 0

    property bool showLoadingIndicator: false
    property bool pendingReboot: false

    Plasmoid.icon: root.icon

    Connections {
        target: Plasmoid.configuration
    }

    Component.onCompleted: {
        queryMode()
    }

    PlasmaCore.DataSource {
        id: envyControlQueryModeDataSource
        engine: "executable"
        connectedSources: []

        onNewData: {
            var exitCode = data["exit code"]
            var exitStatus = data["exit status"]
            var stdout = data["stdout"]
            var stderr = data["stderr"]

            exited(exitCode, exitStatus, stdout, stderr)
            disconnectSource(sourceName)
        }

        function exec(cmd) {
            connectSource(cmd)
        }

        signal exited(int exitCode, int exitStatus, string stdout, string stderr)
    }


    PlasmaCore.DataSource {
        id: envyControlSetModeDataSource
        engine: "executable"
        connectedSources: []

        onNewData: {
            var exitCode = data["exit code"]
            var exitStatus = data["exit status"]
            var stdout = data["stdout"]
            var stderr = data["stderr"]

            exited(exitCode, exitStatus, stdout, stderr)
            disconnectSource(sourceName)
        }

        onSourceConnected: {
            connected()
        }

        function exec(cmd) {
            connectSource(cmd)
        }

        signal exited(int exitCode, int exitStatus, string stdout, string stderr)
        signal connected()
    }


    PlasmaCore.DataSource {
        id: envyControlResetDataSource
        engine: "executable"
        connectedSources: []

        onNewData: {
            var exitCode = data["exit code"]
            var exitStatus = data["exit status"]
            var stdout = data["stdout"]
            var stderr = data["stderr"]

            exited(exitCode, exitStatus, stdout, stderr)
            disconnectSource(sourceName)
        }

        function exec(cmd) {
            connectSource(cmd)
        }

        signal exited(int exitCode, int exitStatus, string stdout, string stderr)
    }


    PlasmaCore.DataSource {
        id: sendNotification
        engine: "executable"
        connectedSources: []

        onNewData: {
            disconnectSource(sourceName)
        }

        function exec(cmd) {
            connectSource(cmd)
        }
    }


    Connections {
        target: envyControlQueryModeDataSource
        function onExited(exitCode, exitStatus, stdout, stderr){
            if (stderr) {
                root.envycontrol = false
                root.icon = root.imageError

                console.warn("ERROR: QueryMode handler: " + stderr)
                showNotification(root.imageError, stderr, stderr, " -u critical")

            } else {

                var mode = stdout.trim()

                // TODO: What if there's a change to EnvyControl and the returned mode doesn't match the ones here?
                root.currentGPUMode = mode
                root.desiredGPUModeIdx = root.gpuModes.indexOf(mode)

                switch (mode) {
                    case "integrated":
                        root.icon = root.imageIntegrated
                        break;
                    case "nvidia":
                        root.icon = root.imageNvidia
                        break;
                    case "hybrid":
                        root.icon = root.imageHybrid
                        break;
                }
            }
        }
    }


    Connections {
        target: envyControlSetModeDataSource
        function onConnected(){
            root.showLoadingIndicator = true
            showNotification(root.icon, i18n("Switching ..."), i18n("Switching GPU mode, please wait."), " -t 0")
        }
        function onExited(exitCode, exitStatus, stdout, stderr){
            root.showLoadingIndicator = false

            if (stderr) {
                // There are errors where "envycontrol -s <mode>" gives possible solutions via the stdout output.
                console.warn("ERROR: SwitchMode handler: " + stderr + " " + stdout)
                showNotification(root.imageError, stderr, stdout, " -u critical")

                // Reset desiredGPUModeIdx since the GPU was not changed (most likely I think)
                root.desiredGPUModeIdx = root.gpuModes.indexOf(root.currentGPUMode)

            } else {
                root.pendingReboot = true

                showNotification(root.icon, i18n("GPU mode changed"), stdout, " -t 0")
            }
        }
    }


    Connections {
        target: envyControlResetDataSource
        function onExited(exitCode, exitStatus, stdout, stderr){
            root.showLoadingIndicator = false

            if (stderr) {
                // There are errors where "envycontrol -s <mode>" gives possible solutions via the stdout output.
                console.warn("ERROR: SwitchMode handler: " + stderr + " " + stdout)
                showNotification(root.imageError, stderr, stdout, " -u critical")
            } else {
                // TODO: Does "envycontrol --reset" change gpu mode? If it does not then remove the next line.
                queryMode()
                showNotification(root.icon, i18n("Changes were reset"), stdout, " -t 0")
            }
        }
    }


    function queryMode() {
        envyControlQueryModeDataSource.exec(commands.query)
    }


    function switchMode(mode: string) {
        envyControlSetModeDataSource.exec(commands[mode])
    }


    function resetEnvyControl() {
        envyControlResetDataSource.exec(commands.reset)
    }


    function showNotification(iconURL: string, title: string, message: string, options = ""){
        sendNotification.exec("notify-send -i " + iconURL + " '" + title + "' '" + message + "'" + options)
    }


    Plasmoid.preferredRepresentation: Plasmoid.compactRepresentation

    Plasmoid.compactRepresentation: Item {
        PlasmaCore.IconItem {
            width: Plasmoid.configuration.iconSize
            height: Plasmoid.configuration.iconSize
            anchors.centerIn: parent

            source: root.icon
            active: compactMouse.containsMouse

            MouseArea {
                id: compactMouse
                anchors.fill: parent
                hoverEnabled: true
                onClicked: {
                    plasmoid.expanded = !plasmoid.expanded
                }
            }
        }
    }

    Plasmoid.fullRepresentation: Item {
        Layout.preferredWidth: 400 * PlasmaCore.Units.devicePixelRatio
        Layout.preferredHeight: 400 * PlasmaCore.Units.devicePixelRatio

        ColumnLayout {
            anchors.centerIn: parent

            Image {
                id: mode_image
                source: root.icon
                Layout.alignment: Qt.AlignCenter
                Layout.preferredHeight: 72
                fillMode: Image.PreserveAspectFit
            }


            PlasmaComponents3.Label {
                Layout.alignment: Qt.AlignCenter
                text: root.envycontrol ? i18n("%1 currently in use", root.currentGPUMode.toUpperCase()) : i18n("EnvyControl is not working")
            }

            PlasmaComponents3.Label {
                Layout.alignment: Qt.AlignCenter
                visible: root.pendingReboot
                color: "red"
                property string switchedToMode: root.gpuModes[root.desiredGPUModeIdx]
                text: i18n("Switched to: " + switchedToMode.toUpperCase())
            }

            PlasmaComponents3.Label {
                Layout.alignment: Qt.AlignCenter
                visible: root.pendingReboot
                color: "red"
                text: i18n("Please reboot your computer for changes to take effect!")
            }


            PlasmaComponents3.Label {
                Layout.topMargin: 10
                text: i18n("Change mode:")
                Layout.alignment: Qt.AlignCenter
            }


            PlasmaComponents3.ComboBox {
                Layout.alignment: Qt.AlignCenter

                enabled: !root.showLoadingIndicator && root.envycontrol
                model: root.gpuModes
                currentIndex: root.desiredGPUModeIdx

                onCurrentIndexChanged: {
                    if (currentIndex !== root.desiredGPUModeIdx) {
                        root.desiredGPUModeIdx = currentIndex
                        switchMode(model[currentIndex])
                    }
                }
            }

            PlasmaComponents3.Label {
                Layout.topMargin: 10
                Layout.alignment: Qt.AlignCenter
                text: i18n("Revert all changes made by EnvyControl:")
            }

            PlasmaComponents3.Button {
                Layout.alignment: Qt.AlignCenter

                enabled: !root.showLoadingIndicator && root.envycontrol
                text: i18n("Reset")
                onClicked: resetEnvyControl()
            }

            BusyIndicator {
                id: loadingIndicator
                Layout.alignment: Qt.AlignCenter
                running: root.showLoadingIndicator
            }


        }
    }

    Plasmoid.toolTipMainText: i18n("Switch GPU mode")
    Plasmoid.toolTipSubText: root.envycontrol ? i18n("%1 currently in use", root.currentGPUMode.toUpperCase()) : i18n("EnvyControl is not working")
}
