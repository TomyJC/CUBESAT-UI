import QtQuick
import QtQuick.Layouts
import "../Componentes"

TarjetaDeDatos {
    id: root

    Layout.fillWidth: true
    Layout.fillHeight: true
    titulo: "BATERÍA / CONECTIVIDAD"
    icono: "🔋"

    // ── Propiedades de datos ─────────────────────
    property real voltaje: -1
    property real rssi: 0
    property real snr: 0
    property real cpuTemp: -1
    property bool datosDisponibles: false

    // ── Cálculo de porcentaje de batería ─────────
    // Li-ion 18650: 3.0 V = 0%, 4.2 V = 100%
    readonly property real _porcentajeBat: {
        if (!root.datosDisponibles || root.voltaje < 0) return 0.0
        return Math.max(0.0, Math.min(1.0, (root.voltaje - 3.0) / 1.2))
    }

    // ── Color dinámico por nivel ─────────────────
    // Sin datos → siempre gris. Con datos → verde / naranja / rojo.
    readonly property color _colorBat: {
        if (!root.datosDisponibles || root.voltaje < 0) return Theme.neutro
        if (_porcentajeBat > 0.50) return Theme.exito
        if (_porcentajeBat > 0.25) return Theme.advertencia
        return Theme.error
    }

    // ── Color RSSI ───────────────────────────────
    function colorRssi(val) {
        if (val > -60) return Theme.exito
        if (val > -80) return Theme.advertencia
        return Theme.error
    }

    // ── Contenido ────────────────────────────────
    contenido: RowLayout {
        anchors.fill: parent
        spacing: Theme.margen

        // ════════════════════════════════════════
        //  BARRA VISUAL DE BATERÍA
        // ════════════════════════════════════════
        Item { Layout.preferredWidth: 15 }
        Item {
            Layout.preferredWidth: 48
            Layout.fillHeight: true

            // Porcentaje numérico encima
            Text {
                id: _pctTexto
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                text: root.datosDisponibles && root.voltaje >= 0
                      ? Math.round(root._porcentajeBat * 100) + "%"
                      : "--"
                font.pixelSize: Theme.fuenteCaption
                font.bold: true
                font.family: Theme.fuenteMono
                color: root._colorBat

                Behavior on color { ColorAnimation { duration: 400 } }
            }

            // Cuerpo de la batería
            Item {
                id: _cuerpo
                anchors.top: _pctTexto.bottom
                anchors.topMargin: 4
                anchors.bottom: _etiquetaVolt.top
                anchors.bottomMargin: 4
                anchors.horizontalCenter: parent.horizontalCenter
                width: 45

                // Terminal positivo (tope)
                Rectangle {
                    id: _terminal
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: parent.top
                    width: 12
                    height: 5
                    radius: 2
                    color: Qt.rgba(
                        root._colorBat.r,
                        root._colorBat.g,
                        root._colorBat.b,
                        0.6
                    )
                }

                // Marco exterior de la batería
                Rectangle {
                    id: _marco
                    anchors.top: _terminal.bottom
                    anchors.bottom: parent.bottom
                    anchors.left: parent.left
                    anchors.right: parent.right
                    radius: 4
                    color: "transparent"
                    border.color: root._colorBat   // gris cuando apagado, color cuando activo
                    border.width: 1.5

                    Behavior on border.color { ColorAnimation { duration: 400 } }

                    // Relleno de nivel
                    Item {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        anchors.margins: 3
                        // Sin datos → altura 0 (barra vacía / apagada)
                        height: root.datosDisponibles ? (parent.height - 6) * root._porcentajeBat : 0
                        clip: true

                        Behavior on height {
                            NumberAnimation {
                                duration: 600
                                easing.type: Easing.OutCubic
                            }
                        }

                        // Gradiente del relleno
                        Rectangle {
                            anchors.fill: parent
                            radius: 2
                            gradient: Gradient {
                                GradientStop {
                                    position: 0.0
                                    color: Qt.rgba(
                                        root._colorBat.r,
                                        root._colorBat.g,
                                        root._colorBat.b,
                                        0.9
                                    )
                                }
                                GradientStop {
                                    position: 1.0
                                    color: Qt.rgba(
                                        root._colorBat.r,
                                        root._colorBat.g,
                                        root._colorBat.b,
                                        0.5
                                    )
                                }
                            }
                        }
                    }

                    // Líneas de segmento (3 divisiones)
                    Repeater {
                        model: 3
                        Rectangle {
                            required property int index
                            x: 3
                            width: _marco.width - 6
                            height: 1
                            // 25%, 50%, 75% desde abajo
                            y: _marco.height - _marco.height * ((index + 1) * 0.25) - 3
                            color: Qt.rgba(1, 1, 1, 0.08)
                        }
                    }
                }
            }

            // Voltaje debajo
            Text {
                id: _etiquetaVolt
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                text: root.datosDisponibles && root.voltaje >= 0
                      ? root.voltaje.toFixed(2) + "V"
                      : "-.--V"
                font.pixelSize: Theme.fuenteCaption
                font.family: Theme.fuenteMono
                font.bold: true
                color: root._colorBat

                Behavior on color { ColorAnimation { duration: 400 } }
            }

            // Parpadeo de alerta solo cuando hay datos Y el nivel es crítico
            SequentialAnimation on opacity {
                running: root.datosDisponibles && root.voltaje >= 0 && root._porcentajeBat <= 0.20
                loops: Animation.Infinite
                NumberAnimation { to: 0.4; duration: 400; easing.type: Easing.InOutSine }
                NumberAnimation { to: 1.0; duration: 400; easing.type: Easing.InOutSine }
            }
        }

        // Separador vertical
        Rectangle {
            Layout.fillHeight: true
            width: 1
            color: Theme.bordeSeparador
        }

        // ════════════════════════════════════════
        //  CUADRÍCULA 2×2 DE MÉTRICAS
        // ════════════════════════════════════════
        GridLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            columns: 2
            rowSpacing: 6
            columnSpacing: 12

            // ── CPU TEMP ──
            ColumnLayout {
                spacing: 1
                Text {
                    text: "CPU TEMP"
                    font.pixelSize: Theme.fuenteCaption
                    font.letterSpacing: 1
                    color: Theme.textoClaro
                }
                RowLayout {
                    spacing: 3
                    Text {
                        text: root.datosDisponibles && root.cpuTemp >= 0
                              ? root.cpuTemp.toFixed(1) : "--"
                        font.pixelSize: Theme.fuenteH3
                        font.bold: true
                        font.family: Theme.fuenteMono
                        color: !root.datosDisponibles      ? Theme.textoMedio
                             : root.cpuTemp >= 70 ? Theme.error
                             : root.cpuTemp >= 55 ? Theme.advertencia
                             : root.cpuTemp >= 0  ? Theme.textoValor
                             : Theme.textoMedio
                    }
                    Text {
                        text: "°C"
                        font.pixelSize: Theme.fuenteSmall
                        color: Theme.textoClaro
                        Layout.alignment: Qt.AlignBottom
                    }
                }
            }

            // ── RSSI ──
            ColumnLayout {
                spacing: 1
                Text {
                    text: "RSSI"
                    font.pixelSize: Theme.fuenteCaption
                    font.letterSpacing: 1
                    color: Theme.textoClaro
                }
                RowLayout {
                    spacing: 3
                    Text {
                        text: root.datosDisponibles ? root.rssi.toFixed(0) : "--"
                        font.pixelSize: Theme.fuenteH3
                        font.bold: true
                        font.family: Theme.fuenteMono
                        color: root.datosDisponibles ? colorRssi(root.rssi) : Theme.textoMedio
                    }
                    Text {
                        text: "dBm"
                        font.pixelSize: Theme.fuenteSmall
                        color: Theme.textoClaro
                        Layout.alignment: Qt.AlignBottom
                    }
                }
            }

            // ── SNR ──
            ColumnLayout {
                spacing: 1
                Text {
                    text: "SNR"
                    font.pixelSize: Theme.fuenteCaption
                    font.letterSpacing: 1
                    color: Theme.textoClaro
                }
                RowLayout {
                    spacing: 3
                    Text {
                        text: root.datosDisponibles ? root.snr.toFixed(1) : "--"
                        font.pixelSize: Theme.fuenteH3
                        font.bold: true
                        font.family: Theme.fuenteMono
                        color: root.datosDisponibles ? Theme.textoPrincipal : Theme.textoMedio
                    }
                    Text {
                        text: "dB"
                        font.pixelSize: Theme.fuenteSmall
                        color: Theme.textoClaro
                        Layout.alignment: Qt.AlignBottom
                    }
                }
            }

            // ── SEÑAL (indicador de barras LoRa) ──
            ColumnLayout {
                spacing: 1
                Text {
                    text: "SEÑAL"
                    font.pixelSize: Theme.fuenteCaption
                    font.letterSpacing: 1
                    color: Theme.textoClaro
                }

                // Mini-indicador de barras de señal (4 barras)
                // height = barra más alta: 8 + 3*5 = 23px
                Row {
                    spacing: 3
                    height: 23
                    Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter

                    Repeater {
                        model: 4
                        Rectangle {
                            required property int index

                            readonly property real _umbral: (index + 1) / 4.0
                            readonly property real _nivelSenal: {
                                if (!root.datosDisponibles) return 0.0
                                // RSSI: -40dBm=100%, -100dBm=0%
                                return Math.max(0.0, Math.min(1.0, (root.rssi + 100) / 60.0))
                            }
                            readonly property bool _activa: _nivelSenal >= _umbral

                            width: 7
                            height: 8 + index * 5   // alturas crecientes: 8,13,18,23
                            radius: 2
                            anchors.bottom: parent.bottom

                            color: _activa
                                   ? colorRssi(root.rssi)
                                   : Qt.rgba(1, 1, 1, 0.10)

                            Behavior on color {
                                ColorAnimation { duration: 300 }
                            }
                        }
                    }
                }
            }
        }
    }
}
