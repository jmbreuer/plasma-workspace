/*
    SPDX-FileCopyrightText: 2012-2013 Daniel Nicoletti <dantti12@gmail.com>
    SPDX-FileCopyrightText: 2013-2015 Kai Uwe Broulik <kde@privat.broulik.de>

    SPDX-License-Identifier: LGPL-2.0-or-later
*/

import QtQuick 2.0
import QtQuick.Layouts 1.1

import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.components 3.0 as PlasmaComponents3
import org.kde.plasma.extras 2.0 as PlasmaExtras
import org.kde.plasma.workspace.components 2.0
import org.kde.kcoreaddons 1.0 as KCoreAddons
import "logic.js" as Logic

Item {
    id: batteryItem
    height: childrenRect.height

    property var battery

    // NOTE: According to the UPower spec this property is only valid for primary batteries, however
    // UPower seems to set the Present property false when a device is added but not probed yet
    readonly property bool isPresent: model["Plugged in"]

    readonly property bool isBroken: model.Capacity > 0 && model.Capacity < 50

    property Component batteryDetails: Flow { // GridLayout crashes with a Repeater in it somehow
        id: detailsLayout

        property int leftColumnWidth: 0
        width: PlasmaCore.Units.gridUnit * 11

        PlasmaComponents3.Label {
            id: brokenBatteryLabel
            width: parent ? parent.width : implicitWidth
            wrapMode: Text.WordWrap
            text: batteryItem.isBroken && typeof model.Capacity !== "undefined" ? i18n("This battery's health is at only %1% and should be replaced. Please contact your hardware vendor for more details.", model.Capacity) : ""
            font: !!detailsLayout.parent.inListView ? PlasmaCore.Theme.smallestFont : PlasmaCore.Theme.defaultFont
            visible: batteryItem.isBroken
        }

        Repeater {
            model: Logic.batteryDetails(batteryItem.battery, batterymonitor.remainingTime)

            PlasmaComponents3.Label {
                id: detailsLabel
                width: modelData.value && parent ? parent.width - detailsLayout.leftColumnWidth - PlasmaCore.Units.smallSpacing : detailsLayout.leftColumnWidth + PlasmaCore.Units.smallSpacing
                wrapMode: Text.NoWrap
                onPaintedWidthChanged: { // horrible HACK to get a column layout
                    if (paintedWidth > detailsLayout.leftColumnWidth) {
                        detailsLayout.leftColumnWidth = paintedWidth
                    }
                }
                height: implicitHeight
                text: modelData.value ? modelData.value : modelData.label

                states: [
                    State {
                        when: !!detailsLayout.parent.inListView // HACK
                        PropertyChanges {
                            target: detailsLabel
                            horizontalAlignment: modelData.value ? Text.AlignRight : Text.AlignLeft
                            font: PlasmaCore.Theme.smallestFont
                            width: parent ? parent.width / 2 : 0
                            elide: Text.ElideNone // eliding and height: implicitHeight causes loops
                        }
                    }
                ]
            }
        }
    }

    Column {
        width: parent.width
        spacing: PlasmaCore.Units.smallSpacing

        PlasmaCore.ToolTipArea {
            width: parent.width
            height: infoRow.height
            active: !detailsLoader.active
            z: 2

            mainItem: Row {
                id: batteryItemToolTip

                property int _s: PlasmaCore.Units.largeSpacing / 2

                Layout.minimumWidth: implicitWidth + batteryItemToolTip._s
                Layout.minimumHeight: implicitHeight + batteryItemToolTip._s * 2
                Layout.maximumWidth: implicitWidth + batteryItemToolTip._s
                Layout.maximumHeight: implicitHeight + batteryItemToolTip._s * 2
                width: implicitWidth + batteryItemToolTip._s
                height: implicitHeight + batteryItemToolTip._s * 2

                spacing: batteryItemToolTip._s*2

                BatteryIcon {
                    x: batteryItemToolTip._s * 2
                    y: batteryItemToolTip._s
                    width: PlasmaCore.Units.iconSizes.desktop // looks weird and small but that's what DefaultTooltip uses
                    height: width
                    batteryType: batteryIcon.batteryType
                    percent: batteryIcon.percent
                    hasBattery: batteryIcon.hasBattery
                    pluggedIn: batteryIcon.pluggedIn
                    visible: !batteryItem.isBroken
                }

                Column {
                    id: mainColumn
                    x: batteryItemToolTip._s
                    y: batteryItemToolTip._s

                    PlasmaExtras.Heading {
                        level: 3
                        text: batteryNameLabel.text
                    }
                    Loader {
                        sourceComponent: batteryItem.batteryDetails
                        opacity: 0.5
                    }
                }
            }

            RowLayout {
                id: infoRow
                width: parent.width
                spacing: PlasmaCore.Units.gridUnit

                BatteryIcon {
                    id: batteryIcon
                    Layout.alignment: Qt.AlignTop
                    width: PlasmaCore.Units.iconSizes.medium
                    height: width
                    batteryType: model.Type
                    percent: model.Percent
                    hasBattery: batteryItem.isPresent
                    pluggedIn: model.State === "Charging" && model["Is Power Supply"]
                }

                Column {
                    Layout.fillWidth: true
                    Layout.alignment: batteryItem.isPresent ? Qt.AlignTop : Qt.AlignVCenter
                    spacing: PlasmaCore.Units.smallSpacing

                    RowLayout {
                        width: parent.width
                        spacing: PlasmaCore.Units.smallSpacing

                        PlasmaComponents3.Label {
                            id: batteryNameLabel
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                            text: model["Pretty Name"]
                        }

                        PlasmaComponents3.Label {
                            text: Logic.stringForBatteryState(model)
                            visible: model["Is Power Supply"]
                            opacity: 0.6
                        }

                        PlasmaComponents3.Label {
                            id: batteryPercent
                            horizontalAlignment: Text.AlignRight
                            visible: batteryItem.isPresent
                            text: i18nc("Placeholder is battery percentage", "%1%", model.Percent)
                        }
                    }

                    PlasmaComponents3.ProgressBar {
                        width: parent.width
                        from: 0
                        to: 100
                        visible: batteryItem.isPresent
                        value: Number(model.Percent)
                    }
                }
            }
        }

        Loader {
            id: detailsLoader
            property bool inListView: true
            anchors {
                left: parent.left
                leftMargin: batteryIcon.width + PlasmaCore.Units.gridUnit
                right: parent.right
            }
            visible: !!item
            opacity: 0.5
            sourceComponent: batteryDetails
        }

        InhibitionHint {
            anchors {
                left: parent.left
                leftMargin: batteryIcon.width + PlasmaCore.Units.gridUnit
                right: parent.right
            }
            readonly property var chargeStopThreshold: pmSource.data["Battery"] ? pmSource.data["Battery"]["Charge Stop Threshold"] : undefined
            readonly property bool pluggedIn: pmSource.data["AC Adapter"] !== undefined && pmSource.data["AC Adapter"]["Plugged in"]
            visible: pluggedIn && typeof chargeStopThreshold === "number" && chargeStopThreshold > 0 && chargeStopThreshold < 100
            iconSource: "kt-speed-limits" // FIXME good icon
            text: i18n("Your battery is configured to only charge up to %1%.", chargeStopThreshold || 0)
        }
    }
}
