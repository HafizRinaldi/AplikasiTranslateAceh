import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Import untuk clipboard
import 'package:http/http.dart' as http;

void main() {
  runApp(const AcehTranslatorApp());
}

// Enum untuk menentukan arah terjemahan
enum TranslationDirection { indoToAceh, acehToIndo }

class AcehTranslatorApp extends StatelessWidget {
  const AcehTranslatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Penerjemah Bahasa Aceh',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.grey[100],
        // FIX: Mengganti CardTheme menjadi CardThemeData
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.white,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.indigo,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
      ),
      home: const TranslatorScreen(),
    );
  }
}

class TranslatorScreen extends StatefulWidget {
  const TranslatorScreen({super.key});

  @override
  State<TranslatorScreen> createState() => _TranslatorScreenState();
}

class _TranslatorScreenState extends State<TranslatorScreen> {
  // Controller for the input text field
  final TextEditingController _textController = TextEditingController();

  // State variables
  String _translatedText = '';
  bool _isLoading = false;
  // State untuk melacak arah terjemahan saat ini, defaultnya dari Indonesia ke Aceh
  TranslationDirection _currentDirection = TranslationDirection.indoToAceh;

  /// Function to swap the translation direction
  void _swapLanguages() {
    setState(() {
      // Ganti arah terjemahan
      _currentDirection = _currentDirection == TranslationDirection.indoToAceh
          ? TranslationDirection.acehToIndo
          : TranslationDirection.indoToAceh;

      // Tukar teks antara input dan output
      final String tempText = _textController.text;
      _textController.text = _translatedText;
      _translatedText = tempText;
    });
  }

  /// Function to call the Gemini API and get the translation
  Future<void> _translateText() async {
    // Check if the input is empty
    if (_textController.text.trim().isEmpty) {
      return;
    }

    // Set loading state to true to show the progress indicator
    setState(() {
      _isLoading = true;
      _translatedText = '';
    });

    // Tentukan bahasa sumber dan target berdasarkan arah terjemahan
    final String sourceLang =
        _currentDirection == TranslationDirection.indoToAceh
        ? 'Bahasa Indonesia'
        : 'Bahasa Aceh';
    final String targetLang =
        _currentDirection == TranslationDirection.indoToAceh
        ? 'Bahasa Aceh'
        : 'Bahasa Indonesia';

    // **MODIFIED PROMPT:** Prompt yang lebih spesifik agar AI hanya mengembalikan hasil terjemahan.
    final String prompt =
        'Terjemahkan kalimat berikut dari $sourceLang ke $targetLang. Penting: HANYA kembalikan teks hasil terjemahannya saja, tanpa ada teks atau penjelasan tambahan. Kalimat untuk diterjemahkan: "${_textController.text}"';

    // Gemini API endpoint and payload structure
    const String apiKey =
        "AIzaSyChyawjayJJep2IuYOMerGwtXdg51TxgJ4"; // Dibiarkan kosong sesuai pengaturan environment
    final String apiUrl =
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash-latest:generateContent?key=$apiKey';
    final payload = {
      "contents": [
        {
          "role": "user",
          "parts": [
            {"text": prompt},
          ],
        },
      ],
    };

    try {
      // Make the POST request to the Gemini API
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      // Check if the request was successful
      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);

        // Extract the translated text from the response
        if (result['candidates'] != null &&
            result['candidates'].isNotEmpty &&
            result['candidates'][0]['content'] != null &&
            result['candidates'][0]['content']['parts'] != null &&
            result['candidates'][0]['content']['parts'].isNotEmpty) {
          setState(() {
            _translatedText =
                result['candidates'][0]['content']['parts'][0]['text'].trim();
          });
        } else {
          _translatedText = 'Maaf, respons tidak valid dari AI.';
        }
      } else {
        // Handle API errors
        final errorBody = jsonDecode(response.body);
        setState(() {
          _translatedText =
              'Error: ${response.statusCode}\n${errorBody['error']['message']}';
        });
      }
    } catch (e) {
      // Handle network or other exceptions
      setState(() {
        _translatedText = 'Terjadi kesalahan: $e';
      });
    } finally {
      // Set loading state to false after completion
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Tentukan label dan hint text berdasarkan arah terjemahan saat ini
    final String sourceLanguageLabel =
        _currentDirection == TranslationDirection.indoToAceh
        ? 'Bahasa Indonesia'
        : 'Bahasa Aceh';
    final String targetLanguageLabel =
        _currentDirection == TranslationDirection.indoToAceh
        ? 'Bahasa Aceh'
        : 'Bahasa Indonesia';
    final String hintText = 'Masukkan teks $sourceLanguageLabel di sini...';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Penerjemah Indonesia - Aceh'),
        centerTitle: true,
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Label Bahasa Sumber (Dinamis)
              Text(
                sourceLanguageLabel,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 8),

              // Input Text Field
              TextField(
                controller: _textController,
                maxLines: 5,
                decoration: InputDecoration(hintText: hintText),
              ),
              const SizedBox(height: 16),

              // Tombol untuk menukar bahasa
              IconButton(
                icon: const Icon(
                  Icons.swap_vert,
                  size: 32,
                  color: Colors.indigo,
                ),
                onPressed: _isLoading ? null : _swapLanguages,
              ),
              const SizedBox(height: 16),

              // Label Bahasa Target (Dinamis)
              Text(
                targetLanguageLabel,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 8),

              // Output Card
              Card(
                child: Container(
                  padding: const EdgeInsets.all(16.0),
                  height: 150,
                  width: double.infinity,
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : Stack(
                          children: [
                            SingleChildScrollView(
                              child: Text(
                                _translatedText,
                                style: const TextStyle(
                                  fontSize: 16,
                                  height: 1.5,
                                ),
                              ),
                            ),
                            if (_translatedText.isNotEmpty)
                              Positioned(
                                top: 0,
                                right: 0,
                                child: IconButton(
                                  icon: const Icon(
                                    Icons.copy,
                                    color: Colors.grey,
                                  ),
                                  onPressed: () {
                                    Clipboard.setData(
                                      ClipboardData(text: _translatedText),
                                    );
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Teks disalin ke clipboard!',
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 24),

              // Translate Button
              ElevatedButton.icon(
                icon: const Icon(Icons.translate),
                onPressed: _isLoading
                    ? null
                    : _translateText, // Disable button while loading
                label: const Text('Terjemahkan'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
