import QtQuick
import QtQuick.Controls as QQC
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
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
  property string resultText: ""
  property string copyText: ""
  property string errorText: ""
  property bool isLoading: false
  property string lastQuery: ""

  function open() {
    opened = true
    Qt.callLater(function() {
      if (inputField) {
        inputField.forceActiveFocus()
        inputField.selectAll()
      }
    })
  }
  function close() { opened = false }
  function toggle() { opened ? close() : open() }
  function closeForPopoutSwitch() { close() }

  readonly property bool popoutSwitchClosing: false

  function lookup() {
    const q = inputField.text.trim()
    if (!q) {
      errorText = "Enter a reference — e.g. John 3:16"
      resultText = ""
      return
    }
    lastQuery = q
    isLoading = true
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
    copyFeedback.visible = true
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

  // KeyboardPanel gives proper layer-shell focus handling for TextField
  KeyboardPanel {
    id: panel
    anchorItem: button
    bar: root.bar
    owner: root
    open: root.opened
    focusTarget: keyCatcher
    contentWidth: fittedContentWidth(Style.space(520))
    contentHeight: fittedContentHeight(mainColumn.implicitHeight + Style.space(8))

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      blocked: inputField.activeFocus
      onCloseRequested: root.close()

      ColumnLayout {
        id: mainColumn
        anchors.fill: parent
        anchors.margins: Style.spacing.sm
        spacing: Style.space(12)

        // Header
        RowLayout {
          Layout.fillWidth: true
          spacing: Style.space(8)

          Text {
            text: "Bible"
            color: Color.popups.text
            font.family: Style.font.family
            font.pixelSize: Style.font.title
            font.bold: true
            Layout.alignment: Qt.AlignVCenter
          }
          Text {
            text: "BSB"
            color: Qt.darker(Color.popups.text, 1.4)
            font.family: Style.font.family
            font.pixelSize: Style.font.caption
            Layout.alignment: Qt.AlignVCenter
          }
          Item { Layout.fillWidth: true }

          // Close affordance
          Button {
            text: "✕"
            implicitWidth: Style.space(28)
            implicitHeight: Style.space(28)
            fontSize: Style.font.caption
            onClicked: root.close()
          }
        }

        // Search row
        RowLayout {
          Layout.fillWidth: true
          spacing: Style.space(8)

          TextField {
            id: inputField
            Layout.fillWidth: true
            placeholderText: "John 3:16  •  Ps 23  •  Gen 1:1-3  •  Rom 8:28"
            font.family: Style.font.family
            font.pixelSize: Style.font.body
            // Enter triggers lookup
            onAccepted: root.lookup()
            Keys.onEscapePressed: root.close()
            // Select all on focus
            onActiveFocusChanged: if (activeFocus) selectAll()
          }

          Button {
            text: root.isLoading ? "…" : "Go"
            enabled: !root.isLoading
            implicitWidth: Style.space(52)
            onClicked: root.lookup()
          }
        }

        Text {
          Layout.fillWidth: true
          text: "Examples: <b>John 3:16</b> &nbsp; <b>Jn 3:16</b> &nbsp; <b>Gen 1:1-3</b> &nbsp; <b>Ps 23</b> &nbsp; <b>1Jn 3:16</b>"
          textFormat: Text.RichText
          wrapMode: Text.Wrap
          color: Qt.darker(Color.popups.text, 1.6)
          font.family: Style.font.family
          font.pixelSize: Style.font.caption
          opacity: 0.85
        }

        // Status / loading
        Text {
          visible: root.isLoading
          Layout.fillWidth: true
          text: "Looking up…"
          color: Qt.darker(Color.popups.text, 1.2)
          font.family: Style.font.family
          font.pixelSize: Style.font.body
          font.italic: true
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

        // Result area with scroll
        Flickable {
          id: resultFlick
          visible: !root.isLoading && root.resultText !== ""
          Layout.fillWidth: true
          Layout.preferredHeight: Math.min(Math.max(resultTextItem.implicitHeight + Style.space(16), Style.space(80)), Style.space(380))
          Layout.maximumHeight: Style.space(380)
          contentHeight: resultTextItem.implicitHeight + Style.space(16)
          contentWidth: width
          clip: true
          boundsBehavior: Flickable.StopAtBounds

          Text {
            id: resultTextItem
            width: resultFlick.width - Style.space(8)
            x: Style.space(4)
            y: Style.space(8)
            text: root.resultText
            wrapMode: Text.Wrap
            textFormat: Text.PlainText
            color: Color.popups.text
            font.family: Style.font.family
            font.pixelSize: Style.font.body
            lineHeight: 1.35
          }

          QQC.ScrollBar.vertical: QQC.ScrollBar {
            policy: QQC.ScrollBar.AsNeeded
          }
        }

        // Copy row
        RowLayout {
          visible: !root.isLoading && root.resultText !== ""
          Layout.fillWidth: true
          spacing: Style.space(8)

          Text {
            visible: lastQuery !== ""
            text: lastQuery
            color: Qt.darker(Color.popups.text, 1.5)
            font.family: Style.font.family
            font.pixelSize: Style.font.caption
            font.italic: true
            elide: Text.ElideRight
            Layout.fillWidth: true
          }

          Button {
            text: "Copy"
            onClicked: root.copyResult()
          }
        }

        Text {
          id: copyFeedback
          visible: false
          text: "Copied to clipboard"
          color: Color.accent
          font.family: Style.font.family
          font.pixelSize: Style.font.caption
          Layout.alignment: Qt.AlignRight
        }

        Timer {
          id: copyFeedbackTimer
          interval: 1800
          onTriggered: copyFeedback.visible = false
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
    function copy(): void { root.copyResult() }
  }
}
