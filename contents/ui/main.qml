import QtQuick 2.0
import QtQuick.Layouts 1.0
import QtQuick.Controls 2.0
import org.kde.plasma.components 3.0 as PlasmaComponents3
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.plasmoid 2.0

/*
 * TODO: Handle the case where the user refuses to grant root permissions.
 */

Item {
    id: root

    readonly property string const_CRITICAL_NOTIFICATION: " -u critical"
    readonly property string const_ZERO_TIMEOUT_NOTIFICATION: " -t 0"

    readonly property string const_IMAGE_ERROR: Qt.resolvedUrl("./image/error.svg")

    // GPU modes available for the EnvyControl tool.
    readonly property var const_GPU_MODES: ["integrated", "nvidia", "hybrid"]

    /*
     * Files used to save the outputs (stdout and stderr) of commands executed with kdesu.
     * Note that each new output overwrites the existing one, so it's not a log.
     */
    readonly property string const_KDESU_COMMANDS_OUTPUT: " >" + Qt.resolvedUrl("./stdout").substring(7) + " 2>" + Qt.resolvedUrl("./stderr").substring(7)

    /*
     * The "envycontrol -s nvidia" command must be executed with "kdesu" because with "pkexec" it does not have access to an environment variable
     * and causes an error, which apparently does not prevent changing the mode, but it does break the execution of the widget's code.
     * I used "kdesu" on the rest of the "envycontrol" commands to keep output handling unified.
     *
     */
    readonly property var const_COMMANDS: ({
        "query": Plasmoid.configuration.envyControlQueryCommand,
        "integrated": "kdesu -c \"" + Plasmoid.configuration.envyControlSetCommand + " integrated" + const_KDESU_COMMANDS_OUTPUT + "\"",
        "nvidia": "kdesu -c \"" + Plasmoid.configuration.envyControlSetCommand + " nvidia " + Plasmoid.configuration.envyControlSetNvidiaOptions + const_KDESU_COMMANDS_OUTPUT + "\"",
        "hybrid": "kdesu -c \"" + Plasmoid.configuration.envyControlSetCommand + " hybrid " + Plasmoid.configuration.envyControlSetHybridOptions + const_KDESU_COMMANDS_OUTPUT + "\"",
        "cpuManufacturer": "lscpu | grep \"Model name:\"",
        // The * is used to mark the end of stdout and the start of stderr.
        "kdesuCommandsOutput": "cat " + Qt.resolvedUrl("./stdout").substring(7) + " && echo '*' && " + "cat " + Qt.resolvedUrl("./stderr").substring(7)
    })


    // The values are set in the function setupCPUManufacturer()
    property string imageIntegrated
    property string imageHybrid

    property var icons: ({
        "integrated": imageIntegrated,
        "nvidia": Qt.resolvedUrl("./image/nvidia.svg"),
                         "hybrid": imageHybrid
    })

    // Whether or not the EnvyControl tool is installed. Assume by default that it is installed, however it is checked in onCompleted().
    property bool envycontrol: true

    /*
     * Current GPU mode.
     * The default is "integrated". However, upon completing the initialization of the widget, the current mode is checked and this variable is updated.
     */
    property string currentGPUMode: const_GPU_MODES[0]
    property string icon: root.icons[root.currentGPUMode]

    // Property used to keep the combobox in sync with the current mode if errors occur when switching mode
    property string desiredGPUMode: const_GPU_MODES[0]

    property bool showLoadingIndicator: false
    property bool pendingReboot: false

    Plasmoid.icon: root.icon

    Connections {
        target: Plasmoid.configuration
    }

    Component.onCompleted: {
        setupCPUManufacturer()
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
        id: cpuManufacturerDataSource
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


    /*
     * The best way I found to read the content of the kadesu commands output files, without using additional libraries or
     * implementing the functionality with C++, was to use the "cat" command (see const_COMMANDS.kdesuCommandsOutput).
     */
    PlasmaCore.DataSource {
        id: readKdesuOutDataSource
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

        function exec() {
            connectSource(const_COMMANDS.kdesuCommandsOutput)
        }

        signal exited(int exitCode, int exitStatus, string stdout, string stderr)
    }


    Connections {
        target: envyControlQueryModeDataSource
        function onExited(exitCode, exitStatus, stdout, stderr){
            if (stderr) {
                root.envycontrol = false
                root.icon = const_IMAGE_ERROR

                showNotification(const_IMAGE_ERROR, stderr, stderr, const_CRITICAL_NOTIFICATION)

            } else {
                var mode = stdout.trim()

                root.currentGPUMode = mode
                root.desiredGPUMode = mode
            }
        }
    }


    Connections {
        target: envyControlSetModeDataSource
        function onConnected(){
            root.showLoadingIndicator = true
            showNotification(root.icons[root.desiredGPUMode], i18n("Switching ..."), i18n("Switching GPU mode, please wait."), const_ZERO_TIMEOUT_NOTIFICATION)
        }
        function onExited(exitCode, exitStatus, stdout, stderr){
            root.showLoadingIndicator = false

            if (stderr) {
                showNotification(const_IMAGE_ERROR, stderr, stdout, const_CRITICAL_NOTIFICATION)
            } else {
                // Read the output of the executed command.
                // Recap: changing the mode needs root permissions, and I run it with kdesu, and since kdesu doesn't output, what I do is save the output to files and then read it from there.
                readKdesuOutDataSource.exec()
            }
        }
    }


    Connections {
        target: cpuManufacturerDataSource
        function onExited(exitCode, exitStatus, stdout, stderr){
            root.showLoadingIndicator = false

            if (stderr) {
                showNotification(const_IMAGE_ERROR, stderr, stdout, const_CRITICAL_NOTIFICATION)
            } else {
                var amdRegex = new RegExp("\\b(amd)\\b", "i")
                var intelRegex = new RegExp("\\b(intel)\\b", "i")

                if(amdRegex.test(stdout)){
                    root.imageHybrid = Qt.resolvedUrl("./image/hybrid-amd.svg")
                    root.imageIntegrated = Qt.resolvedUrl("./image/integrated-amd.svg")
                }else if(intelRegex.test(stdout)){
                    root.imageHybrid = Qt.resolvedUrl("./image/hybrid-intel.svg")
                    root.imageIntegrated = Qt.resolvedUrl("./image/integrated-intel.svg")
                }
            }
        }
    }


    Connections {
        target: readKdesuOutDataSource
        function onExited(exitCode, exitStatus, stdout, stderr){

            if (stderr) {
                // Error related to executing the "cat" command and reading the "kdesu" output files.
                showNotification(const_IMAGE_ERROR, stderr, stdout, const_CRITICAL_NOTIFICATION);
                return;
            }

            var splitIndex = stdout.indexOf("*");

            // If the * is not present, it means that there is a problem with the files used to save the output of commands executed with kdesu.
            if (splitIndex === -1) {
                showNotification(const_IMAGE_ERROR, i18n("No output data"), i18n("No output data was found for the command executed with kdesu."), const_CRITICAL_NOTIFICATION);
                return;
            }

            var kdesuStdout = stdout.substring(0, splitIndex).trim();
            var kdesuStderr = stdout.substring(splitIndex + 1).trim();

            if(kdesuStderr){
                // An error occurred while executing the command "kdesu envycontrol -s [mode]"
                // Reset desiredGPUMode since the GPU was not changed (most likely I think)
                root.desiredGPUMode = root.currentGPUMode;
                showNotification(const_IMAGE_ERROR, kdesuStderr, kdesuStdout, const_CRITICAL_NOTIFICATION);
            } else {
                /*
                 * You can switch to a mode, and then switch back to the current mode, all without restarting your computer.
                 * In this scenario, do the changes that EnvyControl can make really require a reboot? In the end without a reboot,
                 * the current mode is always the one that will continue to run.
                 * I am going to assume that in this case there is no point in restarting the computer, and therefore displaying the message "restart required".
                 */
                if(root.desiredGPUMode !== root.currentGPUMode){
                    root.pendingReboot = true;
                    showNotification(root.icons[root.desiredGPUMode], i18n("GPU mode changed."), kdesuStdout, const_ZERO_TIMEOUT_NOTIFICATION);
                }else{
                    root.pendingReboot = false;
                    showNotification(root.icons[root.desiredGPUMode], i18n("GPU mode changed."), i18n("You have switched back to the current mode."), const_ZERO_TIMEOUT_NOTIFICATION);
                }
            }
        }
    }


    // Try to find out the manufacturer of the CPU to use an appropriate icon.
    function setupCPUManufacturer() {
        cpuManufacturerDataSource.exec(const_COMMANDS.cpuManufacturer)
    }

    function queryMode() {
        envyControlQueryModeDataSource.exec(const_COMMANDS.query)
    }


    function switchMode(mode: string) {
        root.desiredGPUMode = mode
        envyControlSetModeDataSource.exec(const_COMMANDS[mode])
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
        Layout.preferredHeight: 300 * PlasmaCore.Units.devicePixelRatio

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
                text: root.envycontrol ? i18n("%1 currently in use.", root.currentGPUMode.toUpperCase()) : i18n("EnvyControl is not working.")
            }

            PlasmaComponents3.Label {
                Layout.alignment: Qt.AlignCenter
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                visible: root.pendingReboot && !root.showLoadingIndicator
                color: "red"
                text: i18n("Switched to:" + " " + root.desiredGPUMode.toUpperCase()) + "\n" + i18n("Please reboot your computer for changes to take effect.")
            }

            PlasmaComponents3.Label {
                Layout.topMargin: 10
                text: i18n("Change mode:")
                Layout.alignment: Qt.AlignCenter
            }


            PlasmaComponents3.ComboBox {
                Layout.alignment: Qt.AlignCenter

                enabled: !root.showLoadingIndicator && root.envycontrol
                model: const_GPU_MODES
                currentIndex: model.indexOf(root.desiredGPUMode)

                onCurrentIndexChanged: {
                    if (currentIndex !== model.indexOf(root.desiredGPUMode)) {
                        switchMode(model[currentIndex])
                    }
                }
            }


            BusyIndicator {
                id: loadingIndicator
                Layout.alignment: Qt.AlignCenter
                running: root.showLoadingIndicator
            }


        }
    }

    Plasmoid.toolTipMainText: i18n("Switch GPU mode.")
    Plasmoid.toolTipSubText: root.envycontrol ? i18n("%1 currently in use.", root.currentGPUMode.toUpperCase()) : i18n("EnvyControl is not working.")
}
