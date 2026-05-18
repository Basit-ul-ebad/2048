import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';
import '../../../services/storage/storage_service.dart';
import '../../game/presentation/screens/multiplayer_game_screen.dart';

class PlayerSelectionScreen extends StatefulWidget {
  const PlayerSelectionScreen({super.key});

  @override
  State<PlayerSelectionScreen> createState() => _PlayerSelectionScreenState();
}

class _PlayerSelectionScreenState extends State<PlayerSelectionScreen> {
  List<String> _players = [];
  String? _player1;
  String? _player2;
  int _selectedMinutes = 3;
  final TextEditingController _newPlayerController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadPlayers();
  }

  @override
  void dispose() {
    _newPlayerController.dispose();
    super.dispose();
  }

  void _loadPlayers() {
    setState(() {
      _players = StorageService().getPlayers();
    });
  }

  Future<void> _addPlayer() async {
    final name = _newPlayerController.text.trim();
    if (name.isNotEmpty) {
      if (_players.contains(name)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Player already exists')),
        );
        return;
      }
      await StorageService().addPlayer(name);
      _newPlayerController.clear();
      _loadPlayers();
    }
  }

  void _startGame() {
    if (_player1 == null || _player2 == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select both players')),
      );
      return;
    }
    if (_player1 == _player2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select two different players')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MultiplayerGameScreen(
          player1: _player1!,
          player2: _player2!,
          durationMinutes: _selectedMinutes,
        ),
      ),
    );
  }

  Widget _buildPlayerDropdown(String label, String? selectedUser, ValueChanged<String?> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: selectedUser,
          hint: Text('Select $label'),
          items: _players.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
          onChanged: onChanged,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            filled: true,
            fillColor: Colors.white,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Multiplayer Setup'),
        backgroundColor: AppColors.background,
        elevation: 0,
        foregroundColor: AppColors.textDark,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Add Player Section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.boardBackground.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Add New Player', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _newPlayerController,
                          decoration: InputDecoration(
                            hintText: 'Enter name',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _addPlayer,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.getTileColor(32),
                          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                        ),
                        child: const Text('Add', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Select Players Section
            _buildPlayerDropdown('Player 1', _player1, (v) {
              setState(() => _player1 = v);
            }),
            const SizedBox(height: 16),
            if (_player1 != null && _player2 != null && _player1 != _player2)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    'Head to Head Wins: \n$_player1: ${StorageService().getMatchRecord(_player1!, _player2!)[_player1!]} - $_player2: ${StorageService().getMatchRecord(_player1!, _player2!)[_player2!]}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textDark),
                  ),
                ),
              ),
            const SizedBox(height: 16),
            _buildPlayerDropdown('Player 2', _player2, (v) {
              setState(() => _player2 = v);
            }),
            const SizedBox(height: 32),

            // Time Selection
            const Text('Time Limit', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 1, label: Text('1 Min')),
                ButtonSegment(value: 3, label: Text('3 Min')),
                ButtonSegment(value: 5, label: Text('5 Min')),
              ],
              selected: {_selectedMinutes},
              onSelectionChanged: (set) {
                setState(() => _selectedMinutes = set.first);
              },
            ),
            const SizedBox(height: 48),

            ElevatedButton(
              onPressed: _startGame,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.getTileColor(2048),
                padding: const EdgeInsets.symmetric(vertical: 24),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text(
                'Start Match',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
