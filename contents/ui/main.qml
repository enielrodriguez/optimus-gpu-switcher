import QtQuick 2.0
import QtQuick.Layouts 1.0
import QtQuick.Controls 2.0
import org.kde.plasma.components 3.0 as PlasmaComponents3
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.plasmoid 2.0

/*
*
* Note on peculiar behavior of EnvyControl: Starting from integrated mode, and trying to switch directly to nvidia mode,
* an error occurs. It is because you need to switch to hybrid mode first, reboot, and then switch to nvidia mode. When
* this happens, EnvyControl automatically switches to hybrid mode without warning, so all that remains is to restart.
* I don't know if this behavior occurs on all platforms.
*
*/

Item {
    id: root

    property string kdesuPath

    readonly property string const_IMAGE_ERROR: Qt.resolvedUrl("./image/error.png")

    readonly property string const_ZERO_TIMEOUT_NOTIFICATION: " -t 0"

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
        "integrated": root.kdesuPath + " -c \"" + Plasmoid.configuration.envyControlSetCommand + " integrated" + const_KDESU_COMMANDS_OUTPUT + "\"",
        "nvidia": root.kdesuPath + " -c \"" + Plasmoid.configuration.envyControlSetCommand + " nvidia " + Plasmoid.configuration.envyControlSetNvidiaOptions + const_KDESU_COMMANDS_OUTPUT + "\"",
        "hybrid": root.kdesuPath + " -c \"" + Plasmoid.configuration.envyControlSetCommand + " hybrid " + Plasmoid.configuration.envyControlSetHybridOptions + const_KDESU_COMMANDS_OUTPUT + "\"",
        "cpuManufacturer": "lscpu | grep \"GenuineIntel\\|AuthenticAMD\"",
        "findKdesu": "find /usr -type f -name \"kdesu\" -executable 2>/dev/null",
        "findNotificationTool": "find /usr -type f -executable \\( -name \"notify-send\" -o -name \"zenity\" \\)",
        // defined in findNotificationTool Connection
        "sendNotification": () => "",
        // The * is used to mark the end of stdout and the start of stderr.
        "kdesuCommandsOutput": "cat " + Qt.resolvedUrl("./stdout").substring(7) + " && echo '*' && " + "cat " + Qt.resolvedUrl("./stderr").substring(7)
    })

    // These values will surely change after executing the setupCPUManufacturer() function
    property string imageIntegrated: Qt.resolvedUrl("./image/integrated.png")
    property string imageHybrid: Qt.resolvedUrl("./image/hybrid.png")

    property var icons: ({
        "integrated": imageIntegrated,
        "nvidia": Qt.resolvedUrl("./image/nvidia.png"),
        "hybrid": imageHybrid
    })

    // Whether or not the EnvyControl tool is installed. Assume by default that it is installed, however it is checked in onCompleted().
    property bool envycontrol: true

    /*
    * currentGPUMode: The default is "integrated". However, upon completing the initialization of the widget, the current mode is checked and this variable is updated.
    * desiredGPUMode: The mode the user wants to switch to. It stays in sync with the combobox.
    * pendingRebootGPUMode: Mode that was successfully changed to, generally matches the variable desiredGPUMode, except in case of errors.
    */
    property string currentGPUMode: const_GPU_MODES[0]
    property string desiredGPUMode: const_GPU_MODES[0]
    property string pendingRebootGPUMode

    property bool loading: false

    property string icon: root.icons[root.currentGPUMode]

    Plasmoid.icon: root.icon

    Connections {
        target: Plasmoid.configuration
    }

    Component.onCompleted: {
        findNotificationTool()
        findKdesu()
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

        function exec(cmd) {
            connectSource(cmd)
        }

        signal exited(int exitCode, int exitStatus, string stdout, string stderr)
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
        id: findKdesuDataSource
        engine: "executable"
        connectedSources: []

        onNewData: {
            var exitCode = data["exit code"]
            var exitStatus = data["exit status"]
            var stdout = data["stdout"]
            // stderr output was suppressed to avoid handling "permission denied" errors
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
        id: findNotificationToolDataSource
        engine: "executable"
        connectedSources: []

        onNewData: {
            var exitCode = data["exit code"]
            var exitStatus = data["exit status"]
            var stdout = data["stdout"]
            // stderr output was suppressed to avoid handling "permission denied" errors
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

                showNotification(const_IMAGE_ERROR, stderr + " \n " + stderr)

            } else {
                var mode = stdout.trim()

                /*
                * Check if there was an attempt to change the GPU mode and something went wrong.
                * Perhaps in the process, EnviControl switched to another mode automatically without warning.
                */
                if(root.currentGPUMode !== root.desiredGPUMode && root.currentGPUMode !== mode){
                    root.pendingRebootGPUMode = mode
                    showNotification(root.icons[mode], i18n("A change to %1 mode was detected. Please reboot!", mode))
                }else{
                    root.currentGPUMode = mode
                }

                root.desiredGPUMode = mode
                root.loading = false
            }
        }
    }


    Connections {
        target: envyControlSetModeDataSource
        function onExited(exitCode, exitStatus, stdout, stderr){
            root.loading = false

            // root privileges not granted should be 127 but for some reason it is 1, maybe it is normal with kdesu
            if(exitCode === 1){
                showNotification(const_IMAGE_ERROR, i18n("Error: Root privileges are required."))
                root.desiredGPUMode = root.currentGPUMode
                return
            }

            if (stderr) {
                showNotification(const_IMAGE_ERROR, stderr + " \n " + stdout)
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
            root.loading = false

            if (stderr) {
                showNotification(const_IMAGE_ERROR, stderr + " \n " + stdout)
            } else {
                var amdRegex = new RegExp("AuthenticAMD")
                var intelRegex = new RegExp("GenuineIntel")

                if(amdRegex.test(stdout)){
                    root.imageHybrid = Qt.resolvedUrl("./image/hybrid-amd.png")
                    root.imageIntegrated = Qt.resolvedUrl("./image/integrated-amd.png")
                }else if(intelRegex.test(stdout)){
                    root.imageHybrid = Qt.resolvedUrl("./image/hybrid-intel.png")
                    root.imageIntegrated = Qt.resolvedUrl("./image/integrated-intel.png")
                }
            }
        }
    }


    Connections {
        target: findKdesuDataSource
        function onExited(exitCode, exitStatus, stdout, stderr){

            if(stdout){
                root.kdesuPath = stdout.trim()
            }
        }
    }


    Connections {
        target: findNotificationToolDataSource
        function onExited(exitCode, exitStatus, stdout, stderr){

            if (stdout) {
                var paths = stdout.split("\n")
                var path1 = paths[0]
                var path2 = paths[1]

                // prefer notify-send because it allows to use icon, zenity v3.44.0 does not accept icon option
                if (path1 && path1.trim().endsWith("notify-send")) {
                    const_COMMANDS.sendNotification = (title, message, iconURL, options) => path1.trim() + " -i " + iconURL + " '" + title + "' '" + message + "'" + options
                }if (path2 && path2.trim().endsWith("notify-send")) {
                    const_COMMANDS.sendNotification = (title, message, iconURL, options) => path2.trim() + " -i " + iconURL + " '" + title + "' '" + message + "'" + options
                }else if (path1 && path1.trim().endsWith("zenity")) {
                    const_COMMANDS.sendNotification = (title, message, iconURL, options) => path1.trim() + " --notification --text='" + title + "\\n" + message + "'"
                }
            }
        }
    }


    Connections {
        target: readKdesuOutDataSource
        function onExited(exitCode, exitStatus, stdout, stderr){

            if (stderr) {
                // Error related to executing the "cat" command and reading the "kdesu" output files.

                showNotification(const_IMAGE_ERROR, stderr + " \n " + stdout)
                return
            }

            var splitIndex = stdout.indexOf("*")

            if (splitIndex === -1) {
                // If the * is not present, it means that there is a problem with the files used to save the output of commands executed with kdesu.

                showNotification(const_IMAGE_ERROR, i18n("No output data was found for the command executed with kdesu."))
                return
            }

            var kdesuStdout = stdout.substring(0, splitIndex).trim()
            var kdesuStderr = stdout.substring(splitIndex + 1).trim()

            if(kdesuStderr){
                //An error occurred while executing the command "kdesu envycontrol -s [mode]".

                showNotification(const_IMAGE_ERROR, kdesuStderr + " \n " + kdesuStdout)

                // Check the current state in case EnvyControl made changes without warning.
                queryMode()

            } else {
                /*
                * You can switch to a mode, and then switch back to the current mode, all without restarting your computer.
                * In this scenario, do the changes that EnvyControl can make really require a reboot? In the end without a reboot,
                * the current mode is always the one that will continue to run.
                * I am going to assume that in this case there is no point in restarting the computer, and therefore displaying the message "restart required".
                */
                if(root.desiredGPUMode !== root.currentGPUMode){
                    root.pendingRebootGPUMode = root.desiredGPUMode
                    showNotification(root.icons[root.desiredGPUMode], kdesuStdout)
                }else{
                    root.pendingRebootGPUMode = ""
                    showNotification(root.icons[root.desiredGPUMode], i18n("You have switched back to the current mode."))
                }
            }
        }
    }


    // Try to find out the manufacturer of the CPU to use an appropriate icon.
    function setupCPUManufacturer() {
        cpuManufacturerDataSource.exec(const_COMMANDS.cpuManufacturer)
    }

    // Get the current GPU mode
    function queryMode() {
        root.loading = true
        envyControlQueryModeDataSource.exec(const_COMMANDS.query)
    }

    function switchMode(mode: string) {
        root.desiredGPUMode = mode
        root.loading = true

        showNotification(root.icons[mode], i18n("Switching to %1 GPU mode, please wait.", mode))

        envyControlSetModeDataSource.exec(const_COMMANDS[mode])
    }

    function showNotification(iconURL: string, message: string, title = "Optimus GPU Switcher", options = const_ZERO_TIMEOUT_NOTIFICATION){
        sendNotification.exec(const_COMMANDS.sendNotification(title, message, iconURL, options))
    }

    function findKdesu() {
        findKdesuDataSource.exec(const_COMMANDS.findKdesu)
    }

    function findNotificationTool() {
        findNotificationToolDataSource.exec(const_COMMANDS.findNotificationTool)
    }

    Plasmoid.preferredRepresentation: Plasmoid.compactRepresentation

    Plasmoid.compactRepresentation: Item {
        PlasmaCore.IconItem {
            height: Plasmoid.configuration.iconSize
            width: Plasmoid.configuration.iconSize
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
                Layout.preferredHeight: 64
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
                visible: root.pendingRebootGPUMode && !root.loading
                color: "red"
                text: i18n("Switched to:" + " " + root.pendingRebootGPUMode.toUpperCase()) + "\n" + i18n("Please reboot your computer for changes to take effect.")
            }

            PlasmaComponents3.Label {
                Layout.topMargin: 10
                text: i18n("Change mode:")
                Layout.alignment: Qt.AlignCenter
            }


            PlasmaComponents3.ComboBox {
                Layout.alignment: Qt.AlignCenter

                enabled: !root.loading && root.envycontrol
                model: const_GPU_MODES
                currentIndex: model.indexOf(root.desiredGPUMode)

                onCurrentIndexChanged: {
                    if (currentIndex !== model.indexOf(root.desiredGPUMode)) {
                        switchMode(model[currentIndex])
                    }
                }
            }


            PlasmaComponents3.Button {
                Layout.alignment: Qt.AlignCenter
                icon.name: "view-refresh-symbolic"
                text: i18n("Refresh")
                onClicked: queryMode()
                enabled: !root.loading && root.envycontrol
            }


            BusyIndicator {
                id: loadingIndicator
                Layout.alignment: Qt.AlignCenter
                running: root.loading
            }


        }
    }

    Plasmoid.toolTipMainText: i18n("Switch GPU mode.")
    Plasmoid.toolTipSubText: root.envycontrol ? i18n("%1 currently in use.", root.currentGPUMode.toUpperCase()) : i18n("EnvyControl is not working.")
}
