// CustomDataSource.qml
import QtQuick 2.15
import org.kde.plasma.plasma5support as Plasma5Support

// Custom DataSource component that can be used to create various DataSources.
// It provides flexibility by allowing you to specify the 'command' and 'engine' properties.
Plasma5Support.DataSource {
    // The command to execute (e.g., the executable or script to run).
    property string command: ""

    engine: "executable"
    connectedSources: []

    onNewData: (sourceName, data) => {
        var exitCode = data["exit code"]
        var exitStatus = data["exit status"]
        var stdout = data["stdout"]
        var stderr = data["stderr"]

        // Emit the 'exited' signal to indicate that the DataSource execution has completed.
        exited(exitCode, exitStatus, stdout, stderr)

        // Disconnect the DataSource sourceName.
        disconnectSource(sourceName)
    }

    // Execute the DataSource with the specified 'command'.
    function exec() {
        connectSource(command)
    }

    // Signal emitted when the DataSource execution has completed.
    signal exited(int exitCode, int exitStatus, string stdout, string stderr)
}
