# Tempo macOS App Product Brief

## Product Summary

Tempo is a piano practice application that helps musicians learn and improve real sheet music with immediate feedback while they play.
Similar to flowkey.

The macOS app is the main practice hub. A user connects a digital piano or MIDI keyboard to their Mac, opens a piece of music, and begins practicing. Tempo follows the performance in real time, shows the user's position in the score, highlights what should be played next, and clearly identifies correct notes and mistakes.

The goal is to make practicing with Tempo feel more useful and enjoyable than practicing with paper sheet music, while keeping the interface calm, focused, and easy to understand.

## Product Goals

- Let users start a practice session within minutes.
- Work with the sheet music users already own.
- Provide feedback quickly enough to feel connected to the instrument.
- Make difficult sections easy to isolate and repeat.
- Help users understand both individual mistakes and long-term progress.
- Provide a polished experience suitable for beginners and experienced pianists.
- Allow tablets and phones to join a practice session with very little setup.

## Core Experience

The central experience is a distraction-free practice workspace built around the score.

The user should be able to:

1. Open Tempo and choose or import a piece.
2. Connect a digital piano or MIDI keyboard.
3. Select a practice mode.
4. Play while the app follows the score.
5. See immediate, understandable feedback.
6. Repeat a section or continue through the piece.
7. Review a short summary when the session ends.

The app should support long practice sessions without visual fatigue. Controls should remain available when needed, but the music should always be the main focus.

## Main Areas of the App

### Home

The Home screen provides a quick way to continue practicing. It should show recently played pieces, current progress, and a clear action to import or open music.

### Music Library

The library stores the user's sheet music and makes it easy to find a piece. Users can import MusicXML, MuseScore, and MIDI files and organize their music by title, composer, folder, tags, or difficulty.

Each piece can display useful information such as recent practice activity, completion progress, best accuracy, and difficult sections.

### Practice Workspace

The Practice Workspace is the primary screen of the application. It includes:

- A large, highly readable sheet music view.
- A visible current position in the score.
- Highlights for upcoming notes or chords.
- Immediate feedback for correct, incorrect, missed, and extra notes.
- Playback and tempo controls.
- A metronome.
- Measure or section selection.
- Hand selection for right hand, left hand, or both hands.
- An optional visual piano keyboard.
- A compact view of accuracy, progress, and recent mistakes.

Users should be able to zoom, change the score layout, move to a measure, and select a passage directly from the sheet music.

### Session Review

At the end of a practice attempt, the app presents a concise summary. It should answer:

- How long did the user practice?
- How accurate was the performance?
- Which measures caused the most difficulty?
- What types of mistakes occurred?
- Did the attempt improve over previous attempts?
- What should the user practice next?

The review should be useful without feeling judgmental or overly complicated.

### Progress

The Progress area helps users understand improvement over time. It can include practice time, accuracy history, completed pieces, repeated problem areas, and recent achievements.

## Practice Modes

### Guided Practice

Guided Practice helps the user learn the notes at their own pace. The app highlights the next note or chord and waits until the correct input is played before moving forward.

This mode should support slower tempos, separate-hand practice, and clear visual guidance.

### Section Practice

Section Practice lets the user select measures and repeat them continuously. It is intended for difficult passages and should make it fast to change the loop, tempo, and active hands without leaving the score.

### Performance Mode

Performance Mode allows the user to play without interruption. Feedback during the performance should be subtle so it does not distract from playing. A more detailed evaluation is shown afterward.

## Real-Time Feedback

Feedback must be immediate, clear, and visually restrained. The app should recognize:

- Correct notes and chords.
- Wrong notes.
- Missing notes within a chord or passage.
- Extra notes.
- Notes played too early or too late.
- Rhythm and tempo inconsistencies.

The user should always understand what happened without the interface becoming visually noisy. Color should support the explanation, but important feedback should not depend on color alone.

## Score Following and Visualization

Tempo should automatically follow the user's position in the music and keep the relevant part of the score visible.

The score may show:

- The current measure or beat.
- Notes currently expected from the left and right hands.
- Upcoming notes.
- Completed passages.
- Fingering information when included in the score.
- A selected loop or practice section.
- Mistakes from the current attempt.

Movement through the score should feel stable. The display should avoid unnecessary jumping, flashing, or scrolling while the user is reading.

## Piano Connection

Connecting a piano should be simple and clearly explained. The app should:

- Detect available MIDI instruments.
- Make the active instrument obvious.
- Remember a previously used instrument when appropriate.
- Show whether note input and pedals are being received.
- Provide a quick input test.
- Offer an on-screen keyboard for demonstrations or use without a connected piano.

Connection problems should be explained in plain language with direct recovery actions.

## Multi-Device Sessions

The Mac is the main session host, while another device can act as a companion display or controller.

A user should be able to open a pairing view on the Mac and join from a tablet or phone by scanning a QR code or entering a short code. Pairing should not require IP addresses, router settings, or technical networking knowledge.

Possible companion roles include:

- A tablet displaying the score.
- A phone showing session statistics or controls.
- A teacher view following the student's position and mistakes.
- A remote control for page movement, tempo, loops, or the metronome.

All connected devices should remain synchronized closely enough to feel like parts of one application. If a device disconnects, the Mac practice session must continue normally and reconnection should be straightforward.

## Progress and Learning Insights

Tempo should turn practice history into useful guidance. Over time, it should identify:

- Measures that repeatedly cause mistakes.
- Common wrong notes or rhythm problems.
- Sections that have improved.
- Pieces that have not been practiced recently.
- Accuracy and tempo trends.
- Suggested sections for the next practice session.

These insights should support the musician's decisions rather than replace them.

## Recording and Comparison

Users should be able to save practice attempts for later review. A saved attempt may include the played notes, timing, mistakes, score position, and optional audio.

Users can replay an attempt, inspect mistakes on the score, and compare multiple performances of the same section or piece.

## Design and Experience Principles

- **Music first:** The score and the act of playing take priority over dashboards and controls.
- **Immediate response:** Playing a note should produce feedback without a noticeable delay.
- **Low friction:** Common actions should take as few steps as possible.
- **Calm interface:** Avoid clutter, excessive animation, and unnecessary notifications.
- **Readable for long sessions:** Support light and dark appearances, comfortable contrast, and flexible score sizing.
- **Progressive complexity:** Beginners should understand the app immediately, while advanced tools remain available when needed.
- **Clear state:** The user should always know which piece, instrument, practice mode, section, and connected devices are active.
- **Forgiving behavior:** Accidental clicks or temporary connection failures should not destroy practice progress.

## First-Version Priorities

The first complete macOS version should focus on the essential practice loop:

1. Import and manage MusicXML, MuseScore, and MIDI files.
2. Display readable sheet music.
3. Connect and test a MIDI piano.
4. Follow played notes and chords through the score.
5. Provide live correct and incorrect note feedback.
6. Support Guided, Section, and Performance modes.
7. Include tempo, metronome, hand, loop, zoom, and playback controls.
8. Save basic practice history and session summaries.
9. Pair a tablet or phone through a QR code or short code.
10. Provide polished onboarding, empty states, and error recovery.

Advanced analysis, generated sight-reading exercises, teacher tools, audio recording, and detailed performance comparison can follow after the core practice experience is reliable and polished.

## Definition of Success

Tempo succeeds when a user can connect a piano, open a score, and begin a useful practice session without needing instructions. Feedback feels immediate, the score remains comfortable to read, and the application helps the user stay focused on the music.

The product should feel like a dedicated musical tool rather than a generic desktop application: dependable, quiet, responsive, and pleasant enough to use every day.
