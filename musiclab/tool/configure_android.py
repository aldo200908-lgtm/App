#!/usr/bin/env python3
from pathlib import Path
import xml.etree.ElementTree as ET

ns="http://schemas.android.com/apk/res/android"
ET.register_namespace("android",ns)
a=lambda name: "{"+ns+"}"+name
p=Path("android/app/src/main/AndroidManifest.xml")
tree=ET.parse(p)
root=tree.getroot()
for perm in ["android.permission.INTERNET","android.permission.WAKE_LOCK",
             "android.permission.FOREGROUND_SERVICE",
             "android.permission.FOREGROUND_SERVICE_MEDIA_PLAYBACK",
             "android.permission.POST_NOTIFICATIONS"]:
    if not any(x.get(a("name"))==perm for x in root.findall("uses-permission")):
        ET.SubElement(root,"uses-permission",{a("name"):perm})
app=root.find("application")
app.set(a("label"),"MusicLab")
activity=app.find("activity")
activity.set(a("name"),"com.ryanheise.audioservice.AudioServiceActivity")
service=ET.SubElement(app,"service",{
    a("name"):"com.ryanheise.audioservice.AudioService",
    a("foregroundServiceType"):"mediaPlayback",
    a("exported"):"true",
})
i=ET.SubElement(service,"intent-filter")
ET.SubElement(i,"action",{a("name"):"android.media.browse.MediaBrowserService"})
receiver=ET.SubElement(app,"receiver",{
    a("name"):"com.ryanheise.audioservice.MediaButtonReceiver",
    a("exported"):"true",
})
i=ET.SubElement(receiver,"intent-filter")
ET.SubElement(i,"action",{a("name"):"android.intent.action.MEDIA_BUTTON"})
ET.indent(tree,space="    ")
tree.write(p,encoding="utf-8",xml_declaration=True)
print("AndroidManifest configured.")
