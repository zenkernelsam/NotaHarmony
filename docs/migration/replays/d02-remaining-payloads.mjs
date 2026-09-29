// Phase 1051 — recording/comment/checkbox/peer/transient/asset payloads
import { readFileSync } from 'fs';
import { strict as assert } from 'assert';
const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const R = f => readFileSync(D + f + '.java', 'utf8');
const yn2 = R('yn2'), ke8 = R('ke8'), tl2 = R('tl2'), ud8 = R('ud8'), mqf = R('mqf'), tdf = R('tdf'), yda = R('yda'), ra0 = R('ra0');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

t('yn2 CreateRecording fields', yn2.includes('CreateRecording(recording=') && yn2.includes('startTime=') && yn2.includes('endTime=') && yn2.includes('name=') && yn2.includes('segmentation=') && yn2.includes('zIndex='));
t('yn2: akb recording asset', yn2.includes('akb'));
t('ke8 ModifyRecording subset', ke8.includes('ModifyRecording(recording=') && ke8.includes('segmentation=') && ke8.includes('zIndex='));
t('tl2 CreateComment {anchor,text}', tl2.includes('CreateComment(anchor=') && tl2.includes('text='));
t('ud8 ModifyComment {comment,anchor,text,resolved}', ud8.includes('ModifyComment(comment=') && ud8.includes('anchor=') && ud8.includes('resolved='));
t('mqf UpdateCheckbox {textField,location,isChecked}', mqf.includes('UpdateCheckbox(textField=') && mqf.includes('location=') && mqf.includes('isChecked=') && mqf.includes('qo5') && mqf.includes('cxc'));
t('yda PeerInteraction fields', yda.includes('PeerInteraction(cursorPosition=') && yda.includes('selectedEntities=') && yda.includes('tool=') && yda.includes('textSelection=') && yda.includes('recordingInProgress='));
t('yda: u76 tool + qqe selection', yda.includes('u76') && yda.includes('qqe'));
t('tdf TransientInteractionEnded{interactionId}', tdf.includes('TransientInteractionEnded(interactionId='));
t('ra0 AssetCloudPersisted{assetHash}', ra0.includes('AssetCloudPersisted(assetHash='));
t('all 8 payloads cee+ka4', [yn2,ke8,tl2,ud8,mqf,tdf,yda,ra0].every(s => s.includes('extends cee') && s.includes('implements ka4')));
t('th7 segmentation type referenced', yn2.includes('th7') || ke8.includes('th7'));
console.log('remaining-payloads replay: ' + n + '/12 checks green');
