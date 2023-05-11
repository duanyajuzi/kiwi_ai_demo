import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:dio/dio.dart';


class ChatGptService {
  static const String _apiKey = 'YOUR_API_KEY_HERE';
  static const String _apiUrl = 'https://api.openai.com/v1/chat/completions';
  final Dio _dio = Dio();
  Future<String> getResponse(String prompt) async {
    final response = await _dio.post(
        'https://api.openai.com/v1/chat/completions',
        data:{
          'model': 'gpt-3.5-turbo',
          'messages':[
            {
              "role": "user",
              "content": prompt
            }
          ],
          "temperature": 1,
          "top_p": 1,
          "n": 1,
          "stream": false,
          "max_tokens": 250,
          "presence_penalty": 0,
          "frequency_penalty": 0
        },
        options: Options(
            headers: {'Authorization': 'Bearer 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'}
        )
    );

    if (response.statusCode == 200) {

      return response.data['choices'][0]['message']['content'];
    } else {
      throw Exception('Failed to get response from ChatGPT API');
    }
  }
}
