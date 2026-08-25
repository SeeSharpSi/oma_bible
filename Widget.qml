import QtQuick
import QtQuick.Controls as QQC
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.Commons
import qs.Ui

BarWidget {
  id: root
  moduleName: "cassian.bible"

  readonly property string bsbPath: {
    const url = String(Qt.resolvedUrl("./bsb"))
    if (url.indexOf("file://") === 0) return decodeURIComponent(url.substring(7))
    return url
  }

  property bool opened: false
  property bool readerOpened: false
  property string resultText: ""
  property string copyText: ""
  property string errorText: ""
  property bool isLoading: false
  property string lastQuery: ""
  property bool copyConfirmed: false
  property int readerFontLevel: 0

  readonly property color fg: Color.popups.text
  readonly property color dimText: Qt.darker(fg, 1.4)
  readonly property color dimmerText: Qt.darker(fg, 1.75)

  function open() {
    readerOpened = false
    opened = true
    Qt.callLater(function() {
      if (inputField) {
        inputField.forceActiveFocus()
        inputField.selectAll()
      }
    })
  }
  function close() {
    opened = false
    readerOpened = false
  }
  function toggle() { opened ? close() : open() }
  function closeForPopoutSwitch() { close() }

  function openReader() {
    if (!resultText) return
    opened = false
    readerOpened = true
    overlayReader.contentY = 0
    Qt.callLater(function() {
      if (readerOpened) readerKeyCatcher.forceActiveFocus()
    })
  }

  readonly property bool popoutSwitchClosing: false

  // Display structure only: resultText lays each group out as a reference
  // header line followed by its verses, groups separated by a blank line.
  // Splitting that back apart lets the panel style references and verses
  // differently.
  readonly property var resultGroups: {
    if (!root.resultText) return []
    return root.resultText.split("\n\n").map(function(block) {
      const lines = block.split("\n")
      return { ref: lines[0].replace(/;\s*$/, ""), body: lines.slice(1).join("\n") }
    })
  }

  function lookup() {
    const q = inputField.text.trim()
    if (!q) {
      errorText = "Enter a reference — e.g. John 3:16"
      resultText = ""
      return
    }
    lastQuery = q
    isLoading = true
    panelReader.contentY = 0
    resultText = ""
    copyText = ""
    errorText = ""
    // --grouped prefixes each reference group with a \x1e header line
    bibleProc.command = [root.bsbPath, "--grouped", q]
    bibleProc.running = true
  }

  function copyResult() {
    if (!resultText) return
    const payload = copyText !== "" ? copyText : (lastQuery !== "" ? lastQuery + "\n" : "") + resultText
    // Use wl-copy if available, fallback to xclip
    const quoted = Util.shellQuote(payload)
    // Try wl-copy; detaches, no need to wait
    if (bar) bar.run("printf %s " + quoted + " | (wl-copy 2>/dev/null || xclip -selection clipboard 2>/dev/null || cat >/dev/null); echo copied")
    // Brief feedback
    copyConfirmed = true
    copyFeedbackTimer.restart()
  }

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    // book-open glyph (Nerd Font) — fallback is emoji if font missing
    text: "󰂺"
    slotSize: Style.bar.statusSlot
    tooltipText: "Bible — lookup BSB verses (click to search)"
    onPressed: function(btn) { root.toggle() }
  }

  KeyboardPanel {
    id: panel
    anchorItem: button
    bar: root.bar
    owner: root
    open: root.opened
    focusTarget: keyCatcher
    contentWidth: fittedContentWidth(Style.space(520))
    contentHeight: fittedContentHeight(mainColumn.implicitHeight, Style.space(620))

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      blocked: inputField.activeFocus
      onCloseRequested: root.close()

      ColumnLayout {
        id: mainColumn
        anchors.fill: parent
        spacing: Style.space(11)

        RowLayout {
          Layout.fillWidth: true
          spacing: Style.space(7)

          Text {
            text: "BIBLE"
            color: root.fg
            font.family: Style.font.family
            font.pixelSize: Style.font.title
            font.bold: true
          }

          Text {
            text: "BSB"
            color: root.dimmerText
            font.family: Style.font.family
            font.pixelSize: Style.font.caption
            font.letterSpacing: 1
            Layout.alignment: Qt.AlignVCenter
          }

          Item { Layout.fillWidth: true }
        }

        PanelSeparator {
          Layout.fillWidth: true
          foreground: root.fg
        }

        RowLayout {
          Layout.fillWidth: true
          spacing: Style.space(8)

          TextField {
            id: inputField
            Layout.fillWidth: true
            placeholderText: "Search a reference, e.g. John 3:16"
            font.family: Style.font.family
            font.pixelSize: Style.font.body
            onAccepted: root.lookup()
            Keys.onEscapePressed: root.close()
            onActiveFocusChanged: if (activeFocus) selectAll()
          }

          Button {
            text: root.isLoading ? "Searching" : "Search"
            bordered: true
            enabled: !root.isLoading && inputField.text.trim() !== ""
            onClicked: root.lookup()
          }
        }

        Text {
          visible: root.isLoading
          Layout.fillWidth: true
          text: "Looking up " + root.lastQuery + "..."
          color: root.dimText
          font.family: Style.font.family
          font.pixelSize: Style.font.caption
        }

        Text {
          visible: !root.isLoading && root.errorText !== ""
          Layout.fillWidth: true
          text: root.errorText
          wrapMode: Text.Wrap
          color: Color.urgent
          font.family: Style.font.family
          font.pixelSize: Style.font.body
        }

        PanelSeparator {
          visible: !root.isLoading && root.resultGroups.length > 0
          Layout.fillWidth: true
          foreground: root.fg
        }

        Item {
          visible: !root.isLoading && root.resultGroups.length > 0
          Layout.fillWidth: true
          Layout.preferredHeight: Math.min(Math.max(panelReader.contentHeight, Style.space(96)), Style.space(360))
          Layout.maximumHeight: Style.space(360)

          VerseReader {
            id: panelReader
            anchors.fill: parent
            groups: root.resultGroups
            foreground: root.fg
            muted: root.dimText
          }
        }

        PanelSeparator {
          visible: !root.isLoading && root.resultGroups.length > 0
          Layout.fillWidth: true
          foreground: root.fg
        }

        RowLayout {
          visible: !root.isLoading && root.resultGroups.length > 0
          Layout.fillWidth: true
          spacing: Style.space(8)

          Text {
            visible: root.copyConfirmed
            text: "Copied"
            color: Color.accent
            font.family: Style.font.family
            font.pixelSize: Style.font.caption
          }

          Item { Layout.fillWidth: true }

          Button {
            text: "Open"
            onClicked: root.openReader()
          }

          Button {
            text: "Copy"
            bordered: true
            onClicked: root.copyResult()
          }
        }

        Timer {
          id: copyFeedbackTimer
          interval: 1800
          onTriggered: root.copyConfirmed = false
        }
      }
    }
  }

  component VerseReader: Flickable {
    id: verseReader

    required property var groups
    required property color foreground
    required property color muted
    property int fontLevel: 0
    readonly property real _fontScale: fontLevel === 1 ? 1.25 : fontLevel === 2 ? 1.5 : 1.0

    contentWidth: width
    contentHeight: verseColumn.implicitHeight + Style.space(8)
    clip: true
    boundsBehavior: Flickable.StopAtBounds
    interactive: contentHeight > height

    ColumnLayout {
      id: verseColumn
      x: Style.space(4)
      y: Style.space(4)
      width: verseReader.width - Style.space(20)
      spacing: Style.space(16)

      Repeater {
        model: verseReader.groups

        ColumnLayout {
          id: verseGroup
          required property var modelData
          Layout.fillWidth: true
          spacing: Style.space(5)

          Text {
            text: verseGroup.modelData.ref
            color: verseReader.muted
            font.family: Style.font.family
            font.pixelSize: Math.round(Style.font.caption * verseReader._fontScale)
            font.bold: true
            font.letterSpacing: 0.6
          }

          Text {
            Layout.fillWidth: true
            text: verseGroup.modelData.body
            wrapMode: Text.Wrap
            textFormat: Text.PlainText
            color: verseReader.foreground
            font.family: Style.font.family
            font.pixelSize: Math.round(Style.font.body * verseReader._fontScale)
            lineHeight: 1.45
          }
        }
      }
    }

    QQC.ScrollBar.vertical: QQC.ScrollBar {
      policy: QQC.ScrollBar.AsNeeded
      implicitWidth: Style.space(10)
      background: null
      contentItem: Rectangle {
        implicitWidth: parent.implicitWidth
        radius: width / 2
        color: Qt.rgba(verseReader.foreground.r, verseReader.foreground.g, verseReader.foreground.b, 0.3)
        opacity: parent.active ? 1 : 0.4

        Behavior on opacity { NumberAnimation { duration: 120 } }
      }
    }
  }

  PanelWindow {
    id: readerOverlay

    screen: panel.screen
    visible: root.readerOpened
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "cassian-bible-reader"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: root.readerOpened
      ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    Rectangle {
      anchors.fill: parent
      color: Qt.rgba(0, 0, 0, 0.7)
    }

    MouseArea {
      anchors.fill: parent
      acceptedButtons: Qt.AllButtons
      onClicked: root.close()
    }

    Item {
      id: readerKeyCatcher
      anchors.fill: parent
      focus: true
      Keys.onEscapePressed: root.close()

      BorderSurface {
        id: readerCard
        anchors.centerIn: parent
        width: Math.min(parent.width - Style.space(32), Style.space(820))
        height: Math.min(parent.height - Style.space(48),
          Math.max(Style.space(280), overlayReader.contentHeight + Style.space(120)))
        color: Color.popups.background
        borderSpec: Border.surfaceSpec("popups", "border", Color.popups.border, Math.max(1, Style.space(2)))
        radius: Style.cornerRadius
        padding: Style.spacing.popupPadding

        MouseArea {
          anchors.fill: parent
          acceptedButtons: Qt.AllButtons
          onClicked: {}
        }

        ColumnLayout {
          anchors.fill: parent
          anchors.topMargin: readerCard.contentTopInset
          anchors.rightMargin: readerCard.contentRightInset
          anchors.bottomMargin: readerCard.contentBottomInset
          anchors.leftMargin: readerCard.contentLeftInset
          spacing: Style.space(12)

          RowLayout {
            Layout.fillWidth: true
            spacing: Style.space(8)

            Text {
              text: "BIBLE"
              color: root.fg
              font.family: Style.font.family
              font.pixelSize: Style.font.title
              font.bold: true
            }

            Text {
              Layout.fillWidth: true
              text: root.lastQuery
              color: root.dimmerText
              font.family: Style.font.family
              font.pixelSize: Style.font.caption
              elide: Text.ElideRight
            }

            RowLayout {
              spacing: Style.space(4)

              Button {
                text: "A"
                fontFamily: Style.font.family
                fontSize: Style.font.body
                selected: root.readerFontLevel === 0
                onClicked: root.readerFontLevel = 0
                tooltipText: "Default size"
                horizontalPadding: Style.space(6)
                verticalPadding: Style.space(4)
              }

              Button {
                text: "A"
                fontFamily: Style.font.family
                fontSize: Math.round(Style.font.body * 1.25)
                selected: root.readerFontLevel === 1
                onClicked: root.readerFontLevel = 1
                tooltipText: "Larger text"
                horizontalPadding: Style.space(6)
                verticalPadding: Style.space(4)
              }

              Button {
                text: "A"
                fontFamily: Style.font.family
                fontSize: Math.round(Style.font.body * 1.5)
                selected: root.readerFontLevel === 2
                onClicked: root.readerFontLevel = 2
                tooltipText: "Largest text"
                horizontalPadding: Style.space(6)
                verticalPadding: Style.space(4)
              }
            }
          }

          PanelSeparator {
            Layout.fillWidth: true
            foreground: root.fg
          }

          VerseReader {
            id: overlayReader
            Layout.fillWidth: true
            Layout.fillHeight: true
            groups: root.resultGroups
            foreground: root.fg
            muted: root.dimText
            fontLevel: root.readerFontLevel
          }

          PanelSeparator {
            Layout.fillWidth: true
            foreground: root.fg
          }

          RowLayout {
            Layout.fillWidth: true
            spacing: Style.space(8)

            Text {
              text: "Berean Standard Bible"
              color: root.dimmerText
              font.family: Style.font.family
              font.pixelSize: Style.font.caption
            }

            Item { Layout.fillWidth: true }

            Text {
              visible: root.copyConfirmed
              text: "Copied"
              color: Color.accent
              font.family: Style.font.family
              font.pixelSize: Style.font.caption
            }

            Button {
              text: "Copy"
              bordered: true
              onClicked: root.copyResult()
            }
          }
        }
      }
    }
  }

  Process {
    id: bibleProc
    stdout: StdioCollector {
      id: bibleStdout
      waitForEnd: true
      onStreamFinished: {
        const out = String(text || "").trim()
        if (out.length > 0) {
          // Display: header lines become visible reference headers,
          // with a blank line separating each group. Copy: headers kept inline.
          const lines = out.split("\n")
          const displayLines = []
          for (let i = 0; i < lines.length; i++) {
            const l = lines[i]
            if (l.charCodeAt(0) === 0x1e) {
              if (displayLines.length > 0) displayLines.push("")
              displayLines.push(l.substring(1))
            } else {
              displayLines.push(l)
            }
          }
          root.resultText = displayLines.join("\n")
          root.copyText = out.split("\x1e").join("")
          root.errorText = ""
        } else {
          // stdout empty — keep error from stderr/exit handler if set, else generic
          if (root.errorText === "") {
            root.errorText = "No verses found. Try: John 3:16"
          }
          root.resultText = ""
          root.copyText = ""
        }
        root.isLoading = false
      }
    }
    stderr: StdioCollector {
      id: bibleStderr
      waitForEnd: true
      onStreamFinished: {
        const err = String(text || "").trim()
        // Only surface stderr when stdout produced no result
        if (err !== "" && root.resultText === "") {
          const lines = err.split("\n").map(l => l.trim()).filter(l => l !== "")
          const errors = lines.filter(l => l.indexOf("error:") === 0 || l.indexOf("warning:") === 0)
          let msg = errors.length > 0 ? errors.join("\n") : lines[lines.length - 1]
          // Make hints readable: replace absolute script path with "bsb"
          msg = msg.split(root.bsbPath).join("bsb")
          root.errorText = msg
        }
      }
    }
    onExited: function(code, status) {
      // If process failed and no output/error yet, set generic error
      if (code !== 0 && root.resultText === "" && root.errorText === "") {
        root.errorText = "No verses found (code " + code + "). Try: John 3:16"
      }
      root.isLoading = false
    }
  }

  IpcHandler {
    target: "cassian.bible"
    function open(): void { root.open() }
    function close(): void { root.close() }
    function toggle(): void { root.toggle() }
    function state(): string {
      return JSON.stringify({
        opened: root.opened,
        readerOpened: root.readerOpened,
        result: root.resultText,
        error: root.errorText,
        loading: root.isLoading,
        panelContentHeight: panel ? panel.contentHeight : -1,
        panelContentWidth: panel ? panel.contentWidth : -1,
        columnImplicitHeight: mainColumn ? mainColumn.implicitHeight : -1
      })
    }
    function lookup(query: string): void {
      if (query) inputField.text = query
      root.open()
      Qt.callLater(root.lookup)
    }
    function openResult(): void { root.openReader() }
    function copy(): void { root.copyResult() }
  }
}
