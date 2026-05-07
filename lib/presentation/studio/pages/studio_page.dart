import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:museai/domain/entities/generation/generation_entity.dart';
import 'package:museai/domain/entities/song/song_entity.dart';
import 'package:museai/domain/usecases/generation/generation_params.dart';
import 'package:museai/presentation/studio/bloc/studio_cubit.dart';
import 'package:museai/presentation/studio/bloc/studio_state.dart';
import 'package:museai/presentation/studio/widgets/generation_progress_widget.dart';
import 'package:museai/presentation/song_player/pages/song_player_page.dart';
import 'package:museai/service_locator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class StudioPage extends StatefulWidget {
  const StudioPage({super.key});

  @override
  State<StudioPage> createState() => _StudioPageState();
}

class _StudioPageState extends State<StudioPage> {
  final _promptController = TextEditingController();
  String _selectedMood = 'Happy';
  String _selectedGenre = 'Pop';
  int _bpm = 120;

  static const _moods = ['Happy', 'Sad', 'Energetic', 'Calm', 'Romantic', 'Dark'];
  static const _genres = ['Pop', 'Rock', 'Jazz', 'Classical', 'Hip-Hop', 'Electronic', 'Ambient'];

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: sl<StudioCubit>(),
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: const Text('Studio', style: TextStyle(color: Colors.white)),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: BlocConsumer<StudioCubit, StudioState>(
          listener: (context, state) {
            if (state is StudioCompleted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Track ready!')),
              );
            }
            if (state is StudioFailed) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.message)),
              );
            }
          },
          builder: (context, state) {
            if (state is StudioProcessing || state is StudioSubmitting) {
              return GenerationProgressWidget(
                message: state is StudioSubmitting
                    ? 'Sending your prompt to the generation service...'
                    : 'Composing your track with ElevenLabs. This can take up to a couple of minutes.',
              );
            }

            if (state is StudioCompleted) {
              return _CompletedView(generation: state.generation);
            }

            return _FormView(
              promptController: _promptController,
              selectedMood: _selectedMood,
              selectedGenre: _selectedGenre,
              bpm: _bpm,
              moods: _moods,
              genres: _genres,
              onMoodChanged: (v) => setState(() => _selectedMood = v!),
              onGenreChanged: (v) => setState(() => _selectedGenre = v!),
              onBpmChanged: (v) => setState(() => _bpm = v.round()),
              onSubmit: () {
                final uid = Supabase.instance.client.auth.currentUser?.id;
                if (uid == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please sign in before generating a track.'),
                    ),
                  );
                  return;
                }
                if (_promptController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please describe the track you want to generate.'),
                    ),
                  );
                  return;
                }
                context.read<StudioCubit>().submit(
                  GenerationParams(
                    uid: uid,
                    prompt: _promptController.text.trim(),
                    mood: _selectedMood,
                    genre: _selectedGenre,
                    bpm: _bpm,
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _FormView extends StatelessWidget {
  final TextEditingController promptController;
  final String selectedMood;
  final String selectedGenre;
  final int bpm;
  final List<String> moods;
  final List<String> genres;
  final ValueChanged<String?> onMoodChanged;
  final ValueChanged<String?> onGenreChanged;
  final ValueChanged<double> onBpmChanged;
  final VoidCallback onSubmit;

  const _FormView({
    required this.promptController,
    required this.selectedMood,
    required this.selectedGenre,
    required this.bpm,
    required this.moods,
    required this.genres,
    required this.onMoodChanged,
    required this.onGenreChanged,
    required this.onBpmChanged,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Describe your track', style: TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 8),
          TextField(
            controller: promptController,
            maxLines: 3,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'e.g. upbeat summer track with guitar...',
              hintStyle: const TextStyle(color: Colors.white38),
              filled: true,
              fillColor: Colors.white10,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 24),
          _label('Mood'),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: selectedMood,
            dropdownColor: Colors.grey[900],
            style: const TextStyle(color: Colors.white),
            decoration: _dropdownDecoration(),
            items: moods.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
            onChanged: onMoodChanged,
          ),
          const SizedBox(height: 16),
          _label('Genre'),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: selectedGenre,
            dropdownColor: Colors.grey[900],
            style: const TextStyle(color: Colors.white),
            decoration: _dropdownDecoration(),
            items: genres.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
            onChanged: onGenreChanged,
          ),
          const SizedBox(height: 16),
          _label('BPM: $bpm'),
          Slider(
            value: bpm.toDouble(),
            min: 60,
            max: 200,
            divisions: 140,
            activeColor: Colors.deepPurpleAccent,
            onChanged: onBpmChanged,
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurpleAccent,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Generate', style: TextStyle(fontSize: 16, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(String text) =>
      Text(text, style: const TextStyle(color: Colors.white70, fontSize: 13));

  InputDecoration _dropdownDecoration() => InputDecoration(
    filled: true,
    fillColor: Colors.white10,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
  );
}

class _CompletedView extends StatefulWidget {
  final GenerationEntity generation;
  const _CompletedView({required this.generation});

  @override
  State<_CompletedView> createState() => _CompletedViewState();
}

class _CompletedViewState extends State<_CompletedView>
    with SingleTickerProviderStateMixin {
  // Animation 6: ScaleTransition — check icon scales in when generation completes.
  late final AnimationController _scaleController;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    );
    _scaleController.forward();
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ScaleTransition(
              scale: _scaleAnimation,
              child: const Icon(Icons.check_circle_outline,
                  color: Colors.greenAccent, size: 80),
            ),
            const SizedBox(height: 24),
            Text(
              widget.generation.title,
              style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text('Your track is ready!', style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SongPlayerPage(
                      song: widget.generation,
                      songsList: const <SongEntity>[],
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text('Play Track', style: TextStyle(color: Colors.white)),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => context.read<StudioCubit>().retry(),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurpleAccent),
              child: const Text('Create Another', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
