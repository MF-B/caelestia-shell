pragma Singleton

import ".."
import QtQuick
import Quickshell
import Caelestia.Config
import Caelestia.Services
import qs.services
import qs.utils

Searcher {
    id: root

    function transformSearch(search: string): string {
        const prefix = GlobalConfig.launcher.actionPrefix;
        search = search.trim().replace(/\s+/g, " ");
        if (search.startsWith(prefix))
            return search.slice(prefix.length).trim();
        if (prefix === ">" && search.startsWith("＞"))
            return search.slice(1).trim();
        return search.trim();
    }

    function fuzzyScore(needle: string, haystack: string): int {
        let last = -1;
        let score = 0;

        for (const ch of needle) {
            const idx = haystack.indexOf(ch, last + 1);
            if (idx < 0)
                return 0;

            score += idx === last + 1 ? 3 : 1;
            last = idx;
        }

        return score;
    }

    function query(search: string): list<var> {
        const q = transformSearch(search).toLowerCase();
        const candidates = [...variants.instances];

        if (!q)
            return candidates;

        return candidates.map(action => {
            const name = action.name.toLowerCase();
            const desc = action.desc.toLowerCase();
            const command = action.command.join(" ").toLowerCase();

            let score = 0;
            if (name === q)
                score += 1000;
            if (name.startsWith(q))
                score += 500;
            if (name.includes(q))
                score += 300;
            if (desc.includes(q))
                score += 120;
            if (command.includes(q))
                score += 80;
            score += root.fuzzyScore(q, name) * 10;

            return {
                action,
                score
            };
        }).filter(r => r.score > 0).sort((a, b) => {
            if (a.score === b.score)
                return a.action.name.length - b.action.name.length;
            return b.score - a.score;
        }).map(r => r.action);
    }

    list: variants.instances
    useFuzzy: GlobalConfig.launcher.useFuzzy.actions

    Variants {
        id: variants

        model: GlobalConfig.launcher.actions.filter(a => (a.enabled ?? true) && (GlobalConfig.launcher.enableDangerousActions || !(a.dangerous ?? false)))

        Action {}
    }

    component Action: QtObject {
        required property var modelData
        readonly property string name: modelData.name ?? qsTr("Unnamed")
        readonly property string desc: modelData.description ?? qsTr("No description")
        readonly property string icon: modelData.icon ?? "help_outline"
        readonly property list<string> command: modelData.command ?? []
        readonly property bool enabled: modelData.enabled ?? true
        readonly property bool dangerous: modelData.dangerous ?? false

        function onClicked(list: AppList): void {
            if (command.length === 0)
                return;

            if (command[0] === "autocomplete" && command.length > 1) {
                list.search.text = `${GlobalConfig.launcher.actionPrefix}${command[1]} `;
            } else if (command[0] === "setMode" && command.length > 1) {
                list.screenState.launcher = false;
                Colours.setMode(command[1]);
            } else {
                list.screenState.launcher = false;
                if (!SessionManager.exec(command))
                    Quickshell.execDetached(command);
            }
        }
    }
}
