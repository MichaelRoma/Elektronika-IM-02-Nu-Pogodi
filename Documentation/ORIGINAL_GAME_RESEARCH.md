# Original IM-02 research

## Primary reference

- [Scanned IM-02 operating manual](https://www.amuseum.bg/data/files/cms/0/%D0%A0%D1%8A%D0%BA%D0%BE%D0%B2%D0%BE%D0%B4%D1%81%D1%82%D0%B2%D0%BE%20%D0%9D%D1%83%20%D0%9F%D0%BE%D0%B3%D0%BE%D0%B4%D0%B8.pdf), pages 4–12. The measurements and the rules below come from this manual. Its page 18 diagram identifies the physical controls.
- `References/image.png`, a 1774×887 supplied front view. Used for the casing, button and print locations, LCD scenery, wolf, and egg cutouts. It is an image reference, not proof of the exact 1984 hardware geometry.
- [MAME's nupogodi machine listing](https://data.spludlow.co.uk/mame/machine/nupogodi) confirms that a dumped IM-02 program exists. This project does not bundle that ROM or emulate its instructions.

## Verified from the manual

- Nominal case dimensions: **112 × 67 × 14 mm** (page 4). Mass: 0.08 kg. Two 1.5 V cells.
- Four large buttons select four wolf positions. The two left buttons also select ДП/ПП (AM/PM) when setting a time; the upper and lower right buttons set hours and minutes (pages 5–6, figure 2).
- Three small red buttons select Game A, Game B, and clock. The two recessed controls enter alarm time and current time setting (pages 5–6). Pressing the clock button resumes time display and stops an alarm signal (pages 9–10).
- An egg caught in the basket adds one point. A fallen egg adds one miss; if the hare is visible, the penalty is half a miss. Three full misses end a game (pages 6, 10–11).
- Misses clear at scores 200 and 500 with a signal (page 11). Score display reaches 999 (page 6).
- Game A allows eggs from three trays at once; Game B allows all four (page 12).
- As score increases, play becomes harder (page 11). The manual gives no oscillator table, spawn sequence, or exact interval values.
- The clock has 12-hour time and ДП/ПП indicators. The alarm signal lasts one minute (pages 6–7).

## Cross-checks and implementation decisions

- A transcribed copy of the manual at [rootger's IM-02 article](https://rootger.blogspot.com/2010/11/02.html) agrees on scoring, half misses, game modes, and clock behavior. [Love80s](https://love80s.ru/toyshop/electronic_toys/elektronika_im/elektronika_im_02_nu_pogodi/history/) describes the changing excluded tray in Game A and a score slowdown at hundred-point boundaries; the exact tray table is a secondary-source claim, not in the scanned manual.
- The supplied art is **2.00:1**, while the manual face measurement is **1.67:1**. The app displays the supplied art undistorted. Consequently the case proportions cannot be claimed to match a measured original.
- Five egg steps per lane, 0.68 s initial step, 0.22 s floor, a four-tick initial spawn interval, hare period, and the rate curve are **calibration approximations**, isolated in `GameRules`/`GameEngine`. They have not been matched against frame-by-frame hardware recordings or the dumped ROM.
- The score rolls 999→000, based on the [contemporary hardware account](https://rootger.blogspot.com/2010/11/02.html), not explicit wording in the manual.
- The currently active tray exclusion in Game A follows the detailed [Love80s account](https://love80s.ru/toyshop/electronic_toys/elektronika_im/elektronika_im_02_nu_pogodi/history/). This needs hardware verification.
- Bell, hare, and chick are redrawn approximations; the static hens and case print come from the supplied image. Four wolf states share a masked wolf silhouette with discrete placement and horizontal reflection. These are not traced from all four original LCD electrodes.
- Audio uses synthesized square-like beeps. The manual documents a milestone signal and a one-minute alarm but does not provide frequencies or catch/miss waveforms; the chosen tones are approximations.
- A secondary [description of the clock screen](https://gameandwatch.ru/nu-pogodi/) reports silent automatic egg catching in clock mode. The app reproduces it with a simple five-step cycle; its exact sequence is unverified.
- The phone clock replaces battery-backed manual time keeping. Alarm time and clock offset are stored locally. iOS suspension can delay alarm playback; this app does not register a local notification.

## Further verification needed for hardware accuracy

Capture each LCD electrode in all four wolf positions, all egg positions, the hare and all miss states; measure a real face photograph and score-dependent event times; compare against the MAME program behavior and recorded piezo output. These would resolve the identified gaps without changing the domain/presentation separation.
