# MindSpark Quest

MindSpark Quest is an offline-first Flutter puzzle game for children who are
practising attention, impulse control, planning, and working memory. It is a
supportive game, not a diagnostic or medical device.

## Adaptive agent

Each mission records correct, wrong, distractor, and hint events with timing.
The local explainable agent then:

1. calculates reaction time, useful reaction time, commissions, omissions,
   hint use, completion time, and recent variability;
2. updates recency-weighted gameplay indicators for attention, impulse control,
   planning, working memory, engagement, learning trend, and success streak;
3. identifies a strongest skill and growth focus, then applies child-safe rule
   priority (recovery, focus, impulse control, guided, gradual challenge, or
   balanced play) with an evidence-based confidence score;
4. generates the next mission, difficulty, timer, object count, distractors,
   hint level, optional look-before-tapping pause, and a multilingual reason;
5. stores the result and profile locally in Hive.

The agent modules live in `lib/agent/`, mission configuration is produced in
`lib/missions/`, and the UI consumes the stable contract in
`lib/ai_interface/ai_agent_service.dart`.

## Run and verify

```sh
flutter pub get
flutter run
flutter analyze
flutter test
```

The game includes Light Up the Room, Power the Robot, Open the Door, Enchanted
Garden, and Memory Vault. It also includes adaptive result explanations, a
recommended quest on the map, multilingual English/French/Arabic UI,
accessibility settings, caregiver consent/PIN, and a non-diagnostic caregiver
dashboard with model confidence and skill insights.
