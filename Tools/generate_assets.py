from PIL import Image, ImageFilter
import cv2, numpy as np
from pathlib import Path
src=Image.open('References/image.png').convert('RGB')
out=Path('Elektronika IM-02 — Nu, Pogodi/Resources')
out.mkdir(parents=True,exist_ok=True)
src.save(out/'console.png',optimize=True)
a=np.array(src)
# The inset LCD glass is independent of the photographed housing.
lcd=a[205:667,470:1307].copy()
# Rebuild blank LCD glass from measured tone. Preserve printed scenery as a hard mask.
rng=np.random.default_rng(1984)
base=np.empty_like(lcd)
noise=rng.normal(0,1.0,lcd.shape[:2])
for channel,tone in enumerate((139,140,125)):
 base[:,:,channel]=np.clip(tone+noise,0,255).astype('uint8')
static=np.zeros(lcd.shape[:2],np.uint8)
for x1,y1,x2,y2 in [(15,18,175,225),(735,18,822,225),(650,130,822,225),(15,240,216,378),(620,240,822,378),(15,370,160,450),(680,370,822,450),(140,425,822,450)]:
 static[y1:y2,x1:x2]=255
# Eggs and wolf are switched independently, even where they overlap printed trays.
for x1,y1,x2,y2 in [(135,138,197,237),(130,237,215,333),(635,138,710,237),(615,237,725,333),(300,184,545,450)]:
 static[y1:y2,x1:x2]=0
ink=cv2.cvtColor(lcd,cv2.COLOR_RGB2GRAY)<82
base[np.logical_and(ink,static>0)]=[27,31,27]
lcd=base
Image.fromarray(lcd).save(out/'lcd_background.png',optimize=True)
# Wolf and basket: monochrome extracted from supplied artwork, retaining true silhouette.
box=(770,395,1010,645)
cut=np.array(src.crop(box).convert('L'))
alpha=np.clip((105-cut.astype(np.int16))*12,0,255).astype('uint8')
# soften only one-pixel threshold artifacts; no game-time movement interpolation.
alpha=cv2.medianBlur(alpha,3)
rgba=np.empty((cut.shape[0],cut.shape[1],4),dtype='uint8')
rgba[:,:,:3]=[26,30,25];rgba[:,:,3]=alpha
Image.fromarray(rgba,'RGBA').save(out/'wolf_right.png',optimize=True)
# Actual photographed egg segment; isolated from top-left track.
cut=np.array(src.crop((612,344,651,407)).convert('L'))
alpha=np.clip((105-cut.astype(np.int16))*12,0,255).astype('uint8')
yy,xx=np.indices(alpha.shape)
ellipse=((xx-21)/17)**2+((yy-30)/25)**2<=1
alpha[~ellipse]=0
rgba=np.empty((cut.shape[0],cut.shape[1],4),dtype='uint8');rgba[:,:,:3]=[25,29,25];rgba[:,:,3]=alpha
Image.fromarray(rgba,'RGBA').save(out/'egg.png',optimize=True)

# Keep the Xcode catalog in sync with the editable master resources.
import json, shutil
for name in ('console', 'lcd_background', 'wolf_right', 'egg'):
    image_set = Path('Elektronika IM-02 — Nu, Pogodi/Assets.xcassets') / f'{name}.imageset'
    image_set.mkdir(parents=True, exist_ok=True)
    shutil.copy(out / f'{name}.png', image_set / f'{name}.png')
    (image_set / 'Contents.json').write_text(json.dumps({
        'images': [{'filename': f'{name}.png', 'idiom': 'universal'}],
        'info': {'author': 'xcode', 'version': 1}
    }, indent=2))
