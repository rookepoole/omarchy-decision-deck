import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.Commons

Item {
    id: root
    property var shell: null
    property var manifest: null
    property bool opened: false
    property var choices: ["Ship the smallest useful slice", "Prototype the risky part", "Take a walk, then decide", "Ask one person who will disagree", "Delete one requirement"]
    property int selectedIndex: 0
    property int spins: 0
    property bool spinning: false

    function safeChoices(payloadJson) {
        var fallback = root.choices;
        try {
            var payload = JSON.parse(String(payloadJson || "{}")) || {};
            if (!Array.isArray(payload.choices))
                return fallback;
            var cleaned = [];
            for (var i = 0; i < payload.choices.length && cleaned.length < 12; i++) {
                var value = String(payload.choices[i] === undefined ? "" : payload.choices[i]).trim().slice(0, 80);
                if (value)
                    cleaned.push(value);
            }
            return cleaned.length >= 2 ? cleaned : fallback;
        } catch (e) {
            return fallback;
        }
    }
    function open(payloadJson) {
        choices = safeChoices(payloadJson);
        selectedIndex = 0;
        spins = 0;
        spinning = false;
        opened = true;
        Qt.callLater(function () {
            keyCatcher.forceActiveFocus();
        });
    }
    function close() {
        opened = false;
        spinTimer.stop();
    }
    function toggle() {
        if (opened)
            dismiss();
        else
            open("{}");
    }
    function dismiss() {
        if (shell && typeof shell.hide === "function")
            shell.hide((manifest && manifest.id) || "io.github.rookepoole.decision-deck");
        else
            close();
    }
    function draw() {
        if (choices.length < 2 || spinning)
            return;
        spins = 0;
        spinning = true;
        spinTimer.start();
    }

    Timer {
        id: spinTimer
        interval: 65
        repeat: true
        onTriggered: {
            root.selectedIndex = (root.selectedIndex + 1 + Math.floor(Math.random() * Math.max(1, root.choices.length - 1))) % root.choices.length;
            root.spins++;
            if (root.spins >= 14) {
                stop();
                root.spinning = false;
            }
        }
    }

    PanelWindow {
        id: window
        visible: root.opened
        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }
        color: "transparent"
        WlrLayershell.namespace: "rookepoole-decision-deck"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
        exclusionMode: ExclusionMode.Ignore

        Rectangle {
            anchors.fill: parent
            color: Qt.rgba(0.02, 0.015, 0.03, 0.92)
        }
        MouseArea {
            anchors.fill: parent
            onClicked: root.dismiss()
        }

        Item {
            id: keyCatcher
            anchors.fill: parent
            focus: true
            Keys.onPressed: function (event) {
                if (event.key === Qt.Key_Escape) {
                    root.dismiss();
                    event.accepted = true;
                } else if (event.key === Qt.Key_Space || event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                    root.draw();
                    event.accepted = true;
                } else if (event.key === Qt.Key_Left) {
                    root.selectedIndex = (root.selectedIndex - 1 + root.choices.length) % root.choices.length;
                    event.accepted = true;
                } else if (event.key === Qt.Key_Right) {
                    root.selectedIndex = (root.selectedIndex + 1) % root.choices.length;
                    event.accepted = true;
                }
            }

            Rectangle {
                id: card
                width: Math.min(Style.space(660), window.width - Style.space(40))
                height: Math.min(Style.space(460), window.height - Style.space(40))
                anchors.centerIn: parent
                radius: Style.cornerRadius * 2
                color: Color.background
                border.width: 1
                border.color: Qt.rgba(Color.accent.r, Color.accent.g, Color.accent.b, 0.45)
                MouseArea {
                    anchors.fill: parent
                    onClicked: root.draw()
                    cursorShape: Qt.PointingHandCursor
                }

                Column {
                    anchors.fill: parent
                    anchors.margins: Style.space(34)
                    spacing: Style.space(16)
                    Text {
                        width: parent.width
                        text: "DECISION DECK"
                        color: Color.foreground
                        opacity: 0.54
                        font.family: Style.font.family
                        font.pixelSize: Style.font.subtitle
                        font.bold: true
                        horizontalAlignment: Text.AlignHCenter
                    }
                    Item {
                        width: 1
                        height: Style.space(18)
                    }
                    Text {
                        width: parent.width
                        height: Style.space(170)
                        textFormat: Text.PlainText
                        text: root.choices[root.selectedIndex]
                        color: root.spinning ? Color.accent : Color.foreground
                        font.family: Style.font.family
                        font.pixelSize: Style.font.displayLarge * 1.35
                        font.bold: true
                        wrapMode: Text.WordWrap
                        verticalAlignment: Text.AlignVCenter
                        horizontalAlignment: Text.AlignHCenter
                        Behavior on color {
                            ColorAnimation {
                                duration: 120
                            }
                        }
                    }
                    Rectangle {
                        width: parent.width
                        height: 1
                        color: Qt.rgba(Color.foreground.r, Color.foreground.g, Color.foreground.b, 0.14)
                    }
                    Text {
                        width: parent.width
                        text: root.spinning ? "drawing…" : "Space / Enter / click to draw  ·  ← → browse  ·  Esc close"
                        color: Color.foreground
                        opacity: 0.58
                        font.family: Style.font.family
                        font.pixelSize: Style.font.body
                        horizontalAlignment: Text.AlignHCenter
                    }
                    Text {
                        width: parent.width
                        text: root.choices.length + " cards"
                        color: Color.accent
                        opacity: 0.8
                        font.family: Style.font.family
                        font.pixelSize: Style.font.caption
                        horizontalAlignment: Text.AlignHCenter
                    }
                }
            }
        }
    }
}
