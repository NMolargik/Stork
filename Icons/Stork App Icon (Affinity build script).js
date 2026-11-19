// Stork 4.0 app icon (the Jar) as a layered Affinity document. Geometry and colours match the flat layers in
// Marketing/Stork 4.0/icon-final/layers (1-back-jar, 2-middle-marbles, 3-front-lid) on a 1024 x 1024 canvas. Creates a new document each run.
const { Document, NewDocumentOptions, FileExportOptions, FileExportArea } = require('/document.js');
const Nodes = require('/nodes.js');
const { ShapeRectangle, ShapeEllipse, ShapeCornerType } = require('/shapes.js');
const { Colour, Gradient } = require('/colours.js');
const { Rectangle, Transform, CurveBuilder, PolyCurve } = require('/geometry.js');
const { FillDescriptor, GradientFill, GradientFillType, BlendMode } = require('/fills.js');
const { DocumentCommand, AddChildNodesCommandBuilder } = require('/commands.js');
const { InsertionMode } = require('affinity:commands');
const { Selection } = require('/selections.js');
const { UnitType } = require('/units.js');

const DESK = '/Users/nickmolargik/Desktop/Stork Icon (Claude)';
const log = (...a) => console.log(a.join(' '));
const o = NewDocumentOptions.createDefault();
o.units = UnitType.Pixel; o.width = 1024; o.height = 1024; o.dpi = 72; o.createArtboard = true; o.isTransparentBackground = true;
const doc = Document.createFromOptions(o);
const spread = doc.spreads.first;
const kids = n => { const out = []; for (const c of n.children) out.push(c); return out; };
const sel = n => Selection.create(doc, n);
const run = cmd => doc.executeCommand(cmd);
const rgba = hex => { const h = hex.replace('#', ''); return Colour.createRGBA8({ r: parseInt(h.slice(0, 2), 16), g: parseInt(h.slice(2, 4), 16), b: parseInt(h.slice(4, 6), 16), alpha: 255 }); };
const solid = hex => FillDescriptor.createSolid(rgba(hex));
const name = (n, s) => run(DocumentCommand.createSetDescription(sel(n), s));
function addTo(target, def, label) {
  const b = AddChildNodesCommandBuilder.create(); b.addNode(def); b.setInsertionTarget(target); b.setInsertionMode(InsertionMode.Inside_AtBack);
  const cmd = b.createCommand(false); run(cmd);
  const n = cmd.newNodes[0]; if (label) name(n, label); return n;
}
function settle(n, x, y) { const b = n.spreadBaseBox; if (Math.abs(b.x - x) > 0.01 || Math.abs(b.y - y) > 0.01) run(DocumentCommand.createTransform(sel(n), Transform.createTranslate(x - b.x, y - b.y))); return n; }
function vGradient(x, y, w, h, top, bottom) {
  const g = Gradient.create([{ position: 0, colour: rgba(top) }, { position: 1, colour: rgba(bottom) }]);
  const xf = Transform.createTranslate(x + w / 2, y).multiply(Transform.createRotate(Math.PI / 2)).multiply(Transform.createScale(h, h));
  return FillDescriptor.create(GradientFill.create(g, GradientFillType.Linear), true, xf, BlendMode.Normal, false);
}
function rect(target, label, x, y, w, h, fill, radius) {
  const shape = ShapeRectangle.create();
  if (radius) { shape.setAbsoluteSizes(true, w, h); shape.useSingleRadius = true; for (const c of [shape.topLeft, shape.topRight, shape.bottomLeft, shape.bottomRight]) { c.cornerType = ShapeCornerType.Round; c.setRadius(radius, w, h); } }
  return settle(addTo(target, Nodes.ShapeNodeDefinition.create(shape, new Rectangle(x, y, w, h), typeof fill === 'string' ? solid(fill) : fill, null, null, null), label), x, y);
}
function ellipse(target, label, cx, cy, r, hex) {
  return settle(addTo(target, Nodes.ShapeNodeDefinition.create(ShapeEllipse.create(), new Rectangle(cx - r, cy - r, 2 * r, 2 * r), solid(hex), null, null, null), label), cx - r, cy - r);
}
function group(target, label) { return addTo(target, Nodes.ContainerNodeDefinition.create(label), label); }
const LIGHT = ['#FFFFFF', '#E9E8EF'], DARK = ['#34303D', '#121015'];
function artwork(ab, ox, oy) {
  const jar = group(ab, 'Back: jar');
  rect(jar, 'Jar', ox + 222, oy + 250, 580, 670, '#DCD5F4', 170);
  const marbles = group(ab, 'Middle: marbles');
  [['Marble 1 blue', 346, 790, '#6CB8F4'], ['Marble 2 pink', 512, 800, '#EE8AF5'], ['Marble 3 purple', 678, 790, '#7559FF'],
   ['Marble 4 orange', 430, 638, '#F07A3C'], ['Marble 5 blue', 594, 638, '#6CB8F4'], ['Marble 6 pink', 512, 488, '#EE8AF5']]
    .forEach(m => ellipse(marbles, m[0], ox + m[1], oy + m[2], 92, m[3]));
  const lid = group(ab, 'Front: lid');
  rect(lid, 'Lid', ox + 362, oy + 160, 300, 110, '#F07A3C', 44);
}
const boards = [
  { title: 'App Icon, Default', x: 0, bg: LIGHT },
  { title: 'App Icon, Dark', x: 1184, bg: DARK },
];
const first = kids(spread)[0];
for (const [i, b] of boards.entries()) {
  let ab = first;
  if (i > 0) {
    run(DocumentCommand.createAddArtboard(Nodes.ShapeNodeDefinition.create(ShapeRectangle.create(), new Rectangle(b.x, 0, 1024, 1024), null, null, null, null)));
    ab = kids(spread).find(k => { const bb = k.spreadBaseBox; return Math.abs(bb.x - b.x) < 0.5 && Math.abs(bb.width - 1024) < 0.5; });
  }
  name(ab, b.title);
  rect(ab, 'Background', b.x, 0, 1024, 1024, vGradient(b.x, 0, 1024, 1024, b.bg[0], b.bg[1]));
  artwork(ab, b.x, 0);
}
doc.saveAs(DESK + '/Stork App Icon.af');
const abs = []; for (const a of spread.artboards) abs.push(a);
let n = 0;
for (const a of abs) { try { doc.export(DESK + '/export/' + (a.description || 'artboard').replace(/[^A-Za-z0-9]+/g, '-') + '.png', FileExportOptions.createWithPresetName('PNG'), FileExportArea.createForArtboard(a)); n++; } catch (e) { log('export failed', String(e).slice(0, 120)); } }
log('built', abs.length, 'artboards, exported', n, 'uuid', doc.sessionUuid);
