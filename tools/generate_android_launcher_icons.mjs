import fs from 'node:fs/promises';
import path from 'node:path';
import sharp from 'sharp';

const root = process.cwd();
const input = path.join(root, 'assets', 'icon', 'logo.png');
const outBase = path.join(root, 'android', 'app', 'src', 'main', 'res');

const targets = [
  { dir: 'mipmap-mdpi', size: 48 },
  { dir: 'mipmap-hdpi', size: 72 },
  { dir: 'mipmap-xhdpi', size: 96 },
  { dir: 'mipmap-xxhdpi', size: 144 },
  { dir: 'mipmap-xxxhdpi', size: 192 },
];

async function main() {
  await fs.access(input);

  // Ensure source has alpha and is square-ish. We'll fit it inside a square.
  const image = sharp(input, { failOnError: false });

  for (const t of targets) {
    const outDir = path.join(outBase, t.dir);
    const outFile = path.join(outDir, 'ic_launcher.png');

    await fs.mkdir(outDir, { recursive: true });

    await image
      .clone()
      .resize(t.size, t.size, {
        fit: 'contain',
        background: { r: 0, g: 0, b: 0, alpha: 0 },
      })
      .png({ compressionLevel: 9 })
      .toFile(outFile);

    console.log(`Wrote ${t.dir}/ic_launcher.png (${t.size}x${t.size})`);
  }
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
