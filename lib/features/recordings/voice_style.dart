import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Filter groups on the Choose a voice screen.
enum VoiceCategory {
  gender('Gender'),
  characters('Characters'),
  scifi('Sci-fi'),
  effects('Effects');

  const VoiceCategory(this.label);

  final String label;
}

/// All voice templates. The order here is the order of the grid.
///
/// Names are persisted in the library (`Recording.voice`), so never rename
/// an existing value — add new ones instead.
enum VoiceStyle {
  // Gender
  female('Female', 'Turns a male voice female', LucideIcons.venus,
      VoiceCategory.gender),
  male('Male', 'Turns a female voice male', LucideIcons.mars,
      VoiceCategory.gender),
  deep('Deep', 'Lower, richer voice', LucideIcons.chevronsDown,
      VoiceCategory.gender),
  high('High', 'Lighter, higher voice', LucideIcons.chevronsUp,
      VoiceCategory.gender),

  // Characters
  baby('Baby', 'Tiny, cute toddler voice', LucideIcons.baby,
      VoiceCategory.characters),
  chipmunk('Chipmunk', 'Squeaky, fast-talking critter', LucideIcons.squirrel,
      VoiceCategory.characters),
  cartoon('Cartoon', 'Playful exaggerated voice', LucideIcons.smile,
      VoiceCategory.characters),
  elf('Elf', 'Light, sparkly fairy voice', LucideIcons.sparkles,
      VoiceCategory.characters),
  oldMan('Old Man', 'Shaky, wobbly elder voice', LucideIcons.glasses,
      VoiceCategory.characters),
  giant('Giant', 'Huge, booming voice', LucideIcons.mountain,
      VoiceCategory.characters),
  monster('Monster', 'Deep dramatic character', LucideIcons.skull,
      VoiceCategory.characters),
  ghost('Ghost', 'Eerie, breathy whisper', LucideIcons.ghost,
      VoiceCategory.characters),

  // Sci-fi
  robot('Robot', 'Synthetic robotic voice', LucideIcons.bot,
      VoiceCategory.scifi),
  aiAssistant('AI Assistant', 'Flat, futuristic synth voice', LucideIcons.cpu,
      VoiceCategory.scifi),
  alien('Alien', 'Strange futuristic voice', LucideIcons.rocket,
      VoiceCategory.scifi),

  // Effects
  whisper('Whisper', 'Soft, breathy whisper', LucideIcons.wind,
      VoiceCategory.effects),
  megaphone('Megaphone', 'Loud loudspeaker sound', LucideIcons.megaphone,
      VoiceCategory.effects),
  radio('Radio', 'Broadcast-style voice', LucideIcons.radio,
      VoiceCategory.effects),
  echo('Echo', 'Spacious echo effect', LucideIcons.target,
      VoiceCategory.effects),
  underwater('Underwater', 'Muffled, bubbly voice', LucideIcons.waves,
      VoiceCategory.effects);

  const VoiceStyle(this.label, this.description, this.icon, this.category);

  final String label;
  final String description;
  final IconData icon;
  final VoiceCategory category;

  static VoiceStyle? byName(String? name) {
    for (final v in values) {
      if (v.name == name) return v;
    }
    return null;
  }
}
