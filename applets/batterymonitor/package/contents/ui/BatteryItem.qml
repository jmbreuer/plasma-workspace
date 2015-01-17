/*
 *   Copyright 2012-2013 Daniel Nicoletti <dantti12@gmail.com>
 *   Copyright 2013, 2014 Kai Uwe Broulik <kde@privat.broulik.de>
 *
 *   This program is free software; you can redistribute it and/or modify
 *   it under the terms of the GNU Library General Public License as
 *   published by the Free Software Foundation; either version 2 or
 *   (at your option) any later version.
 *
 *   This program is distributed in the hope that it will be useful,
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *   GNU General Public License for more details
 *
 *   You should have received a copy of the GNU Library General Public
 *   License along with this program; if not, write to the
 *   Free Software Foundation, Inc.,
 *   51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 */

import QtQuick 2.0
import QtQuick.Layouts 1.1

import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.components 2.0 as PlasmaComponents
import org.kde.plasma.extras 2.0 as PlasmaExtras
import org.kde.plasma.workspace.components 2.0
import org.kde.kcoreaddons 1.0 as KCoreAddons
import "plasmapackage:/code/logic.js" as Logic

Item {
    id: batteryItem
    width: parent.width
    height: childrenRect.height

    property var battery

    // NOTE: According to the UPower spec this property is only valid for primary batteries, however
    // UPower seems to set the Present property false when a device is added but not probed yet
    readonly property bool isPresent: model["Plugged in"]

    property Component batteryDetails: Flow { // GridLayout crashes with a Repeater in it somehow
        id: detailsLayout

        property int leftColumnWidth: 0
        width: units.gridUnit * 11

        Repeater {
            id: detailsRepeater
            model: Logic.batteryDetails(batteryItem.battery, batterymonitor.remainingTime)

            PlasmaComponents.Label {
                id: detailsLabel
                width: modelData.value ? parent.width - detailsLayout.leftColumnWidth - units.smallSpacing : detailsLayout.leftColumnWidth + units.smallSpacing
                elide: Text.ElideRight
                wrapMode: Text.NoWrap
                onPaintedWidthChanged: { // horrible HACK to get a column layout
                    if (paintedWidth > detailsLayout.leftColumnWidth) {
                        detailsLayout.leftColumnWidth = paintedWidth
                    }
                }
                height: paintedHeight
                text: modelData.value ? modelData.value : modelData.label

                states: State {
                    when: !!detailsLayout.parent.inListView // HACK
                    PropertyChanges {
                        target: detailsLabel
                        horizontalAlignment: modelData.value ? Text.AlignRight : Text.AlignLeft
                        font.pointSize: theme.smallestFont.pointSize
                        width: parent.width / 2
                    }
                }
            }
        }
    }

    Column {
        width: parent.width
        spacing: units.smallSpacing

        PlasmaCore.ToolTipArea {
            width: parent.width
            height: Math.max(batteryIcon.height, batteryNameLabel.height + batteryPercentBar.height)
            active: !detailsLoader.active
            z: 2

            mainItem: Row {
                id: batteryItemToolTip

                property int _s: units.largeSpacing / 2

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
                    width: units.iconSizes.desktop // looks weird and small but that's what DefaultTooltip uses
                    height: width
                    batteryType: batteryIcon.batteryType
                    percent: batteryIcon.percent
                    hasBattery: batteryIcon.hasBattery
                    pluggedIn: batteryIcon.pluggedIn
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

            BatteryIcon {
                id: batteryIcon
                width: units.iconSizes.medium
                height: width
                anchors {
                    verticalCenter: parent.verticalCenter
                    left: parent.left
                    leftMargin: Math.round(units.gridUnit / 2)
                }
                batteryType: model["Type"]
                percent: model["Percent"]
                hasBattery: batteryItem.isPresent
                pluggedIn: model["State"] == "Charging" && model["Is Power Supply"]
            }

            PlasmaComponents.Label {
                id: batteryNameLabel
                anchors {
                    verticalCenter: isPresent ? undefined : batteryIcon.verticalCenter
                    bottom: isPresent ? batteryIcon.verticalCenter : undefined
                    left: batteryIcon.right
                    leftMargin: units.gridUnit
                }
                height: implicitHeight
                elide: Text.ElideRight
                text: model["Pretty Name"]
            }

            PlasmaComponents.Label {
                id: batteryStatusLabel
                anchors {
                    top: batteryNameLabel.top
                    right: batteryPercentBar.right
                }
                text: Logic.stringForBatteryState(model)
                height: implicitHeight
                visible: model["Is Power Supply"]
                opacity: 0.5
            }

            PlasmaComponents.ProgressBar {
                id: batteryPercentBar
                anchors {
                    top: batteryIcon.verticalCenter
                    left: batteryNameLabel.left
                    right: batteryPercent.left
                    rightMargin: Math.round(units.gridUnit / 2)
                }
                minimumValue: 0
                maximumValue: 100
                visible: isPresent
                value: parseInt(model["Percent"])
            }

            PlasmaComponents.Label {
                id: batteryPercent
                anchors {
                    verticalCenter: batteryPercentBar.verticalCenter
                    right: parent.right
                    rightMargin: Math.round(units.gridUnit / 2)
                }
                width: percentageMeasurementLabel.width
                height: paintedHeight
                horizontalAlignment: Text.AlignRight
                visible: isPresent
                text: i18nc("Placeholder is battery percentage", "%1%", model["Percent"])
            }
        }

        Loader {
            id: detailsLoader
            property bool inListView: true
            anchors {
                left: parent.left
                leftMargin: Math.round(units.gridUnit / 2) + batteryIcon.width + units.gridUnit
                right: parent.right
                rightMargin: Math.round(units.gridUnit / 2) + batteryPercent.width + Math.round(units.gridUnit / 2)
            }
            visible: !!item
            opacity: 0.5
            sourceComponent: batteryDetails
            active: batterymonitor.batteries.count < 2
        }
    }

}
